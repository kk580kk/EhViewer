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

import { EhException } from '../client/exception/EhException.ets';

// Re-export so existing consumers keep working via this module.
export { EhException } from '../client/exception/EhException.ets';

/**
 * Localised error message strings, injected by the caller.
 */
export interface ErrorStrings {
  invalidUrl: string;
  timeout: string;
  unknownHost: string;
  /** Expects `{0}` placeholder for status code. */
  badStatusCode: string;
  redirection: string;
  socket: string;
  unknown: string;
}

/**
 * HTTP status code error.
 */
export class StatusCodeException extends Error {
  readonly responseCode: number;
  readonly identified: boolean;

  constructor(responseCode: number, message?: string) {
    super(message ?? `Error response code: ${responseCode}`);
    this.name = 'StatusCodeException';
    this.responseCode = responseCode;
    this.identified = message !== undefined && message.length > 0;
  }
}

/**
 * Utility methods for translating errors into user-readable messages.
 */
export class ExceptionUtils {

  private static errorStrings: ErrorStrings | null = null;

  /**
   * Inject localised error strings. Must be called once during app startup.
   */
  static initialize(strings: ErrorStrings): void {
    ExceptionUtils.errorStrings = strings;
  }

  /**
   * Convert an Error to a user-readable string.
   */
  static getReadableString(e: Error): string {
    const s = ExceptionUtils.errorStrings;
    if (!s) {
      return e.message || 'Unknown error';
    }

    if (e.name === 'TypeError' && e.message && e.message.includes('URL')) {
      return s.invalidUrl;
    }
    if (ExceptionUtils.isTimeoutError(e)) {
      return s.timeout;
    }
    if (ExceptionUtils.isNetworkError(e) && e.message && e.message.includes('getaddrinfo')) {
      return s.unknownHost;
    }
    if (e instanceof StatusCodeException) {
      let msg = s.badStatusCode.replace('{0}', String(e.responseCode));
      if (e.identified) {
        msg += `, ${e.message}`;
      }
      return msg;
    }
    if (ExceptionUtils.isRedirectionError(e)) {
      return s.redirection;
    }
    if (ExceptionUtils.isNetworkError(e)) {
      return s.socket;
    }
    if (e instanceof EhException) {
      return e.message;
    }
    return s.unknown;
  }

  /**
   * Re-throw fatal errors that should never be caught
   * (mirrors the RxJava convention for VirtualMachineError / ThreadDeath / LinkageError).
   * In ArkTS there are no exact equivalents, so we only re-throw RangeError
   * (stack overflow) which is the closest to a fatal VM error.
   */
  static throwIfFatal(t: Error): void {
    if (t instanceof RangeError && t.message && t.message.includes('call stack')) {
      throw t;
    }
  }

  // ---- Private helpers ----

  private static isTimeoutError(e: Error): boolean {
    const msg = e.message || '';
    return e.name === 'TimeoutError'
      || msg.includes('timeout')
      || msg.includes('Timeout')
      || msg.includes('ETIMEDOUT');
  }

  private static isNetworkError(e: Error): boolean {
    const msg = e.message || '';
    return msg.includes('ECONNREFUSED')
      || msg.includes('ECONNRESET')
      || msg.includes('ENOTFOUND')
      || msg.includes('getaddrinfo')
      || msg.includes('socket')
      || msg.includes('network');
  }

  private static isRedirectionError(e: Error): boolean {
    const msg = e.message || '';
    return msg.includes('Too many follow-up requests')
      || msg.includes('redirect')
      || msg.includes('ERR_TOO_MANY_REDIRECTS');
  }
}
