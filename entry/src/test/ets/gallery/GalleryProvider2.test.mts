import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

import type { GalleryProvider2 } from '../../../main/ets/gallery/GalleryProvider2.ets';
import {
  GalleryProvider,
  STATE_WAIT,
  STATE_ERROR,
} from '../../../main/ets/gallery/GalleryProvider.ets';
import type { GalleryProviderListener } from '../../../main/ets/gallery/GalleryProvider.ets';

// ---- Concrete test implementation ----

class StubGalleryProvider extends GalleryProvider {
  testSize = 10;
  testError: string | null = null;

  size(): number { return this.testSize; }
  getError(): string | null { return this.testError; }
  getImageFilename(index: number): string { return `page-${index}`; }
  save(_index: number, _destPath: string): boolean { return true; }
  saveToDir(_index: number, dir: string, filename: string): string | null {
    return `${dir}/${filename}.jpg`;
  }

  protected onRequest(index: number): void { this.notifyPageWait(index); }
  protected onForceRequest(index: number): void { this.notifyPageWait(index); }
  protected onCancelRequest(_index: number): void { /* no-op */ }
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

describe('GalleryProvider2 interface', () => {

  it('GalleryProvider abstract class implements GalleryProvider2', () => {
    // A StubGalleryProvider (extending GalleryProvider) should satisfy
    // GalleryProvider2 at the type level — verify by assigning to the interface type.
    const provider: GalleryProvider2 = new StubGalleryProvider();
    assert.ok(provider !== null);
  });

  describe('contract compliance via abstract class', () => {
    let provider: GalleryProvider2;
    let concrete: StubGalleryProvider;
    let listener: TestListener;

    beforeEach(() => {
      concrete = new StubGalleryProvider();
      provider = concrete; // use interface type
      listener = new TestListener();
      provider.addListener(listener);
    });

    // ---- Lifecycle ----

    it('should start and stop', () => {
      assert.strictEqual(provider.isStarted(), false);
      provider.start();
      assert.strictEqual(provider.isStarted(), true);
      provider.stop();
      assert.strictEqual(provider.isStarted(), false);
    });

    // ---- Page information ----

    it('should return size', () => {
      assert.strictEqual(provider.size(), 10);
    });

    it('should return error', () => {
      assert.strictEqual(provider.getError(), null);
      concrete.testError = 'something went wrong';
      assert.strictEqual(provider.getError(), 'something went wrong');
    });

    // ---- Reading position ----

    it('should return default start page of 0', () => {
      assert.strictEqual(provider.getStartPage(), 0);
    });

    it('putStartPage should not throw', () => {
      // Default is no-op; just verify it doesn't throw
      provider.putStartPage(5);
    });

    // ---- Image access ----

    it('should return image filename', () => {
      assert.strictEqual(provider.getImageFilename(0), 'page-0');
      assert.strictEqual(provider.getImageFilename(3), 'page-3');
    });

    it('should save image', () => {
      assert.strictEqual(provider.save(0, '/tmp/img.jpg'), true);
    });

    it('should save image to directory', () => {
      const path = provider.saveToDir(0, '/output', 'myimage');
      assert.strictEqual(path, '/output/myimage.jpg');
    });

    // ---- Request / cancel ----

    it('should request a page and notify listener', () => {
      provider.request(2);
      assert.deepStrictEqual(listener.pageWaits, [2]);
    });

    it('should force-request a page and notify listener', () => {
      provider.forceRequest(4);
      assert.deepStrictEqual(listener.pageWaits, [4]);
    });

    it('should cancel request without error', () => {
      provider.cancelRequest(1);
      // No assertion needed — just verify no throw
    });

    // ---- Listener management ----

    it('should add and remove listener', () => {
      provider.request(0);
      assert.strictEqual(listener.pageWaits.length, 1);

      provider.removeListener(listener);
      provider.request(1);
      // After removing, listener should not receive new events
      assert.strictEqual(listener.pageWaits.length, 1);
    });
  });

  describe('polymorphism — any GalleryProvider2 can be used uniformly', () => {

    /**
     * Simulates a consumer function that works with any GalleryProvider2,
     * regardless of concrete type (Eh, Dir, Archive).
     */
    function readFirstPage(gp: GalleryProvider2): { filename: string; size: number } {
      gp.start();
      const s = gp.size();
      const filename = gp.getImageFilename(0);
      gp.stop();
      return { filename, size: s };
    }

    it('should work with any concrete provider through the interface', () => {
      const provider = new StubGalleryProvider();
      const result = readFirstPage(provider);
      assert.strictEqual(result.filename, 'page-0');
      assert.strictEqual(result.size, 10);
    });

    it('should allow save operations through the interface', () => {
      const provider: GalleryProvider2 = new StubGalleryProvider();
      assert.strictEqual(provider.save(0, '/tmp/test.jpg'), true);
      assert.strictEqual(provider.saveToDir(0, '/dir', 'img'), '/dir/img.jpg');
    });
  });
});
