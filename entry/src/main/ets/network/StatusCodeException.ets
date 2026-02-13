/*
 * Copyright 2016 Hippo Seven
 * Ported to HarmonyOS ArkTS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

/**
 * Localised HTTP error message strings, injected by the caller.
 *
 * Keys are HTTP status codes (e.g. 400, 404, 500).
 * Values are user-readable descriptions.
 */
export type StatusCodeMessages = Record<number, string>;

/** Default fallback when no localised message is available. */
const DEFAULT_ERROR_MESSAGE = 'Error response code';

/**
 * Built-in English error descriptions for common HTTP status codes.
 * Mirrors the Android StatusCodeException.initialize() entries.
 */
const DEFAULT_STATUS_MESSAGES: StatusCodeMessages = {
  // 4xx Client errors
  400: 'Bad Request',
  401: 'Unauthorized',
  402: 'Payment Required',
  403: 'Forbidden',
  404: 'Not Found',
  405: 'Method Not Allowed',
  406: 'Not Acceptable',
  407: 'Proxy Authentication Required',
  408: 'Request Timeout',
  409: 'Conflict',
  410: 'Gone',
  411: 'Length Required',
  412: 'Precondition Failed',
  413: 'Request Entity Too Large',
  414: 'Request-URI Too Long',
  415: 'Unsupported Media Type',
  416: 'Requested Range Not Satisfiable',
  417: 'Expectation Failed',
  429: 'Too Many Requests',
  // E-Hentai specific
  509: 'Bandwidth Limit Exceeded',
  // 5xx Server errors
  500: 'Internal Server Error',
  501: 'Not Implemented',
  502: 'Bad Gateway',
  503: 'Service Unavailable',
  504: 'Gateway Timeout',
  505: 'HTTP Version Not Supported',
};

/**
 * Exception thrown when an HTTP response has a non-successful status code.
 *
 * Mirrors the Android `com.hippo.network.StatusCodeException`.
 *
 * - Stores the numeric response code.
 * - Looks up a human-readable description from the message map.
 * - Supports optional URL for debugging context.
 */
export class StatusCodeException extends Error {
  /** Localised/customised error messages; overridden via `initialize()`. */
  private static messages: StatusCodeMessages = { ...DEFAULT_STATUS_MESSAGES };

  readonly responseCode: number;
  readonly url: string | undefined;

  /**
   * Inject localised status code messages. Call once during app startup.
   * Messages are merged with the defaults — only provided keys are overwritten.
   */
  static initialize(customMessages: StatusCodeMessages): void {
    StatusCodeException.messages = { ...DEFAULT_STATUS_MESSAGES, ...customMessages };
  }

  /** Reset to built-in defaults (useful in tests). */
  static reset(): void {
    StatusCodeException.messages = { ...DEFAULT_STATUS_MESSAGES };
  }

  constructor(responseCode: number, url?: string) {
    const mapped = StatusCodeException.messages[responseCode];
    const msg = mapped
      ? `${responseCode} ${mapped}`
      : `${DEFAULT_ERROR_MESSAGE}: ${responseCode}`;
    super(msg);
    this.name = 'StatusCodeException';
    this.responseCode = responseCode;
    this.url = url;
  }

  /**
   * Whether the response code has a known human-readable description
   * (i.e. it appears in the message map).
   */
  get isIdentifiedResponseCode(): boolean {
    return StatusCodeException.messages[this.responseCode] !== undefined;
  }

  /** True if this is a client error (4xx). */
  get isClientError(): boolean {
    return this.responseCode >= 400 && this.responseCode < 500;
  }

  /** True if this is a server error (5xx). */
  get isServerError(): boolean {
    return this.responseCode >= 500 && this.responseCode < 600;
  }
}
