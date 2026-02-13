import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

import {
  GalleryReaderViewModel,
  PageState,
  ReadingMode,
  PRELOAD_AHEAD,
  PRELOAD_BEHIND,
} from '../../../main/ets/viewmodel/GalleryReaderViewModel.ets';
import { GallerySource } from '../../../main/ets/gallery/GallerySource.ets';
import type { ReaderState } from '../../../main/ets/gallery/ReaderState.ets';
import type { GalleryProvider2 } from '../../../main/ets/gallery/GalleryProvider2.ets';
import type { GalleryProviderListener } from '../../../main/ets/gallery/GalleryProvider.ets';
import { SettingsService } from '../../../main/ets/service/SettingsService.ets';

// ---- Stub provider ----

class StubProvider implements GalleryProvider2 {
  private listeners: GalleryProviderListener[] = [];
  private _size: number;
  private _started = false;
  startPageWritten: number | null = null;
  requestedPages: number[] = [];
  /** If true, request() immediately notifies onPageSucceed with dummy data. */
  autoSucceed: boolean = false;

  constructor(size: number = 10) {
    this._size = size;
  }

  start(): void { this._started = true; }
  stop(): void { this._started = false; }
  isStarted(): boolean { return this._started; }
  size(): number { return this._size; }
  getError(): string | null { return null; }
  getStartPage(): number { return 0; }
  putStartPage(page: number): void { this.startPageWritten = page; }
  getImageFilename(index: number): string { return `img-${index}`; }
  save(_index: number, _destPath: string): boolean { return false; }
  saveToDir(_index: number, _dir: string, _filename: string): string | null { return null; }
  request(index: number): void {
    this.requestedPages.push(index);
    if (this.autoSucceed) {
      const data = new Uint8Array([0xFF, 0xD8, index & 0xFF]);
      for (const l of this.listeners) {
        l.onPageSucceed(index, data);
      }
    }
  }
  forceRequest(index: number): void { this.requestedPages.push(index); }
  cancelRequest(_index: number): void {}
  addListener(l: GalleryProviderListener): void { this.listeners.push(l); }
  removeListener(l: GalleryProviderListener): void {
    const idx = this.listeners.indexOf(l);
    if (idx >= 0) this.listeners.splice(idx, 1);
  }

  /** Manually fire a page success notification to all listeners. */
  simulatePageSuccess(index: number, data: Uint8Array): void {
    for (const l of this.listeners) {
      l.onPageSucceed(index, data);
    }
  }

  /** Manually fire a page failure notification to all listeners. */
  simulatePageFailure(index: number, error: string): void {
    for (const l of this.listeners) {
      l.onPageFailed(index, error);
    }
  }

  /** Manually fire a page progress notification to all listeners. */
  simulatePagePercent(index: number, percent: number): void {
    for (const l of this.listeners) {
      l.onPagePercent(index, percent);
    }
  }
}

// ---- Tests ----

describe('GalleryReaderViewModel — readerState', () => {
  let vm: GalleryReaderViewModel;
  let provider: StubProvider;

  beforeEach(() => {
    SettingsService.resetDefaults();
    vm = new GalleryReaderViewModel();
    provider = new StubProvider(20);
  });

  it('should expose a default readerState before start', () => {
    const state: ReaderState = vm.readerState;
    assert.strictEqual(typeof state.source, 'string');
    assert.strictEqual(typeof state.currentIndex, 'number');
  });

  it('should initialise readerState with EH source on start', () => {
    vm.start(provider, GallerySource.EH, 3);
    const state = vm.readerState;

    assert.strictEqual(state.source, GallerySource.EH);
    assert.strictEqual(state.currentIndex, 3);
  });

  it('should initialise readerState with DIR source on start', () => {
    vm.start(provider, GallerySource.DIR);
    const state = vm.readerState;

    assert.strictEqual(state.source, GallerySource.DIR);
    assert.strictEqual(state.currentIndex, 0);
  });

  it('should initialise readerState with ARCHIVE source on start', () => {
    vm.start(provider, GallerySource.ARCHIVE, 5);
    const state = vm.readerState;

    assert.strictEqual(state.source, GallerySource.ARCHIVE);
    assert.strictEqual(state.currentIndex, 5);
  });

  it('goToPage should update readerState.currentIndex', () => {
    vm.start(provider, GallerySource.EH);
    vm.goToPage(7);

    assert.strictEqual(vm.readerState.currentIndex, 7);
    assert.strictEqual(vm.currentPage, 7);
  });

  it('nextPage should update readerState.currentIndex', () => {
    vm.start(provider, GallerySource.DIR, 0);
    vm.nextPage();

    assert.strictEqual(vm.readerState.currentIndex, 1);
  });

  it('prevPage should update readerState.currentIndex', () => {
    vm.start(provider, GallerySource.DIR, 5);
    vm.prevPage();

    assert.strictEqual(vm.readerState.currentIndex, 4);
  });

  it('readerState.source should remain stable across page navigations', () => {
    vm.start(provider, GallerySource.ARCHIVE, 0);

    vm.goToPage(3);
    vm.goToPage(10);
    vm.nextPage();

    assert.strictEqual(vm.readerState.source, GallerySource.ARCHIVE);
  });

  it('readerState should be consistent with currentPage', () => {
    vm.start(provider, GallerySource.EH, 0);

    for (let i = 0; i < 15; i++) {
      vm.goToPage(i);
      assert.strictEqual(vm.readerState.currentIndex, vm.currentPage);
    }
  });

  it('readerState is read-only via the getter type', () => {
    vm.start(provider, GallerySource.EH, 2);

    const state: ReaderState = vm.readerState;
    // Verify the read-only interface provides correct values
    assert.strictEqual(state.source, GallerySource.EH);
    assert.strictEqual(state.currentIndex, 2);
  });

  it('starting again resets readerState with new source', () => {
    vm.start(provider, GallerySource.EH, 5);
    assert.strictEqual(vm.readerState.source, GallerySource.EH);
    assert.strictEqual(vm.readerState.currentIndex, 5);

    vm.stop();

    const provider2 = new StubProvider(30);
    vm.start(provider2, GallerySource.DIR, 0);
    assert.strictEqual(vm.readerState.source, GallerySource.DIR);
    assert.strictEqual(vm.readerState.currentIndex, 0);
  });
});

// ---- Page image data ----

describe('GalleryReaderViewModel — page image data', () => {
  let vm: GalleryReaderViewModel;
  let provider: StubProvider;

  beforeEach(() => {
    SettingsService.resetDefaults();
    vm = new GalleryReaderViewModel();
    provider = new StubProvider(20);
  });

  it('should return null for unloaded page', () => {
    vm.start(provider, GallerySource.EH);
    assert.strictEqual(vm.getPageImageData(0), null);
    assert.strictEqual(vm.getPageImageData(5), null);
  });

  it('should store image data on page success', () => {
    vm.start(provider, GallerySource.EH);
    const imgData = new Uint8Array([0xFF, 0xD8, 0x01, 0x02]);
    provider.simulatePageSuccess(0, imgData);

    assert.deepStrictEqual(vm.getPageImageData(0), imgData);
    assert.strictEqual(vm.getPageInfo(0).state, PageState.READY);
  });

  it('should track cached image count', () => {
    vm.start(provider, GallerySource.EH);
    assert.strictEqual(vm.cachedImageCount, 0);

    provider.simulatePageSuccess(0, new Uint8Array([1]));
    assert.strictEqual(vm.cachedImageCount, 1);

    provider.simulatePageSuccess(1, new Uint8Array([2]));
    assert.strictEqual(vm.cachedImageCount, 2);
  });

  it('should clear image data on stop', () => {
    vm.start(provider, GallerySource.EH);
    provider.simulatePageSuccess(0, new Uint8Array([1]));
    provider.simulatePageSuccess(1, new Uint8Array([2]));
    assert.strictEqual(vm.cachedImageCount, 2);

    vm.stop();
    assert.strictEqual(vm.cachedImageCount, 0);
    assert.strictEqual(vm.getPageImageData(0), null);
  });

  it('should clear image data on restart', () => {
    vm.start(provider, GallerySource.EH);
    provider.simulatePageSuccess(0, new Uint8Array([1]));
    assert.strictEqual(vm.cachedImageCount, 1);

    vm.stop();
    const p2 = new StubProvider(10);
    vm.start(p2, GallerySource.DIR);
    assert.strictEqual(vm.cachedImageCount, 0);
  });

  it('should evict distant pages when cache is full', () => {
    vm.start(provider, GallerySource.EH);

    // Navigate to page 14 first so eviction is based on that position
    vm.goToPage(14);

    // Load 15 pages (exceeds MAX_CACHED_IMAGES = 10)
    for (let i = 0; i < 15; i++) {
      provider.simulatePageSuccess(i, new Uint8Array([i]));
    }

    // Should have at most 10 cached pages
    assert.ok(vm.cachedImageCount <= 10);

    // Pages near 14 should be kept
    assert.ok(vm.getPageImageData(14) !== null);
    assert.ok(vm.getPageImageData(13) !== null);
  });

  it('should handle page failure correctly', () => {
    vm.start(provider, GallerySource.EH);
    provider.simulatePageFailure(3, 'Network error');

    const info = vm.getPageInfo(3);
    assert.strictEqual(info.state, PageState.FAILED);
    assert.strictEqual(info.error, 'Network error');
    assert.strictEqual(vm.getPageImageData(3), null);
  });

  it('should handle page progress correctly', () => {
    vm.start(provider, GallerySource.EH);
    provider.simulatePagePercent(2, 0.5);

    const info = vm.getPageInfo(2);
    assert.strictEqual(info.state, PageState.LOADING);
    assert.strictEqual(info.progress, 0.5);
  });
});

// ---- Preloading ----

describe('GalleryReaderViewModel — preloading', () => {
  let vm: GalleryReaderViewModel;
  let provider: StubProvider;

  beforeEach(() => {
    SettingsService.resetDefaults();
    vm = new GalleryReaderViewModel();
    provider = new StubProvider(20);
  });

  it('should request adjacent pages on start', () => {
    vm.start(provider, GallerySource.EH, 5);

    // Should have requested page 5 (current) + adjacent pages
    const requested = provider.requestedPages;
    assert.ok(requested.includes(5), 'current page should be requested');

    // Should preload ahead
    for (let i = 1; i <= PRELOAD_AHEAD; i++) {
      assert.ok(requested.includes(5 + i), `page ${5 + i} should be preloaded ahead`);
    }
    // Should preload behind
    for (let i = 1; i <= PRELOAD_BEHIND; i++) {
      assert.ok(requested.includes(5 - i), `page ${5 - i} should be preloaded behind`);
    }
  });

  it('should request adjacent pages on goToPage', () => {
    vm.start(provider, GallerySource.EH, 0);
    provider.requestedPages = []; // Reset

    vm.goToPage(10);

    const requested = provider.requestedPages;
    assert.ok(requested.includes(10), 'target page should be requested');
    for (let i = 1; i <= PRELOAD_AHEAD; i++) {
      assert.ok(requested.includes(10 + i), `page ${10 + i} should be preloaded`);
    }
    for (let i = 1; i <= PRELOAD_BEHIND; i++) {
      assert.ok(requested.includes(10 - i), `page ${10 - i} should be preloaded`);
    }
  });

  it('should not preload out-of-bounds pages', () => {
    vm.start(provider, GallerySource.EH, 0);
    provider.requestedPages = [];

    vm.goToPage(0);

    // Should not request negative indices
    const requested = provider.requestedPages;
    for (const idx of requested) {
      assert.ok(idx >= 0, `should not request negative index ${idx}`);
    }
  });

  it('should not preload past the last page', () => {
    vm.start(provider, GallerySource.EH, 0);
    provider.requestedPages = [];

    vm.goToPage(19); // Last page of 20

    const requested = provider.requestedPages;
    for (const idx of requested) {
      assert.ok(idx < 20, `should not request index ${idx} past total pages`);
    }
  });

  it('should not re-request already-loaded pages during preload', () => {
    vm.start(provider, GallerySource.EH, 0);

    // Simulate page 1 already loaded
    provider.simulatePageSuccess(1, new Uint8Array([1]));
    provider.requestedPages = [];

    vm.goToPage(0);

    // Page 1 should NOT be re-requested since it's already READY
    const requestsForPage1 = provider.requestedPages.filter(i => i === 1);
    assert.strictEqual(requestsForPage1.length, 0, 'already-loaded page should not be re-requested');
  });
});

// ---- goToPageByRatio ----

describe('GalleryReaderViewModel — goToPageByRatio', () => {
  let vm: GalleryReaderViewModel;
  let provider: StubProvider;

  beforeEach(() => {
    SettingsService.resetDefaults();
    vm = new GalleryReaderViewModel();
    provider = new StubProvider(20);
  });

  it('should navigate to first page at ratio 0', () => {
    vm.start(provider, GallerySource.EH, 10);
    vm.goToPageByRatio(0);
    assert.strictEqual(vm.currentPage, 0);
  });

  it('should navigate to last page at ratio 1', () => {
    vm.start(provider, GallerySource.EH, 0);
    vm.goToPageByRatio(1);
    assert.strictEqual(vm.currentPage, 19);
  });

  it('should navigate to middle page at ratio 0.5', () => {
    vm.start(provider, GallerySource.EH, 0);
    vm.goToPageByRatio(0.5);
    // 0.5 * 19 = 9.5, rounds to 10
    assert.strictEqual(vm.currentPage, 10);
  });

  it('should be no-op when totalPages <= 1', () => {
    const smallProvider = new StubProvider(1);
    vm.start(smallProvider, GallerySource.EH, 0);
    vm.goToPageByRatio(0.5);
    assert.strictEqual(vm.currentPage, 0);
  });

  it('should clamp ratio to valid range', () => {
    vm.start(provider, GallerySource.EH, 0);
    vm.goToPageByRatio(-0.5);
    assert.strictEqual(vm.currentPage, 0);

    vm.goToPageByRatio(1.5);
    assert.strictEqual(vm.currentPage, 19);
  });
});

// ---- Reading direction from settings ----

describe('GalleryReaderViewModel — reading direction', () => {
  let vm: GalleryReaderViewModel;
  let provider: StubProvider;

  beforeEach(() => {
    SettingsService.resetDefaults();
    vm = new GalleryReaderViewModel();
    provider = new StubProvider(20);
  });

  it('should default to LTR reading mode', () => {
    vm.start(provider, GallerySource.EH);
    assert.strictEqual(vm.readingMode, ReadingMode.LEFT_TO_RIGHT);
  });

  it('should read persisted RTL direction from settings on start', () => {
    SettingsService.setReadingDirection(1);
    vm.start(provider, GallerySource.EH);
    assert.strictEqual(vm.readingMode, ReadingMode.RIGHT_TO_LEFT);
  });

  it('should read persisted vertical direction from settings on start', () => {
    SettingsService.setReadingDirection(2);
    vm.start(provider, GallerySource.EH);
    assert.strictEqual(vm.readingMode, ReadingMode.TOP_TO_BOTTOM);
  });

  it('should persist reading mode change to settings', () => {
    vm.start(provider, GallerySource.EH);
    vm.setReadingMode(ReadingMode.RIGHT_TO_LEFT);
    assert.strictEqual(SettingsService.getReadingDirection(), 1);
    assert.strictEqual(vm.readingMode, ReadingMode.RIGHT_TO_LEFT);
  });

  it('should apply same reading direction for DIR source', () => {
    SettingsService.setReadingDirection(2);
    vm.start(provider, GallerySource.DIR);
    assert.strictEqual(vm.readingMode, ReadingMode.TOP_TO_BOTTOM);
  });

  it('should apply same reading direction for ARCHIVE source', () => {
    SettingsService.setReadingDirection(1);
    vm.start(provider, GallerySource.ARCHIVE);
    assert.strictEqual(vm.readingMode, ReadingMode.RIGHT_TO_LEFT);
  });
});

// ---- Save image ----

describe('GalleryReaderViewModel — save image', () => {
  let vm: GalleryReaderViewModel;
  let provider: StubProvider;

  beforeEach(() => {
    SettingsService.resetDefaults();
    vm = new GalleryReaderViewModel();
    provider = new StubProvider(10);
  });

  it('should return null when provider is not started', () => {
    assert.strictEqual(vm.saveImage(0, '/tmp'), null);
  });

  it('should delegate saveImage to provider', () => {
    vm.start(provider, GallerySource.EH);
    // StubProvider.saveToDir returns null by default
    const result = vm.saveImage(0, '/tmp');
    assert.strictEqual(result, null);
  });

  it('should get image filename from provider', () => {
    vm.start(provider, GallerySource.EH);
    const name = vm.getImageFilename(3);
    assert.strictEqual(name, 'img-3');
  });

  it('should return index as filename when not started', () => {
    const name = vm.getImageFilename(5);
    assert.strictEqual(name, '5');
  });
});

// ---- Settings-based flags ----

describe('GalleryReaderViewModel — settings flags', () => {
  beforeEach(() => {
    SettingsService.resetDefaults();
  });

  it('keepScreenOn should reflect settings', () => {
    const vm = new GalleryReaderViewModel();
    assert.strictEqual(vm.keepScreenOn, false);
    SettingsService.setKeepScreenOn(true);
    assert.strictEqual(vm.keepScreenOn, true);
  });

  it('showProgress should reflect settings', () => {
    const vm = new GalleryReaderViewModel();
    assert.strictEqual(vm.showProgress, true);
    SettingsService.setShowProgress(false);
    assert.strictEqual(vm.showProgress, false);
  });

  it('volumePage should reflect settings', () => {
    const vm = new GalleryReaderViewModel();
    assert.strictEqual(vm.volumePage, false);
    SettingsService.setVolumePage(true);
    assert.strictEqual(vm.volumePage, true);
  });
});
