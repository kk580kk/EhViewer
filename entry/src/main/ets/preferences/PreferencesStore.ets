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
 * Abstraction over a key-value preferences store.
 *
 * Production: backed by @ohos.data.preferences.
 * Tests: backed by MemoryPreferencesStore.
 *
 * Mirrors Android SharedPreferences used in Settings.java.
 */
export interface PreferencesStore {
  /** Get a string value, returning defValue if not found or type mismatch. */
  getString(key: string, defValue: string | null): string | null;

  /** Store a string value. Pass null to remove the key. */
  putString(key: string, value: string | null): void;

  /** Get a number value (int/long/float), returning defValue if not found or type mismatch. */
  getNumber(key: string, defValue: number): number;

  /** Store a number value. */
  putNumber(key: string, value: number): void;

  /** Get a boolean value, returning defValue if not found or type mismatch. */
  getBoolean(key: string, defValue: boolean): boolean;

  /** Store a boolean value. */
  putBoolean(key: string, value: boolean): void;

  /** Check whether a key exists. */
  has(key: string): boolean;

  /** Delete a single key. */
  delete(key: string): void;

  /** Remove all keys. */
  clear(): void;

  /** Persist any pending writes to disk. No-op for in-memory implementations. */
  flush(): void;
}
