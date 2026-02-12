/*
 * Copyright 2017 Hippo Seven
 * Ported to HarmonyOS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import type { Cookie } from './Cookie.ets';
import { cookieKey, cookieMatchesUrl } from './Cookie.ets';

/**
 * A set of cookies keyed by (name, domain, path).
 * Adding a cookie with the same key replaces the existing one.
 */
export class CookieSet {
  private map: Map<string, Cookie> = new Map();

  /**
   * Add a cookie. Returns the previously stored cookie with the same key,
   * or null if there was none.
   */
  add(cookie: Cookie): Cookie | null {
    const key = cookieKey(cookie);
    const old = this.map.get(key) ?? null;
    this.map.set(key, cookie);
    return old;
  }

  /**
   * Remove the cookie matching by (name, domain, path).
   * Returns the removed cookie or null.
   */
  remove(cookie: Cookie): Cookie | null {
    const key = cookieKey(cookie);
    const old = this.map.get(key) ?? null;
    if (old) this.map.delete(key);
    return old;
  }

  /**
   * Collect cookies matching the URL into `accepted`,
   * and expired cookies into `expired`. Expired cookies are also removed.
   */
  get(url: URL, accepted: Cookie[], expired: Cookie[]): void {
    const now = Date.now();
    for (const [key, cookie] of this.map.entries()) {
      if (cookie.expiresAt <= now) {
        this.map.delete(key);
        expired.push(cookie);
      } else if (cookieMatchesUrl(cookie, url)) {
        accepted.push(cookie);
      }
    }
  }

  size(): number {
    return this.map.size;
  }

  /** Get all cookies (for testing / serialization). */
  getAll(): Cookie[] {
    return Array.from(this.map.values());
  }
}
