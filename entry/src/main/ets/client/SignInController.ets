/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { EhSignIn } from './EhSignIn.ets';
import type { SignInResult } from './EhSignIn.ets';
import type { ProfileResult } from './parser/ProfileParser.ets';
import { EhCookieStore } from './EhCookieStore.ets';
import { EhUrl } from './EhUrl.ets';
import { SettingsService } from '../service/SettingsService.ets';
import { PageRouter } from '../router/PageRouter.ets';
import type { HttpClient } from '../network/HttpClient.ets';
import type { CookiePersistence } from '../network/CookieRepository.ets';

/** Outcome of a sign-in attempt. */
export interface SignInOutcome {
  success: boolean;
  displayName: string;
  avatar: string | null;
  error: string | null;
}

/**
 * SignInController — application-level singleton that orchestrates the
 * full sign-in flow (authenticate → fetch profile → persist state).
 *
 * Pages call the static methods; the controller handles EhSignIn, cookie
 * storage, SettingsService updates, and error handling.
 */
export class SignInController {
  private static instance: EhSignIn | null = null;
  private static cookieStore: EhCookieStore | null = null;

  /** Initialise with the app-level HttpClient and CookiePersistence. */
  static initialize(httpClient: HttpClient, persistence: CookiePersistence): void {
    SignInController.cookieStore = new EhCookieStore(persistence);
    SignInController.instance = new EhSignIn(httpClient, SignInController.cookieStore);
  }

  /** Initialise with pre-built instances (for testing). */
  static initializeWith(ehSignIn: EhSignIn, cookieStore: EhCookieStore): void {
    SignInController.instance = ehSignIn;
    SignInController.cookieStore = cookieStore;
  }

  /** Reset state (for testing). */
  static reset(): void {
    SignInController.instance = null;
    SignInController.cookieStore = null;
  }

  private static getSignIn(): EhSignIn {
    if (!SignInController.instance) {
      throw new Error('SignInController not initialized. Call initialize() first.');
    }
    return SignInController.instance;
  }

  private static getCookieStore(): EhCookieStore {
    if (!SignInController.cookieStore) {
      throw new Error('SignInController not initialized. Call initialize() first.');
    }
    return SignInController.cookieStore;
  }

  /** Whether the user has valid sign-in cookies. */
  static hasSignedIn(): boolean {
    try {
      return SignInController.getCookieStore().hasSignedIn();
    } catch {
      return false;
    }
  }

  /** Whether the app should show the sign-in flow. */
  static needSignIn(): boolean {
    return SettingsService.getNeedSignIn();
  }

  /**
   * Sign in with username and password.
   * On success, fetches the user profile and persists display name + avatar.
   */
  static async signIn(username: string, password: string): Promise<SignInOutcome> {
    const ehSignIn = SignInController.getSignIn();
    try {
      const result: SignInResult = await ehSignIn.signIn(username, password);
      SettingsService.putDisplayName(result.displayName);

      // Verify cookies were actually set
      if (!SignInController.hasSignedIn()) {
        return { success: false, displayName: '', avatar: null, error: 'Sign in failed: cookies not set' };
      }

      // Try to fetch the full profile (display name + avatar)
      return await SignInController.fetchProfileAndPersist();
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      return { success: false, displayName: '', avatar: null, error: msg };
    }
  }

  /**
   * Sign in by manually providing cookie values.
   * Stores cookies, then fetches the user profile.
   */
  static async signInWithCookie(
    ipbMemberId: string,
    ipbPassHash: string,
    igneous?: string,
  ): Promise<SignInOutcome> {
    const ehSignIn = SignInController.getSignIn();
    try {
      ehSignIn.signInWithCookie(ipbMemberId, ipbPassHash, igneous);

      if (!SignInController.hasSignedIn()) {
        return { success: false, displayName: '', avatar: null, error: 'Cookie sign in failed' };
      }

      return await SignInController.fetchProfileAndPersist();
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      return { success: false, displayName: '', avatar: null, error: msg };
    }
  }

  /**
   * Called after WebView sign-in detects cookies.
   * Fetches the user profile and persists it.
   */
  static async onWebViewSignInComplete(): Promise<SignInOutcome> {
    if (!SignInController.hasSignedIn()) {
      return { success: false, displayName: '', avatar: null, error: 'No valid cookies detected' };
    }
    try {
      return await SignInController.fetchProfileAndPersist();
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      return { success: false, displayName: '', avatar: null, error: msg };
    }
  }

  /** Mark sign-in as no longer needed and persist state. */
  static completeSignIn(): void {
    SettingsService.putNeedSignIn(false);
  }

  /**
   * Skip sign-in. Sets gallery site to E-Hentai and marks sign-in as done.
   */
  static skipSignIn(): void {
    SettingsService.setGallerySite(EhUrl.SITE_E);
    SettingsService.putNeedSignIn(false);
  }

  /**
   * Check if the user is signed in; if not, navigate to the sign-in page.
   * Returns true if already signed in, false if redirecting.
   *
   * Usage in pages that require sign-in:
   *   if (!SignInController.requireSignIn()) return;
   */
  static requireSignIn(): boolean {
    if (SignInController.hasSignedIn()) {
      return true;
    }
    PageRouter.toSignIn();
    return false;
  }

  /** Sign out: clear cookies and reset persisted account info. */
  static signOut(): void {
    try {
      SignInController.getSignIn().signOut();
    } catch {
      // Not initialized — nothing to clear
    }
    SettingsService.putDisplayName('');
    SettingsService.putAvatar('');
  }

  /** Fetch profile and persist display name + avatar. */
  private static async fetchProfileAndPersist(): Promise<SignInOutcome> {
    const ehSignIn = SignInController.getSignIn();
    try {
      const profile: ProfileResult = await ehSignIn.getProfile();
      SettingsService.putDisplayName(profile.displayName);
      SettingsService.putAvatar(profile.avatar ?? '');
      SettingsService.putNeedSignIn(false);
      return {
        success: true,
        displayName: profile.displayName,
        avatar: profile.avatar,
        error: null,
      };
    } catch {
      // Profile fetch failed — sign-in itself succeeded
      SettingsService.putNeedSignIn(false);
      const fallback = SettingsService.getDisplayName();
      return {
        success: true,
        displayName: fallback,
        avatar: null,
        error: null,
      };
    }
  }
}
