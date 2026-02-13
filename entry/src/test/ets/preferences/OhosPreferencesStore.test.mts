import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { OhosPreferencesStore } from '../../../main/ets/preferences/OhosPreferencesStore.ets';
import type { OhosPreferencesProxy } from '../../../main/ets/preferences/OhosPreferencesStore.ets';

/**
 * In-memory mock of OhosPreferencesProxy for testing OhosPreferencesStore
 * without the real @ohos.data.preferences runtime.
 */
class MockOhosProxy implements OhosPreferencesProxy {
  private data = new Map<string, string | number | boolean>();
  flushCallCount = 0;

  getSync(key: string, defValue: string | number | boolean): string | number | boolean {
    const v = this.data.get(key);
    return v !== undefined ? v : defValue;
  }

  putSync(key: string, value: string | number | boolean): void {
    this.data.set(key, value);
  }

  hasSync(key: string): boolean {
    return this.data.has(key);
  }

  deleteSync(key: string): void {
    this.data.delete(key);
  }

  clearSync(): void {
    this.data.clear();
  }

  flush(): Promise<void> {
    this.flushCallCount++;
    return Promise.resolve();
  }
}

describe('OhosPreferencesStore', () => {
  let proxy: MockOhosProxy;
  let store: OhosPreferencesStore;

  beforeEach(() => {
    proxy = new MockOhosProxy();
    store = new OhosPreferencesStore(proxy);
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

    it('should delete key when putting null', () => {
      store.putString('name', 'Alice');
      store.putString('name', null);
      assert.strictEqual(store.has('name'), false);
      assert.strictEqual(store.getString('name', 'fallback'), 'fallback');
    });

    it('should store empty string', () => {
      store.putString('empty', '');
      assert.strictEqual(store.getString('empty', 'nope'), '');
    });

    it('should return defValue on type mismatch (number stored)', () => {
      proxy.putSync('num_key', 42);
      assert.strictEqual(store.getString('num_key', 'default'), 'default');
    });

    it('should return defValue on type mismatch (boolean stored)', () => {
      proxy.putSync('bool_key', true);
      assert.strictEqual(store.getString('bool_key', 'default'), 'default');
    });
  });

  // ---- getNumber / putNumber ----

  describe('getNumber / putNumber', () => {
    it('should return defValue when key does not exist', () => {
      assert.strictEqual(store.getNumber('missing', -1), -1);
    });

    it('should store and retrieve a number', () => {
      store.putNumber('count', 100);
      assert.strictEqual(store.getNumber('count', 0), 100);
    });

    it('should store and retrieve zero', () => {
      store.putNumber('zero', 0);
      assert.strictEqual(store.getNumber('zero', -1), 0);
    });

    it('should store negative numbers', () => {
      store.putNumber('neg', -42);
      assert.strictEqual(store.getNumber('neg', 0), -42);
    });

    it('should store floating point numbers', () => {
      store.putNumber('ratio', 3.14);
      assert.ok(Math.abs(store.getNumber('ratio', 0) - 3.14) < 1e-9);
    });

    it('should overwrite an existing number', () => {
      store.putNumber('val', 1);
      store.putNumber('val', 2);
      assert.strictEqual(store.getNumber('val', 0), 2);
    });

    it('should return defValue on type mismatch (string stored)', () => {
      proxy.putSync('str_key', 'hello');
      assert.strictEqual(store.getNumber('str_key', 99), 99);
    });

    it('should return defValue on type mismatch (boolean stored)', () => {
      proxy.putSync('bool_key', true);
      assert.strictEqual(store.getNumber('bool_key', 99), 99);
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

    it('should return defValue on type mismatch (string stored)', () => {
      proxy.putSync('str_key', 'true');
      assert.strictEqual(store.getBoolean('str_key', false), false);
    });

    it('should return defValue on type mismatch (number stored)', () => {
      proxy.putSync('num_key', 1);
      assert.strictEqual(store.getBoolean('num_key', false), false);
    });
  });

  // ---- has ----

  describe('has', () => {
    it('should return false for non-existent key', () => {
      assert.strictEqual(store.has('nope'), false);
    });

    it('should return true after putString', () => {
      store.putString('key', 'val');
      assert.strictEqual(store.has('key'), true);
    });

    it('should return true after putNumber', () => {
      store.putNumber('n', 1);
      assert.strictEqual(store.has('n'), true);
    });

    it('should return true after putBoolean', () => {
      store.putBoolean('b', true);
      assert.strictEqual(store.has('b'), true);
    });

    it('should return false after delete', () => {
      store.putString('key', 'val');
      store.delete('key');
      assert.strictEqual(store.has('key'), false);
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
    it('should call proxy.flush on putString', () => {
      const before = proxy.flushCallCount;
      store.putString('key', 'val');
      // flushAsync is fire-and-forget, but it should have been called
      assert.ok(proxy.flushCallCount > before);
    });

    it('should call proxy.flush on putNumber', () => {
      const before = proxy.flushCallCount;
      store.putNumber('key', 1);
      assert.ok(proxy.flushCallCount > before);
    });

    it('should call proxy.flush on putBoolean', () => {
      const before = proxy.flushCallCount;
      store.putBoolean('key', true);
      assert.ok(proxy.flushCallCount > before);
    });

    it('should call proxy.flush on delete', () => {
      store.putString('key', 'val');
      const before = proxy.flushCallCount;
      store.delete('key');
      assert.ok(proxy.flushCallCount > before);
    });

    it('should call proxy.flush on clear', () => {
      const before = proxy.flushCallCount;
      store.clear();
      assert.ok(proxy.flushCallCount > before);
    });

    it('should call proxy.flush on explicit flush()', () => {
      const before = proxy.flushCallCount;
      store.flush();
      assert.ok(proxy.flushCallCount > before);
    });

    it('should not throw when proxy.flush rejects', () => {
      // Override flush to reject
      proxy.flush = () => Promise.reject(new Error('disk full'));
      // Should not throw
      store.putString('key', 'val');
      store.flush();
    });
  });

  // ---- cross-type overwrite ----

  describe('cross-type overwrite', () => {
    it('overwriting string with number makes getString return defValue', () => {
      store.putString('key', 'hello');
      store.putNumber('key', 42);
      assert.strictEqual(store.getString('key', 'nope'), 'nope');
      assert.strictEqual(store.getNumber('key', 0), 42);
    });

    it('overwriting number with boolean makes getNumber return defValue', () => {
      store.putNumber('key', 42);
      store.putBoolean('key', true);
      assert.strictEqual(store.getNumber('key', -1), -1);
      assert.strictEqual(store.getBoolean('key', false), true);
    });
  });
});
