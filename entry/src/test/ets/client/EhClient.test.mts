import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { EhClient } from '../../../main/ets/client/EhClient.ets';
import { EhEngine } from '../../../main/ets/client/EhEngine.ets';
import { EhSignIn } from '../../../main/ets/client/EhSignIn.ets';
import { EhCookieStore } from '../../../main/ets/client/EhCookieStore.ets';
import { EhEngineGalleryListFetcher } from '../../../main/ets/client/EhEngineGalleryListFetcher.ets';
import { EhEngineGalleryDetailFetcher } from '../../../main/ets/client/EhEngineGalleryDetailFetcher.ets';
import { MemoryCookiePersistence } from '../../../main/ets/network/CookieRepository.ets';
import type { HttpEngine, HttpRequest, HttpResponse } from '../../../main/ets/network/HttpClient.ets';
import { HttpClient } from '../../../main/ets/network/HttpClient.ets';

// ---- Mock ----

class MockHttpEngine implements HttpEngine {
  response: HttpResponse = { statusCode: 200, headers: {}, body: '' };

  async execute(_request: HttpRequest): Promise<HttpResponse> {
    return this.response;
  }
}

describe('EhClient', () => {
  let mockEngine: MockHttpEngine;
  let httpClient: HttpClient;
  let cookieStore: EhCookieStore;

  beforeEach(() => {
    EhClient.reset();
    mockEngine = new MockHttpEngine();
    const persistence = new MemoryCookiePersistence();
    cookieStore = new EhCookieStore(persistence);
    httpClient = new HttpClient({ engine: mockEngine, cookieJar: cookieStore });
  });

  describe('initialization', () => {
    it('isInitialized returns false before initialize', () => {
      assert.strictEqual(EhClient.isInitialized(), false);
    });

    it('isInitialized returns true after initialize', () => {
      EhClient.initialize(httpClient, cookieStore);
      assert.strictEqual(EhClient.isInitialized(), true);
    });

    it('getEngine throws before initialize', () => {
      assert.throws(() => EhClient.getEngine(), /not initialized/);
    });

    it('getEngine returns EhEngine after initialize', () => {
      EhClient.initialize(httpClient, cookieStore);
      const engine = EhClient.getEngine();
      assert.ok(engine instanceof EhEngine);
    });
  });

  describe('initializeWith', () => {
    it('accepts a pre-built EhEngine', () => {
      const signIn = new EhSignIn(httpClient, cookieStore);
      const engine = new EhEngine(httpClient, signIn);
      EhClient.initializeWith(engine);
      assert.strictEqual(EhClient.isInitialized(), true);
      assert.strictEqual(EhClient.getEngine(), engine);
    });
  });

  describe('factory methods', () => {
    it('galleryListFetcher returns EhEngineGalleryListFetcher', () => {
      EhClient.initialize(httpClient, cookieStore);
      const fetcher = EhClient.galleryListFetcher();
      assert.ok(fetcher instanceof EhEngineGalleryListFetcher);
    });

    it('galleryDetailFetcher returns EhEngineGalleryDetailFetcher', () => {
      EhClient.initialize(httpClient, cookieStore);
      const fetcher = EhClient.galleryDetailFetcher();
      assert.ok(fetcher instanceof EhEngineGalleryDetailFetcher);
    });

    it('galleryListFetcher throws before initialize', () => {
      assert.throws(() => EhClient.galleryListFetcher(), /not initialized/);
    });

    it('galleryDetailFetcher throws before initialize', () => {
      assert.throws(() => EhClient.galleryDetailFetcher(), /not initialized/);
    });
  });

  describe('reset', () => {
    it('clears singleton state', () => {
      EhClient.initialize(httpClient, cookieStore);
      assert.strictEqual(EhClient.isInitialized(), true);

      EhClient.reset();
      assert.strictEqual(EhClient.isInitialized(), false);
    });
  });

  describe('singleton identity', () => {
    it('getEngine returns the same instance on repeated calls', () => {
      EhClient.initialize(httpClient, cookieStore);
      const a = EhClient.getEngine();
      const b = EhClient.getEngine();
      assert.strictEqual(a, b);
    });

    it('re-initialize replaces the engine', () => {
      EhClient.initialize(httpClient, cookieStore);
      const first = EhClient.getEngine();

      // Build a second engine
      const persistence2 = new MemoryCookiePersistence();
      const store2 = new EhCookieStore(persistence2);
      const client2 = new HttpClient({ engine: mockEngine, cookieJar: store2 });
      EhClient.initialize(client2, store2);
      const second = EhClient.getEngine();

      assert.notStrictEqual(first, second);
    });
  });
});
