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

import { formatCookieHeader, parseSetCookieHeaders } from './Cookie.ets';
import type { CookieJar } from './CookieRepository.ets';
import { StatusCodeException } from './StatusCodeException.ets';
import type { RetryStrategy } from './RetryInterceptor.ets';
import { sleep } from './RetryInterceptor.ets';

// ---- Constants ----

const CHROME_USER_AGENT =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) ' +
  'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36';

const CHROME_ACCEPT =
  'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8';

const CHROME_ACCEPT_LANGUAGE = 'en-US,en;q=0.5';

const DEFAULT_TIMEOUT_MS = 30_000;

// ---- Public types ----

export type HttpMethod = 'GET' | 'POST' | 'PUT' | 'DELETE';

/** Key-value pair for headers or form fields. */
export interface KV {
  key: string;
  value: string;
}

/** A single part in a multipart request. */
export interface MultipartPart {
  name: string;
  filename?: string;
  contentType?: string;
  /** String value or binary data (Uint8Array). */
  data: string | Uint8Array;
}

/** Describes the body of an HTTP request. */
export interface HttpRequestBody {
  type: 'json' | 'form' | 'multipart' | 'raw';
  /** JSON string for 'json', ignored for 'form'/'multipart'. */
  content?: string;
  /** Content-Type override (auto-set for json/form/multipart). */
  contentType?: string;
  /** Fields for 'form' body. */
  formFields?: KV[];
  /** Parts for 'multipart' body. */
  parts?: MultipartPart[];
}

/** Full HTTP request descriptor. */
export interface HttpRequest {
  url: string;
  method: HttpMethod;
  headers?: Record<string, string>;
  body?: HttpRequestBody;
  connectTimeoutMs?: number;
  readTimeoutMs?: number;
}

/** Full HTTP response descriptor. */
export interface HttpResponse {
  statusCode: number;
  headers: Record<string, string>;
  body: string;
}

/**
 * Low-level transport abstraction.
 *
 * Production: backed by @ohos.net.http.
 * Tests: replaced by a mock.
 */
export interface HttpEngine {
  /**
   * Execute a fully-resolved request and return the response.
   * Must reject on network-level errors.
   */
  execute(request: HttpRequest): Promise<HttpResponse>;

  /** Release resources (e.g. destroy the @ohos.net.http session). */
  destroy?(): void;
}

// ---- Redirect constants ----

const DEFAULT_MAX_REDIRECTS = 20;

const REDIRECT_CODES: ReadonlySet<number> = new Set([301, 302, 303, 307, 308]);

/**
 * Status codes where the HTTP spec requires POST→GET conversion.
 * 301/302 are technically "MAY" but all major browsers and OkHttp convert.
 * 303 "MUST" convert.
 */
const POST_TO_GET_CODES: ReadonlySet<number> = new Set([301, 302, 303]);

// ---- HttpClient ----

export class HttpClient {
  private engine: HttpEngine;
  private defaultHeaders: Record<string, string>;
  private connectTimeoutMs: number;
  private readTimeoutMs: number;
  private cookieJar: CookieJar | null;
  private throwOnErrorStatus: boolean;
  private maxRedirects: number;
  private retryStrategy: RetryStrategy | null;

  constructor(options: {
    engine: HttpEngine;
    defaultHeaders?: Record<string, string>;
    connectTimeoutMs?: number;
    readTimeoutMs?: number;
    cookieJar?: CookieJar;
    /**
     * When true (default), automatically throw StatusCodeException
     * for HTTP responses with status code >= 400.
     */
    throwOnErrorStatus?: boolean;
    /**
     * Maximum number of redirects to follow (default 20, matching OkHttp).
     * Set to 0 to disable redirect following.
     */
    maxRedirects?: number;
    /**
     * Optional retry strategy for transient failures.
     * When set, failed requests are retried according to the strategy.
     * Matches Android SpiderQueen retry behaviour (e.g. 5xx retried, 509 never retried).
     */
    retryStrategy?: RetryStrategy;
  }) {
    this.engine = options.engine;
    this.connectTimeoutMs = options.connectTimeoutMs ?? DEFAULT_TIMEOUT_MS;
    this.readTimeoutMs = options.readTimeoutMs ?? DEFAULT_TIMEOUT_MS;
    this.cookieJar = options.cookieJar ?? null;
    this.throwOnErrorStatus = options.throwOnErrorStatus ?? true;
    this.maxRedirects = options.maxRedirects ?? DEFAULT_MAX_REDIRECTS;
    this.retryStrategy = options.retryStrategy ?? null;
    this.defaultHeaders = {
      'User-Agent': CHROME_USER_AGENT,
      'Accept': CHROME_ACCEPT,
      'Accept-Language': CHROME_ACCEPT_LANGUAGE,
      ...options.defaultHeaders,
    };
  }

  /** Replace the engine at runtime (useful for testing). */
  setEngine(engine: HttpEngine): void {
    this.engine = engine;
  }

  /** Replace the cookie jar at runtime. */
  setCookieJar(jar: CookieJar | null): void {
    this.cookieJar = jar;
  }

  /** Replace the retry strategy at runtime. */
  setRetryStrategy(strategy: RetryStrategy | null): void {
    this.retryStrategy = strategy;
  }

  /** Send a fully customised request. */
  async execute(request: HttpRequest): Promise<HttpResponse> {
    if (this.retryStrategy) {
      return this.executeWithRetry(request);
    }
    return this.executeWithRedirects(request);
  }

  /**
   * Execute with retry logic wrapping the redirect-aware execution.
   * On failure, consults the RetryStrategy to decide whether to retry.
   */
  private async executeWithRetry(request: HttpRequest): Promise<HttpResponse> {
    let attempt = 0;
    // eslint-disable-next-line no-constant-condition
    while (true) {
      try {
        return await this.executeWithRedirects(request);
      } catch (error: unknown) {
        const delayMs = this.retryStrategy!.shouldRetry(attempt, error);
        if (delayMs < 0) {
          throw error;
        }
        if (delayMs > 0) {
          await sleep(delayMs);
        }
        attempt++;
      }
    }
  }

  /**
   * Execute with redirect following (original execute logic).
   */
  private async executeWithRedirects(request: HttpRequest): Promise<HttpResponse> {
    let currentUrl = request.url;
    let currentMethod = request.method;
    let currentBody = request.body;
    let redirectCount = 0;

    // eslint-disable-next-line no-constant-condition
    while (true) {
      const response = await this.executeOnce({
        ...request,
        url: currentUrl,
        method: currentMethod,
        body: currentBody,
      });

      // Check for redirects
      if (
        this.maxRedirects > 0 &&
        REDIRECT_CODES.has(response.statusCode)
      ) {
        const location = response.headers['Location'] ?? response.headers['location'];
        if (location && location.length > 0) {
          redirectCount++;
          if (redirectCount > this.maxRedirects) {
            throw new Error(`Too many redirects (max ${this.maxRedirects})`);
          }

          // Resolve relative URL against current URL
          currentUrl = resolveUrl(currentUrl, location);

          // POST→GET conversion for 301/302/303
          if (POST_TO_GET_CODES.has(response.statusCode) && currentMethod === 'POST') {
            currentMethod = 'GET';
            currentBody = undefined;
          }

          // 307/308 preserve the method and body
          continue;
        }
      }

      // Not a redirect — apply error handling and return
      if (this.throwOnErrorStatus && response.statusCode >= 400) {
        throw new StatusCodeException(response.statusCode, currentUrl);
      }

      return response;
    }
  }

  /**
   * Execute a single HTTP request (no redirect following).
   * Handles cookie attach/save for this hop.
   */
  private async executeOnce(request: HttpRequest): Promise<HttpResponse> {
    const headers: Record<string, string> = {
      ...this.defaultHeaders,
      ...request.headers,
    };

    // Attach cookies from the jar
    if (this.cookieJar) {
      const cookies = this.cookieJar.loadForRequest(request.url);
      if (cookies.length > 0) {
        headers['Cookie'] = formatCookieHeader(cookies);
      }
    }

    const merged: HttpRequest = {
      ...request,
      connectTimeoutMs: request.connectTimeoutMs ?? this.connectTimeoutMs,
      readTimeoutMs: request.readTimeoutMs ?? this.readTimeoutMs,
      headers,
    };

    const response = await this.engine.execute(merged);

    // Save cookies from the response
    if (this.cookieJar) {
      const setCookie =
        response.headers['Set-Cookie'] ??
        response.headers['set-cookie'] ??
        '';
      if (setCookie.length > 0) {
        const parsed = parseSetCookieHeaders(request.url, setCookie);
        if (parsed.length > 0) {
          this.cookieJar.saveFromResponse(request.url, parsed);
        }
      }
    }

    return response;
  }

  // ---- Convenience methods ----

  async get(url: string, headers?: Record<string, string>): Promise<HttpResponse> {
    return this.execute({ url, method: 'GET', headers });
  }

  async postForm(url: string, fields: KV[], headers?: Record<string, string>): Promise<HttpResponse> {
    return this.execute({
      url,
      method: 'POST',
      headers,
      body: { type: 'form', formFields: fields },
    });
  }

  async postJson(url: string, json: string, headers?: Record<string, string>): Promise<HttpResponse> {
    return this.execute({
      url,
      method: 'POST',
      headers,
      body: { type: 'json', content: json },
    });
  }

  async postMultipart(url: string, parts: MultipartPart[], headers?: Record<string, string>): Promise<HttpResponse> {
    return this.execute({
      url,
      method: 'POST',
      headers,
      body: { type: 'multipart', parts },
    });
  }

  async postRaw(url: string, content: string, contentType: string, headers?: Record<string, string>): Promise<HttpResponse> {
    return this.execute({
      url,
      method: 'POST',
      headers,
      body: { type: 'raw', content, contentType },
    });
  }

  async put(url: string, json: string, headers?: Record<string, string>): Promise<HttpResponse> {
    return this.execute({
      url,
      method: 'PUT',
      headers,
      body: { type: 'json', content: json },
    });
  }

  async delete(url: string, headers?: Record<string, string>): Promise<HttpResponse> {
    return this.execute({ url, method: 'DELETE', headers });
  }
}

// ---- Form encoding helper ----

/**
 * Encode form fields into `application/x-www-form-urlencoded` body string.
 * Exported so the engine implementations can reuse it.
 */
export function encodeFormFields(fields: KV[]): string {
  return fields
    .map(f => `${encodeURIComponent(f.key)}=${encodeURIComponent(f.value)}`)
    .join('&');
}

/**
 * Build a multipart/form-data body manually.
 * Returns { contentType, payload } where payload is the full body string.
 */
export function buildMultipartBody(boundary: string, parts: MultipartPart[]): { contentType: string; payload: string } {
  const lines: string[] = [];
  for (const part of parts) {
    lines.push(`--${boundary}`);
    let disposition = `Content-Disposition: form-data; name="${part.name}"`;
    if (part.filename) {
      disposition += `; filename="${part.filename}"`;
    }
    lines.push(disposition);
    if (part.contentType) {
      lines.push(`Content-Type: ${part.contentType}`);
    }
    lines.push('');
    lines.push(typeof part.data === 'string' ? part.data : uint8ArrayToString(part.data));
  }
  lines.push(`--${boundary}--`);
  return {
    contentType: `multipart/form-data; boundary=${boundary}`,
    payload: lines.join('\r\n'),
  };
}

function uint8ArrayToString(arr: Uint8Array): string {
  const chunks: string[] = [];
  for (let i = 0; i < arr.length; i++) {
    chunks.push(String.fromCharCode(arr[i]));
  }
  return chunks.join('');
}

/**
 * Generate a random boundary string for multipart bodies.
 */
export function generateBoundary(): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result = '----EhViewerBoundary';
  for (let i = 0; i < 16; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

// ---- URL resolution helper ----

/**
 * Resolve a potentially relative URL against a base URL.
 * Handles absolute URLs, protocol-relative, and path-relative redirects.
 */
export function resolveUrl(base: string, target: string): string {
  // Already absolute
  if (target.startsWith('http://') || target.startsWith('https://')) {
    return target;
  }

  try {
    return new URL(target, base).href;
  } catch {
    // Fallback: return target as-is if URL parsing fails
    return target;
  }
}

// ---- EhRequestBuilder helper ----

/**
 * Build standard EhViewer request headers (Referer + Origin),
 * mirroring the Java `EhRequestBuilder`.
 */
export function buildEhHeaders(referer?: string, origin?: string): Record<string, string> {
  const h: Record<string, string> = {};
  if (referer) h['Referer'] = referer;
  if (origin) h['Origin'] = origin;
  return h;
}
