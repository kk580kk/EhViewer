import { describe, it, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import {
  checkSignedIn,
  requireSignIn,
} from '../../../main/ets/client/SignInGuard.ets';
import { SignInController } from '../../../main/ets/client/SignInController.ets';
import { EhSignIn } from '../../../main/ets/client/EhSignIn.ets';
import { EhCookieStore } from '../../../main/ets/client/EhCookieStore.ets';
import { MemoryCookiePersistence } from '../../../main/ets/network/CookieRepository.ets';
import { HttpClient } from '../../../main/ets/network/HttpClient.ets';
import type { HttpEngine, HttpRequest, HttpResponse } from '../../../main/ets/network/HttpClient.ets';
import { Routes } from '../../../main/ets/router/PageRouter.ets';
import { SettingsService } from '../../../main/ets/service/SettingsService.ets';

class StubEngine implements HttpEngine {
  async execute(_request: HttpRequest): Promise<HttpResponse> {
    return { statusCode: 200, headers: {}, body: '' };
  }
}

describe('checkSignedIn', () => {
  let persistence: MemoryCookiePersistence;
  let cookieStore: EhCookieStore;
  let ehSignIn: EhSignIn;

  beforeEach(() => {
    persistence = new MemoryCookiePersistence();
    cookieStore = new EhCookieStore(persistence);
    const httpClient = new HttpClient({ engine: new StubEngine(), cookieJar: cookieStore });
    ehSignIn = new EhSignIn(httpClient, cookieStore);
    SettingsService.putNeedSignIn(true);
    SignInController.initializeWith(ehSignIn, cookieStore);
  });

  afterEach(() => {
    SignInController.reset();
  });

  it('should return signedIn=false when no cookies', () => {
    const result = checkSignedIn();
    assert.strictEqual(result.signedIn, false);
    assert.ok(result.navigation !== null);
    assert.strictEqual(result.navigation!.url, Routes.SIGN_IN);
  });

  it('should return signedIn=true when cookies present', () => {
    ehSignIn.signInWithCookie('12345', 'abcdef0123456789abcdef0123456789');
    const result = checkSignedIn();
    assert.strictEqual(result.signedIn, true);
    assert.strictEqual(result.navigation, null);
  });
});

describe('requireSignIn', () => {
  let persistence: MemoryCookiePersistence;
  let cookieStore: EhCookieStore;
  let ehSignIn: EhSignIn;

  beforeEach(() => {
    persistence = new MemoryCookiePersistence();
    cookieStore = new EhCookieStore(persistence);
    const httpClient = new HttpClient({ engine: new StubEngine(), cookieJar: cookieStore });
    ehSignIn = new EhSignIn(httpClient, cookieStore);
    SettingsService.putNeedSignIn(true);
    SignInController.initializeWith(ehSignIn, cookieStore);
  });

  afterEach(() => {
    SignInController.reset();
  });

  it('should execute action when signed in', () => {
    ehSignIn.signInWithCookie('12345', 'abcdef0123456789abcdef0123456789');
    let executed = false;
    const result = requireSignIn(() => { executed = true; });
    assert.strictEqual(result, true);
    assert.strictEqual(executed, true);
  });

  it('should not execute action when not signed in', () => {
    let executed = false;
    const result = requireSignIn(() => { executed = true; });
    assert.strictEqual(result, false);
    assert.strictEqual(executed, false);
  });

  it('should call onNotSignedIn when not signed in', () => {
    let prompted = false;
    requireSignIn(
      () => {},
      () => { prompted = true; },
    );
    assert.strictEqual(prompted, true);
  });

  it('should not call onNotSignedIn when signed in', () => {
    ehSignIn.signInWithCookie('12345', 'abcdef0123456789abcdef0123456789');
    let prompted = false;
    requireSignIn(
      () => {},
      () => { prompted = true; },
    );
    assert.strictEqual(prompted, false);
  });
});
