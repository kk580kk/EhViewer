import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { HashCodeUtils } from '../../../main/ets/util/HashCodeUtils.ets';

describe('HashCodeUtils', () => {
  describe('hashCode', () => {
    it('should return 0 for no arguments', () => {
      assert.strictEqual(HashCodeUtils.hashCode(), 0);
    });

    it('should return 0 for null and undefined', () => {
      assert.strictEqual(HashCodeUtils.hashCode(null), 0);
      assert.strictEqual(HashCodeUtils.hashCode(undefined), 0);
      assert.strictEqual(HashCodeUtils.hashCode(null, undefined), 0);
    });

    it('should hash a single string (Java-compatible)', () => {
      // Java: "".hashCode() == 0
      assert.strictEqual(HashCodeUtils.hashCode(''), 0);
      // Java: "a".hashCode() == 97
      assert.strictEqual(HashCodeUtils.hashCode('a'), 97);
      // Java: "ab".hashCode() == 97*31 + 98 == 3105
      assert.strictEqual(HashCodeUtils.hashCode('ab'), 3105);
    });

    it('should hash a single number', () => {
      assert.strictEqual(HashCodeUtils.hashCode(0), 0);
      assert.strictEqual(HashCodeUtils.hashCode(42), 42);
      assert.strictEqual(HashCodeUtils.hashCode(-1), -1);
    });

    it('should hash a single boolean', () => {
      assert.strictEqual(HashCodeUtils.hashCode(true), 1);
      assert.strictEqual(HashCodeUtils.hashCode(false), 0);
    });

    it('should combine multiple values using 31-multiplier formula', () => {
      // hash('a', 'b') = 31 * hash('a') + hash('b') = 31 * 97 + 98 = 3105
      assert.strictEqual(HashCodeUtils.hashCode('a', 'b'), 3105);

      // hash('hello', 42) = 31 * hash('hello') + 42
      const helloHash = HashCodeUtils.stringHashCode('hello');
      const expected = (Math.imul(31, helloHash) + 42) | 0;
      assert.strictEqual(HashCodeUtils.hashCode('hello', 42), expected);
    });

    it('should handle nulls in a multi-arg list', () => {
      // hash(null, 'a') = 31 * 0 + 97 = 97
      assert.strictEqual(HashCodeUtils.hashCode(null, 'a'), 97);
      // hash('a', null) = 31 * 97 + 0 = 3007
      assert.strictEqual(HashCodeUtils.hashCode('a', null), 3007);
    });

    it('should produce deterministic results', () => {
      const a = HashCodeUtils.hashCode('name', 'domain', '/path');
      const b = HashCodeUtils.hashCode('name', 'domain', '/path');
      assert.strictEqual(a, b);
    });

    it('should produce different results for different inputs', () => {
      const a = HashCodeUtils.hashCode('foo', 'bar');
      const b = HashCodeUtils.hashCode('bar', 'foo');
      assert.notStrictEqual(a, b);
    });

    it('should handle three string args like CookieSet.Key', () => {
      // Simulates HashCodeUtils.hashCode(name, domain, path)
      const h = HashCodeUtils.hashCode('session_id', 'example.com', '/');
      assert.strictEqual(typeof h, 'number');
      assert.ok(Number.isInteger(h));
    });
  });

  describe('stringHashCode', () => {
    it('should return 0 for empty string', () => {
      assert.strictEqual(HashCodeUtils.stringHashCode(''), 0);
    });

    it('should match Java String.hashCode() for known values', () => {
      // Java: "hello".hashCode() == 99162322
      assert.strictEqual(HashCodeUtils.stringHashCode('hello'), 99162322);
      // Java: "Hello".hashCode() == 69609650
      assert.strictEqual(HashCodeUtils.stringHashCode('Hello'), 69609650);
      // Java: "test".hashCode() == 3556498
      assert.strictEqual(HashCodeUtils.stringHashCode('test'), 3556498);
    });

    it('should use 32-bit integer arithmetic', () => {
      // A long string should still produce a 32-bit int
      const h = HashCodeUtils.stringHashCode('a'.repeat(10000));
      assert.ok(h >= -2147483648 && h <= 2147483647);
      assert.ok(Number.isInteger(h));
    });
  });

  describe('hashCode with numbers', () => {
    it('should hash MAX_SAFE_INTEGER within 32-bit range', () => {
      const h = HashCodeUtils.hashCode(Number.MAX_SAFE_INTEGER);
      assert.ok(Number.isInteger(h));
      assert.ok(h >= -2147483648 && h <= 2147483647);
    });

    it('should hash floats', () => {
      const h = HashCodeUtils.hashCode(3.14);
      assert.ok(Number.isInteger(h));
      // Different floats should produce different hashes
      assert.notStrictEqual(HashCodeUtils.hashCode(3.14), HashCodeUtils.hashCode(2.71));
    });
  });
});
