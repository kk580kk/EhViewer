import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  ContentState,
  resolveContentState,
} from '../../../main/ets/ui/common/ContentState.ets';

describe('ContentState constants', () => {
  it('should have distinct values', () => {
    const values = new Set([
      ContentState.LOADING,
      ContentState.CONTENT,
      ContentState.ERROR,
      ContentState.EMPTY,
    ]);
    assert.strictEqual(values.size, 4);
  });
});

describe('resolveContentState', () => {
  it('should return LOADING when isLoading=true', () => {
    assert.strictEqual(resolveContentState(true, false, false), ContentState.LOADING);
  });

  it('should return LOADING even if hasError and isEmpty', () => {
    assert.strictEqual(resolveContentState(true, true, true), ContentState.LOADING);
  });

  it('should return ERROR when hasError=true and not loading', () => {
    assert.strictEqual(resolveContentState(false, true, false), ContentState.ERROR);
  });

  it('should return ERROR over EMPTY when both true', () => {
    assert.strictEqual(resolveContentState(false, true, true), ContentState.ERROR);
  });

  it('should return EMPTY when isEmpty=true', () => {
    assert.strictEqual(resolveContentState(false, false, true), ContentState.EMPTY);
  });

  it('should return CONTENT when all flags false', () => {
    assert.strictEqual(resolveContentState(false, false, false), ContentState.CONTENT);
  });
});
