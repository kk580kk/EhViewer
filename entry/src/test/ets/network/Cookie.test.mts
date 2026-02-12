import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  CookieBuilder,
  cookieKey,
  domainMatch,
  pathMatch,
  cookieMatchesUrl,
  formatCookieHeader,
  parseSetCookie,
  parseSetCookieHeaders,
  MAX_EXPIRES,
} from '../../../main/ets/network/Cookie.ets';
import type { Cookie } from '../../../main/ets/network/Cookie.ets';

// ---- CookieBuilder ----

describe('CookieBuilder', () => {
  it('should build a cookie with defaults', () => {
    const c = new CookieBuilder().name('sid').value('abc').domain('example.com').build();
    assert.strictEqual(c.name, 'sid');
    assert.strictEqual(c.value, 'abc');
    assert.strictEqual(c.domain, 'example.com');
    assert.strictEqual(c.path, '/');
    assert.strictEqual(c.secure, false);
    assert.strictEqual(c.httpOnly, false);
    assert.strictEqual(c.persistent, false);
    assert.strictEqual(c.hostOnly, false);
    assert.strictEqual(c.expiresAt, MAX_EXPIRES);
  });

  it('should build a host-only cookie', () => {
    const c = new CookieBuilder().name('x').value('y').hostOnlyDomain('h.com').build();
    assert.strictEqual(c.hostOnly, true);
    assert.strictEqual(c.domain, 'h.com');
  });

  it('should mark persistent when expiresAt is set', () => {
    const c = new CookieBuilder().name('x').value('y').domain('d.com')
      .expiresAt(Date.now() + 3600_000).build();
    assert.strictEqual(c.persistent, true);
  });

  it('should set secure and httpOnly flags', () => {
    const c = new CookieBuilder().name('x').value('y').domain('d.com')
      .secure().httpOnly().build();
    assert.strictEqual(c.secure, true);
    assert.strictEqual(c.httpOnly, true);
  });
});

// ---- cookieKey ----

describe('cookieKey', () => {
  it('should produce a unique key from name, domain, path', () => {
    const c = new CookieBuilder().name('sid').value('1').domain('a.com').path('/foo').build();
    assert.strictEqual(cookieKey(c), 'sid\0a.com\0/foo');
  });
});

// ---- domainMatch ----

describe('domainMatch', () => {
  it('should match exact domain', () => {
    assert.strictEqual(domainMatch('example.com', 'example.com'), true);
  });

  it('should match subdomain', () => {
    assert.strictEqual(domainMatch('www.example.com', 'example.com'), true);
  });

  it('should not match unrelated domain', () => {
    assert.strictEqual(domainMatch('other.com', 'example.com'), false);
  });

  it('should not match partial suffix', () => {
    assert.strictEqual(domainMatch('notexample.com', 'example.com'), false);
  });

  it('should not match for IP addresses', () => {
    assert.strictEqual(domainMatch('192.168.1.1', '1.1'), false);
  });
});

// ---- pathMatch ----

describe('pathMatch', () => {
  it('should match exact path', () => {
    assert.strictEqual(pathMatch('/foo', '/foo'), true);
  });

  it('should match subpath', () => {
    assert.strictEqual(pathMatch('/foo/bar', '/foo'), true);
  });

  it('should match root path', () => {
    assert.strictEqual(pathMatch('/anything', '/'), true);
  });

  it('should not match unrelated path', () => {
    assert.strictEqual(pathMatch('/bar', '/foo'), false);
  });
});

// ---- cookieMatchesUrl ----

describe('cookieMatchesUrl', () => {
  it('should match when domain and path match', () => {
    const c = new CookieBuilder().name('s').value('1').domain('example.com').path('/').build();
    assert.strictEqual(cookieMatchesUrl(c, new URL('https://www.example.com/page')), true);
  });

  it('should not match secure cookie on http', () => {
    const c = new CookieBuilder().name('s').value('1').domain('example.com').path('/')
      .secure().build();
    assert.strictEqual(cookieMatchesUrl(c, new URL('http://example.com/')), false);
  });

  it('should match host-only cookie only for exact host', () => {
    const c = new CookieBuilder().name('s').value('1').hostOnlyDomain('example.com').build();
    assert.strictEqual(cookieMatchesUrl(c, new URL('https://example.com/')), true);
    assert.strictEqual(cookieMatchesUrl(c, new URL('https://www.example.com/')), false);
  });
});

// ---- formatCookieHeader ----

describe('formatCookieHeader', () => {
  it('should format cookies as header value', () => {
    const cookies: Cookie[] = [
      new CookieBuilder().name('a').value('1').domain('d').build(),
      new CookieBuilder().name('b').value('2').domain('d').build(),
    ];
    assert.strictEqual(formatCookieHeader(cookies), 'a=1; b=2');
  });

  it('should return empty string for empty array', () => {
    assert.strictEqual(formatCookieHeader([]), '');
  });
});

// ---- parseSetCookie ----

describe('parseSetCookie', () => {
  it('should parse a simple Set-Cookie header', () => {
    const c = parseSetCookie('https://example.com/path', 'sid=abc123');
    assert.ok(c !== null);
    assert.strictEqual(c!.name, 'sid');
    assert.strictEqual(c!.value, 'abc123');
    assert.strictEqual(c!.domain, 'example.com');
    assert.strictEqual(c!.hostOnly, true);
  });

  it('should parse domain attribute', () => {
    const c = parseSetCookie('https://www.example.com/', 'x=y; Domain=.example.com');
    assert.ok(c !== null);
    assert.strictEqual(c!.domain, 'example.com');
    assert.strictEqual(c!.hostOnly, false);
  });

  it('should parse Expires attribute', () => {
    const c = parseSetCookie('https://example.com/', 'x=y; Expires=Thu, 01 Jan 2099 00:00:00 GMT');
    assert.ok(c !== null);
    assert.strictEqual(c!.persistent, true);
    assert.ok(c!.expiresAt > Date.now());
  });

  it('should parse Max-Age attribute', () => {
    const c = parseSetCookie('https://example.com/', 'x=y; Max-Age=3600');
    assert.ok(c !== null);
    assert.strictEqual(c!.persistent, true);
    assert.ok(c!.expiresAt > Date.now());
    assert.ok(c!.expiresAt <= Date.now() + 3600_000 + 1000);
  });

  it('should parse Secure and HttpOnly', () => {
    const c = parseSetCookie('https://example.com/', 'x=y; Secure; HttpOnly');
    assert.ok(c !== null);
    assert.strictEqual(c!.secure, true);
    assert.strictEqual(c!.httpOnly, true);
  });

  it('should parse Path attribute', () => {
    const c = parseSetCookie('https://example.com/foo/bar', 'x=y; Path=/foo');
    assert.ok(c !== null);
    assert.strictEqual(c!.path, '/foo');
  });

  it('should return null for invalid header', () => {
    assert.strictEqual(parseSetCookie('https://example.com/', ''), null);
    assert.strictEqual(parseSetCookie('https://example.com/', '=value'), null);
  });

  it('should return null for invalid URL', () => {
    assert.strictEqual(parseSetCookie('not-a-url', 'x=y'), null);
  });

  it('should reject domain that does not match URL', () => {
    const c = parseSetCookie('https://a.com/', 'x=y; Domain=b.com');
    assert.strictEqual(c, null);
  });

  it('should Max-Age override Expires', () => {
    const c = parseSetCookie(
      'https://example.com/',
      'x=y; Expires=Thu, 01 Jan 1970 00:00:00 GMT; Max-Age=3600'
    );
    assert.ok(c !== null);
    assert.ok(c!.expiresAt > Date.now()); // Max-Age wins
  });
});

// ---- parseSetCookieHeaders ----

describe('parseSetCookieHeaders', () => {
  it('should parse newline-separated cookies', () => {
    const headers = 'a=1; Path=/\nb=2; Path=/';
    const cookies = parseSetCookieHeaders('https://example.com/', headers);
    assert.strictEqual(cookies.length, 2);
    assert.strictEqual(cookies[0].name, 'a');
    assert.strictEqual(cookies[1].name, 'b');
  });

  it('should skip invalid lines', () => {
    const headers = 'a=1\n\n=bad\nb=2';
    const cookies = parseSetCookieHeaders('https://example.com/', headers);
    assert.strictEqual(cookies.length, 2);
  });

  it('should return empty array for empty input', () => {
    assert.strictEqual(parseSetCookieHeaders('https://example.com/', '').length, 0);
  });
});
