import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  ImageLoadState,
  resolveImageState,
} from '../../../main/ets/ui/common/ImageLoadState.ets';

describe('ImageLoadState constants', () => {
  it('should have distinct values', () => {
    const values = new Set([
      ImageLoadState.IDLE,
      ImageLoadState.LOADING,
      ImageLoadState.SUCCESS,
      ImageLoadState.ERROR,
    ]);
    assert.strictEqual(values.size, 4);
  });
});

describe('resolveImageState', () => {
  it('should return IDLE for empty URL', () => {
    assert.strictEqual(resolveImageState('', false, false), ImageLoadState.IDLE);
  });

  it('should return IDLE for empty URL even if loaded/failed', () => {
    assert.strictEqual(resolveImageState('', true, false), ImageLoadState.IDLE);
    assert.strictEqual(resolveImageState('', false, true), ImageLoadState.IDLE);
  });

  it('should return LOADING for non-empty URL, not loaded, not failed', () => {
    assert.strictEqual(
      resolveImageState('http://img.com/pic.jpg', false, false),
      ImageLoadState.LOADING,
    );
  });

  it('should return SUCCESS when loaded', () => {
    assert.strictEqual(
      resolveImageState('http://img.com/pic.jpg', true, false),
      ImageLoadState.SUCCESS,
    );
  });

  it('should return ERROR when failed', () => {
    assert.strictEqual(
      resolveImageState('http://img.com/pic.jpg', false, true),
      ImageLoadState.ERROR,
    );
  });

  it('should return ERROR when both failed and loaded (error takes priority)', () => {
    assert.strictEqual(
      resolveImageState('http://img.com/pic.jpg', true, true),
      ImageLoadState.ERROR,
    );
  });
});
