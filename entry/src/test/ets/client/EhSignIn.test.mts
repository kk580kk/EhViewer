import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { EhSignIn } from '../../../main/ets/client/EhSignIn.ets';
import { EhCookieStore } from '../../../main/ets/client/EhCookieStore.ets';
import { MemoryCookiePersistence } from '../../../main/ets/network/CookieRepository.ets';
import type { HttpEngine, HttpRequest, HttpResponse } from '../../../main/ets/network/HttpClient.ets';
import { HttpClient } from '../../../main/ets/network/HttpClient.ets';

// ---- Mock HttpEngine ----

class MockHttpEngine implements HttpEngine {
  /** Queue of responses in order of registration; matched by URL fragment. */
  private queue: Array<{ fragment: string; response: HttpResponse }> = [];

  /** Add a response that will be consumed on the first matching request. */
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

// ---- Tests ----

describe('EhSignIn', () => {
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
  });

  // ---- Validation helpers ----

  describe('isValidMemberId', () => {
    it('should accept all-digit string', () => {
      assert.strictEqual(EhSignIn.isValidMemberId('1234567'), true);
    });

    it('should accept single digit', () => {
      assert.strictEqual(EhSignIn.isValidMemberId('0'), true);
    });

    it('should reject empty string', () => {
      assert.strictEqual(EhSignIn.isValidMemberId(''), false);
    });

    it('should reject string with letters', () => {
      assert.strictEqual(EhSignIn.isValidMemberId('123abc'), false);
    });

    it('should reject string with special characters', () => {
      assert.strictEqual(EhSignIn.isValidMemberId('123-456'), false);
    });

    it('should reject string with spaces', () => {
      assert.strictEqual(EhSignIn.isValidMemberId('123 456'), false);
    });
  });

  describe('isValidPassHash', () => {
    it('should accept 32-char lowercase hex', () => {
      assert.strictEqual(EhSignIn.isValidPassHash('abcdef0123456789abcdef0123456789'), true);
    });

    it('should reject string shorter than 32 chars', () => {
      assert.strictEqual(EhSignIn.isValidPassHash('abcdef'), false);
    });

    it('should reject string longer than 32 chars', () => {
      assert.strictEqual(EhSignIn.isValidPassHash('abcdef0123456789abcdef0123456789a'), false);
    });

    it('should reject uppercase hex', () => {
      assert.strictEqual(EhSignIn.isValidPassHash('ABCDEF0123456789ABCDEF0123456789'), false);
    });

    it('should reject empty string', () => {
      assert.strictEqual(EhSignIn.isValidPassHash(''), false);
    });

    it('should accept all digits 32-char string', () => {
      assert.strictEqual(EhSignIn.isValidPassHash('01234567890123456789012345678901'), true);
    });

    it('should accept all lowercase letters 32-char string', () => {
      assert.strictEqual(EhSignIn.isValidPassHash('abcdefghijklmnopqrstuvwxyzabcdef'), true);
    });
  });

  // ---- hasSignedIn / signOut ----

  describe('hasSignedIn', () => {
    it('should return false initially', () => {
      assert.strictEqual(ehSignIn.hasSignedIn(), false);
    });

    it('should return true after cookie sign-in', () => {
      ehSignIn.signInWithCookie('12345', 'abcdef0123456789abcdef0123456789');
      assert.strictEqual(ehSignIn.hasSignedIn(), true);
    });

    it('should return false after sign-out', () => {
      ehSignIn.signInWithCookie('12345', 'abcdef0123456789abcdef0123456789');
      ehSignIn.signOut();
      assert.strictEqual(ehSignIn.hasSignedIn(), false);
    });
  });

  // ---- signInWithCookie ----

  describe('signInWithCookie', () => {
    it('should store cookies for E-Hentai and ExHentai', () => {
      ehSignIn.signInWithCookie('99999', 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0');
      assert.strictEqual(cookieStore.hasSignedIn(), true);
    });

    it('should clear previous cookies before storing', () => {
      ehSignIn.signInWithCookie('11111', 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb');
      ehSignIn.signInWithCookie('22222', 'cccccccccccccccccccccccccccccccc');
      // Should still be signed in with the new cookies
      assert.strictEqual(cookieStore.hasSignedIn(), true);
    });

    it('should store igneous cookie when provided', () => {
      ehSignIn.signInWithCookie('12345', 'abcdef0123456789abcdef0123456789', 'someIgneousValue');
      assert.strictEqual(cookieStore.hasSignedIn(), true);
      // igneous cookie should be present in Ex cookies
      assert.strictEqual(
        cookieStore.contains('https://exhentai.org/', EhCookieStore.KEY_IGNEOUS),
        true,
      );
    });

    it('should not store igneous when empty', () => {
      ehSignIn.signInWithCookie('12345', 'abcdef0123456789abcdef0123456789', '');
      assert.strictEqual(
        cookieStore.contains('https://exhentai.org/', EhCookieStore.KEY_IGNEOUS),
        false,
      );
    });
  });

  // ---- signIn (username/password) ----

  describe('signIn', () => {
    it('should return display name on success', async () => {
      engine.setResponse('forums.e-hentai.org', {
        statusCode: 200,
        headers: {},
        body: '<p>You are now logged in as: TestUser</p>',
      });

      const result = await ehSignIn.signIn('user', 'pass');
      assert.strictEqual(result.displayName, 'TestUser');
    });

    it('should throw on error response', async () => {
      engine.setResponse('forums.e-hentai.org', {
        statusCode: 200,
        headers: {},
        body: '<h4>The error returned was:</h4>\n<p>Wrong password</p>',
      });

      await assert.rejects(
        () => ehSignIn.signIn('user', 'wrongpass'),
        (err: Error) => {
          assert.strictEqual(err.message, 'Wrong password');
          return true;
        },
      );
    });
  });

  // ---- getProfile ----

  describe('getProfile', () => {
    it('should fetch profile with display name and avatar', async () => {
      // Step 1: forums page returns profile URL
      engine.setResponse('forums.e-hentai.org/', {
        statusCode: 200,
        headers: {},
        body: '<div id="userlinks"><a href="https://forums.e-hentai.org/index.php?showuser=42">Profile</a></div>',
      });

      // Step 2: profile page
      engine.setResponse('showuser=42', {
        statusCode: 200,
        headers: {},
        body: '<div id="profilename"><a href="#">CoolUser</a><img src="https://example.com/avatar.jpg" /></div>',
      });

      const profile = await ehSignIn.getProfile();
      assert.strictEqual(profile.displayName, 'CoolUser');
      assert.strictEqual(profile.avatar, 'https://example.com/avatar.jpg');
    });
  });
});
