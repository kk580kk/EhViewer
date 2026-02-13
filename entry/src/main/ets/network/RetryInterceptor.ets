/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { StatusCodeException } from './StatusCodeException.ets';

/**
 * Determines whether a failed request should be retried.
 *
 * Mirrors the Android retry behaviour:
 * - SpiderQueen retries image downloads up to 5 times on HTTP errors / IO failures
 * - 509 (bandwidth limit) is never retried — it's a hard stop
 * - Network / connection errors are retried with exponential backoff
 * - Server errors (5xx) are retried
 * - Client errors (4xx) are generally NOT retried, except 408 (timeout) and 429 (rate limit)
 */
export interface RetryStrategy {
  /**
   * Decide whether the request should be retried.
   *
   * @param attempt  Zero-based attempt number (0 = first failure, 1 = second failure, etc.).
   * @param error    The error that caused the failure.
   * @returns The delay in milliseconds before the next retry, or -1 to stop retrying.
   */
  shouldRetry(attempt: number, error: unknown): number;
}

/** HTTP status codes that should never be retried. */
const NON_RETRYABLE_CODES: ReadonlySet<number> = new Set([
  400, // Bad Request
  401, // Unauthorized
  403, // Forbidden
  404, // Not Found
  405, // Method Not Allowed
  410, // Gone
  509, // Bandwidth Limit Exceeded (E-Hentai specific)
]);

/** HTTP status codes that are retryable despite being 4xx. */
const RETRYABLE_4XX_CODES: ReadonlySet<number> = new Set([
  408, // Request Timeout
  429, // Too Many Requests
]);

/**
 * Extract the HTTP status code from an error, if it's a StatusCodeException.
 */
function getStatusCode(error: unknown): number | null {
  if (error instanceof StatusCodeException) {
    return error.responseCode;
  }
  return null;
}

/**
 * Check whether an error represents a network / connection failure
 * (i.e. not an HTTP status code error but a transport-level failure).
 */
function isNetworkError(error: unknown): boolean {
  if (error instanceof StatusCodeException) {
    return false;
  }
  if (error instanceof Error) {
    const msg = error.message.toLowerCase();
    return msg.includes('network') ||
      msg.includes('timeout') ||
      msg.includes('econnrefused') ||
      msg.includes('econnreset') ||
      msg.includes('enotfound') ||
      msg.includes('socket') ||
      msg.includes('fetch failed');
  }
  return false;
}

export interface RetryOptions {
  /** Maximum number of retry attempts (default 3). */
  maxRetries?: number;
  /** Base delay in ms for exponential backoff (default 1000). */
  baseDelayMs?: number;
  /** Maximum delay in ms (default 30000). */
  maxDelayMs?: number;
  /** Jitter factor 0–1 added to delay to avoid thundering herd (default 0.25). */
  jitterFactor?: number;
}

/**
 * Exponential-backoff retry strategy matching Android EhViewer behaviour.
 *
 * - Network / connection errors: always retried (up to maxRetries)
 * - 5xx server errors: always retried
 * - 408/429: retried (429 uses longer base delay)
 * - 509: NEVER retried (bandwidth limit — hard stop, matching Android SpiderQueen)
 * - Other 4xx: NEVER retried
 */
export class ExponentialBackoffRetry implements RetryStrategy {
  private readonly maxRetries: number;
  private readonly baseDelayMs: number;
  private readonly maxDelayMs: number;
  private readonly jitterFactor: number;

  constructor(options?: RetryOptions) {
    this.maxRetries = options?.maxRetries ?? 3;
    this.baseDelayMs = options?.baseDelayMs ?? 1000;
    this.maxDelayMs = options?.maxDelayMs ?? 30_000;
    this.jitterFactor = options?.jitterFactor ?? 0.25;
  }

  shouldRetry(attempt: number, error: unknown): number {
    if (attempt >= this.maxRetries) {
      return -1;
    }

    const code = getStatusCode(error);

    if (code !== null) {
      // Never retry non-retryable status codes (including 509)
      if (NON_RETRYABLE_CODES.has(code)) {
        return -1;
      }

      // Retry server errors (5xx)
      if (code >= 500) {
        return this.computeDelay(attempt);
      }

      // Retry specific 4xx codes
      if (RETRYABLE_4XX_CODES.has(code)) {
        // 429 gets a longer base delay
        if (code === 429) {
          return this.computeDelay(attempt, this.baseDelayMs * 2);
        }
        return this.computeDelay(attempt);
      }

      // Other 4xx — don't retry
      return -1;
    }

    // Network / connection error — retry
    if (isNetworkError(error)) {
      return this.computeDelay(attempt);
    }

    // Unknown error type — don't retry
    return -1;
  }

  private computeDelay(attempt: number, baseMs?: number): number {
    const base = baseMs ?? this.baseDelayMs;
    const delay = Math.min(base * Math.pow(2, attempt), this.maxDelayMs);
    const jitter = delay * this.jitterFactor * Math.random();
    return Math.round(delay + jitter);
  }
}

/**
 * Utility: sleep for the given number of milliseconds.
 * Extracted so tests can verify timing without actually sleeping.
 */
export function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}
