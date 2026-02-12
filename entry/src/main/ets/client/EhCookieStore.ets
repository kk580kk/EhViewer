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
import { EhUrl } from './EhUrl.ets';

export class EhCookieStore extends CookieRepository {
  static readonly KEY_IPD_MEMBER_ID: string = 'ipb_member_id';
  static readonly KEY_IPD_PASS_HASH: string = 'ipb_pass_hash';
  static readonly KEY_IGNEOUS: string = 'igneous';

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
      // Skip content warning and uconfig cookies
      if (cookie.name === EhConfig.KEY_CONTENT_WARNING) continue;
      if (cookie.name === EhConfig.KEY_UCONFIG) continue;
      result.push(cookie);
    }
    // Always add the tips cookie to suppress the content warning
    result.push(EhCookieStore.TIPS_COOKIE);
    return result;
  }
}
