import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { MemoryPreferencesStore } from '../../../main/ets/preferences/MemoryPreferencesStore.ets';
import type { PreferencesStore } from '../../../main/ets/preferences/PreferencesStore.ets';

describe('PreferencesStore (MemoryPreferencesStore)', () => {
  let store: PreferencesStore;

  beforeEach(() => {
    store = new MemoryPreferencesStore();
  });

  // ---- getString / putString ----

  describe('getString / putString', () => {
    it('should return defValue when key does not exist', () => {
      assert.strictEqual(store.getString('missing', 'default'), 'default');
    });

    it('should return null defValue when key does not exist', () => {
      assert.strictEqual(store.getString('missing', null), null);
    });

    it('should store and retrieve a string', () => {
      store.putString('name', 'Alice');
      assert.strictEqual(store.getString('name', null), 'Alice');
    });

    it('should overwrite an existing string', () => {
      store.putString('name', 'Alice');
      store.putString('name', 'Bob');
      assert.strictEqual(store.getString('name', null), 'Bob');
    });

    it('should remove key when putting null', () => {
      store.putString('name', 'Alice');
      store.putString('name', null);
      assert.strictEqual(store.has('name'), false);
      assert.strictEqual(store.getString('name', 'fallback'), 'fallback');
    });

    it('should store empty string', () => {
      store.putString('empty', '');
      assert.strictEqual(store.getString('empty', 'nope'), '');
    });

    it('should return defValue on type mismatch', () => {
      store.putNumber('num_key', 42);
      assert.strictEqual(store.getString('num_key', 'default'), 'default');
    });
  });

  // ---- getNumber / putNumber ----

  describe('getNumber / putNumber', () => {
    it('should return defValue when key does not exist', () => {
      assert.strictEqual(store.getNumber('missing', -1), -1);
    });

    it('should store and retrieve an integer', () => {
      store.putNumber('count', 100);
      assert.strictEqual(store.getNumber('count', 0), 100);
    });

    it('should store and retrieve a float', () => {
      store.putNumber('ratio', 3.14);
      assert.ok(Math.abs(store.getNumber('ratio', 0) - 3.14) < 1e-9);
    });

    it('should store and retrieve zero', () => {
      store.putNumber('zero', 0);
      assert.strictEqual(store.getNumber('zero', -1), 0);
    });

    it('should store negative numbers', () => {
      store.putNumber('neg', -42);
      assert.strictEqual(store.getNumber('neg', 0), -42);
    });

    it('should overwrite an existing number', () => {
      store.putNumber('val', 1);
      store.putNumber('val', 2);
      assert.strictEqual(store.getNumber('val', 0), 2);
    });

    it('should return defValue on type mismatch', () => {
      store.putString('str_key', 'hello');
      assert.strictEqual(store.getNumber('str_key', 99), 99);
    });
  });

  // ---- getBoolean / putBoolean ----

  describe('getBoolean / putBoolean', () => {
    it('should return defValue when key does not exist', () => {
      assert.strictEqual(store.getBoolean('missing', true), true);
      assert.strictEqual(store.getBoolean('missing', false), false);
    });

    it('should store and retrieve true', () => {
      store.putBoolean('flag', true);
      assert.strictEqual(store.getBoolean('flag', false), true);
    });

    it('should store and retrieve false', () => {
      store.putBoolean('flag', false);
      assert.strictEqual(store.getBoolean('flag', true), false);
    });

    it('should overwrite an existing boolean', () => {
      store.putBoolean('flag', true);
      store.putBoolean('flag', false);
      assert.strictEqual(store.getBoolean('flag', true), false);
    });

    it('should return defValue on type mismatch', () => {
      store.putString('str_key', 'true');
      assert.strictEqual(store.getBoolean('str_key', false), false);
    });
  });

  // ---- has ----

  describe('has', () => {
    it('should return false for non-existent key', () => {
      assert.strictEqual(store.has('nope'), false);
    });

    it('should return true after put', () => {
      store.putString('key', 'val');
      assert.strictEqual(store.has('key'), true);
    });

    it('should return false after delete', () => {
      store.putString('key', 'val');
      store.delete('key');
      assert.strictEqual(store.has('key'), false);
    });

    it('should work with all types', () => {
      store.putNumber('n', 1);
      store.putBoolean('b', true);
      assert.strictEqual(store.has('n'), true);
      assert.strictEqual(store.has('b'), true);
    });
  });

  // ---- delete ----

  describe('delete', () => {
    it('should do nothing for non-existent key', () => {
      store.delete('nope'); // should not throw
      assert.strictEqual(store.has('nope'), false);
    });

    it('should remove an existing key', () => {
      store.putNumber('count', 5);
      store.delete('count');
      assert.strictEqual(store.getNumber('count', -1), -1);
    });
  });

  // ---- clear ----

  describe('clear', () => {
    it('should remove all keys', () => {
      store.putString('a', '1');
      store.putNumber('b', 2);
      store.putBoolean('c', true);
      store.clear();
      assert.strictEqual(store.has('a'), false);
      assert.strictEqual(store.has('b'), false);
      assert.strictEqual(store.has('c'), false);
    });

    it('should be safe to call on empty store', () => {
      store.clear(); // should not throw
      assert.strictEqual(store.has('anything'), false);
    });
  });

  // ---- flush ----

  describe('flush', () => {
    it('should not throw (no-op for memory store)', () => {
      store.putString('key', 'val');
      store.flush(); // should not throw
      assert.strictEqual(store.getString('key', null), 'val');
    });
  });

  // ---- cross-type isolation ----

  describe('cross-type isolation', () => {
    it('should isolate keys across different types when overwritten', () => {
      store.putString('key', 'hello');
      assert.strictEqual(store.getNumber('key', -1), -1);
      assert.strictEqual(store.getBoolean('key', false), false);

      store.putNumber('key', 42);
      assert.strictEqual(store.getString('key', 'nope'), 'nope');
      assert.strictEqual(store.getNumber('key', 0), 42);

      store.putBoolean('key', true);
      assert.strictEqual(store.getString('key', 'nope'), 'nope');
      assert.strictEqual(store.getNumber('key', -1), -1);
      assert.strictEqual(store.getBoolean('key', false), true);
    });
  });
});
