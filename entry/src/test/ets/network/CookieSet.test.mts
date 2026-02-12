import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { CookieSet } from '../../../main/ets/network/CookieSet.ets';
import { CookieBuilder } from '../../../main/ets/network/Cookie.ets';

describe('CookieSet', () => {
  describe('add', () => {
    it('should add a cookie and return null when no previous exists', () => {
      const set = new CookieSet();
      const c = new CookieBuilder().name('sid').value('abc').domain('example.com').build();
      const old = set.add(c);
      assert.strictEqual(old, null);
      assert.strictEqual(set.size(), 1);
    });

    it('should replace a cookie with same key and return the old one', () => {
      const set = new CookieSet();
      const c1 = new CookieBuilder().name('sid').value('v1').domain('example.com').build();
      const c2 = new CookieBuilder().name('sid').value('v2').domain('example.com').build();
      set.add(c1);
      const old = set.add(c2);
      assert.strictEqual(old!.value, 'v1');
      assert.strictEqual(set.size(), 1);
      assert.strictEqual(set.getAll()[0].value, 'v2');
    });

    it('should store multiple cookies with different keys', () => {
      const set = new CookieSet();
      set.add(new CookieBuilder().name('a').value('1').domain('d.com').build());
      set.add(new CookieBuilder().name('b').value('2').domain('d.com').build());
      assert.strictEqual(set.size(), 2);
    });

    it('should treat same name but different path as different keys', () => {
      const set = new CookieSet();
      set.add(new CookieBuilder().name('sid').value('1').domain('d.com').path('/').build());
      set.add(new CookieBuilder().name('sid').value('2').domain('d.com').path('/api').build());
      assert.strictEqual(set.size(), 2);
    });
  });

  describe('remove', () => {
    it('should remove an existing cookie and return it', () => {
      const set = new CookieSet();
      const c = new CookieBuilder().name('sid').value('abc').domain('d.com').build();
      set.add(c);
      const removed = set.remove(c);
      assert.strictEqual(removed!.value, 'abc');
      assert.strictEqual(set.size(), 0);
    });

    it('should return null when removing a non-existent cookie', () => {
      const set = new CookieSet();
      const c = new CookieBuilder().name('sid').value('abc').domain('d.com').build();
      const removed = set.remove(c);
      assert.strictEqual(removed, null);
    });
  });

  describe('get', () => {
    it('should collect matching cookies into accepted', () => {
      const set = new CookieSet();
      set.add(new CookieBuilder().name('sid').value('abc').domain('example.com').path('/').build());
      const accepted: import('../../../main/ets/network/Cookie.ets').Cookie[] = [];
      const expired: import('../../../main/ets/network/Cookie.ets').Cookie[] = [];
      set.get(new URL('https://example.com/page'), accepted, expired);
      assert.strictEqual(accepted.length, 1);
      assert.strictEqual(expired.length, 0);
    });

    it('should move expired cookies to expired list and remove them', () => {
      const set = new CookieSet();
      set.add(
        new CookieBuilder().name('old').value('x').domain('example.com').path('/')
          .expiresAt(Date.now() - 1000).build()
      );
      const accepted: import('../../../main/ets/network/Cookie.ets').Cookie[] = [];
      const expired: import('../../../main/ets/network/Cookie.ets').Cookie[] = [];
      set.get(new URL('https://example.com/'), accepted, expired);
      assert.strictEqual(accepted.length, 0);
      assert.strictEqual(expired.length, 1);
      assert.strictEqual(set.size(), 0);
    });

    it('should not match cookies for a different path', () => {
      const set = new CookieSet();
      set.add(new CookieBuilder().name('x').value('1').domain('example.com').path('/api').build());
      const accepted: import('../../../main/ets/network/Cookie.ets').Cookie[] = [];
      const expired: import('../../../main/ets/network/Cookie.ets').Cookie[] = [];
      set.get(new URL('https://example.com/other'), accepted, expired);
      assert.strictEqual(accepted.length, 0);
    });

    it('should not match secure cookies on http', () => {
      const set = new CookieSet();
      set.add(
        new CookieBuilder().name('s').value('1').domain('example.com').path('/')
          .secure().build()
      );
      const accepted: import('../../../main/ets/network/Cookie.ets').Cookie[] = [];
      const expired: import('../../../main/ets/network/Cookie.ets').Cookie[] = [];
      set.get(new URL('http://example.com/'), accepted, expired);
      assert.strictEqual(accepted.length, 0);
    });
  });

  describe('getAll', () => {
    it('should return all cookies', () => {
      const set = new CookieSet();
      set.add(new CookieBuilder().name('a').value('1').domain('d.com').build());
      set.add(new CookieBuilder().name('b').value('2').domain('d.com').build());
      const all = set.getAll();
      assert.strictEqual(all.length, 2);
    });

    it('should return empty array for empty set', () => {
      const set = new CookieSet();
      assert.strictEqual(set.getAll().length, 0);
    });
  });
});
