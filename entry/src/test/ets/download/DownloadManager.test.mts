import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { DownloadManager } from '../../../main/ets/download/DownloadManager.ets';
import type { DownloadInfoListener, DownloadListener } from '../../../main/ets/download/DownloadManager.ets';
import { MemoryDownloadDB } from '../../../main/ets/download/MemoryDownloadDB.ets';
import { DownloadInfo } from '../../../main/ets/download/DownloadInfo.ets';
import { DownloadLabel } from '../../../main/ets/download/DownloadLabel.ets';
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

function makeDownloadInfo(gid: number, state: number = DownloadInfo.STATE_NONE, label: string | null = null): DownloadInfo {
  const di = new DownloadInfo(makeGallery(gid));
  di.state = state;
  di.time = Date.now() + gid;
  di.label = label;
  return di;
}

/** No-op listener that records calls for assertion. */
class SpyInfoListener implements DownloadInfoListener {
  addCalls: { gid: number }[] = [];
  updateCalls: { gid: number }[] = [];
  removeCalls: { gid: number; position: number }[] = [];
  updateAllCount = 0;
  reloadCount = 0;
  changeCount = 0;
  renameCalls: { from: string; to: string }[] = [];
  updateLabelsCount = 0;

  onAdd(info: DownloadInfo, _list: DownloadInfo[], _position: number): void {
    this.addCalls.push({ gid: info.gid });
  }
  onUpdate(info: DownloadInfo, _list: DownloadInfo[]): void {
    this.updateCalls.push({ gid: info.gid });
  }
  onUpdateAll(): void { this.updateAllCount++; }
  onReload(): void { this.reloadCount++; }
  onChange(): void { this.changeCount++; }
  onRenameLabel(from: string, to: string): void { this.renameCalls.push({ from, to }); }
  onRemove(info: DownloadInfo, _list: DownloadInfo[], position: number): void {
    this.removeCalls.push({ gid: info.gid, position });
  }
  onUpdateLabels(): void { this.updateLabelsCount++; }
}

class SpyDownloadListener implements DownloadListener {
  startCalls: number[] = [];
  finishCalls: number[] = [];
  cancelCalls: number[] = [];
  onStart(info: DownloadInfo): void { this.startCalls.push(info.gid); }
  onFinish(info: DownloadInfo): void { this.finishCalls.push(info.gid); }
  onCancel(info: DownloadInfo): void { this.cancelCalls.push(info.gid); }
}

describe('DownloadManager', () => {
  let db: MemoryDownloadDB;
  let mgr: DownloadManager;

  beforeEach(() => {
    db = new MemoryDownloadDB();
    mgr = new DownloadManager(db);
  });

  // =========================================================================
  // Construction & queries
  // =========================================================================

  describe('constructor', () => {
    it('should start empty', () => {
      assert.strictEqual(mgr.isIdle(), true);
      assert.strictEqual(mgr.getAllDownloadInfoList().length, 0);
      assert.strictEqual(mgr.getLabelList().length, 0);
      assert.strictEqual(mgr.getCurrentTask(), null);
    });

    it('should restore from DB', () => {
      const di = makeDownloadInfo(1, DownloadInfo.STATE_FINISH);
      db.putDownloadInfo(di);
      const rebuilt = new DownloadManager(db);
      assert.strictEqual(rebuilt.containDownloadInfo(1), true);
      assert.strictEqual(rebuilt.getDownloadState(1), DownloadInfo.STATE_FINISH);
    });

    it('should restore labels and associate downloads', () => {
      db.addDownloadLabel('MyLabel');
      const di = makeDownloadInfo(1, DownloadInfo.STATE_NONE, 'MyLabel');
      db.putDownloadInfo(di);
      const rebuilt = new DownloadManager(db);
      assert.strictEqual(rebuilt.getLabelList().length, 1);
      const list = rebuilt.getLabelDownloadInfoList('MyLabel');
      assert.ok(list !== null);
      assert.strictEqual(list!.length, 1);
    });
  });

  describe('query API', () => {
    it('getDownloadState returns STATE_INVALID for unknown gid', () => {
      assert.strictEqual(mgr.getDownloadState(999), DownloadInfo.STATE_INVALID);
    });

    it('getDownloadInfo returns null for unknown gid', () => {
      assert.strictEqual(mgr.getDownloadInfo(999), null);
    });

    it('containDownloadInfo returns false for unknown gid', () => {
      assert.strictEqual(mgr.containDownloadInfo(999), false);
    });
  });

  // =========================================================================
  // startDownload
  // =========================================================================

  describe('startDownload', () => {
    it('should add new download and transition to DOWNLOAD immediately', () => {
      mgr.startDownload(makeGallery(1));
      assert.strictEqual(mgr.containDownloadInfo(1), true);
      assert.strictEqual(mgr.getDownloadState(1), DownloadInfo.STATE_DOWNLOAD);
      assert.strictEqual(mgr.getCurrentTask()!.gid, 1);
    });

    it('should queue second download in WAIT state', () => {
      mgr.startDownload(makeGallery(1));
      mgr.startDownload(makeGallery(2));
      assert.strictEqual(mgr.getDownloadState(1), DownloadInfo.STATE_DOWNLOAD);
      assert.strictEqual(mgr.getDownloadState(2), DownloadInfo.STATE_WAIT);
    });

    it('should not duplicate an already-queued download', () => {
      mgr.startDownload(makeGallery(1));
      mgr.startDownload(makeGallery(1)); // no-op, already current
      assert.strictEqual(mgr.getAllDownloadInfoList().length, 1);
    });

    it('should re-queue a FAILED download', () => {
      mgr.startDownload(makeGallery(1));
      // Simulate finish with failure
      mgr.onDownloadFinished(5, 10, 10); // legacy = 5
      assert.strictEqual(mgr.getDownloadState(1), DownloadInfo.STATE_FAILED);

      mgr.startDownload(makeGallery(1));
      // Should be re-queued and since nothing else is running, it's now DOWNLOAD
      assert.strictEqual(mgr.getDownloadState(1), DownloadInfo.STATE_DOWNLOAD);
    });

    it('should assign downloads to the correct label list', () => {
      mgr.addLabel('Comics');
      mgr.startDownload(makeGallery(1), 'Comics');
      const list = mgr.getLabelDownloadInfoList('Comics');
      assert.ok(list !== null);
      assert.strictEqual(list!.length, 1);
      assert.strictEqual(list![0].gid, 1);
    });

    it('should assign downloads with null label to default list', () => {
      mgr.startDownload(makeGallery(1), null);
      assert.strictEqual(mgr.getDefaultDownloadInfoList().length, 1);
    });

    it('should persist to DB', () => {
      mgr.startDownload(makeGallery(42));
      const all = db.getAllDownloadInfo();
      assert.strictEqual(all.length, 1);
      assert.strictEqual(all[0].gid, 42);
    });

    it('should fire onAdd listener for new downloads', () => {
      const spy = new SpyInfoListener();
      mgr.addDownloadInfoListener(spy);
      mgr.startDownload(makeGallery(1));
      assert.strictEqual(spy.addCalls.length, 1);
      assert.strictEqual(spy.addCalls[0].gid, 1);
    });

    it('should fire DownloadListener.onStart', () => {
      const spy = new SpyDownloadListener();
      mgr.setDownloadListener(spy);
      mgr.startDownload(makeGallery(1));
      assert.deepStrictEqual(spy.startCalls, [1]);
    });
  });

  // =========================================================================
  // stopDownload
  // =========================================================================

  describe('stopDownload', () => {
    it('should stop the current download and set state to NONE', () => {
      mgr.startDownload(makeGallery(1));
      mgr.stopDownload(1);
      assert.strictEqual(mgr.getDownloadState(1), DownloadInfo.STATE_NONE);
      assert.strictEqual(mgr.getCurrentTask(), null);
    });

    it('should remove a waiting task from the wait list', () => {
      mgr.startDownload(makeGallery(1));
      mgr.startDownload(makeGallery(2));
      mgr.stopDownload(2);
      assert.strictEqual(mgr.getDownloadState(2), DownloadInfo.STATE_NONE);
      assert.strictEqual(mgr.getWaitList().length, 0);
    });

    it('should promote next waiting task after stopping current', () => {
      mgr.startDownload(makeGallery(1));
      mgr.startDownload(makeGallery(2));
      mgr.stopDownload(1);
      assert.strictEqual(mgr.getDownloadState(2), DownloadInfo.STATE_DOWNLOAD);
      assert.strictEqual(mgr.getCurrentTask()!.gid, 2);
    });

    it('should fire DownloadListener.onCancel for current task', () => {
      const spy = new SpyDownloadListener();
      mgr.setDownloadListener(spy);
      mgr.startDownload(makeGallery(1));
      mgr.stopDownload(1);
      assert.deepStrictEqual(spy.cancelCalls, [1]);
    });

    it('should be no-op for unknown gid', () => {
      mgr.stopDownload(999); // should not throw
    });
  });

  describe('stopCurrentDownload', () => {
    it('should stop the current task', () => {
      mgr.startDownload(makeGallery(1));
      mgr.stopCurrentDownload();
      assert.strictEqual(mgr.getCurrentTask(), null);
      assert.strictEqual(mgr.getDownloadState(1), DownloadInfo.STATE_NONE);
    });
  });

  describe('stopAllDownload', () => {
    it('should stop current and all waiting tasks', () => {
      mgr.startDownload(makeGallery(1));
      mgr.startDownload(makeGallery(2));
      mgr.startDownload(makeGallery(3));
      mgr.stopAllDownload();
      assert.strictEqual(mgr.getCurrentTask(), null);
      assert.strictEqual(mgr.getWaitList().length, 0);
      assert.strictEqual(mgr.getDownloadState(1), DownloadInfo.STATE_NONE);
      assert.strictEqual(mgr.getDownloadState(2), DownloadInfo.STATE_NONE);
      assert.strictEqual(mgr.getDownloadState(3), DownloadInfo.STATE_NONE);
    });
  });

  describe('stopRangeDownload', () => {
    it('should stop a subset of downloads', () => {
      mgr.startDownload(makeGallery(1));
      mgr.startDownload(makeGallery(2));
      mgr.startDownload(makeGallery(3));
      mgr.stopRangeDownload([1, 3]);
      assert.strictEqual(mgr.getDownloadState(1), DownloadInfo.STATE_NONE);
      assert.strictEqual(mgr.getDownloadState(3), DownloadInfo.STATE_NONE);
      // 2 was waiting, should now be promoted
      assert.strictEqual(mgr.getDownloadState(2), DownloadInfo.STATE_DOWNLOAD);
    });
  });

  // =========================================================================
  // startAllDownload / startRangeDownload
  // =========================================================================

  describe('startAllDownload', () => {
    it('should re-queue all NONE and FAILED downloads', () => {
      mgr.addDownload(makeGallery(1));
      mgr.addDownload(makeGallery(2));
      assert.strictEqual(mgr.getDownloadState(1), DownloadInfo.STATE_NONE);
      assert.strictEqual(mgr.getDownloadState(2), DownloadInfo.STATE_NONE);

      mgr.startAllDownload();
      // One should be downloading, one waiting
      const states = [mgr.getDownloadState(1), mgr.getDownloadState(2)];
      assert.ok(states.includes(DownloadInfo.STATE_DOWNLOAD));
      assert.ok(states.includes(DownloadInfo.STATE_WAIT));
    });

    it('should not re-queue FINISH downloads', () => {
      mgr.startDownload(makeGallery(1));
      mgr.onDownloadFinished(10, 10, 10); // complete
      assert.strictEqual(mgr.getDownloadState(1), DownloadInfo.STATE_FINISH);
      mgr.startAllDownload();
      assert.strictEqual(mgr.getDownloadState(1), DownloadInfo.STATE_FINISH);
    });
  });

  describe('startRangeDownload', () => {
    it('should re-queue a specified subset', () => {
      mgr.addDownload(makeGallery(1));
      mgr.addDownload(makeGallery(2));
      mgr.addDownload(makeGallery(3));

      mgr.startRangeDownload([1, 3]);
      assert.ok(
        mgr.getDownloadState(1) === DownloadInfo.STATE_DOWNLOAD ||
        mgr.getDownloadState(1) === DownloadInfo.STATE_WAIT
      );
      assert.strictEqual(mgr.getDownloadState(2), DownloadInfo.STATE_NONE);
      assert.ok(
        mgr.getDownloadState(3) === DownloadInfo.STATE_DOWNLOAD ||
        mgr.getDownloadState(3) === DownloadInfo.STATE_WAIT
      );
    });
  });

  // =========================================================================
  // deleteDownload
  // =========================================================================

  describe('deleteDownload', () => {
    it('should remove a download completely', () => {
      mgr.startDownload(makeGallery(1));
      mgr.deleteDownload(1);
      assert.strictEqual(mgr.containDownloadInfo(1), false);
      assert.strictEqual(mgr.getAllDownloadInfoList().length, 0);
      assert.strictEqual(db.getAllDownloadInfo().length, 0);
    });

    it('should stop current task if it is the one being deleted', () => {
      mgr.startDownload(makeGallery(1));
      mgr.startDownload(makeGallery(2));
      mgr.deleteDownload(1);
      assert.strictEqual(mgr.containDownloadInfo(1), false);
      // 2 should now be downloading
      assert.strictEqual(mgr.getDownloadState(2), DownloadInfo.STATE_DOWNLOAD);
    });

    it('should remove from label list', () => {
      mgr.addLabel('Group');
      mgr.startDownload(makeGallery(1), 'Group');
      mgr.deleteDownload(1);
      assert.strictEqual(mgr.getLabelDownloadInfoList('Group')!.length, 0);
    });

    it('should fire onRemove listener', () => {
      const spy = new SpyInfoListener();
      mgr.addDownloadInfoListener(spy);
      mgr.startDownload(makeGallery(1));
      mgr.deleteDownload(1);
      assert.strictEqual(spy.removeCalls.length, 1);
      assert.strictEqual(spy.removeCalls[0].gid, 1);
    });
  });

  describe('deleteRangeDownload', () => {
    it('should remove multiple downloads at once', () => {
      mgr.startDownload(makeGallery(1));
      mgr.startDownload(makeGallery(2));
      mgr.startDownload(makeGallery(3));
      mgr.deleteRangeDownload([1, 3]);
      assert.strictEqual(mgr.containDownloadInfo(1), false);
      assert.strictEqual(mgr.containDownloadInfo(3), false);
      assert.strictEqual(mgr.containDownloadInfo(2), true);
    });
  });

  // =========================================================================
  // addDownload (without starting)
  // =========================================================================

  describe('addDownload', () => {
    it('should add download in STATE_NONE without starting', () => {
      mgr.addDownload(makeGallery(1));
      assert.strictEqual(mgr.containDownloadInfo(1), true);
      assert.strictEqual(mgr.getDownloadState(1), DownloadInfo.STATE_NONE);
      assert.strictEqual(mgr.getCurrentTask(), null);
    });

    it('should not duplicate', () => {
      mgr.addDownload(makeGallery(1));
      mgr.addDownload(makeGallery(1));
      assert.strictEqual(mgr.getAllDownloadInfoList().length, 1);
    });
  });

  describe('addDownloadBatch', () => {
    it('should import multiple downloads at once', () => {
      const items = [
        makeDownloadInfo(1, DownloadInfo.STATE_FINISH),
        makeDownloadInfo(2, DownloadInfo.STATE_FAILED),
        makeDownloadInfo(3, DownloadInfo.STATE_WAIT), // should be reset to NONE
      ];
      mgr.addDownloadBatch(items);
      assert.strictEqual(mgr.getAllDownloadInfoList().length, 3);
      assert.strictEqual(mgr.getDownloadState(3), DownloadInfo.STATE_NONE);
    });
  });

  // =========================================================================
  // onDownloadFinished
  // =========================================================================

  describe('onDownloadFinished', () => {
    it('should mark as FINISH when all pages completed', () => {
      mgr.startDownload(makeGallery(1));
      mgr.onDownloadFinished(10, 10, 10);
      assert.strictEqual(mgr.getDownloadState(1), DownloadInfo.STATE_FINISH);
      assert.strictEqual(mgr.getCurrentTask(), null);
    });

    it('should mark as FAILED when some pages missing', () => {
      mgr.startDownload(makeGallery(1));
      mgr.onDownloadFinished(8, 10, 10);
      assert.strictEqual(mgr.getDownloadState(1), DownloadInfo.STATE_FAILED);
      const info = mgr.getDownloadInfo(1)!;
      assert.strictEqual(info.legacy, 2);
    });

    it('should auto-start next task after completion', () => {
      mgr.startDownload(makeGallery(1));
      mgr.startDownload(makeGallery(2));
      assert.strictEqual(mgr.getDownloadState(2), DownloadInfo.STATE_WAIT);

      mgr.onDownloadFinished(10, 10, 10);
      assert.strictEqual(mgr.getDownloadState(2), DownloadInfo.STATE_DOWNLOAD);
      assert.strictEqual(mgr.getCurrentTask()!.gid, 2);
    });

    it('should fire DownloadListener.onFinish', () => {
      const spy = new SpyDownloadListener();
      mgr.setDownloadListener(spy);
      mgr.startDownload(makeGallery(1));
      mgr.onDownloadFinished(10, 10, 10);
      assert.deepStrictEqual(spy.finishCalls, [1]);
    });

    it('should persist final state to DB', () => {
      mgr.startDownload(makeGallery(1));
      mgr.onDownloadFinished(10, 10, 10);
      const stored = db.getAllDownloadInfo();
      assert.strictEqual(stored[0].state, DownloadInfo.STATE_FINISH);
    });
  });

  // =========================================================================
  // Label management
  // =========================================================================

  describe('label management', () => {
    it('addLabel should create a new label', () => {
      mgr.addLabel('Comics');
      assert.strictEqual(mgr.containLabel('Comics'), true);
      assert.strictEqual(mgr.getLabelList().length, 1);
      assert.ok(mgr.getLabelDownloadInfoList('Comics') !== null);
    });

    it('addLabel should be idempotent', () => {
      mgr.addLabel('Comics');
      mgr.addLabel('Comics');
      assert.strictEqual(mgr.getLabelList().length, 1);
    });

    it('renameLabel should update label on downloads', () => {
      mgr.addLabel('Old');
      mgr.startDownload(makeGallery(1), 'Old');
      mgr.renameLabel('Old', 'New');

      assert.strictEqual(mgr.containLabel('Old'), false);
      assert.strictEqual(mgr.containLabel('New'), true);
      assert.strictEqual(mgr.getDownloadInfo(1)!.label, 'New');
      assert.strictEqual(mgr.getLabelDownloadInfoList('New')!.length, 1);
      assert.strictEqual(mgr.getLabelDownloadInfoList('Old'), null);
    });

    it('deleteLabel should move downloads to default list', () => {
      mgr.addLabel('Temp');
      mgr.addDownload(makeGallery(1), 'Temp');
      mgr.deleteLabel('Temp');

      assert.strictEqual(mgr.containLabel('Temp'), false);
      assert.strictEqual(mgr.getDownloadInfo(1)!.label, null);
      assert.strictEqual(mgr.getDefaultDownloadInfoList().length, 1);
    });

    it('moveLabel should reorder labels', () => {
      mgr.addLabel('A');
      mgr.addLabel('B');
      mgr.addLabel('C');
      mgr.moveLabel(0, 2);
      assert.strictEqual(mgr.getLabelList()[0].label, 'B');
      assert.strictEqual(mgr.getLabelList()[2].label, 'A');
    });

    it('changeLabel should move downloads between labels', () => {
      mgr.addLabel('Src');
      mgr.addLabel('Dst');
      mgr.addDownload(makeGallery(1), 'Src');
      mgr.addDownload(makeGallery(2), 'Src');

      const infos = mgr.getLabelDownloadInfoList('Src')!.slice();
      mgr.changeLabel(infos, 'Dst');

      assert.strictEqual(mgr.getLabelDownloadInfoList('Src')!.length, 0);
      assert.strictEqual(mgr.getLabelDownloadInfoList('Dst')!.length, 2);
      assert.strictEqual(mgr.getDownloadInfo(1)!.label, 'Dst');
    });
  });

  // =========================================================================
  // Listener management
  // =========================================================================

  describe('listeners', () => {
    it('should remove info listener', () => {
      const spy = new SpyInfoListener();
      mgr.addDownloadInfoListener(spy);
      mgr.removeDownloadInfoListener(spy);
      mgr.startDownload(makeGallery(1));
      assert.strictEqual(spy.addCalls.length, 0);
    });

    it('should clear download listener', () => {
      const spy = new SpyDownloadListener();
      mgr.setDownloadListener(spy);
      mgr.setDownloadListener(null);
      mgr.startDownload(makeGallery(1));
      assert.strictEqual(spy.startCalls.length, 0);
    });

    it('renameLabel should fire onRenameLabel', () => {
      const spy = new SpyInfoListener();
      mgr.addDownloadInfoListener(spy);
      mgr.addLabel('X');
      mgr.renameLabel('X', 'Y');
      assert.strictEqual(spy.renameCalls.length, 1);
      assert.deepStrictEqual(spy.renameCalls[0], { from: 'X', to: 'Y' });
    });

    it('deleteLabel should fire onChange', () => {
      const spy = new SpyInfoListener();
      mgr.addDownloadInfoListener(spy);
      mgr.addLabel('Z');
      mgr.deleteLabel('Z');
      assert.strictEqual(spy.changeCount, 1);
    });

    it('addLabel should fire onUpdateLabels', () => {
      const spy = new SpyInfoListener();
      mgr.addDownloadInfoListener(spy);
      mgr.addLabel('New');
      assert.strictEqual(spy.updateLabelsCount, 1);
    });
  });

  // =========================================================================
  // onStartDownload hook
  // =========================================================================

  describe('onStartDownload hook', () => {
    it('should be called when a task transitions to DOWNLOAD', () => {
      const started: number[] = [];
      mgr.onStartDownload = (info) => started.push(info.gid);
      mgr.startDownload(makeGallery(1));
      assert.deepStrictEqual(started, [1]);
    });
  });

  // =========================================================================
  // Queue ordering
  // =========================================================================

  describe('queue FIFO ordering', () => {
    it('should download tasks in FIFO order', () => {
      const finished: number[] = [];
      mgr.onStartDownload = (info) => finished.push(info.gid);

      mgr.startDownload(makeGallery(1));
      mgr.startDownload(makeGallery(2));
      mgr.startDownload(makeGallery(3));

      assert.deepStrictEqual(finished, [1]); // only 1 started so far
      mgr.onDownloadFinished(10, 10, 10); // finish 1
      assert.deepStrictEqual(finished, [1, 2]); // 2 starts
      mgr.onDownloadFinished(10, 10, 10); // finish 2
      assert.deepStrictEqual(finished, [1, 2, 3]); // 3 starts
    });
  });

  // =========================================================================
  // addDownloadLabelBatch
  // =========================================================================

  describe('addDownloadLabelBatch', () => {
    it('should import multiple labels at once', () => {
      const dl1 = new DownloadLabel('A');
      const dl2 = new DownloadLabel('B');
      mgr.addDownloadLabelBatch([dl1, dl2]);
      assert.strictEqual(mgr.containLabel('A'), true);
      assert.strictEqual(mgr.containLabel('B'), true);
      assert.strictEqual(mgr.getLabelList().length, 2);
    });
  });
});
