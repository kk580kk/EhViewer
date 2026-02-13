import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

import { SpiderScheduler } from '../../../main/ets/spider/SpiderScheduler.ets';
import type { SpiderFactory, SpiderContext } from '../../../main/ets/spider/SpiderScheduler.ets';
import { DownloadManager } from '../../../main/ets/download/DownloadManager.ets';
import { DownloadInfo } from '../../../main/ets/download/DownloadInfo.ets';
import { MemoryDownloadDB } from '../../../main/ets/download/MemoryDownloadDB.ets';
import { GalleryInfo } from '../../../main/ets/model/GalleryInfo.ets';
import { SettingsService } from '../../../main/ets/service/SettingsService.ets';
import { MemoryPreferencesStore } from '../../../main/ets/preferences/MemoryPreferencesStore.ets';
import type { ImageDownloadListener } from '../../../main/ets/spider/ImageDownloader.ets';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function makeGallery(gid: number): GalleryInfo {
  const gi = new GalleryInfo();
  gi.gid = gid;
  gi.token = `tok_${gid}`;
  gi.title = `Gallery ${gid}`;
  gi.category = 2;
  gi.uploader = 'test_user';
  gi.rating = 4.0;
  return gi;
}

// ---------------------------------------------------------------------------
// Stub ImageDownloader — controllable from tests
// ---------------------------------------------------------------------------

class StubImageDownloader {
  private listeners: ImageDownloadListener[] = [];
  paused = false;
  cancelled = false;
  resumed = false;
  downloadAllCalled = false;

  addListener(listener: ImageDownloadListener): void {
    this.listeners.push(listener);
  }

  removeListener(listener: ImageDownloadListener): void {
    const idx = this.listeners.indexOf(listener);
    if (idx >= 0) this.listeners.splice(idx, 1);
  }

  pause(): void { this.paused = true; }
  resume(): void { this.resumed = true; this.paused = false; }
  cancel(): void { this.cancelled = true; }
  isPaused(): boolean { return this.paused; }
  isCancelled(): boolean { return this.cancelled; }

  async downloadAll(): Promise<void> {
    this.downloadAllCalled = true;
    // Does nothing — tests will manually trigger events via simulateXxx methods.
  }

  // ---- Test helpers: simulate events ----

  simulatePageSuccess(index: number, finished: number, downloaded: number, total: number): void {
    for (const l of this.listeners) {
      l.onPageSuccess(index, finished, downloaded, total);
    }
  }

  simulatePageFailure(index: number, error: string, finished: number, downloaded: number, total: number): void {
    for (const l of this.listeners) {
      l.onPageFailure(index, error, finished, downloaded, total);
    }
  }

  simulateFinish(finished: number, downloaded: number, total: number): void {
    for (const l of this.listeners) {
      l.onFinish(finished, downloaded, total);
    }
  }

  // Required by ImageDownloader interface but unused in scheduler
  getFinished(): number { return 0; }
  getDownloaded(): number { return 0; }
  getPageStates(): ReadonlyArray<number> { return []; }
}

// ---------------------------------------------------------------------------
// Mock SpiderFactory
// ---------------------------------------------------------------------------

class MockSpiderFactory implements SpiderFactory {
  /** Map of gid -> most recent stub downloader created for that task. */
  created: Map<number, StubImageDownloader> = new Map();
  /** Total number of createSpider calls. */
  createCount = 0;

  createSpider(info: DownloadInfo): SpiderContext {
    this.createCount++;
    const downloader = new StubImageDownloader();
    this.created.set(info.gid, downloader);
    return { downloader: downloader as unknown as import('../../../main/ets/spider/ImageDownloader.ets').ImageDownloader };
  }

  getDownloader(gid: number): StubImageDownloader {
    const d = this.created.get(gid);
    if (!d) throw new Error(`No downloader created for gid ${gid}`);
    return d;
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe('SpiderScheduler', () => {
  let db: MemoryDownloadDB;
  let mgr: DownloadManager;
  let factory: MockSpiderFactory;
  let scheduler: SpiderScheduler;

  beforeEach(() => {
    SettingsService.initialize(new MemoryPreferencesStore());
    db = new MemoryDownloadDB();
    mgr = new DownloadManager(db);
    factory = new MockSpiderFactory();
    scheduler = new SpiderScheduler(mgr, factory);
  });

  // =========================================================================
  // Start download → spider creation
  // =========================================================================

  describe('start download', () => {
    it('should create spider when DownloadManager starts a task', () => {
      mgr.startDownload(makeGallery(1));
      assert.strictEqual(factory.created.size, 1);
      assert.ok(factory.created.has(1));
    });

    it('should call downloadAll on the created spider', () => {
      mgr.startDownload(makeGallery(1));
      const dl = factory.getDownloader(1);
      assert.strictEqual(dl.downloadAllCalled, true);
    });

    it('should track spider as active', () => {
      mgr.startDownload(makeGallery(1));
      assert.strictEqual(scheduler.getActiveCount(), 1);
      assert.strictEqual(scheduler.hasActive(1), true);
    });

    it('should not create duplicate spiders for same gid', () => {
      mgr.startDownload(makeGallery(1));
      // Trying to start again (e.g. re-queue) should be no-op in DownloadManager
      // because the task is already active
      mgr.startDownload(makeGallery(1));
      assert.strictEqual(factory.created.size, 1);
    });
  });

  // =========================================================================
  // Progress forwarding
  // =========================================================================

  describe('progress forwarding', () => {
    it('should forward page success to DownloadManager progress', () => {
      mgr.startDownload(makeGallery(1));
      const dl = factory.getDownloader(1);

      dl.simulatePageSuccess(0, 1, 1, 10);

      const info = mgr.getDownloadInfo(1)!;
      assert.strictEqual(info.finished, 1);
      assert.strictEqual(info.downloaded, 1);
      assert.strictEqual(info.total, 10);
    });

    it('should forward page failure to DownloadManager progress', () => {
      mgr.startDownload(makeGallery(1));
      const dl = factory.getDownloader(1);

      dl.simulatePageFailure(0, 'timeout', 0, 1, 10);

      const info = mgr.getDownloadInfo(1)!;
      assert.strictEqual(info.downloaded, 1);
      assert.strictEqual(info.total, 10);
    });
  });

  // =========================================================================
  // Finish forwarding
  // =========================================================================

  describe('finish forwarding', () => {
    it('should forward finish to DownloadManager and mark as FINISH', () => {
      mgr.startDownload(makeGallery(1));
      const dl = factory.getDownloader(1);

      dl.simulateFinish(10, 10, 10);

      assert.strictEqual(mgr.getDownloadState(1), DownloadInfo.STATE_FINISH);
    });

    it('should mark as FAILED when not all pages finished', () => {
      mgr.startDownload(makeGallery(1));
      const dl = factory.getDownloader(1);

      dl.simulateFinish(8, 10, 10);

      assert.strictEqual(mgr.getDownloadState(1), DownloadInfo.STATE_FAILED);
      assert.strictEqual(mgr.getDownloadInfo(1)!.legacy, 2);
    });

    it('should remove spider from active map after finish', () => {
      mgr.startDownload(makeGallery(1));
      const dl = factory.getDownloader(1);

      dl.simulateFinish(10, 10, 10);

      assert.strictEqual(scheduler.hasActive(1), false);
      assert.strictEqual(scheduler.getActiveCount(), 0);
    });

    it('should auto-start next queued task after finish', () => {
      mgr.startDownload(makeGallery(1));
      mgr.startDownload(makeGallery(2));
      assert.strictEqual(mgr.getDownloadState(2), DownloadInfo.STATE_WAIT);

      const dl1 = factory.getDownloader(1);
      dl1.simulateFinish(10, 10, 10);

      // Task 2 should now be downloading with its own spider
      assert.strictEqual(mgr.getDownloadState(2), DownloadInfo.STATE_DOWNLOAD);
      assert.ok(factory.created.has(2));
      assert.strictEqual(scheduler.hasActive(2), true);
    });
  });

  // =========================================================================
  // Pause / Resume
  // =========================================================================

  describe('pause', () => {
    it('should pause the spider when DownloadManager pauses', () => {
      mgr.startDownload(makeGallery(1));
      const dl = factory.getDownloader(1);

      mgr.pauseDownload(1);

      assert.strictEqual(dl.paused, true);
    });

    it('should be safe to pause unknown gid', () => {
      mgr.pauseDownload(999); // should not throw
    });
  });

  describe('resume', () => {
    it('should resume the spider when DownloadManager resumes', () => {
      mgr.startDownload(makeGallery(1));
      const dl = factory.getDownloader(1);

      mgr.pauseDownload(1);
      mgr.resumeDownload(1);

      assert.strictEqual(dl.resumed, true);
      assert.strictEqual(dl.paused, false);
    });
  });

  // =========================================================================
  // Cancel / Stop
  // =========================================================================

  describe('cancel', () => {
    it('should cancel the spider when DownloadManager stops a download', () => {
      mgr.startDownload(makeGallery(1));
      const dl = factory.getDownloader(1);

      mgr.stopDownload(1);

      assert.strictEqual(dl.cancelled, true);
      assert.strictEqual(scheduler.hasActive(1), false);
    });

    it('should cancel all spiders when stopAllDownload is called', () => {
      SettingsService.setConcurrentDownloadLimit(3);
      mgr.startDownload(makeGallery(1));
      mgr.startDownload(makeGallery(2));
      mgr.startDownload(makeGallery(3));

      mgr.stopAllDownload();

      assert.strictEqual(factory.getDownloader(1).cancelled, true);
      assert.strictEqual(factory.getDownloader(2).cancelled, true);
      assert.strictEqual(factory.getDownloader(3).cancelled, true);
      assert.strictEqual(scheduler.getActiveCount(), 0);
    });

    it('should cancel spider when deleteDownload is called', () => {
      mgr.startDownload(makeGallery(1));
      const dl = factory.getDownloader(1);

      mgr.deleteDownload(1);

      assert.strictEqual(dl.cancelled, true);
      assert.strictEqual(scheduler.hasActive(1), false);
    });
  });

  // =========================================================================
  // Concurrent downloads
  // =========================================================================

  describe('concurrent downloads', () => {
    it('should manage multiple spiders simultaneously', () => {
      SettingsService.setConcurrentDownloadLimit(3);
      mgr.startDownload(makeGallery(1));
      mgr.startDownload(makeGallery(2));
      mgr.startDownload(makeGallery(3));

      assert.strictEqual(scheduler.getActiveCount(), 3);
      assert.strictEqual(factory.created.size, 3);
    });

    it('should correctly finish one of concurrent tasks', () => {
      SettingsService.setConcurrentDownloadLimit(2);
      mgr.startDownload(makeGallery(1));
      mgr.startDownload(makeGallery(2));
      mgr.startDownload(makeGallery(3));

      // Finish task 1
      factory.getDownloader(1).simulateFinish(10, 10, 10);

      assert.strictEqual(mgr.getDownloadState(1), DownloadInfo.STATE_FINISH);
      assert.strictEqual(scheduler.hasActive(1), false);
      // Task 3 should be promoted
      assert.strictEqual(mgr.getDownloadState(3), DownloadInfo.STATE_DOWNLOAD);
      assert.strictEqual(scheduler.hasActive(3), true);
    });
  });

  // =========================================================================
  // Dispose
  // =========================================================================

  describe('dispose', () => {
    it('should cancel all active spiders', () => {
      SettingsService.setConcurrentDownloadLimit(2);
      mgr.startDownload(makeGallery(1));
      mgr.startDownload(makeGallery(2));

      scheduler.dispose();

      assert.strictEqual(factory.getDownloader(1).cancelled, true);
      assert.strictEqual(factory.getDownloader(2).cancelled, true);
      assert.strictEqual(scheduler.getActiveCount(), 0);
    });

    it('should detach all hooks', () => {
      scheduler.dispose();

      assert.strictEqual(mgr.onStartDownload, null);
      assert.strictEqual(mgr.onPauseDownload, null);
      assert.strictEqual(mgr.onResumeDownload, null);
      assert.strictEqual(mgr.onCancelDownload, null);
    });

    it('should not create spiders after dispose', () => {
      scheduler.dispose();
      mgr.startDownload(makeGallery(1));
      assert.strictEqual(factory.created.size, 0);
    });
  });

  // =========================================================================
  // Edge cases
  // =========================================================================

  describe('edge cases', () => {
    it('pause then stop should cancel spider and remove from active', () => {
      mgr.startDownload(makeGallery(1));
      const dl = factory.getDownloader(1);

      mgr.pauseDownload(1);
      mgr.stopDownload(1);

      assert.strictEqual(dl.cancelled, true);
      assert.strictEqual(scheduler.hasActive(1), false);
    });

    it('finish after cancel should be safe (spider already removed)', () => {
      mgr.startDownload(makeGallery(1));
      const dl = factory.getDownloader(1);

      mgr.stopDownload(1);
      // Late finish event from the spider (race condition)
      // Should not throw or corrupt state
      dl.simulateFinish(5, 10, 10);
      assert.strictEqual(scheduler.hasActive(1), false);
    });

    it('should handle re-start after finish', () => {
      mgr.startDownload(makeGallery(1));
      factory.getDownloader(1).simulateFinish(10, 10, 10);
      assert.strictEqual(mgr.getDownloadState(1), DownloadInfo.STATE_FINISH);

      // Re-start the same gallery
      mgr.startDownload(makeGallery(1));
      assert.strictEqual(mgr.getDownloadState(1), DownloadInfo.STATE_DOWNLOAD);
      assert.strictEqual(scheduler.hasActive(1), true);
      // A new (second) downloader should have been created
      assert.strictEqual(factory.createCount, 2);
    });
  });
});
