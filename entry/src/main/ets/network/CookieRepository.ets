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
import { domainMatch, formatCookieHeader } from './Cookie.ets';
import { CookieSet } from './CookieSet.ets';

// ---- Persistence interface ----

/**
 * Abstraction for cookie persistence.
 * Production: backed by Preferences or RelationalStore.
 * Tests: use MemoryCookiePersistence.
 */
export interface CookiePersistence {
  loadAll(): Cookie[];
  add(cookie: Cookie): void;
  update(from: Cookie, to: Cookie): void;
  remove(cookie: Cookie): void;
  clear(): void;
}

/** In-memory persistence for testing or session-only cookies. */
export class MemoryCookiePersistence implements CookiePersistence {
  private cookies: Cookie[] = [];

  loadAll(): Cookie[] {
    const now = Date.now();
    // Filter out non-persistent and expired cookies on load
    this.cookies = this.cookies.filter(c => c.persistent && c.expiresAt > now);
    return [...this.cookies];
  }

  add(cookie: Cookie): void {
    this.cookies.push(cookie);
  }

  update(from: Cookie, to: Cookie): void {
    const idx = this.cookies.findIndex(c => cookieEquals(c, from));
    if (idx >= 0) {
      this.cookies[idx] = to;
    }
  }

  remove(cookie: Cookie): void {
    const idx = this.cookies.findIndex(c => cookieEquals(c, cookie));
    if (idx >= 0) {
      this.cookies.splice(idx, 1);
    }
  }

  clear(): void {
    this.cookies = [];
  }
}

function cookieEquals(a: Cookie, b: Cookie): boolean {
  return a.name === b.name && a.domain === b.domain && a.path === b.path &&
    a.value === b.value && a.expiresAt === b.expiresAt;
}

// ---- CookieJar interface ----

export interface CookieJar {
  saveFromResponse(url: string, cookies: Cookie[]): void;
  loadForRequest(url: string): Cookie[];
}

// ---- CookieRepository ----

export class CookieRepository implements CookieJar {
  private map: Map<string, CookieSet> = new Map();
  private db: CookiePersistence;

  constructor(db: CookiePersistence) {
    this.db = db;
    this.loadFromPersistence();
  }

  private loadFromPersistence(): void {
    const all = this.db.loadAll();
    for (const cookie of all) {
      let set = this.map.get(cookie.domain);
      if (!set) {
        set = new CookieSet();
        this.map.set(cookie.domain, set);
      }
      set.add(cookie);
    }
  }

  addCookie(cookie: Cookie): void {
    let toAdd: Cookie | null = null;
    let toUpdate: Cookie | null = null;
    let toRemove: Cookie | null = null;

    let set = this.map.get(cookie.domain);
    if (!set) {
      set = new CookieSet();
      this.map.set(cookie.domain, set);
    }

    if (cookie.expiresAt <= Date.now()) {
      toRemove = set.remove(cookie);
      // If the cookie is not persistent, it's not in database
      if (toRemove && !toRemove.persistent) {
        toRemove = null;
      }
    } else {
      toAdd = cookie;
      toUpdate = set.add(cookie);
      // If the cookie is not persistent, it's not in database
      if (!toAdd.persistent) toAdd = null;
      if (toUpdate && !toUpdate.persistent) toUpdate = null;
      // Remove the cookie if it updates to null
      if (!toAdd && toUpdate) {
        toRemove = toUpdate;
        toUpdate = null;
      }
    }

    if (toRemove) {
      this.db.remove(toRemove);
    }
    if (toAdd) {
      if (toUpdate) {
        this.db.update(toUpdate, toAdd);
      } else {
        this.db.add(toAdd);
      }
    }
  }

  getCookieHeader(url: string): string {
    return formatCookieHeader(this.getCookies(url));
  }

  getCookies(url: string): Cookie[] {
    let parsed: URL;
    try {
      parsed = new URL(url);
    } catch {
      return [];
    }

    const accepted: Cookie[] = [];
    const expired: Cookie[] = [];

    for (const [domain, cookieSet] of this.map.entries()) {
      if (domainMatch(parsed.hostname, domain)) {
        cookieSet.get(parsed, accepted, expired);
      }
    }

    for (const cookie of expired) {
      if (cookie.persistent) {
        this.db.remove(cookie);
      }
    }

    // RFC 6265 §5.4 step 2: sort by path length descending
    accepted.sort((a, b) => b.path.length - a.path.length);
    return accepted;
  }

  contains(url: string, name: string): boolean {
    return this.getCookies(url).some(c => c.name === name);
  }

  clear(): void {
    this.map.clear();
    this.db.clear();
  }

  // ---- CookieJar interface ----

  saveFromResponse(url: string, cookies: Cookie[]): void {
    for (const cookie of cookies) {
      this.addCookie(cookie);
    }
  }

  loadForRequest(url: string): Cookie[] {
    return this.getCookies(url);
  }

  /** Expose domain map for testing. */
  _getMap(): Map<string, CookieSet> {
    return this.map;
  }
}
