import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { EhHttpClient } from '../../../main/ets/client/EhHttpClient.ets';
import { MemoryDatabaseStore } from '../../../main/ets/database/MemoryDatabaseStore.ets';
import { CookieBuilder, MAX_EXPIRES } from '../../../main/ets/network/Cookie.ets';
import { EhCookieStore } from '../../../main/ets/client/EhCookieStore.ets';
import { EhUrl } from '../../../main/ets/client/EhUrl.ets';
import type { HttpEngine, HttpRequest, HttpResponse } from '../../../main/ets/network/HttpClient.ets';

// ---- Mock engine ----

class MockEngine implements HttpEngine {
  lastRequest: HttpRequest | null = null;
  response: HttpResponse = { statusCode: 200, headers: {}, body: '' };

  async execute(request: HttpRequest): Promise<HttpResponse> {
    this.lastRequest = request;
    return this.response;
  }
}

describe('EhHttpClient', () => {
  let dbStore: MemoryDatabaseStore;
  let engine: MockEngine;

  beforeEach(() => {
    EhHttpClient.reset();
    dbStore = new MemoryDatabaseStore();
    engine = new MockEngine();
  });

  describe('initialize', () => {
    it('should create HttpClient and CookieStore', () => {
      EhHttpClient.initialize(dbStore, engine);
      assert.ok(EhHttpClient.isInitialized());
      assert.ok(EhHttpClient.getHttpClient() !== null);
      assert.ok(EhHttpClient.getCookieStore() !== null);
    });

    it('should throw before initialization', () => {
      assert.throws(() => EhHttpClient.getHttpClient(), /not initialized/);
      assert.throws(() => EhHttpClient.getCookieStore(), /not initialized/);
    });
  });

  describe('cookie persistence in requests', () => {
    it('should attach persisted cookies to outgoing requests', async () => {
      EhHttpClient.initialize(dbStore, engine);
      const store = EhHttpClient.getCookieStore();
      const client = EhHttpClient.getHttpClient();

      // Add a persistent cookie
      store.addCookie(
        new CookieBuilder().name('sid').value('test123')
          .domain('example.com').path('/').expiresAt(MAX_EXPIRES).build()
      );

      await client.get('https://example.com/page');

      assert.ok(engine.lastRequest !== null);
      assert.strictEqual(engine.lastRequest!.headers!['Cookie'], 'sid=test123');
    });

    it('should save Set-Cookie from response and carry in next request', async () => {
      EhHttpClient.initialize(dbStore, engine);
      const client = EhHttpClient.getHttpClient();

      // First request: server sends Set-Cookie
      engine.response = {
        statusCode: 200,
        headers: { 'Set-Cookie': 'token=abc; Path=/; Max-Age=3600' },
        body: 'ok',
      };
      await client.get('https://example.com/login');

      // Second request: cookie should be attached
      engine.response = { statusCode: 200, headers: {}, body: 'ok' };
      await client.get('https://example.com/dashboard');

      assert.strictEqual(engine.lastRequest!.headers!['Cookie'], 'token=abc');
    });

    it('should persist cookies across EhHttpClient re-initialization', async () => {
      // First session: receive a cookie
      EhHttpClient.initialize(dbStore, engine);
      const client = EhHttpClient.getHttpClient();

      engine.response = {
        statusCode: 200,
        headers: { 'Set-Cookie': 'persist=yes; Path=/; Max-Age=86400' },
        body: 'ok',
      };
      await client.get('https://example.com/');

      // Simulate app restart: reset EhHttpClient but keep the same dbStore
      EhHttpClient.reset();
      const engine2 = new MockEngine();
      EhHttpClient.initialize(dbStore, engine2);
      const client2 = EhHttpClient.getHttpClient();

      engine2.response = { statusCode: 200, headers: {}, body: 'ok' };
      await client2.get('https://example.com/');

      assert.strictEqual(engine2.lastRequest!.headers!['Cookie'], 'persist=yes');
    });

    it('should not carry cookies for unrelated domains', async () => {
      EhHttpClient.initialize(dbStore, engine);
      const store = EhHttpClient.getCookieStore();
      const client = EhHttpClient.getHttpClient();

      store.addCookie(
        new CookieBuilder().name('sid').value('abc')
          .domain('example.com').path('/').expiresAt(MAX_EXPIRES).build()
      );

      await client.get('https://other.com/page');

      // No Cookie header for unrelated domain
      assert.strictEqual(engine.lastRequest!.headers!['Cookie'], undefined);
    });
  });

  describe('EH-specific cookie behavior', () => {
    it('should force-persist auth cookies from EH domains', async () => {
      EhHttpClient.initialize(dbStore, engine);
      const client = EhHttpClient.getHttpClient();

      // Server sends session auth cookies (no Expires/Max-Age)
      engine.response = {
        statusCode: 200,
        headers: {
          'Set-Cookie': 'ipb_member_id=12345; Path=/\nipb_pass_hash=abc123def456abc123def456abc123de; Path=/',
        },
        body: 'ok',
      };
      await client.get(EhUrl.HOST_E);

      // Simulate restart with same database
      EhHttpClient.reset();
      const engine2 = new MockEngine();
      EhHttpClient.initialize(dbStore, engine2);
      const client2 = EhHttpClient.getHttpClient();

      engine2.response = { statusCode: 200, headers: {}, body: 'ok' };
      await client2.get(EhUrl.HOST_E);

      // Auth cookies should survive restart (forced persistent by EhCookieStore)
      const cookie = engine2.lastRequest!.headers!['Cookie'] ?? '';
      assert.ok(cookie.includes('ipb_member_id=12345'));
      assert.ok(cookie.includes('ipb_pass_hash=abc123def456abc123def456abc123de'));
    });

    it('should report signed-in status after receiving auth cookies', async () => {
      EhHttpClient.initialize(dbStore, engine);
      const store = EhHttpClient.getCookieStore();
      const client = EhHttpClient.getHttpClient();

      assert.strictEqual(store.hasSignedIn(), false);

      engine.response = {
        statusCode: 200,
        headers: {
          'Set-Cookie': 'ipb_member_id=12345; Path=/\nipb_pass_hash=abc123def456abc123def456abc123de; Path=/',
        },
        body: 'ok',
      };
      await client.get(EhUrl.HOST_E);

      assert.strictEqual(store.hasSignedIn(), true);
    });

    it('should add tips cookie for EH requests', async () => {
      EhHttpClient.initialize(dbStore, engine);
      const client = EhHttpClient.getHttpClient();

      await client.get(EhUrl.HOST_E);

      // The tips cookie (nw=1) should be added by EhCookieStore.loadForRequest
      const cookie = engine.lastRequest!.headers!['Cookie'] ?? '';
      assert.ok(cookie.includes('nw=1'));
    });
  });

  describe('reset', () => {
    it('should clear all state', () => {
      EhHttpClient.initialize(dbStore, engine);
      assert.ok(EhHttpClient.isInitialized());

      EhHttpClient.reset();
      assert.strictEqual(EhHttpClient.isInitialized(), false);
    });
  });
});
