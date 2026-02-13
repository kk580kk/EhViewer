import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

import { LruCache } from '../../../main/ets/util/LruCache.ets';

describe('LruCache', () => {

  // ---- Construction ----

  describe('constructor', () => {
    it('should throw for maxEntries < 1', () => {
      assert.throws(() => new LruCache(0), /maxEntries/);
    });

    it('should throw for maxBytes < 1', () => {
      assert.throws(() => new LruCache(10, 0), /maxBytes/);
    });

    it('should create empty cache', () => {
      const cache = new LruCache<string, string>(5);
      assert.strictEqual(cache.size, 0);
      assert.strictEqual(cache.bytes, 0);
    });
  });

  // ---- Basic put / get ----

  describe('put and get', () => {
    it('should store and retrieve a value', () => {
      const cache = new LruCache<string, number>(5);
      cache.put('a', 42);
      assert.strictEqual(cache.get('a'), 42);
    });

    it('should return undefined for missing key', () => {
      const cache = new LruCache<string, number>(5);
      assert.strictEqual(cache.get('missing'), undefined);
    });

    it('should overwrite existing key', () => {
      const cache = new LruCache<string, number>(5);
      cache.put('a', 1);
      cache.put('a', 2);
      assert.strictEqual(cache.get('a'), 2);
      assert.strictEqual(cache.size, 1);
    });
  });

  // ---- has ----

  describe('has', () => {
    it('should return true for existing key', () => {
      const cache = new LruCache<string, number>(5);
      cache.put('x', 10);
      assert.ok(cache.has('x'));
    });

    it('should return false for missing key', () => {
      const cache = new LruCache<string, number>(5);
      assert.ok(!cache.has('x'));
    });
  });

  // ---- delete ----

  describe('delete', () => {
    it('should remove entry and return true', () => {
      const cache = new LruCache<string, number>(5);
      cache.put('a', 1);
      assert.ok(cache.delete('a'));
      assert.strictEqual(cache.size, 0);
      assert.strictEqual(cache.get('a'), undefined);
    });

    it('should return false for missing key', () => {
      const cache = new LruCache<string, number>(5);
      assert.ok(!cache.delete('nope'));
    });
  });

  // ---- clear ----

  describe('clear', () => {
    it('should remove all entries', () => {
      const cache = new LruCache<string, number>(5);
      cache.put('a', 1);
      cache.put('b', 2);
      cache.clear();
      assert.strictEqual(cache.size, 0);
      assert.strictEqual(cache.bytes, 0);
    });
  });

  // ---- LRU eviction by entry count ----

  describe('eviction by maxEntries', () => {
    it('should evict oldest entry when maxEntries exceeded', () => {
      const cache = new LruCache<string, number>(3);
      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);
      // Cache full: [a, b, c]
      cache.put('d', 4);
      // 'a' should be evicted: [b, c, d]
      assert.strictEqual(cache.size, 3);
      assert.ok(!cache.has('a'));
      assert.ok(cache.has('b'));
      assert.ok(cache.has('d'));
    });

    it('should promote accessed entry so it is not evicted', () => {
      const cache = new LruCache<string, number>(3);
      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);
      // Access 'a' to promote it
      cache.get('a');
      // Now order: [b, c, a]
      cache.put('d', 4);
      // 'b' should be evicted: [c, a, d]
      assert.ok(!cache.has('b'));
      assert.ok(cache.has('a'));
      assert.ok(cache.has('c'));
      assert.ok(cache.has('d'));
    });
  });

  // ---- LRU eviction by byte size ----

  describe('eviction by maxBytes', () => {
    it('should evict entries when maxBytes exceeded', () => {
      const sizeOf = (v: Uint8Array) => v.byteLength;
      const cache = new LruCache<number, Uint8Array>(100, 10, sizeOf);

      cache.put(0, new Uint8Array(4)); // 4 bytes
      cache.put(1, new Uint8Array(4)); // 4 bytes → total 8
      assert.strictEqual(cache.size, 2);
      assert.strictEqual(cache.bytes, 8);

      cache.put(2, new Uint8Array(5)); // +5 → 13 > 10, evict oldest until fits
      // Entry 0 (4 bytes) evicted → 8, still > 10? No, 4+5=9 ≤ 10
      assert.ok(!cache.has(0));
      assert.ok(cache.has(1));
      assert.ok(cache.has(2));
      assert.strictEqual(cache.bytes, 9);
    });

    it('should evict multiple entries if needed', () => {
      const sizeOf = (v: Uint8Array) => v.byteLength;
      const cache = new LruCache<number, Uint8Array>(100, 10, sizeOf);

      cache.put(0, new Uint8Array(3));
      cache.put(1, new Uint8Array(3));
      cache.put(2, new Uint8Array(3)); // total 9
      cache.put(3, new Uint8Array(8)); // +8 = 17 > 10, need to evict
      // Evict 0 (3) → 14, evict 1 (3) → 11, evict 2 (3) → 8 ≤ 10
      assert.ok(!cache.has(0));
      assert.ok(!cache.has(1));
      assert.ok(!cache.has(2));
      assert.ok(cache.has(3));
      assert.strictEqual(cache.bytes, 8);
    });
  });

  // ---- Byte accounting ----

  describe('byte accounting', () => {
    it('should track bytes correctly on put and delete', () => {
      const sizeOf = (v: Uint8Array) => v.byteLength;
      const cache = new LruCache<number, Uint8Array>(10, 1000, sizeOf);

      cache.put(0, new Uint8Array(100));
      assert.strictEqual(cache.bytes, 100);

      cache.put(1, new Uint8Array(200));
      assert.strictEqual(cache.bytes, 300);

      cache.delete(0);
      assert.strictEqual(cache.bytes, 200);

      cache.clear();
      assert.strictEqual(cache.bytes, 0);
    });

    it('should update bytes when overwriting a key', () => {
      const sizeOf = (v: Uint8Array) => v.byteLength;
      const cache = new LruCache<number, Uint8Array>(10, 1000, sizeOf);

      cache.put(0, new Uint8Array(100));
      assert.strictEqual(cache.bytes, 100);

      cache.put(0, new Uint8Array(50));
      assert.strictEqual(cache.bytes, 50);
      assert.strictEqual(cache.size, 1);
    });
  });

  // ---- keys() ----

  describe('keys', () => {
    it('should iterate in LRU order (oldest first)', () => {
      const cache = new LruCache<string, number>(5);
      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);
      cache.get('a'); // promote 'a'
      const keys = [...cache.keys()];
      assert.deepStrictEqual(keys, ['b', 'c', 'a']);
    });
  });
});
