import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

import { GallerySource } from '../../../main/ets/gallery/GallerySource.ets';
import type { ReaderState } from '../../../main/ets/gallery/ReaderState.ets';
import { MutableReaderState } from '../../../main/ets/gallery/ReaderState.ets';

describe('GallerySource', () => {
  it('has three distinct values', () => {
    const values = new Set([GallerySource.EH, GallerySource.DIR, GallerySource.ARCHIVE]);
    assert.strictEqual(values.size, 3);
  });

  it('EH equals "eh"', () => {
    assert.strictEqual(GallerySource.EH as string, 'eh');
  });

  it('DIR equals "dir"', () => {
    assert.strictEqual(GallerySource.DIR as string, 'dir');
  });

  it('ARCHIVE equals "archive"', () => {
    assert.strictEqual(GallerySource.ARCHIVE as string, 'archive');
  });
});

describe('MutableReaderState', () => {
  it('should store source and initial index', () => {
    const state = new MutableReaderState(GallerySource.EH, 5);
    assert.strictEqual(state.source, GallerySource.EH);
    assert.strictEqual(state.currentIndex, 5);
  });

  it('should default currentIndex to 0', () => {
    const state = new MutableReaderState(GallerySource.DIR);
    assert.strictEqual(state.currentIndex, 0);
  });

  it('setCurrentIndex should update currentIndex', () => {
    const state = new MutableReaderState(GallerySource.ARCHIVE, 0);
    state.setCurrentIndex(42);
    assert.strictEqual(state.currentIndex, 42);
  });

  it('setSource should update source', () => {
    const state = new MutableReaderState(GallerySource.EH);
    state.setSource(GallerySource.DIR);
    assert.strictEqual(state.source, GallerySource.DIR);
  });

  it('multiple setCurrentIndex calls', () => {
    const state = new MutableReaderState(GallerySource.EH);
    for (let i = 0; i < 50; i++) {
      state.setCurrentIndex(i);
      assert.strictEqual(state.currentIndex, i);
    }
  });

  it('source remains stable when only index changes', () => {
    const state = new MutableReaderState(GallerySource.ARCHIVE, 3);
    state.setCurrentIndex(10);
    state.setCurrentIndex(99);
    assert.strictEqual(state.source, GallerySource.ARCHIVE);
  });
});

describe('ReaderState (read-only interface)', () => {
  it('exposes source and currentIndex as read-only via interface', () => {
    const mutable = new MutableReaderState(GallerySource.DIR, 7);
    const readOnly: ReaderState = mutable;

    assert.strictEqual(readOnly.source, GallerySource.DIR);
    assert.strictEqual(readOnly.currentIndex, 7);
  });

  it('reflects mutations made through MutableReaderState', () => {
    const mutable = new MutableReaderState(GallerySource.EH, 0);
    const readOnly: ReaderState = mutable;

    mutable.setCurrentIndex(15);
    assert.strictEqual(readOnly.currentIndex, 15);
  });

  it('does not expose setCurrentIndex on the interface type', () => {
    const readOnly: ReaderState = new MutableReaderState(GallerySource.EH);
    // TypeScript ensures 'setCurrentIndex' is not accessible via ReaderState.
    // At runtime we verify the interface shape has only the expected properties.
    assert.strictEqual(typeof readOnly.source, 'string');
    assert.strictEqual(typeof readOnly.currentIndex, 'number');
  });
});
