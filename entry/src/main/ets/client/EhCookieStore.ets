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

import type { Cookie } from '../network/Cookie.ets';
import {
  CookieBuilder,
  MAX_EXPIRES,
  domainMatch,
} from '../network/Cookie.ets';
import {
  CookieRepository,
} from '../network/CookieRepository.ets';
import type { CookiePersistence } from '../network/CookieRepository.ets';
import { EhConfig } from './EhConfig.ets';
import { EhConfigHolder } from './EhConfigHolder.ets';
import { EhUrl } from './EhUrl.ets';

export class EhCookieStore extends CookieRepository {
  static readonly KEY_IPD_MEMBER_ID: string = 'ipb_member_id';
  static readonly KEY_IPD_PASS_HASH: string = 'ipb_pass_hash';
  static readonly KEY_IGNEOUS: string = 'igneous';

  /** Auth cookie names that must be persisted even if the server sends them as session cookies. */
  private static readonly AUTH_COOKIE_NAMES: ReadonlySet<string> = new Set([
    EhCookieStore.KEY_IPD_MEMBER_ID,
    EhCookieStore.KEY_IPD_PASS_HASH,
    EhCookieStore.KEY_IGNEOUS,
  ]);

  /** Pre-built cookie that suppresses the content warning page. */
  static readonly TIPS_COOKIE: Cookie = new CookieBuilder()
    .name(EhConfig.KEY_CONTENT_WARNING)
    .value(EhConfig.CONTENT_WARNING_NOT_SHOW)
    .domain(EhUrl.DOMAIN_E)
    .path('/')
    .expiresAt(MAX_EXPIRES)
    .build();

  constructor(db: CookiePersistence) {
    super(db);
  }

  signOut(): void {
    this.clear();
  }

  hasSignedIn(): boolean {
    return (
      this.contains(EhUrl.HOST_E, EhCookieStore.KEY_IPD_MEMBER_ID) &&
      this.contains(EhUrl.HOST_E, EhCookieStore.KEY_IPD_PASS_HASH)
    );
  }

  /**
   * Ensures auth cookies from EH domains are persisted to the database,
   * even if the server sends them as session cookies (without Expires/Max-Age).
   */
  override saveFromResponse(url: string, cookies: Cookie[]): void {
    let hostname: string;
    try {
      hostname = new URL(url).hostname;
    } catch {
      super.saveFromResponse(url, cookies);
      return;
    }

    if (domainMatch(hostname, EhUrl.DOMAIN_E) || domainMatch(hostname, EhUrl.DOMAIN_EX)) {
      const processed: Cookie[] = cookies.map(cookie => {
        if (!cookie.persistent && EhCookieStore.AUTH_COOKIE_NAMES.has(cookie.name)) {
          return EhCookieStore.newCookie(cookie, cookie.domain, true, false, false);
        }
        return cookie;
      });
      super.saveFromResponse(url, processed);
    } else {
      super.saveFromResponse(url, cookies);
    }
  }

  /**
   * Clone a cookie with a new domain, optionally forcing persistence and long-lived expiry.
   */
  static newCookie(
    cookie: Cookie,
    newDomain: string,
    forcePersistent: boolean,
    forceLongLive: boolean,
    forceNotHostOnly: boolean,
  ): Cookie {
    const builder = new CookieBuilder()
      .name(cookie.name)
      .value(cookie.value)
      .path(cookie.path);

    if (forceLongLive) {
      builder.expiresAt(MAX_EXPIRES);
    } else if (cookie.persistent) {
      builder.expiresAt(cookie.expiresAt);
    } else if (forcePersistent) {
      builder.expiresAt(MAX_EXPIRES);
    }

    if (cookie.hostOnly && !forceNotHostOnly) {
      builder.hostOnlyDomain(newDomain);
    } else {
      builder.domain(newDomain);
    }

    if (cookie.secure) builder.secure();
    if (cookie.httpOnly) builder.httpOnly();

    return builder.build();
  }

  override loadForRequest(url: string): Cookie[] {
    const cookies = super.loadForRequest(url);

    let parsed: URL;
    try {
      parsed = new URL(url);
    } catch {
      return cookies;
    }

    const checkTips = domainMatch(parsed.hostname, EhUrl.DOMAIN_E);
    if (!checkTips) return cookies;

    const result: Cookie[] = [];
    for (const cookie of cookies) {
      // Skip content warning and uconfig cookies (we inject uconfig from EhConfig)
      if (cookie.name === EhConfig.KEY_CONTENT_WARNING) continue;
      if (cookie.name === EhConfig.KEY_UCONFIG) continue;
      result.push(cookie);
    }
    // Inject uconfig cookie from current EhConfig
    const ehConfig = EhConfigHolder.get();
    const domain = EhConfig.getGalleryDomain();
    result.push(new CookieBuilder()
      .name(EhConfig.KEY_UCONFIG)
      .value(ehConfig.uconfig())
      .domain(domain)
      .path('/')
      .expiresAt(MAX_EXPIRES)
      .build());
    // Always add the tips cookie to suppress the content warning
    result.push(EhCookieStore.TIPS_COOKIE);
    return result;
  }
}
