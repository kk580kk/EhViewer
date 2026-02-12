/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { LockPatternUtils, PatternCell } from './LockPatternUtils.ets';
import type { SecureStorage } from './SecureStorage.ets';

/** Keys used inside SecureStorage for security-related data. */
const KEY_LOCK_PATTERN = 'lock_pattern';
const KEY_FINGERPRINT_ENABLED = 'fingerprint_enabled';

/** Result of a pattern verification attempt. */
export const VerifyResult = {
  /** Pattern matches. */
  SUCCESS: 'success',
  /** Pattern does not match. */
  WRONG: 'wrong',
  /** Too many failed attempts — locked out. */
  LOCKED_OUT: 'locked_out',
  /** No pattern has been set, verification not required. */
  NOT_SET: 'not_set',
} as const;

export type VerifyResult = (typeof VerifyResult)[keyof typeof VerifyResult];

/**
 * Core security guard that manages lock-pattern setup and verification.
 *
 * Mirrors the logic in Android's SetSecurityActivity + SecurityScene.
 *
 * - Stores/retrieves the lock pattern via SecureStorage (encrypted at rest).
 * - Tracks consecutive failed attempts and locks the user out after MAX_RETRIES.
 * - Provides a biometric-enabled flag for UI layers.
 */
export class SecurityGuard {
  static readonly MAX_RETRIES = 5;

  private storage: SecureStorage;
  private failedAttempts: number = 0;

  constructor(storage: SecureStorage) {
    this.storage = storage;
  }

  // ---- Pattern Management ----

  /** Whether a lock pattern is currently configured. */
  isPatternSet(): boolean {
    const pattern = this.storage.get(KEY_LOCK_PATTERN);
    return pattern !== null && pattern.length > 0;
  }

  /**
   * Set a new lock pattern.
   * Pass an empty string or empty array to clear the lock.
   */
  setPattern(cells: PatternCell[]): void {
    if (cells.length <= 1) {
      this.storage.put(KEY_LOCK_PATTERN, null);
      return;
    }
    const patternStr = LockPatternUtils.patternToString(cells);
    this.storage.put(KEY_LOCK_PATTERN, patternStr);
  }

  /** Set a lock pattern directly from a serialized string. */
  setPatternString(pattern: string): void {
    if (pattern.length === 0) {
      this.storage.put(KEY_LOCK_PATTERN, null);
    } else {
      this.storage.put(KEY_LOCK_PATTERN, pattern);
    }
  }

  /** Clear the lock pattern and reset failed attempts. */
  clearPattern(): void {
    this.storage.put(KEY_LOCK_PATTERN, null);
    this.failedAttempts = 0;
  }

  /** Get the raw pattern string (for display in SetSecurity UI). */
  getPatternString(): string {
    return this.storage.get(KEY_LOCK_PATTERN) ?? '';
  }

  // ---- Verification ----

  /**
   * Verify a user-entered pattern against the stored pattern.
   * Returns a VerifyResult indicating success, failure, or lockout.
   */
  verifyPattern(entered: PatternCell[]): VerifyResult {
    if (!this.isPatternSet()) {
      return VerifyResult.NOT_SET;
    }

    if (this.failedAttempts >= SecurityGuard.MAX_RETRIES) {
      return VerifyResult.LOCKED_OUT;
    }

    const enteredStr = LockPatternUtils.patternToString(entered);
    const storedStr = this.storage.get(KEY_LOCK_PATTERN) ?? '';

    if (enteredStr === storedStr) {
      this.failedAttempts = 0;
      return VerifyResult.SUCCESS;
    }

    this.failedAttempts++;
    if (this.failedAttempts >= SecurityGuard.MAX_RETRIES) {
      return VerifyResult.LOCKED_OUT;
    }
    return VerifyResult.WRONG;
  }

  /** Verify directly from a pattern string. */
  verifyPatternString(entered: string): VerifyResult {
    if (!this.isPatternSet()) {
      return VerifyResult.NOT_SET;
    }

    if (this.failedAttempts >= SecurityGuard.MAX_RETRIES) {
      return VerifyResult.LOCKED_OUT;
    }

    const storedStr = this.storage.get(KEY_LOCK_PATTERN) ?? '';
    if (entered === storedStr) {
      this.failedAttempts = 0;
      return VerifyResult.SUCCESS;
    }

    this.failedAttempts++;
    if (this.failedAttempts >= SecurityGuard.MAX_RETRIES) {
      return VerifyResult.LOCKED_OUT;
    }
    return VerifyResult.WRONG;
  }

  /** Get current number of consecutive failed attempts. */
  getFailedAttempts(): number {
    return this.failedAttempts;
  }

  /** Get remaining attempts before lockout. */
  getRemainingAttempts(): number {
    return Math.max(0, SecurityGuard.MAX_RETRIES - this.failedAttempts);
  }

  /** Reset the failed attempt counter (e.g. after a timeout). */
  resetFailedAttempts(): void {
    this.failedAttempts = 0;
  }

  // ---- Biometric ----

  /** Whether biometric/fingerprint authentication is enabled. */
  isFingerprintEnabled(): boolean {
    return this.storage.get(KEY_FINGERPRINT_ENABLED) === 'true';
  }

  /** Enable or disable biometric authentication. */
  setFingerprintEnabled(enabled: boolean): void {
    if (enabled) {
      this.storage.put(KEY_FINGERPRINT_ENABLED, 'true');
    } else {
      this.storage.put(KEY_FINGERPRINT_ENABLED, null);
    }
  }

  // ---- Convenience ----

  /** Whether the app should show the security lock screen on launch. */
  shouldShowLockScreen(): boolean {
    return this.isPatternSet();
  }
}
