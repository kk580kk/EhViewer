import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { EhEngine } from '../../../main/ets/client/EhEngine.ets';
import { EhSignIn } from '../../../main/ets/client/EhSignIn.ets';
import { EhCookieStore } from '../../../main/ets/client/EhCookieStore.ets';
import { EhException } from '../../../main/ets/client/exception/EhException.ets';
import { MemoryCookiePersistence } from '../../../main/ets/network/CookieRepository.ets';
import type { HttpEngine, HttpRequest, HttpResponse } from '../../../main/ets/network/HttpClient.ets';
import { HttpClient } from '../../../main/ets/network/HttpClient.ets';

// ---- Mocks ----

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

describe('EhEngine', () => {
  let mockEngine: MockHttpEngine;
  let httpClient: HttpClient;
  let cookieStore: EhCookieStore;
  let signIn: EhSignIn;
  let engine: EhEngine;

  beforeEach(() => {
    mockEngine = new MockHttpEngine();
    const persistence = new MemoryCookiePersistence();
    cookieStore = new EhCookieStore(persistence);
    httpClient = new HttpClient({ engine: mockEngine, cookieJar: cookieStore });
    signIn = new EhSignIn(httpClient, cookieStore);
    engine = new EhEngine(httpClient, signIn);
  });

  describe('signIn / getProfile / hasSignedIn / signOut', () => {
    it('signIn delegates to EhSignIn and returns display name', async () => {
      mockEngine.setResponse('Login', {
        statusCode: 200,
        headers: {},
        body: '<p>You are now logged in as: TestUser</p>',
      });
      const name = await engine.signIn('user', 'pass');
      assert.strictEqual(name, 'TestUser');
    });

    it('getProfile delegates to EhSignIn', async () => {
      mockEngine.setResponse('showuser=1', {
        statusCode: 200,
        headers: {},
        body: '<div id="profilename"><a>ProfileUser</a></div>',
      });
      mockEngine.setResponse('forums.e-hentai.org', {
        statusCode: 200,
        headers: {},
        body: '<div id="userlinks"><a href="https://forums.e-hentai.org/index.php?showuser=1">profile</a></div>',
      });
      const profile = await engine.getProfile();
      assert.strictEqual(profile.displayName, 'ProfileUser');
    });

    it('hasSignedIn returns false when no cookies', () => {
      assert.strictEqual(engine.hasSignedIn(), false);
    });

    it('signOut clears cookies via EhSignIn', () => {
      engine.signOut();
      assert.strictEqual(engine.hasSignedIn(), false);
    });
  });

  describe('getGalleryList', () => {
    it('returns empty list when body says No hits found', async () => {
      mockEngine.setResponse('page=', {
        statusCode: 200,
        headers: {},
        body: '<html><body>No hits found</p></body></html>',
      });
      const result = await engine.getGalleryList('https://e-hentai.org/?page=0');
      assert.strictEqual(result.galleryInfoList.length, 0);
      assert.ok(result.pages >= 0);
    });
  });

  describe('addFavorites', () => {
    it('throws EhException for dstCat > 9', async () => {
      mockEngine.setResponse('gallerypopups', {
        statusCode: 200,
        headers: {},
        body: '',
      });
      await assert.rejects(
        async () => engine.addFavorites(1, 'token', 10, null),
        (e: Error) => e instanceof EhException && e.message.includes('Invalid dstCat')
      );
    });

    it('throws EhException for dstCat < -1', async () => {
      await assert.rejects(
        async () => engine.addFavorites(1, 'token', -2, null),
        (e: Error) => e instanceof EhException && e.message.includes('Invalid dstCat')
      );
    });
  });

  describe('modifyFavorites', () => {
    it('throws EhException for invalid dstCat', async () => {
      await assert.rejects(
        async () => engine.modifyFavorites('https://e-hentai.org/favorites.php', [1], 10),
        (e: Error) => e instanceof EhException && e.message.includes('Invalid dstCat')
      );
    });
  });

  describe('getGalleryToken', () => {
    it('returns token from API response', async () => {
      mockEngine.setResponse('api.php', {
        statusCode: 200,
        headers: {},
        body: JSON.stringify({ tokenlist: [{ token: 'abc123page' }] }),
      });
      const token = await engine.getGalleryToken(123, 'gtoken', 0);
      assert.strictEqual(token, 'abc123page');
    });
  });

  describe('rateGallery', () => {
    it('returns rating and count from API response', async () => {
      mockEngine.setResponse('api.php', {
        statusCode: 200,
        headers: {},
        body: JSON.stringify({ rating_avg: 4.5, rating_cnt: 100 }),
      });
      const result = await engine.rateGallery(1, 'key', 100, 'token', 4.5);
      assert.strictEqual(result.rating, 4.5);
      assert.strictEqual(result.ratingCount, 100);
    });
  });

  describe('voteComment', () => {
    it('returns VoteCommentResult from API response', async () => {
      mockEngine.setResponse('api.php', {
        statusCode: 200,
        headers: {},
        body: JSON.stringify({
          comment_id: 42,
          comment_score: 10,
          comment_vote: 1,
        }),
      });
      const result = await engine.voteComment(1, 'key', 100, 'token', 42, 1);
      assert.strictEqual(result.id, 42);
      assert.strictEqual(result.score, 10);
      assert.strictEqual(result.vote, 1);
    });
  });
});
