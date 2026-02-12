import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { FavoritesViewModel, FavState } from '../../../main/ets/viewmodel/FavoritesViewModel.ets';
import { MemoryEhDB } from '../../../main/ets/database/MemoryEhDB.ets';
import { GalleryInfo } from '../../../main/ets/model/GalleryInfo.ets';

function makeGallery(gid: number, title: string, category: number = 2): GalleryInfo {
  const gi = new GalleryInfo();
  gi.gid = gid;
  gi.token = `tok_${gid}`;
  gi.title = title;
  gi.category = category;
  gi.uploader = 'test_user';
  gi.rating = 4.0;
  return gi;
}

describe('FavoritesViewModel', () => {
  let db: MemoryEhDB;
  let vm: FavoritesViewModel;

  beforeEach(() => {
    db = new MemoryEhDB();
    vm = new FavoritesViewModel(db);
  });

  describe('initial state', () => {
    it('should start in IDLE state', () => {
      assert.strictEqual(vm.state, FavState.IDLE);
      assert.deepStrictEqual(vm.items, []);
      assert.strictEqual(vm.isEmpty, true);
      assert.strictEqual(vm.count, 0);
    });
  });

  describe('load', () => {
    it('should load empty list as EMPTY state', () => {
      vm.load();
      assert.strictEqual(vm.state, FavState.EMPTY);
      assert.strictEqual(vm.isEmpty, true);
      assert.strictEqual(vm.count, 0);
    });

    it('should load favorites as SUCCESS state', () => {
      db.putLocalFavorites(makeGallery(1, 'Gallery One'));
      db.putLocalFavorites(makeGallery(2, 'Gallery Two'));
      vm.load();
      assert.strictEqual(vm.state, FavState.SUCCESS);
      assert.strictEqual(vm.count, 2);
      assert.strictEqual(vm.isEmpty, false);
    });
  });

  describe('search', () => {
    it('should filter favorites by keyword', () => {
      db.putLocalFavorites(makeGallery(1, 'Alpha'));
      db.putLocalFavorites(makeGallery(2, 'Beta'));
      db.putLocalFavorites(makeGallery(3, 'Alpha Beta'));

      vm.search('Alpha');
      assert.strictEqual(vm.count, 2);
      assert.strictEqual(vm.keyword, 'Alpha');
    });

    it('should return empty for unmatched keyword', () => {
      db.putLocalFavorites(makeGallery(1, 'Alpha'));
      vm.search('zzz');
      assert.strictEqual(vm.state, FavState.EMPTY);
      assert.strictEqual(vm.count, 0);
    });
  });

  describe('clearSearch', () => {
    it('should reload all after clearing search', () => {
      db.putLocalFavorites(makeGallery(1, 'Alpha'));
      db.putLocalFavorites(makeGallery(2, 'Beta'));
      vm.search('Alpha');
      assert.strictEqual(vm.count, 1);

      vm.clearSearch();
      assert.strictEqual(vm.count, 2);
      assert.strictEqual(vm.keyword, '');
    });
  });

  describe('removeFavorite', () => {
    it('should remove a single favorite and refresh', () => {
      db.putLocalFavorites(makeGallery(1, 'One'));
      db.putLocalFavorites(makeGallery(2, 'Two'));
      vm.load();
      assert.strictEqual(vm.count, 2);

      vm.removeFavorite(1);
      assert.strictEqual(vm.count, 1);
      assert.strictEqual(vm.items[0].gid, 2);
    });
  });

  describe('removeFavorites (batch)', () => {
    it('should remove multiple favorites', () => {
      db.putLocalFavorites(makeGallery(1, 'One'));
      db.putLocalFavorites(makeGallery(2, 'Two'));
      db.putLocalFavorites(makeGallery(3, 'Three'));
      vm.load();

      vm.removeFavorites([1, 3]);
      assert.strictEqual(vm.count, 1);
      assert.strictEqual(vm.items[0].gid, 2);
    });
  });

  describe('isFavorited', () => {
    it('should return true for existing favorites', () => {
      db.putLocalFavorites(makeGallery(1, 'One'));
      assert.strictEqual(vm.isFavorited(1), true);
      assert.strictEqual(vm.isFavorited(999), false);
    });
  });

  describe('addFavorite', () => {
    it('should add a new favorite and refresh', () => {
      vm.load();
      assert.strictEqual(vm.count, 0);

      vm.addFavorite(makeGallery(42, 'New Gallery'));
      assert.strictEqual(vm.count, 1);
      assert.strictEqual(vm.items[0].gid, 42);
    });

    it('should not duplicate existing favorites', () => {
      vm.addFavorite(makeGallery(1, 'One'));
      vm.addFavorite(makeGallery(1, 'One again'));
      assert.strictEqual(vm.count, 1);
    });
  });

  describe('title', () => {
    it('should return "Local Favorites" by default', () => {
      assert.strictEqual(vm.title, 'Local Favorites');
    });
  });

  describe('refresh', () => {
    it('should re-apply the current keyword filter', () => {
      db.putLocalFavorites(makeGallery(1, 'Alpha'));
      db.putLocalFavorites(makeGallery(2, 'Beta'));

      vm.search('Alpha');
      assert.strictEqual(vm.count, 1);

      // Add a new matching gallery directly to DB
      db.putLocalFavorites(makeGallery(3, 'Alpha Gamma'));
      vm.refresh();
      assert.strictEqual(vm.count, 2);
    });
  });
});
