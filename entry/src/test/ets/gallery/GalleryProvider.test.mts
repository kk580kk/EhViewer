import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

import {
  GalleryProvider,
  STATE_WAIT,
  STATE_ERROR,
  isSupportedImageFile,
} from '../../../main/ets/gallery/GalleryProvider.ets';
import type { GalleryProviderListener } from '../../../main/ets/gallery/GalleryProvider.ets';

// ---- Concrete test subclass ----

class TestGalleryProvider extends GalleryProvider {
  testSize = STATE_WAIT;
  testError: string | null = null;
  requestedIndices: number[] = [];
  forceRequestedIndices: number[] = [];
  cancelledIndices: number[] = [];

  size(): number { return this.testSize; }
  getError(): string | null { return this.testError; }
  getImageFilename(index: number): string { return `img-${index}`; }
  save(_index: number, _destPath: string): boolean { return true; }
  saveToDir(_index: number, _dir: string, _filename: string): string | null { return null; }

  protected onRequest(index: number): void {
    this.requestedIndices.push(index);
    this.notifyPageWait(index);
  }
  protected onForceRequest(index: number): void {
    this.forceRequestedIndices.push(index);
  }
  protected onCancelRequest(index: number): void {
    this.cancelledIndices.push(index);
  }

  // Expose protected methods for testing
  doNotifyDataChanged(): void { this.notifyDataChanged(); }
  doNotifyPageSucceed(index: number, data: Uint8Array): void { this.notifyPageSucceed(index, data); }
  doNotifyPageFailed(index: number, error: string): void { this.notifyPageFailed(index, error); }
  doNotifyPagePercent(index: number, percent: number): void { this.notifyPagePercent(index, percent); }
}

// ---- Test listener ----

class TestListener implements GalleryProviderListener {
  dataChangedCount = 0;
  pageWaits: number[] = [];
  pagePercents: { index: number; percent: number }[] = [];
  pageSucceeds: { index: number; data: Uint8Array }[] = [];
  pageFails: { index: number; error: string }[] = [];

  onDataChanged(): void { this.dataChangedCount++; }
  onPageWait(index: number): void { this.pageWaits.push(index); }
  onPagePercent(index: number, percent: number): void { this.pagePercents.push({ index, percent }); }
  onPageSucceed(index: number, data: Uint8Array): void { this.pageSucceeds.push({ index, data }); }
  onPageFailed(index: number, error: string): void { this.pageFails.push({ index, error }); }
}

// ---- Tests ----

describe('isSupportedImageFile', () => {
  it('should accept supported extensions', () => {
    assert.ok(isSupportedImageFile('photo.jpg'));
    assert.ok(isSupportedImageFile('photo.JPEG'));
    assert.ok(isSupportedImageFile('pic.png'));
    assert.ok(isSupportedImageFile('anim.gif'));
  });

  it('should reject unsupported extensions', () => {
    assert.ok(!isSupportedImageFile('doc.txt'));
    assert.ok(!isSupportedImageFile('video.mp4'));
    assert.ok(!isSupportedImageFile('archive.zip'));
    assert.ok(!isSupportedImageFile('noext'));
  });
});

describe('GalleryProvider (base)', () => {
  let provider: TestGalleryProvider;
  let listener: TestListener;

  beforeEach(() => {
    provider = new TestGalleryProvider();
    listener = new TestListener();
    provider.addListener(listener);
  });

  it('should report initial state as STATE_WAIT', () => {
    assert.strictEqual(provider.size(), STATE_WAIT);
  });

  it('should track start/stop lifecycle', () => {
    assert.ok(!provider.isStarted());
    provider.start();
    assert.ok(provider.isStarted());
    provider.stop();
    assert.ok(!provider.isStarted());
  });

  it('should dispatch request to onRequest', () => {
    provider.request(3);
    assert.deepStrictEqual(provider.requestedIndices, [3]);
    assert.deepStrictEqual(listener.pageWaits, [3]);
  });

  it('should dispatch forceRequest to onForceRequest', () => {
    provider.forceRequest(5);
    assert.deepStrictEqual(provider.forceRequestedIndices, [5]);
  });

  it('should dispatch cancelRequest to onCancelRequest', () => {
    provider.cancelRequest(7);
    assert.deepStrictEqual(provider.cancelledIndices, [7]);
  });

  it('should notify listeners on data changed', () => {
    provider.doNotifyDataChanged();
    assert.strictEqual(listener.dataChangedCount, 1);
  });

  it('should notify listeners on page succeed', () => {
    const data = new Uint8Array([1, 2, 3]);
    provider.doNotifyPageSucceed(0, data);
    assert.strictEqual(listener.pageSucceeds.length, 1);
    assert.strictEqual(listener.pageSucceeds[0].index, 0);
    assert.deepStrictEqual(listener.pageSucceeds[0].data, data);
  });

  it('should notify listeners on page failed', () => {
    provider.doNotifyPageFailed(2, 'network error');
    assert.strictEqual(listener.pageFails.length, 1);
    assert.strictEqual(listener.pageFails[0].index, 2);
    assert.strictEqual(listener.pageFails[0].error, 'network error');
  });

  it('should notify listeners on page percent', () => {
    provider.doNotifyPagePercent(1, 0.5);
    assert.strictEqual(listener.pagePercents.length, 1);
    assert.strictEqual(listener.pagePercents[0].percent, 0.5);
  });

  it('should support multiple listeners', () => {
    const listener2 = new TestListener();
    provider.addListener(listener2);
    provider.doNotifyDataChanged();
    assert.strictEqual(listener.dataChangedCount, 1);
    assert.strictEqual(listener2.dataChangedCount, 1);
  });

  it('should remove listener correctly', () => {
    provider.removeListener(listener);
    provider.doNotifyDataChanged();
    assert.strictEqual(listener.dataChangedCount, 0);
  });

  it('should not add duplicate listener', () => {
    provider.addListener(listener);
    provider.doNotifyDataChanged();
    assert.strictEqual(listener.dataChangedCount, 1);
  });

  it('should return default start page of 0', () => {
    assert.strictEqual(provider.getStartPage(), 0);
  });

  it('should return error from subclass', () => {
    provider.testError = 'test error';
    assert.strictEqual(provider.getError(), 'test error');
  });
});
