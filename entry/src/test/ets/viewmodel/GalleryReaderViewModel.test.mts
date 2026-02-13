import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

import {
  GalleryReaderViewModel,
} from '../../../main/ets/viewmodel/GalleryReaderViewModel.ets';
import { GallerySource } from '../../../main/ets/gallery/GallerySource.ets';
import type { ReaderState } from '../../../main/ets/gallery/ReaderState.ets';
import type { GalleryProvider2 } from '../../../main/ets/gallery/GalleryProvider2.ets';
import type { GalleryProviderListener } from '../../../main/ets/gallery/GalleryProvider.ets';

// ---- Stub provider ----

class StubProvider implements GalleryProvider2 {
  private listeners: GalleryProviderListener[] = [];
  private _size: number;
  private _started = false;
  startPageWritten: number | null = null;
  requestedPages: number[] = [];

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
  request(index: number): void { this.requestedPages.push(index); }
  forceRequest(index: number): void { this.requestedPages.push(index); }
  cancelRequest(_index: number): void {}
  addListener(l: GalleryProviderListener): void { this.listeners.push(l); }
  removeListener(l: GalleryProviderListener): void {
    const idx = this.listeners.indexOf(l);
    if (idx >= 0) this.listeners.splice(idx, 1);
  }
}

// ---- Tests ----

describe('GalleryReaderViewModel — readerState', () => {
  let vm: GalleryReaderViewModel;
  let provider: StubProvider;

  beforeEach(() => {
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
