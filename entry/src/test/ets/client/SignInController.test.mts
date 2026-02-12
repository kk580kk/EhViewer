import { describe, it, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { SignInController } from '../../../main/ets/client/SignInController.ets';
import { EhSignIn } from '../../../main/ets/client/EhSignIn.ets';
import { EhCookieStore } from '../../../main/ets/client/EhCookieStore.ets';
import { MemoryCookiePersistence } from '../../../main/ets/network/CookieRepository.ets';
import { HttpClient } from '../../../main/ets/network/HttpClient.ets';
import type { HttpEngine, HttpRequest, HttpResponse } from '../../../main/ets/network/HttpClient.ets';
import { SettingsService } from '../../../main/ets/service/SettingsService.ets';

// ---- Mock HttpEngine ----

class MockHttpEngine implements HttpEngine {
  private queue: Array<{ fragment: string; response: HttpResponse }> = [];

  setResponse(urlFragment: string, response: HttpResponse): void {
    this.queue.push({ fragment: urlFragment, response });
  }

  async execute(request: HttpRequest): Promise<HttpResponse> {
    const idx = this.queue.findIndex(e => request.url.includes(e.fragment));
    if (idx >= 0) {
      const entry = this.queue[idx];
      this.queue.splice(idx, 1);
      return entry.response;
    }
    return { statusCode: 404, headers: {}, body: 'Not found' };
  }
}

describe('SignInController', () => {
  let engine: MockHttpEngine;
  let httpClient: HttpClient;
  let persistence: MemoryCookiePersistence;
  let cookieStore: EhCookieStore;
  let ehSignIn: EhSignIn;

  beforeEach(() => {
    engine = new MockHttpEngine();
    persistence = new MemoryCookiePersistence();
    cookieStore = new EhCookieStore(persistence);
    httpClient = new HttpClient({ engine, cookieJar: cookieStore });
    ehSignIn = new EhSignIn(httpClient, cookieStore);

    // Reset global state
    SettingsService.putNeedSignIn(true);
    SettingsService.putDisplayName('');
    SettingsService.putAvatar('');

    SignInController.initializeWith(ehSignIn, cookieStore);
  });

  afterEach(() => {
    SignInController.reset();
  });

  // ---- hasSignedIn ----

  describe('hasSignedIn', () => {
    it('should return false when no cookies set', () => {
      assert.strictEqual(SignInController.hasSignedIn(), false);
    });

    it('should return true after cookie sign-in', () => {
      ehSignIn.signInWithCookie('12345', 'abcdef0123456789abcdef0123456789');
      assert.strictEqual(SignInController.hasSignedIn(), true);
    });
  });

  // ---- needSignIn ----

  describe('needSignIn', () => {
    it('should return true initially', () => {
      assert.strictEqual(SignInController.needSignIn(), true);
    });

    it('should return false after completeSignIn', () => {
      SignInController.completeSignIn();
      assert.strictEqual(SignInController.needSignIn(), false);
    });
  });

  // ---- signInWithCookie ----

  describe('signInWithCookie', () => {
    it('should succeed and fetch profile', async () => {
      // Mock forums page
      engine.setResponse('forums.e-hentai.org/', {
        statusCode: 200,
        headers: {},
        body: '<div id="userlinks"><a href="https://forums.e-hentai.org/index.php?showuser=1">Profile</a></div>',
      });

      // Mock profile page
      engine.setResponse('showuser=1', {
        statusCode: 200,
        headers: {},
        body: '<div id="profilename"><a href="#">TestUser</a></div>',
      });

      const outcome = await SignInController.signInWithCookie(
        '12345',
        'abcdef0123456789abcdef0123456789',
      );

      assert.strictEqual(outcome.success, true);
      assert.strictEqual(outcome.displayName, 'TestUser');
      assert.strictEqual(outcome.error, null);
    });

    it('should still succeed when profile fetch fails', async () => {
      // Store cookies, then profile fetch fails
      engine.setResponse('forums.e-hentai.org/', {
        statusCode: 500,
        headers: {},
        body: 'Internal Server Error',
      });

      const outcome = await SignInController.signInWithCookie(
        '12345',
        'abcdef0123456789abcdef0123456789',
      );

      // Sign-in succeeds (cookies are valid), profile fetch fails gracefully
      assert.strictEqual(outcome.success, true);
      assert.strictEqual(outcome.error, null);
    });
  });

  // ---- skipSignIn ----

  describe('skipSignIn', () => {
    it('should set needSignIn to false', () => {
      SignInController.skipSignIn();
      assert.strictEqual(SettingsService.getNeedSignIn(), false);
    });

    it('should set gallery site to E-Hentai', () => {
      SignInController.skipSignIn();
      assert.strictEqual(SettingsService.getGallerySite(), 0); // SITE_E
    });
  });

  // ---- requireSignIn ----

  describe('requireSignIn', () => {
    it('should return true when signed in', () => {
      ehSignIn.signInWithCookie('12345', 'abcdef0123456789abcdef0123456789');
      assert.strictEqual(SignInController.requireSignIn(), true);
    });

    it('should return false and navigate when not signed in', () => {
      const result = SignInController.requireSignIn();
      assert.strictEqual(result, false);
    });
  });

  // ---- signOut ----

  describe('signOut', () => {
    it('should clear cookies and account info', () => {
      ehSignIn.signInWithCookie('12345', 'abcdef0123456789abcdef0123456789');
      SettingsService.putDisplayName('TestUser');
      SettingsService.putAvatar('https://example.com/avatar.jpg');

      SignInController.signOut();

      assert.strictEqual(SignInController.hasSignedIn(), false);
      assert.strictEqual(SettingsService.getDisplayName(), '');
      assert.strictEqual(SettingsService.getAvatar(), '');
    });
  });

  // ---- completeSignIn ----

  describe('completeSignIn', () => {
    it('should persist needSignIn as false', () => {
      SignInController.completeSignIn();
      assert.strictEqual(SettingsService.getNeedSignIn(), false);
    });
  });

  // ---- Not initialized ----

  describe('uninitialized state', () => {
    it('should return false from hasSignedIn when not initialized', () => {
      SignInController.reset();
      assert.strictEqual(SignInController.hasSignedIn(), false);
    });

    it('should throw from signIn when not initialized', async () => {
      SignInController.reset();
      await assert.rejects(
        () => SignInController.signIn('user', 'pass'),
        (err: Error) => {
          assert.ok(err.message.includes('not initialized'));
          return true;
        },
      );
    });
  });
});
