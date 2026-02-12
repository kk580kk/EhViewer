import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { CookieDatabase } from '../../../main/ets/network/CookieDatabase.ets';
import { CookieRepository } from '../../../main/ets/network/CookieRepository.ets';
import { CookieBuilder } from '../../../main/ets/network/Cookie.ets';
import { MemoryDatabaseStore } from '../../../main/ets/database/MemoryDatabaseStore.ets';

describe('CookieDatabase', () => {
  let store: MemoryDatabaseStore;
  let cookieDb: CookieDatabase;

  beforeEach(() => {
    store = new MemoryDatabaseStore();
    cookieDb = new CookieDatabase(store);
  });

  describe('add / loadAll', () => {
    it('should persist a cookie and load it back', () => {
      const c = new CookieBuilder()
        .name('sid').value('abc').domain('example.com').path('/')
        .expiresAt(Date.now() + 3600_000).build();

      cookieDb.add(c);
      const loaded = cookieDb.loadAll();
      assert.strictEqual(loaded.length, 1);
      assert.strictEqual(loaded[0].name, 'sid');
      assert.strictEqual(loaded[0].value, 'abc');
      assert.strictEqual(loaded[0].domain, 'example.com');
    });

    it('should persist multiple cookies', () => {
      cookieDb.add(
        new CookieBuilder().name('a').value('1').domain('d.com')
          .expiresAt(Date.now() + 3600_000).build()
      );
      cookieDb.add(
        new CookieBuilder().name('b').value('2').domain('d.com')
          .expiresAt(Date.now() + 3600_000).build()
      );
      assert.strictEqual(cookieDb.loadAll().length, 2);
    });

    it('should not load expired cookies', () => {
      cookieDb.add(
        new CookieBuilder().name('old').value('x').domain('d.com')
          .expiresAt(Date.now() - 1000).build()
      );
      assert.strictEqual(cookieDb.loadAll().length, 0);
    });

    it('should not load non-persistent cookies', () => {
      // A cookie without expiresAt set has persistent=false
      const c = new CookieBuilder().name('s').value('x').domain('d.com').build();
      assert.strictEqual(c.persistent, false);
      cookieDb.add(c);
      // It's in the DB row but loadAll filters it out
      assert.strictEqual(cookieDb.loadAll().length, 0);
    });

    it('should preserve secure and httpOnly flags', () => {
      cookieDb.add(
        new CookieBuilder().name('s').value('v').domain('d.com')
          .expiresAt(Date.now() + 3600_000).secure().httpOnly().build()
      );
      const loaded = cookieDb.loadAll();
      assert.strictEqual(loaded[0].secure, true);
      assert.strictEqual(loaded[0].httpOnly, true);
    });

    it('should preserve hostOnly flag', () => {
      cookieDb.add(
        new CookieBuilder().name('h').value('v').hostOnlyDomain('exact.com')
          .expiresAt(Date.now() + 3600_000).build()
      );
      const loaded = cookieDb.loadAll();
      assert.strictEqual(loaded[0].hostOnly, true);
      assert.strictEqual(loaded[0].domain, 'exact.com');
    });
  });

  describe('update', () => {
    it('should update an existing cookie value', () => {
      const c1 = new CookieBuilder().name('sid').value('old').domain('d.com')
        .expiresAt(Date.now() + 3600_000).build();
      const c2 = new CookieBuilder().name('sid').value('new').domain('d.com')
        .expiresAt(Date.now() + 3600_000).build();

      cookieDb.add(c1);
      cookieDb.update(c1, c2);

      const loaded = cookieDb.loadAll();
      assert.strictEqual(loaded.length, 1);
      assert.strictEqual(loaded[0].value, 'new');
    });

    it('should be a no-op if the from cookie is not tracked', () => {
      const c1 = new CookieBuilder().name('x').value('1').domain('d.com')
        .expiresAt(Date.now() + 3600_000).build();
      const c2 = new CookieBuilder().name('x').value('2').domain('d.com')
        .expiresAt(Date.now() + 3600_000).build();

      // Never added c1, so update should be no-op
      cookieDb.update(c1, c2);
      assert.strictEqual(cookieDb.loadAll().length, 0);
    });
  });

  describe('remove', () => {
    it('should remove a cookie', () => {
      const c = new CookieBuilder().name('sid').value('abc').domain('d.com')
        .expiresAt(Date.now() + 3600_000).build();

      cookieDb.add(c);
      assert.strictEqual(cookieDb.loadAll().length, 1);

      cookieDb.remove(c);
      assert.strictEqual(cookieDb.loadAll().length, 0);
    });

    it('should be a no-op if the cookie is not tracked', () => {
      const c = new CookieBuilder().name('x').value('1').domain('d.com')
        .expiresAt(Date.now() + 3600_000).build();
      cookieDb.remove(c); // should not throw
    });
  });

  describe('clear', () => {
    it('should remove all cookies', () => {
      cookieDb.add(
        new CookieBuilder().name('a').value('1').domain('d.com')
          .expiresAt(Date.now() + 3600_000).build()
      );
      cookieDb.add(
        new CookieBuilder().name('b').value('2').domain('d.com')
          .expiresAt(Date.now() + 3600_000).build()
      );
      cookieDb.clear();
      assert.strictEqual(cookieDb.loadAll().length, 0);
    });
  });

  describe('integration with CookieRepository', () => {
    it('should persist cookies across CookieRepository instances', () => {
      const repo1 = new CookieRepository(cookieDb);
      repo1.addCookie(
        new CookieBuilder().name('token').value('abc123').domain('example.com')
          .expiresAt(Date.now() + 3600_000).build()
      );

      // Create a new CookieDatabase from the same store to simulate restart
      const cookieDb2 = new CookieDatabase(store);
      const repo2 = new CookieRepository(cookieDb2);
      const cookies = repo2.getCookies('https://example.com/');
      assert.strictEqual(cookies.length, 1);
      assert.strictEqual(cookies[0].name, 'token');
      assert.strictEqual(cookies[0].value, 'abc123');
    });

    it('should not persist session cookies across instances', () => {
      const repo1 = new CookieRepository(cookieDb);
      repo1.addCookie(
        new CookieBuilder().name('sess').value('tmp').domain('example.com').build()
      );
      // Session cookie in current repo
      assert.strictEqual(repo1.getCookies('https://example.com/').length, 1);

      // Recreate — session cookie should be gone
      const cookieDb2 = new CookieDatabase(store);
      const repo2 = new CookieRepository(cookieDb2);
      assert.strictEqual(repo2.getCookies('https://example.com/').length, 0);
    });

    it('should handle cookie update via CookieRepository', () => {
      const repo = new CookieRepository(cookieDb);
      repo.addCookie(
        new CookieBuilder().name('sid').value('v1').domain('example.com')
          .expiresAt(Date.now() + 3600_000).build()
      );
      repo.addCookie(
        new CookieBuilder().name('sid').value('v2').domain('example.com')
          .expiresAt(Date.now() + 3600_000).build()
      );

      // Recreate to verify persistence
      const cookieDb2 = new CookieDatabase(store);
      const repo2 = new CookieRepository(cookieDb2);
      const cookies = repo2.getCookies('https://example.com/');
      assert.strictEqual(cookies.length, 1);
      assert.strictEqual(cookies[0].value, 'v2');
    });

    it('should handle cookie removal via CookieRepository', () => {
      const repo = new CookieRepository(cookieDb);
      repo.addCookie(
        new CookieBuilder().name('a').value('1').domain('example.com')
          .expiresAt(Date.now() + 3600_000).build()
      );
      repo.clear();

      // Recreate to verify persistence
      const cookieDb2 = new CookieDatabase(store);
      const repo2 = new CookieRepository(cookieDb2);
      assert.strictEqual(repo2.getCookies('https://example.com/').length, 0);
    });
  });
});
