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
import { StatusCodeException } from '../network/StatusCodeException.ets';

// Re-export so existing consumers keep working via this module.
export { EhException } from '../client/exception/EhException.ets';
export { StatusCodeException } from '../network/StatusCodeException.ets';

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
 * Utility methods for exception chain traversal, message extraction,
 * and translating errors into user-readable messages.
 */
export class ExceptionUtils {

  private static errorStrings: ErrorStrings | null = null;

  /** Maximum depth when walking cause chains to avoid infinite loops. */
  private static readonly MAX_CHAIN_DEPTH = 64;

  /**
   * Inject localised error strings. Must be called once during app startup.
   */
  static initialize(strings: ErrorStrings): void {
    ExceptionUtils.errorStrings = strings;
  }

  // ---- Exception chain traversal ----

  /**
   * Walk the cause chain starting from `e` and return all errors in order
   * (outermost first). Stops at the first `null`/`undefined` cause or when
   * a cycle is detected.
   */
  static getCauseChain(e: Error): Error[] {
    const chain: Error[] = [];
    const visited = new Set<Error>();
    let current: Error | undefined = e;
    while (current && !visited.has(current) && chain.length < ExceptionUtils.MAX_CHAIN_DEPTH) {
      visited.add(current);
      chain.push(current);
      current = current.cause instanceof Error ? current.cause as Error : undefined;
    }
    return chain;
  }

  /**
   * Return the root cause (deepest cause) of the error chain.
   * If the error has no cause, returns itself.
   */
  static getRootCause(e: Error): Error {
    const chain = ExceptionUtils.getCauseChain(e);
    return chain[chain.length - 1];
  }

  // ---- Message extraction ----

  /**
   * Collect all non-empty messages from the cause chain (outermost first).
   */
  static getMessages(e: Error): string[] {
    return ExceptionUtils.getCauseChain(e)
      .map(err => err.message)
      .filter(msg => msg !== undefined && msg.length > 0);
  }

  /**
   * Return the first non-empty message found in the cause chain,
   * or the fallback string if none exists.
   */
  static getFirstMessage(e: Error, fallback: string = 'Unknown error'): string {
    const messages = ExceptionUtils.getMessages(e);
    return messages.length > 0 ? messages[0] : fallback;
  }

  /**
   * Return the root cause's message, or the fallback string.
   */
  static getRootCauseMessage(e: Error, fallback: string = 'Unknown error'): string {
    const root = ExceptionUtils.getRootCause(e);
    return root.message && root.message.length > 0 ? root.message : fallback;
  }

  // ---- Readable string conversion ----

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
      if (e.isIdentifiedResponseCode) {
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

  // ---- Fatal error handling ----

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
