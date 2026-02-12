/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import {
  encodeFormFields,
  buildMultipartBody,
  generateBoundary,
} from './HttpClient.ets';
import type {
  HttpEngine,
  HttpRequest,
  HttpResponse,
} from './HttpClient.ets';

// ---- Abstraction over @ohos.net.http ----

/** Mirrors the request options accepted by @ohos.net.http. */
export interface OhosHttpRequestOptions {
  method: string;
  header?: Record<string, string>;
  extraData?: string;
  connectTimeout?: number;
  readTimeout?: number;
}

/** Mirrors the response returned by @ohos.net.http. */
export interface OhosHttpResponse {
  responseCode: number;
  header: Record<string, string>;
  result: string;
}

/**
 * Abstraction over an @ohos.net.http session.
 * Production: wraps http.createHttp().
 * Tests: replaced by a mock.
 */
export interface OhosHttpSession {
  request(url: string, options: OhosHttpRequestOptions): Promise<OhosHttpResponse>;
  destroy(): void;
}

/** Factory that creates a new OhosHttpSession per request. */
export type OhosHttpSessionFactory = () => OhosHttpSession;

// ---- Method mapping ----

/** Map our HttpMethod string to the @ohos.net.http method constant. */
function mapMethod(method: string): string {
  // @ohos.net.http uses the RequestMethod enum but accepts the string form too.
  // We pass the uppercase HTTP verb directly which is compatible.
  return method;
}

// ---- OhosHttpEngine ----

/**
 * HttpEngine implementation backed by @ohos.net.http.
 *
 * Each `execute()` call creates a new HTTP session, performs the request,
 * and destroys the session. This matches HarmonyOS best practices where
 * each http.createHttp() instance handles one request.
 */
export class OhosHttpEngine implements HttpEngine {
  private sessionFactory: OhosHttpSessionFactory;

  constructor(sessionFactory: OhosHttpSessionFactory) {
    this.sessionFactory = sessionFactory;
  }

  async execute(request: HttpRequest): Promise<HttpResponse> {
    const session = this.sessionFactory();
    try {
      const { extraData, contentType } = resolveBody(request);

      const headers: Record<string, string> = { ...request.headers };
      if (contentType) {
        headers['Content-Type'] = contentType;
      }

      const options: OhosHttpRequestOptions = {
        method: mapMethod(request.method),
        header: headers,
        connectTimeout: request.connectTimeoutMs,
        readTimeout: request.readTimeoutMs,
      };

      if (extraData !== undefined) {
        options.extraData = extraData;
      }

      const ohosResponse = await session.request(request.url, options);

      return {
        statusCode: ohosResponse.responseCode,
        headers: normalizeHeaders(ohosResponse.header),
        body: ohosResponse.result ?? '',
      };
    } finally {
      session.destroy();
    }
  }
}

// ---- Body resolution ----

interface ResolvedBody {
  extraData?: string;
  contentType?: string;
}

/**
 * Resolve an HttpRequest's body descriptor into a plain string payload
 * and Content-Type header, ready for the ohos HTTP API.
 */
function resolveBody(request: HttpRequest): ResolvedBody {
  if (!request.body) {
    return {};
  }

  const body = request.body;

  switch (body.type) {
    case 'json':
      return {
        extraData: body.content ?? '',
        contentType: body.contentType ?? 'application/json',
      };

    case 'form':
      return {
        extraData: encodeFormFields(body.formFields ?? []),
        contentType: body.contentType ?? 'application/x-www-form-urlencoded',
      };

    case 'multipart': {
      const boundary = generateBoundary();
      const { contentType, payload } = buildMultipartBody(boundary, body.parts ?? []);
      return {
        extraData: payload,
        contentType: body.contentType ?? contentType,
      };
    }

    case 'raw':
      return {
        extraData: body.content ?? '',
        contentType: body.contentType,
      };

    default:
      return {};
  }
}

// ---- Header normalization ----

/**
 * Normalize response headers: HarmonyOS may return header values as
 * arrays or as newline-separated strings. We flatten them into
 * a simple Record<string, string>.
 */
function normalizeHeaders(raw: Record<string, string | string[]> | undefined): Record<string, string> {
  if (!raw) return {};

  const result: Record<string, string> = {};
  for (const key of Object.keys(raw)) {
    const value = raw[key];
    if (Array.isArray(value)) {
      result[key] = value.join(', ');
    } else {
      result[key] = String(value);
    }
  }
  return result;
}

// ---- Factory helper for production ----

/**
 * Create an OhosHttpEngine using the real @ohos.net.http module.
 *
 * Usage:
 *   import http from '@ohos.net.http';
 *   const engine = createOhosHttpEngine(http);
 *   const client = new HttpClient({ engine });
 *
 * @param httpModule The @ohos.net.http module (or compatible mock).
 */
export function createOhosHttpEngine(httpModule: { createHttp: () => OhosHttpSession }): OhosHttpEngine {
  return new OhosHttpEngine(() => httpModule.createHttp());
}
