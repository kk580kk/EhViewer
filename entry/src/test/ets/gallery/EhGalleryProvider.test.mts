import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

import {
  EhGalleryProvider,
  MODE_READ,
} from '../../../main/ets/gallery/EhGalleryProvider.ets';
import type {
  OnSpiderListener,
  SpiderQueenLike,
  SpiderQueenFactory,
} from '../../../main/ets/gallery/EhGalleryProvider.ets';
import { STATE_ERROR } from '../../../main/ets/gallery/GalleryProvider.ets';
import type { GalleryProviderListener } from '../../../main/ets/gallery/GalleryProvider.ets';
import { GalleryInfo } from '../../../main/ets/model/GalleryInfo.ets';

// ---- Mock SpiderQueen ----

class MockSpiderQueen implements SpiderQueenLike {
  listeners: OnSpiderListener[] = [];
  testSize = 20;
  testError: string | null = null;
  testStartPage = 3;

  requestedIndices: number[] = [];
  forceRequestedIndices: number[] = [];
  cancelledIndices: number[] = [];
  savedStartPage: number | null = null;

  /** What request() returns — null=wait, number=percent, string=error */
  requestResult: number | string | null = null;
  forceRequestResult: number | string | null = null;

  addOnSpiderListener(listener: OnSpiderListener): void {
    this.listeners.push(listener);
  }

  removeOnSpiderListener(listener: OnSpiderListener): void {
    const idx = this.listeners.indexOf(listener);
    if (idx >= 0) this.listeners.splice(idx, 1);
  }

  size(): number { return this.testSize; }
  getError(): string | null { return this.testError; }
  getStartPage(): number { return this.testStartPage; }
  putStartPage(page: number): void { this.savedStartPage = page; }

  request(index: number): number | string | null {
    this.requestedIndices.push(index);
    return this.requestResult;
  }

  forceRequest(index: number): number | string | null {
    this.forceRequestedIndices.push(index);
    return this.forceRequestResult;
  }

  cancelRequest(index: number): void {
    this.cancelledIndices.push(index);
  }

  save(_index: number, _destPath: string): boolean { return true; }
  saveToDir(_index: number, dir: string, filename: string): string | null {
    return `${dir}/${filename}.jpg`;
  }
}

// ---- Mock Factory ----

class MockFactory implements SpiderQueenFactory {
  spider: MockSpiderQueen;
  obtainedWith: { galleryInfo: GalleryInfo; mode: number } | null = null;
  releasedWith: { spider: SpiderQueenLike; mode: number } | null = null;

  constructor(spider: MockSpiderQueen) {
    this.spider = spider;
  }

  obtain(galleryInfo: GalleryInfo, mode: number): SpiderQueenLike {
    this.obtainedWith = { galleryInfo, mode };
    return this.spider;
  }

  release(spider: SpiderQueenLike, mode: number): void {
    this.releasedWith = { spider, mode };
  }
}

// ---- Test Listener ----

class TestListener implements GalleryProviderListener {
  dataChangedCount = 0;
  pageDataChangedIndices: number[] = [];
  pageWaits: number[] = [];
  pagePercents: { index: number; percent: number }[] = [];
  pageSucceeds: { index: number; data: Uint8Array }[] = [];
  pageFails: { index: number; error: string }[] = [];

  onDataChanged(): void { this.dataChangedCount++; }
  onPageDataChanged(index: number): void { this.pageDataChangedIndices.push(index); }
  onPageWait(index: number): void { this.pageWaits.push(index); }
  onPagePercent(index: number, percent: number): void { this.pagePercents.push({ index, percent }); }
  onPageSucceed(index: number, data: Uint8Array): void { this.pageSucceeds.push({ index, data }); }
  onPageFailed(index: number, error: string): void { this.pageFails.push({ index, error }); }
}

// ---- Helper ----

function makeGalleryInfo(gid: number, token: string): GalleryInfo {
  const info = new GalleryInfo();
  info.gid = gid;
  info.token = token;
  return info;
}

// ---- Tests ----

describe('EhGalleryProvider', () => {
  let spider: MockSpiderQueen;
  let factory: MockFactory;
  let galleryInfo: GalleryInfo;
  let provider: EhGalleryProvider;
  let listener: TestListener;

  beforeEach(() => {
    spider = new MockSpiderQueen();
    factory = new MockFactory(spider);
    galleryInfo = makeGalleryInfo(12345, 'abc123');
    provider = new EhGalleryProvider(galleryInfo, factory);
    listener = new TestListener();
    provider.addListener(listener);
  });

  // ---- Lifecycle ----

  describe('lifecycle', () => {
    it('should obtain spider on start', () => {
      provider.start();
      assert.ok(factory.obtainedWith !== null);
      assert.strictEqual(factory.obtainedWith!.mode, MODE_READ);
      assert.strictEqual(factory.obtainedWith!.galleryInfo, galleryInfo);
    });

    it('should register as spider listener on start', () => {
      provider.start();
      assert.strictEqual(spider.listeners.length, 1);
    });

    it('should release spider on stop', () => {
      provider.start();
      provider.stop();
      assert.ok(factory.releasedWith !== null);
      assert.strictEqual(factory.releasedWith!.spider, spider);
      assert.strictEqual(factory.releasedWith!.mode, MODE_READ);
    });

    it('should remove spider listener on stop', () => {
      provider.start();
      provider.stop();
      assert.strictEqual(spider.listeners.length, 0);
    });

    it('should handle stop without start', () => {
      // Should not throw
      provider.stop();
      assert.strictEqual(factory.releasedWith, null);
    });
  });

  // ---- Size / Error ----

  describe('size and error', () => {
    it('should return STATE_ERROR when not started', () => {
      assert.strictEqual(provider.size(), STATE_ERROR);
    });

    it('should delegate size to spider when started', () => {
      provider.start();
      assert.strictEqual(provider.size(), 20);
    });

    it('should return "Not started" error when not started', () => {
      assert.strictEqual(provider.getError(), 'Not started');
    });

    it('should delegate error to spider when started', () => {
      spider.testError = 'network failure';
      provider.start();
      assert.strictEqual(provider.getError(), 'network failure');
    });

    it('should return null error when spider has no error', () => {
      provider.start();
      assert.strictEqual(provider.getError(), null);
    });
  });

  // ---- Start page ----

  describe('start page', () => {
    it('should return 0 when not started', () => {
      assert.strictEqual(provider.getStartPage(), 0);
    });

    it('should delegate getStartPage to spider', () => {
      provider.start();
      assert.strictEqual(provider.getStartPage(), 3);
    });

    it('should delegate putStartPage to spider', () => {
      provider.start();
      provider.putStartPage(7);
      assert.strictEqual(spider.savedStartPage, 7);
    });

    it('should not throw putStartPage when not started', () => {
      provider.putStartPage(5);
      // No spider, should be no-op
      assert.strictEqual(spider.savedStartPage, null);
    });
  });

  // ---- Image filename ----

  describe('getImageFilename', () => {
    it('should format filename as gid-token-paddedIndex', () => {
      assert.strictEqual(provider.getImageFilename(0), '12345-abc123-00000001');
    });

    it('should pad index correctly for large indices', () => {
      assert.strictEqual(provider.getImageFilename(99), '12345-abc123-00000100');
    });

    it('should pad index for maximum 8 digits', () => {
      assert.strictEqual(provider.getImageFilename(9999999), '12345-abc123-10000000');
    });
  });

  // ---- Save ----

  describe('save', () => {
    it('should return false when not started', () => {
      assert.strictEqual(provider.save(0, '/tmp/img.jpg'), false);
    });

    it('should delegate save to spider', () => {
      provider.start();
      assert.strictEqual(provider.save(0, '/tmp/img.jpg'), true);
    });

    it('should return null for saveToDir when not started', () => {
      assert.strictEqual(provider.saveToDir(0, '/dir', 'file'), null);
    });

    it('should delegate saveToDir to spider', () => {
      provider.start();
      assert.strictEqual(provider.saveToDir(0, '/dir', 'file'), '/dir/file.jpg');
    });
  });

  // ---- Request handling ----

  describe('request handling', () => {
    it('should notify page wait when spider returns null', () => {
      provider.start();
      spider.requestResult = null;
      provider.request(5);
      assert.deepStrictEqual(spider.requestedIndices, [5]);
      assert.deepStrictEqual(listener.pageWaits, [5]);
    });

    it('should notify page percent when spider returns number', () => {
      provider.start();
      spider.requestResult = 0.42;
      provider.request(3);
      assert.strictEqual(listener.pagePercents.length, 1);
      assert.strictEqual(listener.pagePercents[0].index, 3);
      assert.strictEqual(listener.pagePercents[0].percent, 0.42);
    });

    it('should notify page failed when spider returns string', () => {
      provider.start();
      spider.requestResult = 'download error';
      provider.request(7);
      assert.strictEqual(listener.pageFails.length, 1);
      assert.strictEqual(listener.pageFails[0].index, 7);
      assert.strictEqual(listener.pageFails[0].error, 'download error');
    });

    it('should not throw request when not started', () => {
      provider.request(0);
      // No spider → no-op; no crash
      assert.strictEqual(listener.pageWaits.length, 0);
    });
  });

  describe('force request handling', () => {
    it('should notify page wait when spider returns null', () => {
      provider.start();
      spider.forceRequestResult = null;
      provider.forceRequest(2);
      assert.deepStrictEqual(spider.forceRequestedIndices, [2]);
      assert.deepStrictEqual(listener.pageWaits, [2]);
    });

    it('should notify page percent when spider returns number', () => {
      provider.start();
      spider.forceRequestResult = 0.75;
      provider.forceRequest(4);
      assert.strictEqual(listener.pagePercents.length, 1);
      assert.strictEqual(listener.pagePercents[0].percent, 0.75);
    });

    it('should notify page failed when spider returns string', () => {
      provider.start();
      spider.forceRequestResult = 'timeout';
      provider.forceRequest(1);
      assert.strictEqual(listener.pageFails.length, 1);
      assert.strictEqual(listener.pageFails[0].error, 'timeout');
    });
  });

  describe('cancel request', () => {
    it('should delegate cancelRequest to spider', () => {
      provider.start();
      provider.cancelRequest(6);
      assert.deepStrictEqual(spider.cancelledIndices, [6]);
    });

    it('should not throw cancelRequest when not started', () => {
      provider.cancelRequest(0);
      assert.deepStrictEqual(spider.cancelledIndices, []);
    });
  });

  // ---- OnSpiderListener callbacks ----

  describe('OnSpiderListener callbacks', () => {
    beforeEach(() => {
      provider.start();
    });

    it('onGetPages should notify data changed', () => {
      provider.onGetPages(50);
      assert.strictEqual(listener.dataChangedCount, 1);
    });

    it('onGet509 should not throw', () => {
      // No-op; just verify no crash
      provider.onGet509(0);
    });

    it('onPageDownload should notify percent when contentLength > 0', () => {
      provider.onPageDownload(3, 1000, 500, 100);
      assert.strictEqual(listener.pagePercents.length, 1);
      assert.strictEqual(listener.pagePercents[0].index, 3);
      assert.strictEqual(listener.pagePercents[0].percent, 0.5);
    });

    it('onPageDownload should not notify when contentLength <= 0', () => {
      provider.onPageDownload(3, 0, 500, 100);
      assert.strictEqual(listener.pagePercents.length, 0);

      provider.onPageDownload(3, -1, 500, 100);
      assert.strictEqual(listener.pagePercents.length, 0);
    });

    it('onPageSuccess should notify page data changed', () => {
      provider.onPageSuccess(2, 1, 1, 10);
      assert.deepStrictEqual(listener.pageDataChangedIndices, [2]);
    });

    it('onPageFailure should notify page failed', () => {
      provider.onPageFailure(4, 'network error', 0, 0, 10);
      assert.strictEqual(listener.pageFails.length, 1);
      assert.strictEqual(listener.pageFails[0].index, 4);
      assert.strictEqual(listener.pageFails[0].error, 'network error');
    });

    it('onFinish should not throw', () => {
      // No-op; just verify no crash
      provider.onFinish(10, 10, 10);
    });

    it('onGetImageSuccess should notify page succeed', () => {
      const data = new Uint8Array([0xFF, 0xD8, 0xFF]);
      provider.onGetImageSuccess(1, data);
      assert.strictEqual(listener.pageSucceeds.length, 1);
      assert.strictEqual(listener.pageSucceeds[0].index, 1);
      assert.deepStrictEqual(listener.pageSucceeds[0].data, data);
    });

    it('onGetImageFailure should notify page failed', () => {
      provider.onGetImageFailure(5, 'decode failed');
      assert.strictEqual(listener.pageFails.length, 1);
      assert.strictEqual(listener.pageFails[0].index, 5);
      assert.strictEqual(listener.pageFails[0].error, 'decode failed');
    });
  });

  // ---- Edge cases ----

  describe('edge cases', () => {
    it('should work with different gallery info values', () => {
      const info2 = makeGalleryInfo(99999, 'xyz789');
      const provider2 = new EhGalleryProvider(info2, factory);
      assert.strictEqual(provider2.getImageFilename(0), '99999-xyz789-00000001');
    });

    it('should support multiple start/stop cycles', () => {
      provider.start();
      assert.strictEqual(spider.listeners.length, 1);
      provider.stop();
      assert.strictEqual(spider.listeners.length, 0);

      // Start again with fresh spider
      const spider2 = new MockSpiderQueen();
      spider2.testSize = 30;
      factory.spider = spider2;
      provider.start();
      assert.strictEqual(provider.size(), 30);
      provider.stop();
    });

    it('should return STATE_ERROR after stop', () => {
      provider.start();
      assert.strictEqual(provider.size(), 20);
      provider.stop();
      assert.strictEqual(provider.size(), STATE_ERROR);
    });

    it('should pass download progress correctly', () => {
      provider.start();
      provider.onPageDownload(0, 2048, 1024, 512);
      assert.strictEqual(listener.pagePercents[0].percent, 0.5);

      provider.onPageDownload(0, 2048, 2048, 256);
      assert.strictEqual(listener.pagePercents[1].percent, 1.0);
    });
  });
});
