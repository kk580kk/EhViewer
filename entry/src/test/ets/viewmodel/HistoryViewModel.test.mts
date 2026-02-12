import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { HistoryViewModel, HistoryState } from '../../../main/ets/viewmodel/HistoryViewModel.ets';
import { MemoryEhDB } from '../../../main/ets/database/MemoryEhDB.ets';
import { GalleryInfo } from '../../../main/ets/model/GalleryInfo.ets';
import { HistoryInfo } from '../../../main/ets/model/HistoryInfo.ets';

function makeGallery(gid: number, title: string): GalleryInfo {
  const gi = new GalleryInfo();
  gi.gid = gid;
  gi.token = `tok_${gid}`;
  gi.title = title;
  gi.category = 2;
  gi.uploader = 'test_user';
  gi.rating = 3.5;
  return gi;
}

describe('HistoryViewModel', () => {
  let db: MemoryEhDB;
  let vm: HistoryViewModel;

  beforeEach(() => {
    db = new MemoryEhDB();
    vm = new HistoryViewModel(db);
  });

  describe('initial state', () => {
    it('should start in IDLE state', () => {
      assert.strictEqual(vm.state, HistoryState.IDLE);
      assert.deepStrictEqual(vm.items, []);
      assert.strictEqual(vm.isEmpty, true);
      assert.strictEqual(vm.count, 0);
    });
  });

  describe('load', () => {
    it('should load empty list as EMPTY state', () => {
      vm.load();
      assert.strictEqual(vm.state, HistoryState.EMPTY);
      assert.strictEqual(vm.isEmpty, true);
    });

    it('should load history as SUCCESS state', () => {
      db.putHistoryInfo(makeGallery(1, 'First'));
      db.putHistoryInfo(makeGallery(2, 'Second'));
      vm.load();
      assert.strictEqual(vm.state, HistoryState.SUCCESS);
      assert.strictEqual(vm.count, 2);
      assert.strictEqual(vm.isEmpty, false);
    });

    it('should return items in reverse-chronological order', () => {
      // Insert with explicit time gaps to guarantee ordering
      const hi1 = new HistoryInfo(makeGallery(1, 'Old'));
      hi1.time = 1000;
      const hi2 = new HistoryInfo(makeGallery(2, 'New'));
      hi2.time = 2000;
      db.putHistoryInfoList([hi1, hi2]);
      vm.load();
      // Most recent (gid=2) should be first
      assert.strictEqual(vm.items[0].gid, 2);
      assert.strictEqual(vm.items[1].gid, 1);
    });
  });

  describe('deleteAt', () => {
    it('should delete by index and refresh', () => {
      db.putHistoryInfo(makeGallery(1, 'One'));
      db.putHistoryInfo(makeGallery(2, 'Two'));
      vm.load();

      const result = vm.deleteAt(0);
      assert.strictEqual(result, true);
      assert.strictEqual(vm.count, 1);
    });

    it('should return false for invalid index', () => {
      vm.load();
      assert.strictEqual(vm.deleteAt(-1), false);
      assert.strictEqual(vm.deleteAt(0), false);
      assert.strictEqual(vm.deleteAt(999), false);
    });
  });

  describe('deleteHistory', () => {
    it('should delete a specific history entry', () => {
      db.putHistoryInfo(makeGallery(1, 'One'));
      db.putHistoryInfo(makeGallery(2, 'Two'));
      vm.load();

      vm.deleteHistory(vm.items[0]);
      assert.strictEqual(vm.count, 1);
    });
  });

  describe('clearAll', () => {
    it('should remove all history entries', () => {
      db.putHistoryInfo(makeGallery(1, 'One'));
      db.putHistoryInfo(makeGallery(2, 'Two'));
      db.putHistoryInfo(makeGallery(3, 'Three'));
      vm.load();
      assert.strictEqual(vm.count, 3);

      vm.clearAll();
      assert.strictEqual(vm.count, 0);
      assert.strictEqual(vm.state, HistoryState.EMPTY);
    });
  });

  describe('recordVisit', () => {
    it('should add a gallery to history', () => {
      vm.recordVisit(makeGallery(1, 'Visited'));
      vm.load();
      assert.strictEqual(vm.count, 1);
      assert.strictEqual(vm.items[0].gid, 1);
    });

    it('should update timestamp for existing entry', () => {
      vm.recordVisit(makeGallery(1, 'First visit'));
      vm.load();
      const firstTime = vm.items[0].time;

      // Record same gallery again — time should update
      vm.recordVisit(makeGallery(1, 'Second visit'));
      vm.load();
      assert.strictEqual(vm.count, 1);
      assert.ok(vm.items[0].time >= firstTime);
    });
  });

  describe('refresh', () => {
    it('should reload history from db', () => {
      db.putHistoryInfo(makeGallery(1, 'One'));
      vm.load();
      assert.strictEqual(vm.count, 1);

      db.putHistoryInfo(makeGallery(2, 'Two'));
      vm.refresh();
      assert.strictEqual(vm.count, 2);
    });
  });
});
