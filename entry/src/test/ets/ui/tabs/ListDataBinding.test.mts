import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import {
  GalleryListViewModel,
  ListState,
  ListMode,
} from '../../../../main/ets/viewmodel/GalleryListViewModel.ets';
import { DownloadsViewModel, DownloadsState } from '../../../../main/ets/viewmodel/DownloadsViewModel.ets';
import { MemoryEhDB } from '../../../../main/ets/database/MemoryEhDB.ets';
import { DownloadInfo } from '../../../../main/ets/download/DownloadInfo.ets';
import { GalleryInfo } from '../../../../main/ets/model/GalleryInfo.ets';
import { DataMappers } from '../../../../main/ets/viewmodel/DataMappers.ets';
import { PageRouter, Routes } from '../../../../main/ets/router/PageRouter.ets';
import type { GalleryListFetcher, GalleryListResult } from '../../../../main/ets/viewmodel/GalleryListViewModel.ets';

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

function makeDownload(gid: number, title: string, state: number = DownloadInfo.STATE_NONE): DownloadInfo {
  const di = new DownloadInfo(makeGallery(gid, title));
  di.state = state;
  di.time = Date.now() + gid;
  return di;
}

class MockFetcher implements GalleryListFetcher {
  items: GalleryInfo[] = [];
  hasNextPage: boolean = false;
  async fetchList(_url: string): Promise<GalleryListResult> {
    return { items: [...this.items], hasNextPage: this.hasNextPage };
  }
}

describe('Gallery List data binding to UI', () => {
  let fetcher: MockFetcher;
  let vm: GalleryListViewModel;

  beforeEach(() => {
    fetcher = new MockFetcher();
    vm = new GalleryListViewModel(fetcher);
  });

  it('should produce GalleryItemData array suitable for GalleryListTab @Prop binding', async () => {
    fetcher.items = [makeGallery(1, 'G1'), makeGallery(2, 'G2')];
    await vm.load();

    // Simulate what Index.ets does: map to display data
    const items = DataMappers.toGalleryItems(vm.items);
    const listState = vm.state;
    const hasMore = vm.hasMore;

    assert.strictEqual(items.length, 2);
    assert.strictEqual(listState, ListState.SUCCESS);
    assert.strictEqual(hasMore, false);

    // Each item has all required display fields
    for (const item of items) {
      assert.ok(item.gid > 0);
      assert.ok(item.token.length > 0);
      assert.ok(item.title.length > 0);
      assert.ok(typeof item.rating === 'number');
      assert.ok(typeof item.categoryText === 'string');
      assert.ok(typeof item.categoryColor === 'string');
    }
  });

  it('should reflect refresh in mapped items', async () => {
    fetcher.items = [makeGallery(1)];
    await vm.load();
    let items = DataMappers.toGalleryItems(vm.items);
    assert.strictEqual(items.length, 1);

    fetcher.items = [makeGallery(10), makeGallery(11), makeGallery(12)];
    await vm.refresh();
    items = DataMappers.toGalleryItems(vm.items);
    assert.strictEqual(items.length, 3);
    assert.strictEqual(items[0].gid, 10);
  });

  it('should reflect mode switch in mode title', async () => {
    fetcher.items = [makeGallery(1)];

    vm.setListMode(ListMode.SUBSCRIPTION);
    await vm.load();
    assert.strictEqual(vm.modeTitle, 'Subscription');

    vm.setListMode(ListMode.WHATS_HOT);
    await vm.load();
    assert.strictEqual(vm.modeTitle, "What's Hot");

    vm.setListMode(ListMode.HOMEPAGE);
    await vm.load();
    assert.strictEqual(vm.modeTitle, 'Homepage');
  });

  it('should expose error message on failure', async () => {
    fetcher.items = [];
    // Override fetchList to throw
    const original = fetcher.fetchList.bind(fetcher);
    fetcher.fetchList = async (_url: string) => { throw new Error('Test error'); };
    await vm.load();

    assert.strictEqual(vm.state, ListState.FAILED);
    assert.strictEqual(vm.error, 'Test error');

    // Restore
    fetcher.fetchList = original;
  });
});

describe('Downloads data binding to UI', () => {
  let db: MemoryEhDB;
  let vm: DownloadsViewModel;

  beforeEach(() => {
    db = new MemoryEhDB();
    vm = new DownloadsViewModel(db);
  });

  it('should produce DownloadItemData array suitable for DownloadsTab @Prop binding', () => {
    db.putDownloadInfo(makeDownload(1, 'DL1', DownloadInfo.STATE_DOWNLOAD));
    db.putDownloadInfo(makeDownload(2, 'DL2', DownloadInfo.STATE_FINISH));
    vm.load();

    const items = DataMappers.toDownloadItems(vm.items);
    assert.strictEqual(items.length, 2);

    // Each item has download-specific display fields
    for (const item of items) {
      assert.ok(item.gid > 0);
      assert.ok(typeof item.stateText === 'string');
      assert.ok(typeof item.progressPercent === 'number');
      assert.ok(typeof item.canStart === 'boolean');
      assert.ok(typeof item.canStop === 'boolean');
    }
  });

  it('should reflect refresh after adding a new download', () => {
    db.putDownloadInfo(makeDownload(1, 'DL1'));
    vm.load();
    let items = DataMappers.toDownloadItems(vm.items);
    assert.strictEqual(items.length, 1);

    db.putDownloadInfo(makeDownload(2, 'DL2'));
    vm.refresh();
    items = DataMappers.toDownloadItems(vm.items);
    assert.strictEqual(items.length, 2);
  });

  it('should reflect refresh after removing a download', () => {
    db.putDownloadInfo(makeDownload(1, 'DL1'));
    db.putDownloadInfo(makeDownload(2, 'DL2'));
    vm.load();

    vm.removeDownload(1);
    const items = DataMappers.toDownloadItems(vm.items);
    assert.strictEqual(items.length, 1);
    assert.strictEqual(items[0].gid, 2);
  });
});

describe('Click navigation from list items', () => {
  it('should navigate to gallery detail with correct params', () => {
    const result = PageRouter.toGalleryDetail(123, 'abc_token');
    assert.strictEqual(result.url, Routes.GALLERY_DETAIL);
    assert.strictEqual(result.params!['gid'], 123);
    assert.strictEqual(result.params!['token'], 'abc_token');
  });

  it('should navigate to gallery reader with correct params', () => {
    const result = PageRouter.toGalleryReader(123, 'abc_token', 10);
    assert.strictEqual(result.url, Routes.GALLERY_READER);
    assert.strictEqual(result.params!['gid'], 123);
    assert.strictEqual(result.params!['token'], 'abc_token');
    assert.strictEqual(result.params!['page'], 10);
  });

  it('should navigate to reader with default page 0', () => {
    const result = PageRouter.toGalleryReader(42, 'tok');
    assert.strictEqual(result.params!['page'], 0);
  });
});
