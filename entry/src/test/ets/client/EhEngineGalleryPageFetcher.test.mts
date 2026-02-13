import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { EhEngine } from '../../../main/ets/client/EhEngine.ets';
import { EhSignIn } from '../../../main/ets/client/EhSignIn.ets';
import { EhCookieStore } from '../../../main/ets/client/EhCookieStore.ets';
import { EhClient } from '../../../main/ets/client/EhClient.ets';
import { EhEngineGalleryPageFetcher } from '../../../main/ets/client/EhEngineGalleryPageFetcher.ets';
import type { GalleryPageFetcher } from '../../../main/ets/client/EhEngineGalleryPageFetcher.ets';
import { MemoryCookiePersistence } from '../../../main/ets/network/CookieRepository.ets';
import type { HttpEngine, HttpRequest, HttpResponse } from '../../../main/ets/network/HttpClient.ets';
import { HttpClient } from '../../../main/ets/network/HttpClient.ets';

// ---- Mock ----

class MockHttpEngine implements HttpEngine {
  private responses: Map<string, HttpResponse> = new Map();
  lastRequest: HttpRequest | null = null;

  setResponse(urlOrKey: string, response: HttpResponse): void {
    this.responses.set(urlOrKey, response);
  }

  async execute(request: HttpRequest): Promise<HttpResponse> {
    this.lastRequest = request;
    for (const [key, res] of this.responses) {
      if (request.url.includes(key)) {
        return res;
      }
    }
    return { statusCode: 200, headers: {}, body: '' };
  }
}

// ---- Tests ----

describe('EhEngineGalleryPageFetcher', () => {
  let mockEngine: MockHttpEngine;
  let httpClient: HttpClient;
  let cookieStore: EhCookieStore;
  let engine: EhEngine;
  let fetcher: GalleryPageFetcher;

  beforeEach(() => {
    mockEngine = new MockHttpEngine();
    const persistence = new MemoryCookiePersistence();
    cookieStore = new EhCookieStore(persistence);
    httpClient = new HttpClient({ engine: mockEngine, cookieJar: cookieStore });
    const signIn = new EhSignIn(httpClient, cookieStore);
    engine = new EhEngine(httpClient, signIn);
    fetcher = new EhEngineGalleryPageFetcher(engine);
  });

  describe('getGalleryToken', () => {
    it('delegates to EhEngine and returns token', async () => {
      mockEngine.setResponse('api.php', {
        statusCode: 200,
        headers: {},
        body: JSON.stringify({ tokenlist: [{ token: 'pagetoken123' }] }),
      });
      const token = await fetcher.getGalleryToken(100, 'gtoken', 0);
      assert.strictEqual(token, 'pagetoken123');
    });
  });

  describe('getGalleryPage', () => {
    it('delegates to EhEngine and returns page result', async () => {
      const pageHtml = `
        <div id="i3"><img id="img" src="https://hath.network/h/keystuff/test.jpg" style=""></div>
        <div id="i6"><a href="#" onclick="return nl('abc-123')">Click to load</a></div>
        <script>var showkey="a1b2c3d4e5";</script>
      `;
      mockEngine.setResponse('s/', {
        statusCode: 200,
        headers: {},
        body: pageHtml,
      });
      const result = await fetcher.getGalleryPage(
        'https://e-hentai.org/s/ptok/100-1', 100, 'token'
      );
      assert.strictEqual(result.imageUrl, 'https://hath.network/h/keystuff/test.jpg');
      assert.strictEqual(result.skipHathKey, 'abc-123');
      assert.strictEqual(result.showKey, 'a1b2c3d4e5');
    });
  });

  describe('getGalleryPageApi', () => {
    it('delegates to EhEngine and returns API result', async () => {
      const apiBody = JSON.stringify({
        i3: '<img id="img" src="https://hath.network/api/image.jpg" style="">',
        i6: '<a href="#" onclick="return nl(\'def-456\')">click</a>',
        i7: '',
      });
      mockEngine.setResponse('api.php', {
        statusCode: 200,
        headers: {},
        body: apiBody,
      });
      const result = await fetcher.getGalleryPageApi(100, 0, 'pToken', 'showKey', null);
      assert.strictEqual(result.imageUrl, 'https://hath.network/api/image.jpg');
      assert.strictEqual(result.skipHathKey, 'def-456');
    });
  });

  describe('interface compliance', () => {
    it('EhEngineGalleryPageFetcher satisfies GalleryPageFetcher', () => {
      const f: GalleryPageFetcher = new EhEngineGalleryPageFetcher(engine);
      assert.ok(typeof f.getGalleryToken === 'function');
      assert.ok(typeof f.getGalleryPage === 'function');
      assert.ok(typeof f.getGalleryPageApi === 'function');
    });
  });
});

describe('EhClient.galleryPageFetcher', () => {
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

  it('returns EhEngineGalleryPageFetcher after initialize', () => {
    EhClient.initialize(httpClient, cookieStore);
    const fetcher = EhClient.galleryPageFetcher();
    assert.ok(fetcher instanceof EhEngineGalleryPageFetcher);
  });

  it('throws before initialize', () => {
    assert.throws(() => EhClient.galleryPageFetcher(), /not initialized/);
  });

  it('fetcher delegates to the shared engine', async () => {
    EhClient.initialize(httpClient, cookieStore);
    mockEngine.setResponse('api.php', {
      statusCode: 200,
      headers: {},
      body: JSON.stringify({ tokenlist: [{ token: 'shared-token' }] }),
    });
    const fetcher = EhClient.galleryPageFetcher();
    const token = await fetcher.getGalleryToken(1, 'gt', 0);
    assert.strictEqual(token, 'shared-token');
  });
});
