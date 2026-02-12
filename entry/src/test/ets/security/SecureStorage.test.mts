import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { MemorySecureStorage } from '../../../main/ets/security/SecureStorage.ets';
import type { SecureStorage } from '../../../main/ets/security/SecureStorage.ets';

describe('SecureStorage (MemorySecureStorage)', () => {
  let store: SecureStorage;

  beforeEach(() => {
    store = new MemorySecureStorage();
  });

  describe('get / put', () => {
    it('should return null for missing key', () => {
      assert.strictEqual(store.get('missing'), null);
    });

    it('should store and retrieve a value', () => {
      store.put('token', 'abc123');
      assert.strictEqual(store.get('token'), 'abc123');
    });

    it('should overwrite an existing value', () => {
      store.put('token', 'old');
      store.put('token', 'new');
      assert.strictEqual(store.get('token'), 'new');
    });

    it('should remove key when putting null', () => {
      store.put('token', 'abc');
      store.put('token', null);
      assert.strictEqual(store.get('token'), null);
      assert.strictEqual(store.has('token'), false);
    });

    it('should store empty string', () => {
      store.put('empty', '');
      assert.strictEqual(store.get('empty'), '');
      assert.strictEqual(store.has('empty'), true);
    });
  });

  describe('has', () => {
    it('should return false for non-existent key', () => {
      assert.strictEqual(store.has('nope'), false);
    });

    it('should return true after put', () => {
      store.put('key', 'val');
      assert.strictEqual(store.has('key'), true);
    });

    it('should return false after delete', () => {
      store.put('key', 'val');
      store.delete('key');
      assert.strictEqual(store.has('key'), false);
    });
  });

  describe('delete', () => {
    it('should do nothing for non-existent key', () => {
      store.delete('nope'); // should not throw
    });

    it('should remove an existing key', () => {
      store.put('key', 'val');
      store.delete('key');
      assert.strictEqual(store.get('key'), null);
    });
  });

  describe('clear', () => {
    it('should remove all keys', () => {
      store.put('a', '1');
      store.put('b', '2');
      store.put('c', '3');
      store.clear();
      assert.strictEqual(store.has('a'), false);
      assert.strictEqual(store.has('b'), false);
      assert.strictEqual(store.has('c'), false);
    });

    it('should be safe on empty store', () => {
      store.clear(); // should not throw
    });
  });
});
