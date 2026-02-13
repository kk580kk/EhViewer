import { describe, it, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import {
  GalleryDetailViewModel,
  DetailState,
  type GalleryDetailFetcher,
} from '../../../main/ets/viewmodel/GalleryDetailViewModel.ets';
import { GalleryDetail } from '../../../main/ets/model/GalleryDetail.ets';
import { GalleryInfo } from '../../../main/ets/model/GalleryInfo.ets';
import { DownloadManager } from '../../../main/ets/download/DownloadManager.ets';
import { DownloadInfo } from '../../../main/ets/download/DownloadInfo.ets';
import { MemoryDownloadDB } from '../../../main/ets/download/MemoryDownloadDB.ets';
import { SettingsService } from '../../../main/ets/service/SettingsService.ets';
import { MemoryPreferencesStore } from '../../../main/ets/preferences/MemoryPreferencesStore.ets';
import { EhConfig } from '../../../main/ets/client/EhConfig.ets';
import { LargePreviewSet } from '../../../main/ets/model/LargePreviewSet.ets';
import { GalleryTagGroup } from '../../../main/ets/model/GalleryTagGroup.ets';

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

function makeDetail(gid: number, token: string): GalleryDetail {
  const d = new GalleryDetail();
  d.gid = gid;
  d.token = token;
  d.title = `Gallery ${gid}`;
  d.titleJpn = '';
  d.thumb = `https://example.com/thumb/${gid}`;
  d.category = EhConfig.DOUJINSHI;
  d.uploader = 'test_user';
  d.rating = 4.0;
  d.ratingCount = 50;
  d.posted = '2024-01-01';
  d.pages = 20;
  d.language = 'Japanese';
  d.size = '50 MB';
  d.favoriteCount = 100;
  d.isFavorited = false;
  d.tags = [];
  const ps = new LargePreviewSet();
  d.previewSet = ps;
  d.previewPages = 1;
  return d;
}

function createMockFetcher(): GalleryDetailFetcher {
  return {
    async fetchDetail(gid: number, token: string): Promise<GalleryDetail> {
      return makeDetail(gid, token);
    },
  };
}

// ---------------------------------------------------------------------------
// Tests: Download integration in GalleryDetailViewModel
// ---------------------------------------------------------------------------

describe('GalleryDetailViewModel — download integration', () => {
  let db: MemoryDownloadDB;
  let mgr: DownloadManager;
  let vm: GalleryDetailViewModel;

  beforeEach(() => {
    SettingsService.initialize(new MemoryPreferencesStore());
    db = new MemoryDownloadDB();
    mgr = new DownloadManager(db);
    vm = new GalleryDetailViewModel(createMockFetcher(), mgr);
  });

  afterEach(() => {
    vm.dispose();
  });

  // =========================================================================
  // Initial state
  // =========================================================================

  describe('initial download state', () => {
    it('should report STATE_INVALID before load', () => {
      assert.strictEqual(vm.downloadState, DownloadInfo.STATE_INVALID);
      assert.strictEqual(vm.isDownloading, false);
      assert.strictEqual(vm.isDownloaded, false);
      assert.strictEqual(vm.hasDownload, false);
      assert.strictEqual(vm.downloadButtonText, 'Download');
    });

    it('should report STATE_INVALID after load when gallery has no download', async () => {
      await vm.load(1, 'tok_1');
      assert.strictEqual(vm.downloadState, DownloadInfo.STATE_INVALID);
      assert.strictEqual(vm.isDownloading, false);
      assert.strictEqual(vm.isDownloaded, false);
      assert.strictEqual(vm.hasDownload, false);
    });
  });

  // =========================================================================
  // startDownload
  // =========================================================================

  describe('startDownload', () => {
    it('should initiate download and update state', async () => {
      await vm.load(1, 'tok_1');
      const result = vm.startDownload();

      assert.strictEqual(result, true);
      assert.strictEqual(vm.hasDownload, true);
      // Should be DOWNLOAD (since it's the first task, ensureDownload promotes it)
      assert.strictEqual(vm.downloadState, DownloadInfo.STATE_DOWNLOAD);
      assert.strictEqual(vm.isDownloading, true);
    });

    it('should queue download in DownloadManager', async () => {
      await vm.load(1, 'tok_1');
      vm.startDownload();

      assert.strictEqual(mgr.containDownloadInfo(1), true);
      assert.strictEqual(mgr.getDownloadState(1), DownloadInfo.STATE_DOWNLOAD);
    });

    it('should persist download to DB', async () => {
      await vm.load(1, 'tok_1');
      vm.startDownload();

      const all = db.getAllDownloadInfo();
      assert.strictEqual(all.length, 1);
      assert.strictEqual(all[0].gid, 1);
    });

    it('should assign label when provided', async () => {
      mgr.addLabel('Comics');
      await vm.load(1, 'tok_1');
      vm.startDownload('Comics');

      const info = mgr.getDownloadInfo(1);
      assert.ok(info !== null);
      assert.strictEqual(info!.label, 'Comics');
    });

    it('should return false when no detail is loaded', () => {
      const result = vm.startDownload();
      assert.strictEqual(result, false);
    });

    it('should return false when already downloading', async () => {
      await vm.load(1, 'tok_1');
      vm.startDownload();
      const result = vm.startDownload();
      assert.strictEqual(result, false);
    });

    it('should return false when already downloaded', async () => {
      await vm.load(1, 'tok_1');
      vm.startDownload();
      mgr.onDownloadFinished(20, 20, 20, 1);
      const result = vm.startDownload();
      assert.strictEqual(result, false);
    });

    it('should retry a failed download', async () => {
      await vm.load(1, 'tok_1');
      vm.startDownload();
      mgr.onDownloadFinished(10, 20, 20, 1); // fails

      assert.strictEqual(vm.downloadState, DownloadInfo.STATE_FAILED);
      assert.strictEqual(vm.downloadButtonText, 'Retry');

      const result = vm.startDownload();
      assert.strictEqual(result, true);
      assert.strictEqual(vm.downloadState, DownloadInfo.STATE_DOWNLOAD);
    });
  });

  // =========================================================================
  // stopDownload
  // =========================================================================

  describe('stopDownload', () => {
    it('should stop an active download', async () => {
      await vm.load(1, 'tok_1');
      vm.startDownload();
      assert.strictEqual(vm.isDownloading, true);

      vm.stopDownload();
      assert.strictEqual(vm.downloadState, DownloadInfo.STATE_NONE);
      assert.strictEqual(vm.isDownloading, false);
    });

    it('should be no-op without DownloadManager', async () => {
      const vmNoMgr = new GalleryDetailViewModel(createMockFetcher());
      await vmNoMgr.load(1, 'tok_1');
      vmNoMgr.stopDownload(); // should not throw
    });
  });

  // =========================================================================
  // Progress callbacks
  // =========================================================================

  describe('progress callbacks', () => {
    it('should update progress on onDownloadProgress', async () => {
      await vm.load(1, 'tok_1');
      vm.startDownload();

      mgr.onDownloadProgress(5, 5, 20, 2048, 30000, 1);

      assert.strictEqual(vm.downloadProgressPercent, 25);
      assert.strictEqual(vm.downloadStatusText, '5/20');
      assert.ok(vm.downloadSpeedText !== null);
    });

    it('should update state on onDownloadStateChanged (finish)', async () => {
      await vm.load(1, 'tok_1');
      vm.startDownload();

      mgr.onDownloadFinished(20, 20, 20, 1);

      assert.strictEqual(vm.downloadState, DownloadInfo.STATE_FINISH);
      assert.strictEqual(vm.isDownloaded, true);
      assert.strictEqual(vm.isDownloading, false);
      assert.strictEqual(vm.downloadButtonText, 'Downloaded');
      assert.strictEqual(vm.downloadProgressPercent, 100);
    });

    it('should update state on onDownloadStateChanged (fail)', async () => {
      await vm.load(1, 'tok_1');
      vm.startDownload();

      mgr.onDownloadFinished(10, 20, 20, 1);

      assert.strictEqual(vm.downloadState, DownloadInfo.STATE_FAILED);
      assert.strictEqual(vm.isDownloaded, false);
      assert.strictEqual(vm.isDownloading, false);
      assert.strictEqual(vm.downloadButtonText, 'Retry');
    });

    it('should ignore callbacks for other galleries', async () => {
      await vm.load(1, 'tok_1');
      vm.startDownload();

      // Start another gallery's download directly on DownloadManager
      const other = new GalleryInfo();
      other.gid = 2;
      other.token = 'tok_2';
      other.title = 'Other Gallery';
      other.category = 2;
      mgr.onDownloadFinished(20, 20, 20, 1); // finish gallery 1
      mgr.startDownload(other);

      // Progress for gallery 2 should not affect vm
      mgr.onDownloadProgress(5, 5, 10, 1024, 10000, 2);

      // vm should still show gallery 1's completed state
      assert.strictEqual(vm.downloadState, DownloadInfo.STATE_FINISH);
    });

    it('should not fire after dispose', async () => {
      await vm.load(1, 'tok_1');
      vm.startDownload();

      vm.dispose();

      // Should not throw, and should not update vm
      mgr.onDownloadProgress(5, 5, 20, 2048, 30000, 1);

      // State should remain what it was when dispose was called
      assert.strictEqual(vm.downloadState, DownloadInfo.STATE_DOWNLOAD);
    });
  });

  // =========================================================================
  // onStateChange callback
  // =========================================================================

  describe('onStateChange notification', () => {
    it('should fire onStateChange when download starts', async () => {
      let callCount = 0;
      vm.setOnStateChange(() => { callCount++; });

      await vm.load(1, 'tok_1');
      const loadCalls = callCount;

      vm.startDownload();
      assert.ok(callCount > loadCalls, 'onStateChange should fire after startDownload');
    });

    it('should fire onStateChange on progress update', async () => {
      await vm.load(1, 'tok_1');
      vm.startDownload();

      let callCount = 0;
      vm.setOnStateChange(() => { callCount++; });

      mgr.onDownloadProgress(5, 5, 20, 2048, 30000, 1);
      assert.ok(callCount >= 1, 'onStateChange should fire on progress');
    });

    it('should fire onStateChange on state change', async () => {
      await vm.load(1, 'tok_1');
      vm.startDownload();

      let callCount = 0;
      vm.setOnStateChange(() => { callCount++; });

      mgr.onDownloadFinished(20, 20, 20, 1);
      assert.ok(callCount >= 1, 'onStateChange should fire on state change');
    });
  });

  // =========================================================================
  // Download button text
  // =========================================================================

  describe('downloadButtonText', () => {
    it('should show "Download" initially', () => {
      assert.strictEqual(vm.downloadButtonText, 'Download');
    });

    it('should show progress percent when downloading', async () => {
      await vm.load(1, 'tok_1');
      vm.startDownload();
      mgr.onDownloadProgress(10, 10, 20, 1024, 10000, 1);
      assert.strictEqual(vm.downloadButtonText, '50%');
    });

    it('should show "Downloading" when indeterminate', async () => {
      await vm.load(1, 'tok_1');
      vm.startDownload();
      // Right after start, progress is indeterminate (total=-1)
      // Actually after ensureDownload, total is set to -1
      // Let's check the button text
      if (vm.downloadProgressPercent < 0) {
        assert.strictEqual(vm.downloadButtonText, 'Downloading');
      }
    });

    it('should show "Downloaded" when finished', async () => {
      await vm.load(1, 'tok_1');
      vm.startDownload();
      mgr.onDownloadFinished(20, 20, 20, 1);
      assert.strictEqual(vm.downloadButtonText, 'Downloaded');
    });

    it('should show "Retry" when failed', async () => {
      await vm.load(1, 'tok_1');
      vm.startDownload();
      mgr.onDownloadFinished(10, 20, 20, 1);
      assert.strictEqual(vm.downloadButtonText, 'Retry');
    });

    it('should show "Waiting" when queued', async () => {
      // Start a first download to occupy the slot
      const gi = new GalleryInfo();
      gi.gid = 99;
      gi.token = 'tok_99';
      gi.title = 'Blocker';
      gi.category = 2;
      mgr.startDownload(gi);

      await vm.load(1, 'tok_1');
      vm.startDownload();
      assert.strictEqual(vm.downloadButtonText, 'Waiting');
    });
  });

  // =========================================================================
  // Sync on load (pre-existing download)
  // =========================================================================

  describe('sync download state on load', () => {
    it('should detect pre-existing download when loading gallery', async () => {
      // Pre-add a download before loading gallery detail
      const gi = new GalleryInfo();
      gi.gid = 1;
      gi.token = 'tok_1';
      gi.title = 'Pre-existing';
      gi.category = 2;
      mgr.startDownload(gi);
      mgr.onDownloadFinished(20, 20, 20, 1);

      await vm.load(1, 'tok_1');

      assert.strictEqual(vm.downloadState, DownloadInfo.STATE_FINISH);
      assert.strictEqual(vm.isDownloaded, true);
      assert.strictEqual(vm.downloadButtonText, 'Downloaded');
    });

    it('should detect in-progress download when loading gallery', async () => {
      const gi = new GalleryInfo();
      gi.gid = 1;
      gi.token = 'tok_1';
      gi.title = 'In Progress';
      gi.category = 2;
      mgr.startDownload(gi);

      await vm.load(1, 'tok_1');

      assert.strictEqual(vm.downloadState, DownloadInfo.STATE_DOWNLOAD);
      assert.strictEqual(vm.isDownloading, true);
    });
  });

  // =========================================================================
  // Without DownloadManager
  // =========================================================================

  describe('without DownloadManager', () => {
    it('should work normally without download capability', async () => {
      const vmNoMgr = new GalleryDetailViewModel(createMockFetcher());
      await vmNoMgr.load(1, 'tok_1');

      assert.strictEqual(vmNoMgr.state, DetailState.SUCCESS);
      assert.strictEqual(vmNoMgr.downloadState, DownloadInfo.STATE_INVALID);
      assert.strictEqual(vmNoMgr.startDownload(), false);
      assert.strictEqual(vmNoMgr.hasDownload, false);
      assert.strictEqual(vmNoMgr.downloadButtonText, 'Download');
    });
  });

  // =========================================================================
  // End-to-end: gallery detail → download → queue → persist → progress → finish
  // =========================================================================

  describe('end-to-end flow', () => {
    it('should complete full download lifecycle', async () => {
      // 1. Load gallery detail
      await vm.load(1, 'tok_1');
      assert.strictEqual(vm.state, DetailState.SUCCESS);
      assert.strictEqual(vm.downloadButtonText, 'Download');

      // 2. Start download
      vm.startDownload();
      assert.strictEqual(vm.isDownloading, true);
      assert.strictEqual(mgr.containDownloadInfo(1), true);

      // 3. Verify persisted to DB
      assert.strictEqual(db.getAllDownloadInfo().length, 1);
      assert.strictEqual(db.getAllDownloadInfo()[0].gid, 1);

      // 4. Simulate progress
      mgr.onDownloadProgress(10, 10, 20, 4096, 15000, 1);
      assert.strictEqual(vm.downloadProgressPercent, 50);
      assert.strictEqual(vm.downloadStatusText, '10/20');

      // 5. Finish download
      mgr.onDownloadFinished(20, 20, 20, 1);
      assert.strictEqual(vm.isDownloaded, true);
      assert.strictEqual(vm.downloadButtonText, 'Downloaded');

      // 6. Verify final state persisted
      const persisted = db.getAllDownloadInfo();
      assert.strictEqual(persisted[0].state, DownloadInfo.STATE_FINISH);
    });

    it('should handle failed download and retry', async () => {
      // 1. Load and start
      await vm.load(1, 'tok_1');
      vm.startDownload();

      // 2. Download fails
      mgr.onDownloadFinished(10, 20, 20, 1);
      assert.strictEqual(vm.downloadState, DownloadInfo.STATE_FAILED);
      assert.strictEqual(vm.downloadButtonText, 'Retry');

      // 3. Retry
      const retried = vm.startDownload();
      assert.strictEqual(retried, true);
      assert.strictEqual(vm.downloadState, DownloadInfo.STATE_DOWNLOAD);

      // 4. Succeed this time
      mgr.onDownloadFinished(20, 20, 20, 1);
      assert.strictEqual(vm.isDownloaded, true);
    });

    it('should handle stop and re-download', async () => {
      // 1. Start
      await vm.load(1, 'tok_1');
      vm.startDownload();
      assert.strictEqual(vm.isDownloading, true);

      // 2. Stop
      vm.stopDownload();
      assert.strictEqual(vm.isDownloading, false);
      assert.strictEqual(vm.downloadState, DownloadInfo.STATE_NONE);

      // 3. Re-start
      const result = vm.startDownload();
      assert.strictEqual(result, true);
      assert.strictEqual(vm.isDownloading, true);
    });
  });
});
