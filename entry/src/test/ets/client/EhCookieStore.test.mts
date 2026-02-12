import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { EhCookieStore } from '../../../main/ets/client/EhCookieStore.ets';
import { CookieBuilder, MAX_EXPIRES } from '../../../main/ets/network/Cookie.ets';
import { MemoryCookiePersistence } from '../../../main/ets/network/CookieRepository.ets';
import { EhUrl } from '../../../main/ets/client/EhUrl.ets';
import { EhConfig } from '../../../main/ets/client/EhConfig.ets';

describe('EhCookieStore', () => {
  let persistence: MemoryCookiePersistence;
  let store: EhCookieStore;

  beforeEach(() => {
    persistence = new MemoryCookiePersistence();
    store = new EhCookieStore(persistence);
  });

  describe('hasSignedIn', () => {
    it('should return false when no cookies are set', () => {
      assert.strictEqual(store.hasSignedIn(), false);
    });

    it('should return false when only member_id is set', () => {
      store.addCookie(
        new CookieBuilder().name(EhCookieStore.KEY_IPD_MEMBER_ID).value('12345')
          .domain(EhUrl.DOMAIN_E).path('/').expiresAt(MAX_EXPIRES).build()
      );
      assert.strictEqual(store.hasSignedIn(), false);
    });

    it('should return false when only pass_hash is set', () => {
      store.addCookie(
        new CookieBuilder().name(EhCookieStore.KEY_IPD_PASS_HASH).value('abc123')
          .domain(EhUrl.DOMAIN_E).path('/').expiresAt(MAX_EXPIRES).build()
      );
      assert.strictEqual(store.hasSignedIn(), false);
    });

    it('should return true when both member_id and pass_hash are set', () => {
      store.addCookie(
        new CookieBuilder().name(EhCookieStore.KEY_IPD_MEMBER_ID).value('12345')
          .domain(EhUrl.DOMAIN_E).path('/').expiresAt(MAX_EXPIRES).build()
      );
      store.addCookie(
        new CookieBuilder().name(EhCookieStore.KEY_IPD_PASS_HASH).value('abc123')
          .domain(EhUrl.DOMAIN_E).path('/').expiresAt(MAX_EXPIRES).build()
      );
      assert.strictEqual(store.hasSignedIn(), true);
    });
  });

  describe('signOut', () => {
    it('should clear all cookies', () => {
      store.addCookie(
        new CookieBuilder().name(EhCookieStore.KEY_IPD_MEMBER_ID).value('12345')
          .domain(EhUrl.DOMAIN_E).path('/').expiresAt(MAX_EXPIRES).build()
      );
      store.addCookie(
        new CookieBuilder().name(EhCookieStore.KEY_IPD_PASS_HASH).value('abc123')
          .domain(EhUrl.DOMAIN_E).path('/').expiresAt(MAX_EXPIRES).build()
      );
      assert.strictEqual(store.hasSignedIn(), true);
      store.signOut();
      assert.strictEqual(store.hasSignedIn(), false);
    });
  });

  describe('loadForRequest', () => {
    it('should add tips cookie for e-hentai.org domain', () => {
      store.addCookie(
        new CookieBuilder().name('sid').value('abc')
          .domain(EhUrl.DOMAIN_E).path('/').expiresAt(MAX_EXPIRES).build()
      );
      const cookies = store.loadForRequest(EhUrl.HOST_E);
      // Should include 'sid' + tips cookie
      const names = cookies.map(c => c.name);
      assert.ok(names.includes('sid'));
      assert.ok(names.includes(EhConfig.KEY_CONTENT_WARNING));
    });

    it('should filter out content warning cookie from stored cookies', () => {
      store.addCookie(
        new CookieBuilder().name(EhConfig.KEY_CONTENT_WARNING).value('0')
          .domain(EhUrl.DOMAIN_E).path('/').expiresAt(MAX_EXPIRES).build()
      );
      const cookies = store.loadForRequest(EhUrl.HOST_E);
      // The stored 'nw' cookie should be filtered out; only the built-in tips cookie remains
      const nwCookies = cookies.filter(c => c.name === EhConfig.KEY_CONTENT_WARNING);
      assert.strictEqual(nwCookies.length, 1);
      assert.strictEqual(nwCookies[0].value, EhConfig.CONTENT_WARNING_NOT_SHOW);
    });

    it('should filter out uconfig cookie from stored cookies', () => {
      store.addCookie(
        new CookieBuilder().name(EhConfig.KEY_UCONFIG).value('some_val')
          .domain(EhUrl.DOMAIN_E).path('/').expiresAt(MAX_EXPIRES).build()
      );
      const cookies = store.loadForRequest(EhUrl.HOST_E);
      assert.ok(!cookies.some(c => c.name === EhConfig.KEY_UCONFIG));
    });

    it('should not add tips cookie for non-e-hentai domains', () => {
      store.addCookie(
        new CookieBuilder().name('sid').value('abc')
          .domain('other.com').path('/').expiresAt(MAX_EXPIRES).build()
      );
      const cookies = store.loadForRequest('https://other.com/');
      assert.strictEqual(cookies.length, 1);
      assert.strictEqual(cookies[0].name, 'sid');
    });
  });

  describe('newCookie', () => {
    it('should clone cookie with new domain', () => {
      const original = new CookieBuilder()
        .name('sid').value('abc').domain('e-hentai.org').path('/')
        .expiresAt(Date.now() + 3600_000).build();
      const cloned = EhCookieStore.newCookie(original, 'exhentai.org', false, false, false);
      assert.strictEqual(cloned.domain, 'exhentai.org');
      assert.strictEqual(cloned.name, 'sid');
      assert.strictEqual(cloned.value, 'abc');
    });

    it('should force persistent with long-live', () => {
      const original = new CookieBuilder()
        .name('sid').value('abc').domain('d.com').path('/').build();
      assert.strictEqual(original.persistent, false);
      const cloned = EhCookieStore.newCookie(original, 'd.com', false, true, false);
      assert.strictEqual(cloned.expiresAt, MAX_EXPIRES);
    });

    it('should force persistent when forcePersistent is true', () => {
      const original = new CookieBuilder()
        .name('sid').value('abc').domain('d.com').path('/').build();
      const cloned = EhCookieStore.newCookie(original, 'd.com', true, false, false);
      assert.strictEqual(cloned.expiresAt, MAX_EXPIRES);
    });

    it('should preserve host-only unless forceNotHostOnly', () => {
      const original = new CookieBuilder()
        .name('sid').value('abc').hostOnlyDomain('d.com').path('/').build();
      assert.strictEqual(original.hostOnly, true);

      const cloned1 = EhCookieStore.newCookie(original, 'new.com', false, false, false);
      assert.strictEqual(cloned1.hostOnly, true);

      const cloned2 = EhCookieStore.newCookie(original, 'new.com', false, false, true);
      assert.strictEqual(cloned2.hostOnly, false);
    });

    it('should preserve secure and httpOnly flags', () => {
      const original = new CookieBuilder()
        .name('sid').value('abc').domain('d.com').path('/')
        .secure().httpOnly().expiresAt(Date.now() + 3600_000).build();
      const cloned = EhCookieStore.newCookie(original, 'd.com', false, false, false);
      assert.strictEqual(cloned.secure, true);
      assert.strictEqual(cloned.httpOnly, true);
    });
  });

  describe('cookie constants', () => {
    it('should have correct cookie key constants', () => {
      assert.strictEqual(EhCookieStore.KEY_IPD_MEMBER_ID, 'ipb_member_id');
      assert.strictEqual(EhCookieStore.KEY_IPD_PASS_HASH, 'ipb_pass_hash');
      assert.strictEqual(EhCookieStore.KEY_IGNEOUS, 'igneous');
    });

    it('should have a valid TIPS_COOKIE', () => {
      const tips = EhCookieStore.TIPS_COOKIE;
      assert.strictEqual(tips.name, EhConfig.KEY_CONTENT_WARNING);
      assert.strictEqual(tips.value, EhConfig.CONTENT_WARNING_NOT_SHOW);
      assert.strictEqual(tips.domain, EhUrl.DOMAIN_E);
      assert.strictEqual(tips.path, '/');
      assert.strictEqual(tips.expiresAt, MAX_EXPIRES);
    });
  });
});
