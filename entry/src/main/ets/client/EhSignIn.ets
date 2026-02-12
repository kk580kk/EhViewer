/*
 * Copyright 2016 Hippo Seven
 * Ported to HarmonyOS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { CookieBuilder, MAX_EXPIRES } from '../network/Cookie.ets';
import type { Cookie } from '../network/Cookie.ets';
import type { HttpClient, KV } from '../network/HttpClient.ets';
import { buildEhHeaders } from '../network/HttpClient.ets';
import { EhCookieStore } from './EhCookieStore.ets';
import { EhUrl } from './EhUrl.ets';
import { SignInParser } from './parser/SignInParser.ets';
import { ForumsParser } from './parser/ForumsParser.ets';
import { ProfileParser } from './parser/ProfileParser.ets';
import type { ProfileResult } from './parser/ProfileParser.ets';

/** Result from a username/password sign-in attempt. */
export interface SignInResult {
  displayName: string;
}

/** Result from getProfile after sign-in. */
export type { ProfileResult };

/**
 * EhSignIn — handles all authentication-related operations.
 *
 * Mirrors the sign-in portion of the Java EhEngine:
 *  - signIn (username/password form post)
 *  - signInWithCookie (manually enter ipb_member_id / ipb_pass_hash)
 *  - getProfile (fetch display name and avatar after login)
 *  - signOut (clear cookies)
 *  - hasSignedIn (check cookies)
 */
export class EhSignIn {
  private httpClient: HttpClient;
  private cookieStore: EhCookieStore;

  constructor(httpClient: HttpClient, cookieStore: EhCookieStore) {
    this.httpClient = httpClient;
    this.cookieStore = cookieStore;
  }

  /** Whether the user has valid sign-in cookies. */
  hasSignedIn(): boolean {
    return this.cookieStore.hasSignedIn();
  }

  /** Clear all cookies (sign out). */
  signOut(): void {
    this.cookieStore.signOut();
  }

  /**
   * Sign in with username and password.
   * Posts to the forums sign-in endpoint and parses the response for the display name.
   */
  async signIn(username: string, password: string): Promise<SignInResult> {
    const url = EhUrl.API_SIGN_IN;
    const referer = 'https://forums.e-hentai.org/index.php?act=Login&CODE=00';
    const origin = 'https://forums.e-hentai.org';

    const fields: KV[] = [
      { key: 'UserName', value: username },
      { key: 'PassWord', value: password },
      { key: 'submit', value: 'Log me in' },
      { key: 'CookieDate', value: '1' },
      { key: 'temporary_https', value: 'off' },
    ];

    const response = await this.httpClient.postForm(url, fields, buildEhHeaders(referer, origin));
    const displayName = SignInParser.parse(response.body);
    return { displayName };
  }

  /**
   * Sign in by manually providing cookie values.
   * Stores them for both E-Hentai and ExHentai domains.
   */
  signInWithCookie(ipbMemberId: string, ipbPassHash: string, igneous?: string): void {
    // Clear existing cookies first
    this.cookieStore.signOut();

    const addCookiePair = (name: string, value: string): void => {
      this.cookieStore.addCookie(EhSignIn.buildCookie(name, value, EhUrl.DOMAIN_E));
      this.cookieStore.addCookie(EhSignIn.buildCookie(name, value, EhUrl.DOMAIN_EX));
    };

    addCookiePair(EhCookieStore.KEY_IPD_MEMBER_ID, ipbMemberId);
    addCookiePair(EhCookieStore.KEY_IPD_PASS_HASH, ipbPassHash);

    if (igneous && igneous.length > 0) {
      addCookiePair(EhCookieStore.KEY_IGNEOUS, igneous);
    }
  }

  /**
   * Fetch the user profile (display name and avatar) from the forums page.
   * Typically called after a successful sign-in.
   */
  async getProfile(): Promise<ProfileResult> {
    // Step 1: fetch forums page to get profile URL
    const forumsUrl = EhUrl.URL_FORUMS;
    const forumsResponse = await this.httpClient.get(forumsUrl);
    const profileUrl = ForumsParser.parse(forumsResponse.body);

    // Step 2: fetch profile page
    const profileResponse = await this.httpClient.get(profileUrl, buildEhHeaders(forumsUrl));
    return ProfileParser.parse(profileResponse.body);
  }

  // ---- Validation helpers (same logic as Java CookieSignInScene) ----

  /** Check if ipb_member_id is all digits. */
  static isValidMemberId(id: string): boolean {
    if (id.length === 0) return false;
    for (let i = 0; i < id.length; i++) {
      const ch = id.charCodeAt(i);
      if (ch < 0x30 || ch > 0x39) return false; // '0' - '9'
    }
    return true;
  }

  /** Check if ipb_pass_hash is a 32-char lowercase hex string. */
  static isValidPassHash(hash: string): boolean {
    if (hash.length !== 32) return false;
    for (let i = 0; i < hash.length; i++) {
      const ch = hash.charCodeAt(i);
      const isDigit = ch >= 0x30 && ch <= 0x39;      // '0'-'9'
      const isLowerHex = ch >= 0x61 && ch <= 0x7A;    // 'a'-'z'
      if (!isDigit && !isLowerHex) return false;
    }
    return true;
  }

  /** Build a persistent cookie for a given domain. */
  private static buildCookie(name: string, value: string, domain: string): Cookie {
    return new CookieBuilder()
      .name(name)
      .value(value)
      .domain(domain)
      .path('/')
      .expiresAt(MAX_EXPIRES)
      .build();
  }
}
