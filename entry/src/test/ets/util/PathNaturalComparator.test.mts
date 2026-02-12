import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { PathNaturalComparator } from '../../../main/ets/util/PathNaturalComparator.ets';

const cmp = new PathNaturalComparator();

function assertOrder(s1: string | null, s2: string | null): void {
  assert.ok(cmp.compare(s1, s2) < 0, `expected "${s1}" < "${s2}"`);
  assert.ok(cmp.compare(s2, s1) > 0, `expected "${s2}" > "${s1}"`);
}

function assertEqual(s1: string | null, s2: string | null): void {
  assert.strictEqual(cmp.compare(s1, s2), 0, `expected "${s1}" == "${s2}"`);
  assert.strictEqual(cmp.compare(s2, s1), 0, `expected "${s2}" == "${s1}"`);
}

describe('PathNaturalComparator', () => {
  it('should treat path separators as segment boundaries', () => {
    assertOrder('ab/d', 'abcd');
    assertOrder('ab\\d', 'abcd');
  });

  it('should order segments numerically', () => {
    assertOrder('ab/d2', 'ab/d11');
  });

  it('should ignore leading and trailing separators', () => {
    assertEqual('/abc', 'abc');
    assertEqual('/abc', '\\abc');
    assertEqual('abc', '\\abc');
    assertEqual('abc///', 'abc');
  });

  it('should handle empty strings', () => {
    assertOrder('', '1');
    assertEqual('', '');
  });

  it('should handle nulls', () => {
    assertEqual(null, null);
    assertOrder(null, '1');
  });
});
