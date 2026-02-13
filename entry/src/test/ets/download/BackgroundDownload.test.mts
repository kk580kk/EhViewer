import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { DownloadService } from '../../../main/ets/download/DownloadService.ets';
import type { NotificationAdapter, DownloadedItem } from '../../../main/ets/download/DownloadService.ets';
import { OhosBackgroundTaskHandle } from '../../../main/ets/platform/OhosBackgroundTaskHandle.ets';
import type { BackgroundTaskManagerApi } from '../../../main/ets/platform/OhosBackgroundTaskHandle.ets';
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

/** Records calls to the background task manager API. */
class SpyBackgroundTaskManagerApi implements BackgroundTaskManagerApi {
  startCalls = 0;
  stopCalls = 0;
  shouldFailStart = false;

  async startBackgroundRunning(): Promise<void> {
    this.startCalls++;
    if (this.shouldFailStart) {
      throw new Error('start failed');
    }
  }

  async stopBackgroundRunning(): Promise<void> {
    this.stopCalls++;
  }
}

class StubNotification implements NotificationAdapter {
  showDownloading(): void {}
  showDownloaded(): void {}
  show509Alert(): void {}
  cancelDownloading(): void {}
}

// ---------------------------------------------------------------------------
// Integration tests: DownloadService + OhosBackgroundTaskHandle
// ---------------------------------------------------------------------------

describe('Background download integration', () => {
  let db: MemoryDownloadDB;
  let mgr: DownloadManager;
  let service: DownloadService;
  let api: SpyBackgroundTaskManagerApi;
  let bgTask: OhosBackgroundTaskHandle;

  beforeEach(() => {
    SettingsService.initialize(new MemoryPreferencesStore());
    db = new MemoryDownloadDB();
    mgr = new DownloadManager(db);
    service = new DownloadService();
    api = new SpyBackgroundTaskManagerApi();
    bgTask = new OhosBackgroundTaskHandle(api);
    service.start(mgr, bgTask, new StubNotification());
  });

  it('should request OS background running when download starts', async () => {
    mgr.startDownload(makeGallery(1));
    await Promise.resolve();

    assert.strictEqual(bgTask.isRunning(), true);
    assert.strictEqual(api.startCalls, 1);
  });

  it('should release OS background running when all downloads complete', async () => {
    mgr.startDownload(makeGallery(1));
    await Promise.resolve();
    assert.strictEqual(bgTask.isRunning(), true);

    mgr.onDownloadFinished(10, 10, 10);
    await Promise.resolve();
    assert.strictEqual(bgTask.isRunning(), false);
    assert.strictEqual(api.stopCalls, 1);
  });

  it('should keep background running while queued downloads remain', async () => {
    mgr.startDownload(makeGallery(1));
    mgr.startDownload(makeGallery(2));
    await Promise.resolve();

    // Finish first download — second should still keep background running
    mgr.onDownloadFinished(10, 10, 10);
    await Promise.resolve();
    assert.strictEqual(bgTask.isRunning(), true);
    assert.strictEqual(api.stopCalls, 0);

    // Finish second download — now background should be released
    mgr.onDownloadFinished(10, 10, 10);
    await Promise.resolve();
    assert.strictEqual(bgTask.isRunning(), false);
    assert.strictEqual(api.stopCalls, 1);
  });

  it('should release background running when download is stopped', async () => {
    mgr.startDownload(makeGallery(1));
    await Promise.resolve();
    assert.strictEqual(bgTask.isRunning(), true);

    mgr.stopDownload(1);
    await Promise.resolve();
    assert.strictEqual(bgTask.isRunning(), false);
  });

  it('should release background running when service is stopped', async () => {
    mgr.startDownload(makeGallery(1));
    await Promise.resolve();
    assert.strictEqual(bgTask.isRunning(), true);

    service.stop();
    await Promise.resolve();
    assert.strictEqual(bgTask.isRunning(), false);
  });

  it('should handle OS background request failure gracefully', async () => {
    api.shouldFailStart = true;
    mgr.startDownload(makeGallery(1));
    // Let the promise rejection handler run
    await new Promise(resolve => setTimeout(resolve, 10));

    // Background running should be reset to false after failure
    assert.strictEqual(bgTask.isRunning(), false);
    // Download should still be tracked in the manager
    assert.strictEqual(mgr.getDownloadState(1), DownloadInfo.STATE_DOWNLOAD);
  });

  it('should re-request background running on new download after failure', async () => {
    api.shouldFailStart = true;
    mgr.startDownload(makeGallery(1));
    await new Promise(resolve => setTimeout(resolve, 10));
    assert.strictEqual(bgTask.isRunning(), false);

    // Finish gallery 1 so the slot is free
    mgr.onDownloadFinished(10, 10, 10);

    // Fix the API and start another download
    api.shouldFailStart = false;
    mgr.startDownload(makeGallery(2));
    await Promise.resolve();
    // The new onStart re-requests background running
    assert.strictEqual(bgTask.isRunning(), true);
    assert.strictEqual(api.startCalls, 2);
  });

  it('should not request background running after service stop', () => {
    service.stop();
    // Starting a download after stop should not reach the bgTask
    // (service detaches from download manager)
    mgr.startDownload(makeGallery(1));
    assert.strictEqual(bgTask.isRunning(), false);
    assert.strictEqual(api.startCalls, 0);
  });
});
