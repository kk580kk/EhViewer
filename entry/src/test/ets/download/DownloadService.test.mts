import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { DownloadService, DownloadAction } from '../../../main/ets/download/DownloadService.ets';
import type { BackgroundTaskHandle, NotificationAdapter, DownloadedItem, ActionParams } from '../../../main/ets/download/DownloadService.ets';
import { DownloadManager } from '../../../main/ets/download/DownloadManager.ets';
import { MemoryDownloadDB } from '../../../main/ets/download/MemoryDownloadDB.ets';
import { DownloadInfo } from '../../../main/ets/download/DownloadInfo.ets';
import { GalleryInfo } from '../../../main/ets/model/GalleryInfo.ets';
import { SettingsService } from '../../../main/ets/service/SettingsService.ets';
import { MemoryPreferencesStore } from '../../../main/ets/preferences/MemoryPreferencesStore.ets';

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

function makeGallery(gid: number, title: string = `Gallery ${gid}`): GalleryInfo {
  const gi = new GalleryInfo();
  gi.gid = gid;
  gi.token = `tok_${gid}`;
  gi.title = title;
  gi.category = 2;
  gi.uploader = 'test_user';
  gi.rating = 4.0;
  return gi;
}

/** Spy that records BackgroundTaskHandle calls. */
class SpyBackgroundTask implements BackgroundTaskHandle {
  requestCount = 0;
  cancelCount = 0;
  requestBackgroundRunning(): void { this.requestCount++; }
  cancelBackgroundRunning(): void { this.cancelCount++; }
}

/** Spy that records NotificationAdapter calls. */
class SpyNotification implements NotificationAdapter {
  downloadingCalls: { title: string; text: string; progress: number; total: number }[] = [];
  downloadedCalls: { text: string; items: DownloadedItem[] }[] = [];
  alert509Count = 0;
  cancelDownloadingCount = 0;

  showDownloading(title: string, text: string, progress: number, total: number): void {
    this.downloadingCalls.push({ title, text, progress, total });
  }
  showDownloaded(text: string, items: DownloadedItem[]): void {
    this.downloadedCalls.push({ text, items: [...items] });
  }
  show509Alert(): void { this.alert509Count++; }
  cancelDownloading(): void { this.cancelDownloadingCount++; }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe('DownloadService', () => {
  let db: MemoryDownloadDB;
  let mgr: DownloadManager;
  let service: DownloadService;
  let bgTask: SpyBackgroundTask;
  let notif: SpyNotification;

  beforeEach(() => {
    SettingsService.initialize(new MemoryPreferencesStore());
    db = new MemoryDownloadDB();
    mgr = new DownloadManager(db);
    service = new DownloadService();
    bgTask = new SpyBackgroundTask();
    notif = new SpyNotification();
  });

  // =========================================================================
  // Lifecycle
  // =========================================================================

  describe('lifecycle', () => {
    it('should not be running before start', () => {
      assert.strictEqual(service.isRunning(), false);
    });

    it('should be running after start', () => {
      service.start(mgr, bgTask, notif);
      assert.strictEqual(service.isRunning(), true);
    });

    it('should not be running after stop', () => {
      service.start(mgr, bgTask, notif);
      service.stop();
      assert.strictEqual(service.isRunning(), false);
    });

    it('start should be idempotent', () => {
      service.start(mgr, bgTask, notif);
      service.start(mgr, bgTask, notif); // no-op
      assert.strictEqual(service.isRunning(), true);
    });

    it('stop should be idempotent', () => {
      service.start(mgr, bgTask, notif);
      service.stop();
      service.stop(); // no-op
      assert.strictEqual(service.isRunning(), false);
    });

    it('stop should cancel background running', () => {
      service.start(mgr, bgTask, notif);
      service.stop();
      assert.strictEqual(bgTask.cancelCount, 1);
    });

    it('should work without optional adapters', () => {
      service.start(mgr);
      assert.strictEqual(service.isRunning(), true);
      // Should not throw when starting downloads without notification
      mgr.startDownload(makeGallery(1));
      service.stop();
    });
  });

  // =========================================================================
  // Action handling
  // =========================================================================

  describe('handleAction', () => {
    beforeEach(() => {
      service.start(mgr, bgTask, notif);
    });

    it('START should start a download', () => {
      service.handleAction(DownloadAction.START, {
        galleryInfo: makeGallery(1),
        label: null,
      });
      assert.strictEqual(mgr.containDownloadInfo(1), true);
      assert.strictEqual(mgr.getDownloadState(1), DownloadInfo.STATE_DOWNLOAD);
    });

    it('START with label should assign label', () => {
      mgr.addLabel('Comics');
      service.handleAction(DownloadAction.START, {
        galleryInfo: makeGallery(1),
        label: 'Comics',
      });
      assert.strictEqual(mgr.getDownloadInfo(1)!.label, 'Comics');
    });

    it('START_RANGE should start multiple downloads', () => {
      mgr.addDownload(makeGallery(1));
      mgr.addDownload(makeGallery(2));
      service.handleAction(DownloadAction.START_RANGE, { gidList: [1, 2] });

      const state1 = mgr.getDownloadState(1);
      const state2 = mgr.getDownloadState(2);
      assert.ok(
        state1 === DownloadInfo.STATE_DOWNLOAD || state1 === DownloadInfo.STATE_WAIT
      );
      assert.ok(
        state2 === DownloadInfo.STATE_DOWNLOAD || state2 === DownloadInfo.STATE_WAIT
      );
    });

    it('START_ALL should start all idle downloads', () => {
      mgr.addDownload(makeGallery(1));
      mgr.addDownload(makeGallery(2));
      service.handleAction(DownloadAction.START_ALL);

      const states = [mgr.getDownloadState(1), mgr.getDownloadState(2)];
      assert.ok(states.includes(DownloadInfo.STATE_DOWNLOAD));
    });

    it('STOP should stop a download', () => {
      mgr.startDownload(makeGallery(1));
      service.handleAction(DownloadAction.STOP, { gid: 1 });
      assert.strictEqual(mgr.getDownloadState(1), DownloadInfo.STATE_NONE);
    });

    it('STOP_CURRENT should stop the current download', () => {
      mgr.startDownload(makeGallery(1));
      service.handleAction(DownloadAction.STOP_CURRENT);
      assert.strictEqual(mgr.getCurrentTask(), null);
    });

    it('STOP_RANGE should stop specified downloads', () => {
      mgr.startDownload(makeGallery(1));
      mgr.startDownload(makeGallery(2));
      mgr.startDownload(makeGallery(3));
      service.handleAction(DownloadAction.STOP_RANGE, { gidList: [1, 3] });
      assert.strictEqual(mgr.getDownloadState(1), DownloadInfo.STATE_NONE);
      assert.strictEqual(mgr.getDownloadState(3), DownloadInfo.STATE_NONE);
    });

    it('STOP_ALL should stop all downloads', () => {
      mgr.startDownload(makeGallery(1));
      mgr.startDownload(makeGallery(2));
      service.handleAction(DownloadAction.STOP_ALL);
      assert.strictEqual(mgr.isIdle(), true);
    });

    it('DELETE should delete a download', () => {
      mgr.startDownload(makeGallery(1));
      service.handleAction(DownloadAction.DELETE, { gid: 1 });
      assert.strictEqual(mgr.containDownloadInfo(1), false);
    });

    it('DELETE_RANGE should delete multiple downloads', () => {
      mgr.startDownload(makeGallery(1));
      mgr.startDownload(makeGallery(2));
      service.handleAction(DownloadAction.DELETE_RANGE, { gidList: [1, 2] });
      assert.strictEqual(mgr.containDownloadInfo(1), false);
      assert.strictEqual(mgr.containDownloadInfo(2), false);
    });

    it('CLEAR should reset stats', () => {
      mgr.startDownload(makeGallery(1));
      mgr.onDownloadFinished(10, 10, 10);
      assert.strictEqual(service.getStats().finishedCount, 1);

      service.handleAction(DownloadAction.CLEAR);
      assert.strictEqual(service.getStats().finishedCount, 0);
      assert.strictEqual(service.getStats().downloadedCount, 0);
    });

    it('should be no-op when not started', () => {
      const unstarted = new DownloadService();
      // Should not throw
      unstarted.handleAction(DownloadAction.START, { galleryInfo: makeGallery(1) });
    });

    it('should ignore START without galleryInfo', () => {
      service.handleAction(DownloadAction.START, {});
      assert.strictEqual(mgr.getAllDownloadInfoList().length, 0);
    });

    it('should ignore STOP without gid', () => {
      mgr.startDownload(makeGallery(1));
      service.handleAction(DownloadAction.STOP, {});
      // Download should still be running
      assert.strictEqual(mgr.getDownloadState(1), DownloadInfo.STATE_DOWNLOAD);
    });
  });

  // =========================================================================
  // Background task management
  // =========================================================================

  describe('background task management', () => {
    beforeEach(() => {
      service.start(mgr, bgTask, notif);
    });

    it('should request background running when download starts', () => {
      mgr.startDownload(makeGallery(1));
      assert.ok(bgTask.requestCount >= 1);
    });

    it('should cancel background running when all downloads finish', () => {
      mgr.startDownload(makeGallery(1));
      mgr.onDownloadFinished(10, 10, 10);
      assert.ok(bgTask.cancelCount >= 1);
    });

    it('should cancel background running when download is cancelled', () => {
      mgr.startDownload(makeGallery(1));
      mgr.stopDownload(1);
      assert.ok(bgTask.cancelCount >= 1);
    });

    it('should not cancel background running while downloads are queued', () => {
      mgr.startDownload(makeGallery(1));
      mgr.startDownload(makeGallery(2));
      const cancelBefore = bgTask.cancelCount;
      mgr.onDownloadFinished(10, 10, 10); // finish #1, #2 starts
      // Should not have cancelled — still active
      assert.strictEqual(bgTask.cancelCount, cancelBefore);
    });

    it('should cancel background running via STOP_ALL', () => {
      mgr.startDownload(makeGallery(1));
      service.handleAction(DownloadAction.STOP_ALL);
      assert.ok(bgTask.cancelCount >= 1);
    });
  });

  // =========================================================================
  // DownloadListener (notification behavior)
  // =========================================================================

  describe('notification behavior', () => {
    beforeEach(() => {
      service.start(mgr, bgTask, notif);
    });

    it('should show downloading notification on start', () => {
      mgr.startDownload(makeGallery(1, 'Test Gallery'));
      assert.strictEqual(notif.downloadingCalls.length, 1);
      assert.strictEqual(notif.downloadingCalls[0].title, 'Test Gallery');
    });

    it('should cancel downloading notification on finish', () => {
      mgr.startDownload(makeGallery(1));
      mgr.onDownloadFinished(10, 10, 10);
      assert.ok(notif.cancelDownloadingCount >= 1);
    });

    it('should show downloaded notification on finish', () => {
      mgr.startDownload(makeGallery(1, 'My Gallery'));
      mgr.onDownloadFinished(10, 10, 10);
      assert.strictEqual(notif.downloadedCalls.length, 1);
      assert.ok(notif.downloadedCalls[0].text.includes('My Gallery'));
    });

    it('should cancel downloading notification on cancel', () => {
      mgr.startDownload(makeGallery(1));
      mgr.stopDownload(1);
      assert.ok(notif.cancelDownloadingCount >= 1);
    });

    it('should show 509 alert', () => {
      service.onGet509();
      assert.strictEqual(notif.alert509Count, 1);
    });

    it('should update downloading notification on progress', () => {
      mgr.startDownload(makeGallery(1, 'Progress Gallery'));
      const info = mgr.getDownloadInfo(1)!;
      info.speed = 1048576; // 1 MB/s
      info.remaining = 30000; // 30s
      info.finished = 5;
      info.total = 10;

      service.onDownloadProgress(info);

      const last = notif.downloadingCalls[notif.downloadingCalls.length - 1];
      assert.strictEqual(last.title, 'Progress Gallery');
      assert.ok(last.text.includes('/s'));
      assert.strictEqual(last.progress, 5);
      assert.strictEqual(last.total, 10);
    });
  });

  // =========================================================================
  // Stats tracking
  // =========================================================================

  describe('stats tracking', () => {
    beforeEach(() => {
      service.start(mgr, bgTask, notif);
    });

    it('should track finished download', () => {
      mgr.startDownload(makeGallery(1));
      mgr.onDownloadFinished(10, 10, 10);

      const stats = service.getStats();
      assert.strictEqual(stats.finishedCount, 1);
      assert.strictEqual(stats.failedCount, 0);
      assert.strictEqual(stats.downloadedCount, 1);
    });

    it('should track failed download', () => {
      mgr.startDownload(makeGallery(1));
      mgr.onDownloadFinished(5, 10, 10); // legacy = 5

      const stats = service.getStats();
      assert.strictEqual(stats.finishedCount, 0);
      assert.strictEqual(stats.failedCount, 1);
      assert.strictEqual(stats.downloadedCount, 1);
    });

    it('should track multiple downloads', () => {
      mgr.startDownload(makeGallery(1));
      mgr.onDownloadFinished(10, 10, 10); // success
      mgr.startDownload(makeGallery(2));
      mgr.onDownloadFinished(5, 10, 10); // fail

      const stats = service.getStats();
      assert.strictEqual(stats.finishedCount, 1);
      assert.strictEqual(stats.failedCount, 1);
      assert.strictEqual(stats.downloadedCount, 2);
    });

    it('should update state when retrying same download', () => {
      mgr.startDownload(makeGallery(1));
      mgr.onDownloadFinished(5, 10, 10); // fail first time

      let stats = service.getStats();
      assert.strictEqual(stats.failedCount, 1);

      // Retry and succeed
      mgr.startDownload(makeGallery(1));
      mgr.onDownloadFinished(10, 10, 10);

      stats = service.getStats();
      assert.strictEqual(stats.finishedCount, 1);
      assert.strictEqual(stats.failedCount, 0);
      assert.strictEqual(stats.downloadedCount, 1); // still 1 unique download
    });

    it('should clear stats', () => {
      mgr.startDownload(makeGallery(1));
      mgr.onDownloadFinished(10, 10, 10);
      service.clearStats();

      const stats = service.getStats();
      assert.strictEqual(stats.finishedCount, 0);
      assert.strictEqual(stats.failedCount, 0);
      assert.strictEqual(stats.downloadedCount, 0);
      assert.strictEqual(stats.items.size, 0);
    });

    it('should include item details in stats', () => {
      mgr.startDownload(makeGallery(1, 'Gallery A'));
      mgr.onDownloadFinished(10, 10, 10);

      const stats = service.getStats();
      const item = stats.items.get(1);
      assert.ok(item !== undefined);
      assert.strictEqual(item!.title, 'Gallery A');
      assert.strictEqual(item!.finished, true);
    });
  });

  // =========================================================================
  // Downloaded notification text
  // =========================================================================

  describe('downloaded notification text', () => {
    beforeEach(() => {
      service.start(mgr, bgTask, notif);
    });

    it('should show single success text', () => {
      mgr.startDownload(makeGallery(1, 'My Gallery'));
      mgr.onDownloadFinished(10, 10, 10);

      const call = notif.downloadedCalls[0];
      assert.ok(call.text.includes('My Gallery'));
      assert.ok(call.text.includes('downloaded'));
    });

    it('should show count for multiple successes', () => {
      mgr.startDownload(makeGallery(1));
      mgr.onDownloadFinished(10, 10, 10);
      mgr.startDownload(makeGallery(2));
      mgr.onDownloadFinished(10, 10, 10);

      const lastCall = notif.downloadedCalls[notif.downloadedCalls.length - 1];
      assert.ok(lastCall.text.includes('2'));
    });

    it('should show single failure text', () => {
      mgr.startDownload(makeGallery(1, 'Failed Gallery'));
      mgr.onDownloadFinished(5, 10, 10);

      const call = notif.downloadedCalls[0];
      assert.ok(call.text.includes('Failed Gallery'));
      assert.ok(call.text.includes('failed'));
    });

    it('should show mixed text for success and failure', () => {
      mgr.startDownload(makeGallery(1));
      mgr.onDownloadFinished(10, 10, 10); // success
      mgr.startDownload(makeGallery(2));
      mgr.onDownloadFinished(5, 10, 10); // fail

      const lastCall = notif.downloadedCalls[notif.downloadedCalls.length - 1];
      assert.ok(lastCall.text.includes('downloaded'));
      assert.ok(lastCall.text.includes('failed'));
    });
  });

  // =========================================================================
  // Title resolution
  // =========================================================================

  describe('title resolution', () => {
    beforeEach(() => {
      service.start(mgr, bgTask, notif);
    });

    it('should prefer titleJpn over title', () => {
      const gi = makeGallery(1, 'English Title');
      gi.titleJpn = 'Japanese Title';
      mgr.startDownload(gi);

      assert.strictEqual(notif.downloadingCalls[0].title, 'Japanese Title');
    });

    it('should fall back to title when titleJpn is empty', () => {
      const gi = makeGallery(1, 'English Title');
      gi.titleJpn = '';
      mgr.startDownload(gi);

      assert.strictEqual(notif.downloadingCalls[0].title, 'English Title');
    });

    it('should fall back to gid when both titles are empty', () => {
      const gi = makeGallery(42);
      gi.title = '';
      gi.titleJpn = '';
      mgr.startDownload(gi);

      assert.strictEqual(notif.downloadingCalls[0].title, 'Gallery 42');
    });
  });

  // =========================================================================
  // Edge cases
  // =========================================================================

  describe('edge cases', () => {
    it('should handle rapid start/stop cycles', () => {
      service.start(mgr, bgTask, notif);
      for (let i = 1; i <= 10; i++) {
        mgr.startDownload(makeGallery(i));
      }
      mgr.stopAllDownload();

      assert.strictEqual(mgr.isIdle(), true);
      assert.ok(bgTask.cancelCount >= 1);
    });

    it('should handle actions after stop', () => {
      service.start(mgr, bgTask, notif);
      service.stop();
      // Should not throw
      service.handleAction(DownloadAction.START, { galleryInfo: makeGallery(1) });
    });

    it('should handle progress update without notification', () => {
      service.start(mgr); // no notification adapter
      mgr.startDownload(makeGallery(1));
      const info = mgr.getDownloadInfo(1)!;
      info.speed = 1000;
      // Should not throw
      service.onDownloadProgress(info);
    });

    it('should handle 509 without notification', () => {
      service.start(mgr); // no notification adapter
      // Should not throw
      service.onGet509();
    });
  });
});
