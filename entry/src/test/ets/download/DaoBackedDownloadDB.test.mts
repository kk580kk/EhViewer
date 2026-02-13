import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { MemoryDatabaseStore } from '../../../main/ets/database/MemoryDatabaseStore.ets';
import { DownloadsDao } from '../../../main/ets/database/dao/DownloadsDao.ets';
import { DownloadLabelDao } from '../../../main/ets/database/dao/DownloadLabelDao.ets';
import { DaoBackedDownloadDB } from '../../../main/ets/download/DaoBackedDownloadDB.ets';
import { DownloadInfo } from '../../../main/ets/download/DownloadInfo.ets';
import { DownloadLabel } from '../../../main/ets/download/DownloadLabel.ets';
import { DownloadManager } from '../../../main/ets/download/DownloadManager.ets';
import { GalleryInfo } from '../../../main/ets/model/GalleryInfo.ets';

function makeGallery(gid: number, title: string = `Gallery ${gid}`): GalleryInfo {
  const gi = new GalleryInfo();
  gi.gid = gid;
  gi.token = `tok_${gid}`;
  gi.title = title;
  gi.titleJpn = `JP ${title}`;
  gi.thumb = `https://example.com/thumb/${gid}`;
  gi.category = 2;
  gi.posted = '2024-01-01';
  gi.uploader = 'test_user';
  gi.rating = 4.5;
  gi.simpleLanguage = 'EN';
  return gi;
}

function createDB(): { store: MemoryDatabaseStore; db: DaoBackedDownloadDB } {
  const store = new MemoryDatabaseStore();
  DownloadsDao.createTable(store);
  DownloadLabelDao.createTable(store);
  const db = new DaoBackedDownloadDB(store);
  return { store, db };
}

describe('DaoBackedDownloadDB', () => {
  let store: MemoryDatabaseStore;
  let db: DaoBackedDownloadDB;

  beforeEach(() => {
    ({ store, db } = createDB());
  });

  // =========================================================================
  // Download Info CRUD
  // =========================================================================

  describe('putDownloadInfo / getAllDownloadInfo', () => {
    it('should insert and retrieve a download info', () => {
      const info = new DownloadInfo(makeGallery(1, 'Test Gallery'));
      info.state = DownloadInfo.STATE_WAIT;
      info.time = 1000;
      info.label = null;

      db.putDownloadInfo(info);

      const all = db.getAllDownloadInfo();
      assert.strictEqual(all.length, 1);
      assert.strictEqual(all[0].gid, 1);
      assert.strictEqual(all[0].title, 'Test Gallery');
      assert.strictEqual(all[0].token, 'tok_1');
      assert.strictEqual(all[0].state, DownloadInfo.STATE_WAIT);
      assert.strictEqual(all[0].time, 1000);
    });

    it('should persist GalleryInfo fields', () => {
      const gi = makeGallery(42, 'Full Test');
      const info = new DownloadInfo(gi);
      info.state = DownloadInfo.STATE_FINISH;
      info.time = 2000;

      db.putDownloadInfo(info);

      const loaded = db.getAllDownloadInfo()[0];
      assert.strictEqual(loaded.gid, 42);
      assert.strictEqual(loaded.token, 'tok_42');
      assert.strictEqual(loaded.title, 'Full Test');
      assert.strictEqual(loaded.titleJpn, 'JP Full Test');
      assert.strictEqual(loaded.thumb, 'https://example.com/thumb/42');
      assert.strictEqual(loaded.category, 2);
      assert.strictEqual(loaded.posted, '2024-01-01');
      assert.strictEqual(loaded.uploader, 'test_user');
      assert.ok(Math.abs(loaded.rating - 4.5) < 0.01);
      assert.strictEqual(loaded.simpleLanguage, 'EN');
    });

    it('should update existing download info', () => {
      const info = new DownloadInfo(makeGallery(1));
      info.state = DownloadInfo.STATE_WAIT;
      info.time = 1000;
      db.putDownloadInfo(info);

      info.state = DownloadInfo.STATE_FINISH;
      info.legacy = 0;
      db.putDownloadInfo(info);

      const all = db.getAllDownloadInfo();
      assert.strictEqual(all.length, 1);
      assert.strictEqual(all[0].state, DownloadInfo.STATE_FINISH);
    });

    it('should order by time descending', () => {
      const info1 = new DownloadInfo(makeGallery(1));
      info1.time = 100;
      const info2 = new DownloadInfo(makeGallery(2));
      info2.time = 300;
      const info3 = new DownloadInfo(makeGallery(3));
      info3.time = 200;

      db.putDownloadInfo(info1);
      db.putDownloadInfo(info2);
      db.putDownloadInfo(info3);

      const all = db.getAllDownloadInfo();
      assert.strictEqual(all.length, 3);
      assert.strictEqual(all[0].gid, 2); // time=300
      assert.strictEqual(all[1].gid, 3); // time=200
      assert.strictEqual(all[2].gid, 1); // time=100
    });

    it('should return empty list when no downloads', () => {
      assert.deepStrictEqual(db.getAllDownloadInfo(), []);
    });
  });

  describe('removeDownloadInfo', () => {
    it('should remove a download by gid', () => {
      const info1 = new DownloadInfo(makeGallery(1));
      info1.time = 100;
      const info2 = new DownloadInfo(makeGallery(2));
      info2.time = 200;
      db.putDownloadInfo(info1);
      db.putDownloadInfo(info2);

      db.removeDownloadInfo(1);

      const all = db.getAllDownloadInfo();
      assert.strictEqual(all.length, 1);
      assert.strictEqual(all[0].gid, 2);
    });

    it('should be no-op for non-existent gid', () => {
      db.removeDownloadInfo(999);
      assert.strictEqual(db.getAllDownloadInfo().length, 0);
    });
  });

  // =========================================================================
  // Download Labels CRUD
  // =========================================================================

  describe('addDownloadLabel / getAllDownloadLabelList', () => {
    it('should add a label and return it with id set', () => {
      const label = db.addDownloadLabel('Comics');
      assert.strictEqual(label.label, 'Comics');
      assert.ok(label.id !== null);
      assert.ok(label.time > 0);
    });

    it('should return labels ordered by time ascending', () => {
      const l1 = db.addDownloadLabel('Alpha');
      const l2 = db.addDownloadLabel('Beta');
      const l3 = db.addDownloadLabel('Gamma');

      const all = db.getAllDownloadLabelList();
      assert.strictEqual(all.length, 3);
      // Labels were added sequentially, so time order is Alpha, Beta, Gamma
      assert.strictEqual(all[0].label, 'Alpha');
      assert.strictEqual(all[1].label, 'Beta');
      assert.strictEqual(all[2].label, 'Gamma');
    });
  });

  describe('addDownloadLabelObject', () => {
    it('should add an existing label object with preserved time', () => {
      const original = new DownloadLabel('Imported');
      original.time = 999;

      const added = db.addDownloadLabelObject(original);
      assert.strictEqual(added.label, 'Imported');
      assert.strictEqual(added.time, 999);
      assert.ok(added.id !== null);

      const all = db.getAllDownloadLabelList();
      assert.strictEqual(all.length, 1);
      assert.strictEqual(all[0].label, 'Imported');
    });
  });

  describe('updateDownloadLabel', () => {
    it('should rename a label', () => {
      const label = db.addDownloadLabel('OldName');
      label.label = 'NewName';
      db.updateDownloadLabel(label);

      const all = db.getAllDownloadLabelList();
      assert.strictEqual(all.length, 1);
      assert.strictEqual(all[0].label, 'NewName');
    });
  });

  describe('removeDownloadLabel', () => {
    it('should remove a label', () => {
      const l1 = db.addDownloadLabel('Keep');
      const l2 = db.addDownloadLabel('Remove');

      db.removeDownloadLabel(l2);

      const all = db.getAllDownloadLabelList();
      assert.strictEqual(all.length, 1);
      assert.strictEqual(all[0].label, 'Keep');
    });
  });

  describe('moveDownloadLabel', () => {
    it('should swap label positions', () => {
      // Use explicit times to ensure deterministic ordering
      const la = new DownloadLabel('A'); la.time = 100;
      const lb = new DownloadLabel('B'); lb.time = 200;
      const lc = new DownloadLabel('C'); lc.time = 300;
      db.addDownloadLabelObject(la);
      db.addDownloadLabelObject(lb);
      db.addDownloadLabelObject(lc);

      // Move A (position 0) to position 2
      db.moveDownloadLabel(0, 2);

      const all = db.getAllDownloadLabelList();
      assert.strictEqual(all.length, 3);
      // After move: B, C, A
      assert.strictEqual(all[0].label, 'B');
      assert.strictEqual(all[1].label, 'C');
      assert.strictEqual(all[2].label, 'A');
    });

    it('should be no-op for out-of-range positions', () => {
      db.addDownloadLabel('X');
      db.moveDownloadLabel(-1, 0);
      db.moveDownloadLabel(0, 5);

      const all = db.getAllDownloadLabelList();
      assert.strictEqual(all.length, 1);
      assert.strictEqual(all[0].label, 'X');
    });

    it('should be no-op for same position', () => {
      db.addDownloadLabel('A');
      db.addDownloadLabel('B');
      db.moveDownloadLabel(1, 1);

      const all = db.getAllDownloadLabelList();
      assert.strictEqual(all[0].label, 'A');
      assert.strictEqual(all[1].label, 'B');
    });
  });

  // =========================================================================
  // Integration: DownloadManager + DaoBackedDownloadDB
  // =========================================================================

  describe('DownloadManager integration', () => {
    it('should persist downloads through DownloadManager', () => {
      const mgr = new DownloadManager(db);
      const gallery = makeGallery(1, 'Persisted Gallery');

      mgr.startDownload(gallery);

      // Verify data was persisted to the DB
      const persisted = db.getAllDownloadInfo();
      assert.strictEqual(persisted.length, 1);
      assert.strictEqual(persisted[0].gid, 1);
      assert.strictEqual(persisted[0].title, 'Persisted Gallery');
      assert.strictEqual(persisted[0].token, 'tok_1');
    });

    it('should survive DownloadManager reconstruction', () => {
      // First manager: add downloads
      const mgr1 = new DownloadManager(db);
      mgr1.startDownload(makeGallery(1, 'First'));
      mgr1.onDownloadFinished(10, 10, 10); // completes
      mgr1.startDownload(makeGallery(2, 'Second'));
      mgr1.onDownloadFinished(5, 10, 10); // fails

      // Simulate app restart: create new manager from same DB
      const mgr2 = new DownloadManager(db);

      assert.strictEqual(mgr2.containDownloadInfo(1), true);
      assert.strictEqual(mgr2.containDownloadInfo(2), true);

      const info1 = mgr2.getDownloadInfo(1);
      assert.ok(info1 !== null);
      assert.strictEqual(info1!.title, 'First');
      assert.strictEqual(info1!.state, DownloadInfo.STATE_FINISH);

      const info2 = mgr2.getDownloadInfo(2);
      assert.ok(info2 !== null);
      assert.strictEqual(info2!.title, 'Second');
      assert.strictEqual(info2!.state, DownloadInfo.STATE_FAILED);
    });

    it('should persist labels through DownloadManager', () => {
      const mgr1 = new DownloadManager(db);
      mgr1.addLabel('Comics');
      mgr1.addLabel('Manga');
      mgr1.startDownload(makeGallery(1, 'Test'), 'Comics');

      // Simulate restart
      const mgr2 = new DownloadManager(db);
      const labels = mgr2.getLabelList();
      assert.strictEqual(labels.length, 2);

      const info = mgr2.getDownloadInfo(1);
      assert.ok(info !== null);
      assert.strictEqual(info!.label, 'Comics');
    });

    it('should persist delete operations', () => {
      const mgr1 = new DownloadManager(db);
      mgr1.startDownload(makeGallery(1, 'ToDelete'));
      mgr1.onDownloadFinished(10, 10, 10);
      mgr1.startDownload(makeGallery(2, 'ToKeep'));
      mgr1.onDownloadFinished(10, 10, 10);

      mgr1.deleteDownload(1);

      // Simulate restart
      const mgr2 = new DownloadManager(db);
      assert.strictEqual(mgr2.containDownloadInfo(1), false);
      assert.strictEqual(mgr2.containDownloadInfo(2), true);
    });

    it('should persist state changes', () => {
      const mgr = new DownloadManager(db);
      mgr.startDownload(makeGallery(1, 'Test'));
      // Currently downloading, stop it
      mgr.stopDownload(1);

      // Verify the persisted state
      const persisted = db.getAllDownloadInfo();
      assert.strictEqual(persisted[0].state, DownloadInfo.STATE_NONE);
    });
  });
});
