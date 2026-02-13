import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import {
  GalleryDetailViewModel,
  DetailState,
  type GalleryDetailFetcher,
} from '../../../main/ets/viewmodel/GalleryDetailViewModel.ets';
import { GalleryDetail } from '../../../main/ets/model/GalleryDetail.ets';
import { GalleryTagGroup } from '../../../main/ets/model/GalleryTagGroup.ets';
import { LargePreviewSet } from '../../../main/ets/model/LargePreviewSet.ets';
import { EhConfig } from '../../../main/ets/client/EhConfig.ets';

function makeDetail(gid: number, token: string): GalleryDetail {
  const d = new GalleryDetail();
  d.gid = gid;
  d.token = token;
  d.title = 'Test Title';
  d.titleJpn = 'テスト';
  d.thumb = 'https://example.com/thumb.jpg';
  d.category = EhConfig.DOUJINSHI;
  d.uploader = 'uploader1';
  d.rating = 4.5;
  d.ratingCount = 100;
  d.posted = '2024-01-15 12:00';
  d.pages = 42;
  d.language = 'Japanese';
  d.size = '80 MB';
  d.favoriteCount = 200;
  d.isFavorited = false;
  const g = new GalleryTagGroup();
  g.groupName = 'language';
  g.addTag('japanese');
  d.tags = [g];
  const ps = new LargePreviewSet();
  ps.addItem(0, 'https://ex/p0.jpg', 'https://page/0');
  ps.addItem(1, 'https://ex/p1.jpg', 'https://page/1');
  d.previewSet = ps;
  d.previewPages = 2;
  return d;
}

const mockFetcher: GalleryDetailFetcher = {
  async fetchDetail(gid: number, token: string): Promise<GalleryDetail> {
    return makeDetail(gid, token);
  },
};

describe('GalleryDetailViewModel', () => {
  let vm: GalleryDetailViewModel;

  beforeEach(() => {
    vm = new GalleryDetailViewModel(mockFetcher);
  });

  describe('initial state', () => {
    it('should start in LOADING state', () => {
      assert.strictEqual(vm.state, DetailState.LOADING);
      assert.strictEqual(vm.error, '');
      assert.strictEqual(vm.detail, null);
    });
  });

  describe('load', () => {
    it('should set SUCCESS and detail after load', async () => {
      await vm.load(100, 'tok_100');
      assert.strictEqual(vm.state, DetailState.SUCCESS);
      assert.strictEqual(vm.error, '');
      assert.ok(vm.detail !== null);
      assert.strictEqual(vm.detail!.gid, 100);
      assert.strictEqual(vm.detail!.token, 'tok_100');
      assert.strictEqual(vm.detail!.title, 'Test Title');
    });

    it('should expose display properties', async () => {
      await vm.load(100, 'tok_100');
      assert.ok(vm.displayTitle.length > 0);
      assert.ok(vm.categoryText.length > 0);
      assert.strictEqual(vm.uploaderText, 'uploader1');
      assert.strictEqual(vm.ratingValue, 4.5);
      assert.strictEqual(vm.pagesText, '42 pages');
      assert.strictEqual(vm.languageText, 'Japanese');
      assert.strictEqual(vm.sizeText, '80 MB');
      assert.strictEqual(vm.favoriteCountText, '200');
      assert.strictEqual(vm.postedText, '2024-01-15 12:00');
      assert.strictEqual(vm.ratingCountText, '100 votes');
      assert.strictEqual(vm.isFavorited, false);
    });

    it('should return tags and comments', async () => {
      await vm.load(100, 'tok_100');
      assert.strictEqual(vm.tags.length, 1);
      assert.strictEqual(vm.tags[0].groupName, 'language');
      assert.deepStrictEqual(vm.tags[0].getTags(), ['japanese']);
    });

    it('should return previews via getPreviews', async () => {
      await vm.load(100, 'tok_100');
      const previews = vm.getPreviews();
      assert.strictEqual(previews.length, 2);
      assert.strictEqual(previews[0].imageUrl, 'https://ex/p0.jpg');
      assert.strictEqual(previews[0].pageUrl, 'https://page/0');
      assert.strictEqual(previews[1].imageUrl, 'https://ex/p1.jpg');
      assert.strictEqual(vm.previewCount, 2);
      assert.strictEqual(vm.previewPages, 2);
    });

    it('should set FAILED on fetcher error', async () => {
      const failFetcher: GalleryDetailFetcher = {
        async fetchDetail(): Promise<GalleryDetail> {
          throw new Error('Network error');
        },
      };
      const failVm = new GalleryDetailViewModel(failFetcher);
      await failVm.load(1, 't');
      assert.strictEqual(failVm.state, DetailState.FAILED);
      assert.strictEqual(failVm.error, 'Network error');
      assert.strictEqual(failVm.detail, null);
    });
  });

  describe('setOnStateChange', () => {
    it('allows setting callback', () => {
      let called = 0;
      vm.setOnStateChange(() => { called++; });
      assert.strictEqual(called, 0);
      vm.setOnStateChange(null);
      assert.strictEqual(called, 0);
    });
  });
});
