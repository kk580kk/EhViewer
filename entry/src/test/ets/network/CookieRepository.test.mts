import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { CookieRepository, MemoryCookiePersistence } from '../../../main/ets/network/CookieRepository.ets';
import { CookieBuilder } from '../../../main/ets/network/Cookie.ets';

describe('CookieRepository', () => {
  let persistence: MemoryCookiePersistence;
  let repo: CookieRepository;

  beforeEach(() => {
    persistence = new MemoryCookiePersistence();
    repo = new CookieRepository(persistence);
  });

  describe('addCookie / getCookies', () => {
    it('should store and retrieve a cookie', () => {
      const c = new CookieBuilder().name('sid').value('abc').domain('example.com').build();
      repo.addCookie(c);
      const cookies = repo.getCookies('https://example.com/');
      assert.strictEqual(cookies.length, 1);
      assert.strictEqual(cookies[0].name, 'sid');
      assert.strictEqual(cookies[0].value, 'abc');
    });

    it('should not return cookies for unrelated domain', () => {
      const c = new CookieBuilder().name('sid').value('abc').domain('example.com').build();
      repo.addCookie(c);
      const cookies = repo.getCookies('https://other.com/');
      assert.strictEqual(cookies.length, 0);
    });

    it('should replace cookies with the same key', () => {
      repo.addCookie(new CookieBuilder().name('sid').value('1').domain('example.com').build());
      repo.addCookie(new CookieBuilder().name('sid').value('2').domain('example.com').build());
      const cookies = repo.getCookies('https://example.com/');
      assert.strictEqual(cookies.length, 1);
      assert.strictEqual(cookies[0].value, '2');
    });

    it('should remove expired cookies', () => {
      repo.addCookie(
        new CookieBuilder().name('old').value('x').domain('example.com')
          .expiresAt(Date.now() - 1000).build()
      );
      const cookies = repo.getCookies('https://example.com/');
      assert.strictEqual(cookies.length, 0);
    });
  });

  describe('getCookieHeader', () => {
    it('should return formatted cookie header', () => {
      repo.addCookie(new CookieBuilder().name('a').value('1').domain('example.com').build());
      repo.addCookie(new CookieBuilder().name('b').value('2').domain('example.com').build());
      const header = repo.getCookieHeader('https://example.com/');
      assert.ok(header.includes('a=1'));
      assert.ok(header.includes('b=2'));
    });
  });

  describe('contains', () => {
    it('should return true if cookie exists', () => {
      repo.addCookie(new CookieBuilder().name('sid').value('x').domain('example.com').build());
      assert.strictEqual(repo.contains('https://example.com/', 'sid'), true);
    });

    it('should return false if cookie does not exist', () => {
      assert.strictEqual(repo.contains('https://example.com/', 'nope'), false);
    });
  });

  describe('clear', () => {
    it('should remove all cookies', () => {
      repo.addCookie(new CookieBuilder().name('a').value('1').domain('example.com').build());
      repo.clear();
      assert.strictEqual(repo.getCookies('https://example.com/').length, 0);
    });
  });

  describe('CookieJar interface', () => {
    it('saveFromResponse should store cookies', () => {
      const c1 = new CookieBuilder().name('a').value('1').domain('example.com').build();
      const c2 = new CookieBuilder().name('b').value('2').domain('example.com').build();
      repo.saveFromResponse('https://example.com/', [c1, c2]);
      assert.strictEqual(repo.loadForRequest('https://example.com/').length, 2);
    });

    it('loadForRequest should sort by path length descending', () => {
      repo.addCookie(new CookieBuilder().name('a').value('1').domain('example.com').path('/').build());
      repo.addCookie(new CookieBuilder().name('b').value('2').domain('example.com').path('/foo').build());
      repo.addCookie(new CookieBuilder().name('c').value('3').domain('example.com').path('/foo/bar').build());
      const cookies = repo.loadForRequest('https://example.com/foo/bar');
      assert.strictEqual(cookies[0].name, 'c'); // longest path first
      assert.strictEqual(cookies[1].name, 'b');
      assert.strictEqual(cookies[2].name, 'a');
    });
  });

  describe('persistence', () => {
    it('should persist persistent cookies', () => {
      const c = new CookieBuilder().name('p').value('x').domain('example.com')
        .expiresAt(Date.now() + 3600_000).build();
      repo.addCookie(c);
      // Create a new repo from the same persistence
      const repo2 = new CookieRepository(persistence);
      const cookies = repo2.getCookies('https://example.com/');
      assert.strictEqual(cookies.length, 1);
      assert.strictEqual(cookies[0].name, 'p');
    });

    it('should not persist session cookies across instances', () => {
      const c = new CookieBuilder().name('s').value('x').domain('example.com').build();
      assert.strictEqual(c.persistent, false);
      repo.addCookie(c);
      // Session cookie is available in same repo
      assert.strictEqual(repo.getCookies('https://example.com/').length, 1);
      // But not after re-creating from persistence
      const repo2 = new CookieRepository(persistence);
      assert.strictEqual(repo2.getCookies('https://example.com/').length, 0);
    });
  });
});
