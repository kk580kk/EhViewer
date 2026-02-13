import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { DownloadsViewModel, DownloadsState } from '../../../main/ets/viewmodel/DownloadsViewModel.ets';
import { MemoryEhDB } from '../../../main/ets/database/MemoryEhDB.ets';
import { DownloadManager } from '../../../main/ets/download/DownloadManager.ets';
import { DownloadInfo } from '../../../main/ets/download/DownloadInfo.ets';
import { GalleryInfo } from '../../../main/ets/model/GalleryInfo.ets';

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

function makeDownload(gid: number, title: string, state: number = DownloadInfo.STATE_NONE, label: string | null = null): DownloadInfo {
  const di = new DownloadInfo(makeGallery(gid, title));
  di.state = state;
  di.time = Date.now() + gid; // ensure ordering
  di.label = label;
  return di;
}

describe('DownloadsViewModel', () => {
  let db: MemoryEhDB;
  let vm: DownloadsViewModel;

  beforeEach(() => {
    db = new MemoryEhDB();
    vm = new DownloadsViewModel(db);
  });

  describe('initial state', () => {
    it('should start in IDLE state', () => {
      assert.strictEqual(vm.state, DownloadsState.IDLE);
      assert.deepStrictEqual(vm.items, []);
      assert.strictEqual(vm.isEmpty, true);
      assert.strictEqual(vm.count, 0);
    });

    it('should have default labelNames', () => {
      assert.deepStrictEqual(vm.labelNames, ['All Downloads']);
    });
  });

  describe('load', () => {
    it('should load empty list as EMPTY state', () => {
      vm.load();
      assert.strictEqual(vm.state, DownloadsState.EMPTY);
      assert.strictEqual(vm.isEmpty, true);
    });

    it('should load downloads as SUCCESS state', () => {
      db.putDownloadInfo(makeDownload(1, 'DL One'));
      db.putDownloadInfo(makeDownload(2, 'DL Two'));
      vm.load();
      assert.strictEqual(vm.state, DownloadsState.SUCCESS);
      assert.strictEqual(vm.count, 2);
    });
  });

  describe('label filtering', () => {
    it('should show all items when label is null', () => {
      db.putDownloadInfo(makeDownload(1, 'One', DownloadInfo.STATE_NONE, 'A'));
      db.putDownloadInfo(makeDownload(2, 'Two', DownloadInfo.STATE_NONE, 'B'));
      db.putDownloadInfo(makeDownload(3, 'Three', DownloadInfo.STATE_NONE, null));
      vm.load();
      assert.strictEqual(vm.count, 3);
    });

    it('should filter by label', () => {
      db.putDownloadInfo(makeDownload(1, 'One', DownloadInfo.STATE_NONE, 'GroupA'));
      db.putDownloadInfo(makeDownload(2, 'Two', DownloadInfo.STATE_NONE, 'GroupB'));
      db.putDownloadInfo(makeDownload(3, 'Three', DownloadInfo.STATE_NONE, 'GroupA'));
      vm.load();

      vm.setLabel('GroupA');
      assert.strictEqual(vm.count, 2);
      assert.strictEqual(vm.currentLabel, 'GroupA');
    });

    it('should return empty when no items match label', () => {
      db.putDownloadInfo(makeDownload(1, 'One', DownloadInfo.STATE_NONE, 'A'));
      vm.load();

      vm.setLabel('NonExistent');
      assert.strictEqual(vm.state, DownloadsState.EMPTY);
      assert.strictEqual(vm.count, 0);
    });

    it('should reset to all when label set to null', () => {
      db.putDownloadInfo(makeDownload(1, 'One', DownloadInfo.STATE_NONE, 'A'));
      db.putDownloadInfo(makeDownload(2, 'Two', DownloadInfo.STATE_NONE, 'B'));
      vm.load();
      vm.setLabel('A');
      assert.strictEqual(vm.count, 1);

      vm.setLabel(null);
      assert.strictEqual(vm.count, 2);
      assert.strictEqual(vm.currentLabel, null);
    });
  });

  describe('removeDownload', () => {
    it('should remove a single download and refresh', () => {
      db.putDownloadInfo(makeDownload(1, 'One'));
      db.putDownloadInfo(makeDownload(2, 'Two'));
      vm.load();

      vm.removeDownload(1);
      assert.strictEqual(vm.count, 1);
      assert.strictEqual(vm.items[0].gid, 2);
    });
  });

  describe('removeDownloads (batch)', () => {
    it('should remove multiple downloads', () => {
      db.putDownloadInfo(makeDownload(1, 'One'));
      db.putDownloadInfo(makeDownload(2, 'Two'));
      db.putDownloadInfo(makeDownload(3, 'Three'));
      vm.load();

      vm.removeDownloads([1, 3]);
      assert.strictEqual(vm.count, 1);
      assert.strictEqual(vm.items[0].gid, 2);
    });
  });

  describe('label management', () => {
    it('should add a label', () => {
      const label = vm.addLabel('MyLabel');
      assert.strictEqual(label.label, 'MyLabel');
      assert.ok(label.id !== null);
      assert.deepStrictEqual(vm.labelNames, ['All Downloads', 'MyLabel']);
    });

    it('should remove a label', () => {
      const label = vm.addLabel('ToRemove');
      vm.removeLabel(label);
      assert.deepStrictEqual(vm.labelNames, ['All Downloads']);
    });

    it('should reset filter when current label is removed', () => {
      const label = vm.addLabel('Active');
      db.putDownloadInfo(makeDownload(1, 'One', DownloadInfo.STATE_NONE, 'Active'));
      db.putDownloadInfo(makeDownload(2, 'Two', DownloadInfo.STATE_NONE, null));
      vm.load();
      vm.setLabel('Active');
      assert.strictEqual(vm.count, 1);

      vm.removeLabel(label);
      assert.strictEqual(vm.currentLabel, null);
      // After removing the label, all items should show
      vm.load();
      assert.strictEqual(vm.count, 2);
    });
  });

  describe('title', () => {
    it('should return "All Downloads" when no label selected', () => {
      assert.strictEqual(vm.title, 'All Downloads');
    });

    it('should return label name when a label is selected', () => {
      vm.addLabel('MyGroup');
      vm.load();
      vm.setLabel('MyGroup');
      assert.strictEqual(vm.title, 'MyGroup');
    });
  });

  describe('static helpers', () => {
    it('getStateText should return correct strings', () => {
      const none = makeDownload(1, 'X', DownloadInfo.STATE_NONE);
      assert.strictEqual(DownloadsViewModel.getStateText(none), 'Not started');

      const wait = makeDownload(2, 'X', DownloadInfo.STATE_WAIT);
      assert.strictEqual(DownloadsViewModel.getStateText(wait), 'Waiting');

      const finish = makeDownload(3, 'X', DownloadInfo.STATE_FINISH);
      assert.strictEqual(DownloadsViewModel.getStateText(finish), 'Completed');

      const failed = makeDownload(4, 'X', DownloadInfo.STATE_FAILED);
      assert.strictEqual(DownloadsViewModel.getStateText(failed), 'Failed');

      const failedLegacy = makeDownload(5, 'X', DownloadInfo.STATE_FAILED);
      failedLegacy.legacy = 3;
      assert.strictEqual(DownloadsViewModel.getStateText(failedLegacy), 'Failed (3)');
    });

    it('getProgressText should show fraction or placeholder', () => {
      const dl = makeDownload(1, 'X', DownloadInfo.STATE_DOWNLOAD);
      dl.finished = 12;
      dl.total = 36;
      assert.strictEqual(DownloadsViewModel.getProgressText(dl), '12/36');

      const indeterminate = makeDownload(2, 'X', DownloadInfo.STATE_DOWNLOAD);
      indeterminate.total = -1;
      assert.strictEqual(DownloadsViewModel.getProgressText(indeterminate), 'Downloading...');
    });

    it('getProgressPercent should return correct percentage or -1', () => {
      const dl = makeDownload(1, 'X');
      dl.finished = 50;
      dl.total = 100;
      assert.strictEqual(DownloadsViewModel.getProgressPercent(dl), 50);

      dl.total = 0;
      assert.strictEqual(DownloadsViewModel.getProgressPercent(dl), -1);
    });

    it('canStart should be true for NONE and FAILED states', () => {
      assert.strictEqual(DownloadsViewModel.canStart(makeDownload(1, 'X', DownloadInfo.STATE_NONE)), true);
      assert.strictEqual(DownloadsViewModel.canStart(makeDownload(2, 'X', DownloadInfo.STATE_FAILED)), true);
      assert.strictEqual(DownloadsViewModel.canStart(makeDownload(3, 'X', DownloadInfo.STATE_DOWNLOAD)), false);
      assert.strictEqual(DownloadsViewModel.canStart(makeDownload(4, 'X', DownloadInfo.STATE_WAIT)), false);
      assert.strictEqual(DownloadsViewModel.canStart(makeDownload(5, 'X', DownloadInfo.STATE_FINISH)), false);
    });

    it('canStop should be true for WAIT and DOWNLOAD states', () => {
      assert.strictEqual(DownloadsViewModel.canStop(makeDownload(1, 'X', DownloadInfo.STATE_WAIT)), true);
      assert.strictEqual(DownloadsViewModel.canStop(makeDownload(2, 'X', DownloadInfo.STATE_DOWNLOAD)), true);
      assert.strictEqual(DownloadsViewModel.canStop(makeDownload(3, 'X', DownloadInfo.STATE_NONE)), false);
      assert.strictEqual(DownloadsViewModel.canStop(makeDownload(4, 'X', DownloadInfo.STATE_FINISH)), false);
    });
  });

  // =========================================================================
  // Download task operations (with DownloadManager)
  // =========================================================================

  describe('addDownload (via DownloadManager)', () => {
    let mgr: DownloadManager;
    let vmWithMgr: DownloadsViewModel;

    beforeEach(() => {
      // Use shared MemoryEhDB as both EhDB and DownloadDB
      mgr = new DownloadManager(db);
      vmWithMgr = new DownloadsViewModel(db, mgr);
    });

    it('should add and start a new download', () => {
      const result = vmWithMgr.addDownload(makeGallery(1, 'Test'));
      assert.strictEqual(result, true);
      assert.strictEqual(mgr.containDownloadInfo(1), true);
      vmWithMgr.load();
      assert.strictEqual(vmWithMgr.count, 1);
    });

    it('should return false when DownloadManager is not set', () => {
      // vm has no DownloadManager
      assert.strictEqual(vm.addDownload(makeGallery(1)), false);
    });

    it('should assign label when adding download', () => {
      mgr.addLabel('Comics');
      vmWithMgr.addDownload(makeGallery(1, 'Test'), 'Comics');
      const info = mgr.getDownloadInfo(1);
      assert.ok(info !== null);
      assert.strictEqual(info!.label, 'Comics');
    });
  });

  describe('cancelDownload (via DownloadManager)', () => {
    let mgr: DownloadManager;
    let vmWithMgr: DownloadsViewModel;

    beforeEach(() => {
      mgr = new DownloadManager(db);
      vmWithMgr = new DownloadsViewModel(db, mgr);
    });

    it('should stop a downloading task', () => {
      vmWithMgr.addDownload(makeGallery(1, 'Test'));
      assert.strictEqual(mgr.getDownloadState(1), DownloadInfo.STATE_DOWNLOAD);

      const result = vmWithMgr.cancelDownload(1);
      assert.strictEqual(result, true);
      assert.strictEqual(mgr.getDownloadState(1), DownloadInfo.STATE_NONE);
    });

    it('should stop a waiting task', () => {
      vmWithMgr.addDownload(makeGallery(1, 'First'));
      vmWithMgr.addDownload(makeGallery(2, 'Second'));
      assert.strictEqual(mgr.getDownloadState(2), DownloadInfo.STATE_WAIT);

      vmWithMgr.cancelDownload(2);
      assert.strictEqual(mgr.getDownloadState(2), DownloadInfo.STATE_NONE);
    });

    it('should return false when DownloadManager is not set', () => {
      assert.strictEqual(vm.cancelDownload(1), false);
    });
  });

  describe('retryDownload (via DownloadManager)', () => {
    let mgr: DownloadManager;
    let vmWithMgr: DownloadsViewModel;

    beforeEach(() => {
      mgr = new DownloadManager(db);
      vmWithMgr = new DownloadsViewModel(db, mgr);
    });

    it('should retry a failed download', () => {
      vmWithMgr.addDownload(makeGallery(1, 'Test'));
      mgr.onDownloadFinished(5, 10, 10); // fails
      assert.strictEqual(mgr.getDownloadState(1), DownloadInfo.STATE_FAILED);

      const result = vmWithMgr.retryDownload(1);
      assert.strictEqual(result, true);
      assert.strictEqual(mgr.getDownloadState(1), DownloadInfo.STATE_DOWNLOAD);
    });

    it('should return false for non-existent gid', () => {
      assert.strictEqual(vmWithMgr.retryDownload(999), false);
    });

    it('should return false when DownloadManager is not set', () => {
      assert.strictEqual(vm.retryDownload(1), false);
    });

    it('should refresh items after retry', () => {
      vmWithMgr.addDownload(makeGallery(1, 'Test'));
      mgr.onDownloadFinished(5, 10, 10); // fails
      vmWithMgr.load();
      assert.strictEqual(vmWithMgr.items[0].state, DownloadInfo.STATE_FAILED);

      vmWithMgr.retryDownload(1);
      // After retry + refresh, state should be updated
      assert.strictEqual(vmWithMgr.items[0].state, DownloadInfo.STATE_DOWNLOAD);
    });
  });

  describe('removeDownload with DownloadManager', () => {
    let mgr: DownloadManager;
    let vmWithMgr: DownloadsViewModel;

    beforeEach(() => {
      mgr = new DownloadManager(db);
      vmWithMgr = new DownloadsViewModel(db, mgr);
    });

    it('should stop and remove a downloading task', () => {
      vmWithMgr.addDownload(makeGallery(1, 'Test'));
      vmWithMgr.addDownload(makeGallery(2, 'Test2'));
      assert.strictEqual(mgr.getDownloadState(1), DownloadInfo.STATE_DOWNLOAD);

      vmWithMgr.removeDownload(1);
      assert.strictEqual(mgr.containDownloadInfo(1), false);
      // Task 2 should be promoted
      assert.strictEqual(mgr.getDownloadState(2), DownloadInfo.STATE_DOWNLOAD);
    });

    it('removeDownloads should batch-remove via DownloadManager', () => {
      vmWithMgr.addDownload(makeGallery(1, 'A'));
      vmWithMgr.addDownload(makeGallery(2, 'B'));
      vmWithMgr.addDownload(makeGallery(3, 'C'));

      vmWithMgr.removeDownloads([1, 3]);
      assert.strictEqual(mgr.containDownloadInfo(1), false);
      assert.strictEqual(mgr.containDownloadInfo(3), false);
      assert.strictEqual(mgr.containDownloadInfo(2), true);
    });
  });
});
