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

// ---- Cookie data model ----

export interface Cookie {
  readonly name: string;
  readonly value: string;
  /** Expiry timestamp in milliseconds since epoch. */
  readonly expiresAt: number;
  readonly domain: string;
  readonly path: string;
  readonly secure: boolean;
  readonly httpOnly: boolean;
  /** Whether the cookie was set with an explicit Expires/Max-Age. */
  readonly persistent: boolean;
  /** Whether the cookie is restricted to the exact domain (no leading dot). */
  readonly hostOnly: boolean;
}

/** Sentinel value for cookies that never expire. */
export const MAX_EXPIRES: number = 253402300799999; // ~9999-12-31

// ---- Builder ----

export class CookieBuilder {
  private _name: string = '';
  private _value: string = '';
  private _expiresAt: number = MAX_EXPIRES;
  private _domain: string = '';
  private _path: string = '/';
  private _secure: boolean = false;
  private _httpOnly: boolean = false;
  private _persistent: boolean = false;
  private _hostOnly: boolean = false;

  name(n: string): CookieBuilder { this._name = n; return this; }
  value(v: string): CookieBuilder { this._value = v; return this; }
  expiresAt(t: number): CookieBuilder { this._expiresAt = t; this._persistent = true; return this; }
  domain(d: string): CookieBuilder { this._domain = d; this._hostOnly = false; return this; }
  hostOnlyDomain(d: string): CookieBuilder { this._domain = d; this._hostOnly = true; return this; }
  path(p: string): CookieBuilder { this._path = p; return this; }
  secure(): CookieBuilder { this._secure = true; return this; }
  httpOnly(): CookieBuilder { this._httpOnly = true; return this; }

  build(): Cookie {
    return {
      name: this._name,
      value: this._value,
      expiresAt: this._expiresAt,
      domain: this._domain,
      path: this._path,
      secure: this._secure,
      httpOnly: this._httpOnly,
      persistent: this._persistent,
      hostOnly: this._hostOnly,
    };
  }
}

// ---- Cookie key (for deduplication) ----

export function cookieKey(cookie: Cookie): string {
  return `${cookie.name}\0${cookie.domain}\0${cookie.path}`;
}

// ---- Domain matching (RFC 6265 §5.1.3 / okhttp3) ----

const VERIFY_AS_IP_ADDRESS = /^([0-9a-fA-F]*:[0-9a-fA-F:.]*|[\d.]+)$/;

function verifyAsIpAddress(host: string): boolean {
  return VERIFY_AS_IP_ADDRESS.test(host);
}

export function domainMatch(urlHost: string, cookieDomain: string): boolean {
  if (urlHost === cookieDomain) {
    return true;
  }
  if (
    urlHost.endsWith(cookieDomain) &&
    urlHost.charAt(urlHost.length - cookieDomain.length - 1) === '.' &&
    !verifyAsIpAddress(urlHost)
  ) {
    return true;
  }
  return false;
}

// ---- Path matching (RFC 6265 §5.1.4) ----

export function pathMatch(requestPath: string, cookiePath: string): boolean {
  if (requestPath === cookiePath) return true;
  if (requestPath.startsWith(cookiePath)) {
    if (cookiePath.endsWith('/')) return true;
    if (requestPath.charAt(cookiePath.length) === '/') return true;
  }
  return false;
}

// ---- Cookie matches URL ----

export function cookieMatchesUrl(cookie: Cookie, url: URL): boolean {
  const host = url.hostname;
  if (cookie.hostOnly) {
    if (host !== cookie.domain) return false;
  } else {
    if (!domainMatch(host, cookie.domain)) return false;
  }
  if (!pathMatch(url.pathname, cookie.path)) return false;
  if (cookie.secure && url.protocol !== 'https:') return false;
  return true;
}

// ---- Format Cookie header value ----

export function formatCookieHeader(cookies: Cookie[]): string {
  return cookies.map(c => `${c.name}=${c.value}`).join('; ');
}

// ---- Parse Set-Cookie header ----

/**
 * Parse a single Set-Cookie header string into a Cookie.
 * Returns null if the header is invalid.
 */
export function parseSetCookie(urlStr: string, header: string): Cookie | null {
  const url = safeParseUrl(urlStr);
  if (!url) return null;

  const parts = header.split(';').map(s => s.trim());
  if (parts.length === 0) return null;

  // First part is name=value
  const nameValue = parts[0];
  const eqIdx = nameValue.indexOf('=');
  if (eqIdx <= 0) return null;

  const name = nameValue.substring(0, eqIdx).trim();
  const value = nameValue.substring(eqIdx + 1).trim();

  if (name.length === 0) return null;

  let expiresAt: number = MAX_EXPIRES;
  let domain: string = '';
  let path: string = '';
  let secure: boolean = false;
  let httpOnly: boolean = false;
  let persistent: boolean = false;
  let hostOnly: boolean = true;
  let maxAgeSet: boolean = false;

  for (let i = 1; i < parts.length; i++) {
    const attr = parts[i];
    const attrEq = attr.indexOf('=');
    let attrName: string;
    let attrValue: string;
    if (attrEq >= 0) {
      attrName = attr.substring(0, attrEq).trim().toLowerCase();
      attrValue = attr.substring(attrEq + 1).trim();
    } else {
      attrName = attr.toLowerCase();
      attrValue = '';
    }

    switch (attrName) {
      case 'expires':
        if (!maxAgeSet) {
          const ts = Date.parse(attrValue);
          if (!isNaN(ts)) {
            expiresAt = ts;
            persistent = true;
          }
        }
        break;
      case 'max-age': {
        const seconds = parseInt(attrValue, 10);
        if (!isNaN(seconds)) {
          maxAgeSet = true;
          persistent = true;
          expiresAt = seconds <= 0 ? 0 : Date.now() + seconds * 1000;
        }
        break;
      }
      case 'domain':
        // Remove leading dot per RFC 6265
        domain = attrValue.startsWith('.') ? attrValue.substring(1) : attrValue;
        domain = domain.toLowerCase();
        hostOnly = false;
        break;
      case 'path':
        path = attrValue;
        break;
      case 'secure':
        secure = true;
        break;
      case 'httponly':
        httpOnly = true;
        break;
    }
  }

  // Default domain to the request host
  if (domain.length === 0) {
    domain = url.hostname;
    hostOnly = true;
  } else {
    // Verify domain matches the request URL
    if (!domainMatch(url.hostname, domain)) {
      return null;
    }
  }

  // Default path
  if (path.length === 0 || !path.startsWith('/')) {
    path = defaultPath(url.pathname);
  }

  return {
    name, value, expiresAt, domain, path,
    secure, httpOnly, persistent, hostOnly,
  };
}

/**
 * Parse potentially multiple Set-Cookie headers.
 * Handles newline-separated values (common when HTTP libraries concatenate headers).
 */
export function parseSetCookieHeaders(urlStr: string, headerValue: string): Cookie[] {
  const cookies: Cookie[] = [];
  const lines = headerValue.split('\n');
  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed.length > 0) {
      const cookie = parseSetCookie(urlStr, trimmed);
      if (cookie) cookies.push(cookie);
    }
  }
  return cookies;
}

// ---- Helpers ----

function defaultPath(requestPath: string): string {
  if (!requestPath.startsWith('/')) return '/';
  const lastSlash = requestPath.lastIndexOf('/');
  if (lastSlash === 0) return '/';
  return requestPath.substring(0, lastSlash);
}

function safeParseUrl(urlStr: string): URL | null {
  try {
    return new URL(urlStr);
  } catch {
    return null;
  }
}
