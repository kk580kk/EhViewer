/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

/**
 * Abstraction for encrypted/secure key-value storage.
 *
 * Production: backed by HarmonyOS encrypted preferences or keystore.
 * Tests: backed by MemorySecureStorage (plaintext in-memory).
 *
 * Used for storing sensitive data such as cookies, lock pattern, tokens.
 */
export interface SecureStorage {
  /** Retrieve a secret string. Returns null if not found. */
  get(key: string): string | null;

  /** Store a secret string. Pass null to remove. */
  put(key: string, value: string | null): void;

  /** Check whether a key exists. */
  has(key: string): boolean;

  /** Remove a single key. */
  delete(key: string): void;

  /** Remove all stored secrets. */
  clear(): void;
}

/**
 * In-memory implementation of SecureStorage for unit tests.
 * Data is NOT encrypted — useful only for testing.
 */
export class MemorySecureStorage implements SecureStorage {
  private data: Map<string, string> = new Map();

  get(key: string): string | null {
    return this.data.get(key) ?? null;
  }

  put(key: string, value: string | null): void {
    if (value === null) {
      this.data.delete(key);
    } else {
      this.data.set(key, value);
    }
  }

  has(key: string): boolean {
    return this.data.has(key);
  }

  delete(key: string): void {
    this.data.delete(key);
  }

  clear(): void {
    this.data.clear();
  }
}
