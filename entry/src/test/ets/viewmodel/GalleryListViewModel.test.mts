import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import {
  GalleryListViewModel,
  ListState,
  ListMode,
} from '../../../main/ets/viewmodel/GalleryListViewModel.ets';
import type { GalleryListFetcher, GalleryListResult } from '../../../main/ets/viewmodel/GalleryListViewModel.ets';
import { GalleryInfo } from '../../../main/ets/model/GalleryInfo.ets';
import { DataMappers } from '../../../main/ets/viewmodel/DataMappers.ets';
import { PageRouter, Routes } from '../../../main/ets/router/PageRouter.ets';

function makeGallery(gid: number, title: string = `Gallery ${gid}`): GalleryInfo {
  const gi = new GalleryInfo();
  gi.gid = gid;
  gi.token = `tok_${gid}`;
  gi.title = title;
  gi.category = 2;
  gi.uploader = 'test_user';
  gi.rating = 4.0;
  gi.posted = '2024-01-15';
  return gi;
}

/** Configurable mock fetcher for testing. */
class MockFetcher implements GalleryListFetcher {
  items: GalleryInfo[] = [];
  hasNextPage: boolean = false;
  callCount: number = 0;
  lastUrl: string = '';
  shouldFail: boolean = false;
  failMessage: string = 'Network error';

  async fetchList(url: string): Promise<GalleryListResult> {
    this.callCount++;
    this.lastUrl = url;
    if (this.shouldFail) {
      throw new Error(this.failMessage);
    }
    return { items: [...this.items], hasNextPage: this.hasNextPage };
  }
}

describe('GalleryListViewModel', () => {
  let fetcher: MockFetcher;
  let vm: GalleryListViewModel;

  beforeEach(() => {
    fetcher = new MockFetcher();
    vm = new GalleryListViewModel(fetcher);
  });

  describe('initial state', () => {
    it('should start in IDLE state', () => {
      assert.strictEqual(vm.state, ListState.IDLE);
      assert.deepStrictEqual(vm.items, []);
      assert.strictEqual(vm.isEmpty, true);
      assert.strictEqual(vm.count, 0);
      assert.strictEqual(vm.hasMore, false);
      assert.strictEqual(vm.error, '');
    });

    it('should default to HOMEPAGE mode', () => {
      assert.strictEqual(vm.listMode, ListMode.HOMEPAGE);
      assert.strictEqual(vm.modeTitle, 'Homepage');
    });
  });

  describe('load', () => {
    it('should load empty list as EMPTY state', async () => {
      fetcher.items = [];
      await vm.load();
      assert.strictEqual(vm.state, ListState.EMPTY);
      assert.strictEqual(vm.isEmpty, true);
      assert.strictEqual(vm.count, 0);
    });

    it('should load items as SUCCESS state', async () => {
      fetcher.items = [makeGallery(1), makeGallery(2), makeGallery(3)];
      fetcher.hasNextPage = false;
      await vm.load();
      assert.strictEqual(vm.state, ListState.SUCCESS);
      assert.strictEqual(vm.count, 3);
      assert.strictEqual(vm.hasMore, false);
    });

    it('should set hasMore when fetcher reports next page', async () => {
      fetcher.items = [makeGallery(1)];
      fetcher.hasNextPage = true;
      await vm.load();
      assert.strictEqual(vm.hasMore, true);
    });

    it('should set FAILED state on error', async () => {
      fetcher.shouldFail = true;
      fetcher.failMessage = 'Server down';
      await vm.load();
      assert.strictEqual(vm.state, ListState.FAILED);
      assert.strictEqual(vm.error, 'Server down');
      assert.strictEqual(vm.count, 0);
    });

    it('should reset items on load', async () => {
      fetcher.items = [makeGallery(1)];
      await vm.load();
      assert.strictEqual(vm.count, 1);

      fetcher.items = [makeGallery(2), makeGallery(3)];
      await vm.load();
      assert.strictEqual(vm.count, 2);
      assert.strictEqual(vm.items[0].gid, 2);
    });
  });

  describe('refresh', () => {
    it('should reset page index and reload', async () => {
      fetcher.items = [makeGallery(1)];
      fetcher.hasNextPage = true;
      await vm.load();
      await vm.loadMore();

      fetcher.items = [makeGallery(10)];
      fetcher.hasNextPage = false;
      await vm.refresh();

      assert.strictEqual(vm.pageIndex, 0);
      assert.strictEqual(vm.count, 1);
      assert.strictEqual(vm.items[0].gid, 10);
    });
  });

  describe('loadMore', () => {
    it('should append items and increment page', async () => {
      fetcher.items = [makeGallery(1)];
      fetcher.hasNextPage = true;
      await vm.load();
      assert.strictEqual(vm.pageIndex, 0);

      fetcher.items = [makeGallery(2)];
      fetcher.hasNextPage = false;
      await vm.loadMore();

      assert.strictEqual(vm.pageIndex, 1);
      assert.strictEqual(vm.count, 2);
      assert.strictEqual(vm.items[0].gid, 1);
      assert.strictEqual(vm.items[1].gid, 2);
      assert.strictEqual(vm.hasMore, false);
    });

    it('should not load more when hasMore is false', async () => {
      fetcher.items = [makeGallery(1)];
      fetcher.hasNextPage = false;
      await vm.load();

      const callsBefore = fetcher.callCount;
      await vm.loadMore();
      assert.strictEqual(fetcher.callCount, callsBefore);
    });

    it('should rollback page index on error', async () => {
      fetcher.items = [makeGallery(1)];
      fetcher.hasNextPage = true;
      await vm.load();

      fetcher.shouldFail = true;
      await vm.loadMore();

      assert.strictEqual(vm.pageIndex, 0);
      assert.strictEqual(vm.state, ListState.FAILED);
    });
  });

  describe('search', () => {
    it('should set keyword and switch to SEARCH mode', async () => {
      fetcher.items = [makeGallery(1, 'Found')];
      await vm.search('test keyword');
      assert.strictEqual(vm.keyword, 'test keyword');
      assert.strictEqual(vm.listMode, ListMode.SEARCH);
      assert.strictEqual(vm.modeTitle, 'Search');
      assert.strictEqual(vm.count, 1);
    });
  });

  describe('clearSearch', () => {
    it('should clear keyword and return to HOMEPAGE mode', async () => {
      fetcher.items = [makeGallery(1)];
      await vm.search('test');
      assert.strictEqual(vm.listMode, ListMode.SEARCH);

      await vm.clearSearch();
      assert.strictEqual(vm.keyword, '');
      assert.strictEqual(vm.listMode, ListMode.HOMEPAGE);
    });
  });

  describe('setListMode', () => {
    it('should change mode and reset state', () => {
      vm.setListMode(ListMode.SUBSCRIPTION);
      assert.strictEqual(vm.listMode, ListMode.SUBSCRIPTION);
      assert.strictEqual(vm.modeTitle, 'Subscription');
      assert.deepStrictEqual(vm.items, []);
    });

    it('should clear keyword on mode change', () => {
      vm.setKeyword('test');
      vm.setListMode(ListMode.WHATS_HOT);
      assert.strictEqual(vm.keyword, '');
      assert.strictEqual(vm.modeTitle, "What's Hot");
    });
  });

  describe('buildUrl', () => {
    it('should include page index in URL', async () => {
      fetcher.items = [makeGallery(1)];
      fetcher.hasNextPage = true;
      await vm.load();
      await vm.loadMore();

      // The fetcher was called with a URL containing page=1
      assert.ok(fetcher.lastUrl.includes('page=1'));
    });
  });

  describe('DataMappers integration', () => {
    it('should map GalleryListViewModel items to GalleryItemData', async () => {
      const gi = makeGallery(42, 'Test Gallery');
      gi.simpleLanguage = 'EN';
      fetcher.items = [gi];
      await vm.load();

      const mapped = DataMappers.toGalleryItems(vm.items);
      assert.strictEqual(mapped.length, 1);
      assert.strictEqual(mapped[0].gid, 42);
      assert.strictEqual(mapped[0].title, 'Test Gallery');
      assert.strictEqual(mapped[0].token, 'tok_42');
      assert.strictEqual(mapped[0].simpleLanguage, 'EN');
    });
  });

  describe('navigation integration', () => {
    it('PageRouter.toGalleryDetail should build correct NavResult', () => {
      const result = PageRouter.toGalleryDetail(42, 'tok_42');
      assert.strictEqual(result.url, Routes.GALLERY_DETAIL);
      assert.deepStrictEqual(result.params, { gid: 42, token: 'tok_42' });
    });

    it('PageRouter.toGalleryReader should build correct NavResult', () => {
      const result = PageRouter.toGalleryReader(42, 'tok_42', 5);
      assert.strictEqual(result.url, Routes.GALLERY_READER);
      assert.deepStrictEqual(result.params, { gid: 42, token: 'tok_42', page: 5 });
    });
  });
});

describe('GalleryListViewModel + DownloadsViewModel data binding', () => {
  it('GalleryListViewModel items can be mapped to GalleryItemData for list display', async () => {
    const fetcher = new MockFetcher();
    const vm = new GalleryListViewModel(fetcher);
    fetcher.items = [makeGallery(1, 'Gallery One'), makeGallery(2, 'Gallery Two')];
    fetcher.hasNextPage = true;
    await vm.load();

    const displayItems = DataMappers.toGalleryItems(vm.items);
    assert.strictEqual(displayItems.length, 2);
    assert.strictEqual(displayItems[0].gid, 1);
    assert.strictEqual(displayItems[0].title, 'Gallery One');
    assert.strictEqual(displayItems[1].gid, 2);
    assert.strictEqual(displayItems[1].title, 'Gallery Two');
  });

  it('after refresh, mapped items reflect new data', async () => {
    const fetcher = new MockFetcher();
    const vm = new GalleryListViewModel(fetcher);
    fetcher.items = [makeGallery(1)];
    await vm.load();

    fetcher.items = [makeGallery(10), makeGallery(11)];
    await vm.refresh();

    const displayItems = DataMappers.toGalleryItems(vm.items);
    assert.strictEqual(displayItems.length, 2);
    assert.strictEqual(displayItems[0].gid, 10);
    assert.strictEqual(displayItems[1].gid, 11);
  });

  it('after loadMore, mapped items include appended data', async () => {
    const fetcher = new MockFetcher();
    const vm = new GalleryListViewModel(fetcher);
    fetcher.items = [makeGallery(1)];
    fetcher.hasNextPage = true;
    await vm.load();

    fetcher.items = [makeGallery(2)];
    fetcher.hasNextPage = false;
    await vm.loadMore();

    const displayItems = DataMappers.toGalleryItems(vm.items);
    assert.strictEqual(displayItems.length, 2);
  });
});
