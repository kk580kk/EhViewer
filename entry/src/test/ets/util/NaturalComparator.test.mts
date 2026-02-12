import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { NaturalComparator } from '../../../main/ets/util/NaturalComparator.ets';

const cmp = new NaturalComparator();

function assertOrder(s1: string | null, s2: string | null): void {
  assert.ok(cmp.compare(s1, s2) < 0, `expected "${s1}" < "${s2}"`);
  assert.ok(cmp.compare(s2, s1) > 0, `expected "${s2}" > "${s1}"`);
}

function assertEqual(s1: string | null, s2: string | null): void {
  assert.strictEqual(cmp.compare(s1, s2), 0, `expected "${s1}" == "${s2}"`);
  assert.strictEqual(cmp.compare(s2, s1), 0, `expected "${s2}" == "${s1}"`);
}

describe('NaturalComparator', () => {
  it('should order numbers naturally', () => {
    assertOrder('1', '2');
    assertOrder('2', '11');
    assertOrder('2', '00011');
  });

  it('should order mixed strings naturally', () => {
    assertOrder('a2', 'a11');
    assertOrder('a2a', 'a11a');
  });

  it('should treat equal strings as equal', () => {
    assertEqual('2', '2');
    assertEqual('11', '11');
    assertEqual('a11', 'a11');
    assertEqual('a2', 'a2');
    assertEqual('a2a', 'a2a');
  });

  it('should handle empty strings', () => {
    assertOrder('', '1');
    assertEqual('', '');
  });

  it('should handle nulls', () => {
    assertEqual(null, null);
    assertOrder(null, '1');
  });

  it('should handle big numbers', () => {
    assertOrder('1', '22222222222222222222222222222222222222222222222222222222222222222222222');
  });

  it('should order leading zeros correctly', () => {
    assertOrder('000000000000000001', '1');
    assertOrder('000000000000000001', '0001');
    assertOrder('00000000000000000', '0');
    assertOrder('00000000000000000', '000');
  });
});
