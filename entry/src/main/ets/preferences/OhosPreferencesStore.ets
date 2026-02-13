/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import type { PreferencesStore } from './PreferencesStore.ets';

/**
 * Proxy interface for @ohos.data.preferences.Preferences.
 *
 * Production: the real Preferences object from
 *   `dataPreferences.getPreferencesSync(context, { name })` satisfies this.
 * Tests: supply a mock or use MemoryPreferencesStore instead.
 */
export interface OhosPreferencesProxy {
  getSync(key: string, defValue: string | number | boolean): string | number | boolean;
  putSync(key: string, value: string | number | boolean): void;
  hasSync(key: string): boolean;
  deleteSync(key: string): void;
  clearSync(): void;
  flush(): Promise<void>;
}

/**
 * PreferencesStore implementation backed by @ohos.data.preferences.
 *
 * Wraps an OhosPreferencesProxy and provides type-safe get/put
 * with fallback to default values on type mismatch.
 *
 * Usage (production):
 *   import dataPreferences from '@ohos.data.preferences';
 *   const ohosPrefs = dataPreferences.getPreferencesSync(context, { name: 'settings' });
 *   const store = new OhosPreferencesStore(ohosPrefs as OhosPreferencesProxy);
 *   SettingsService.initialize(store);
 */
export class OhosPreferencesStore implements PreferencesStore {
  private readonly prefs: OhosPreferencesProxy;

  constructor(prefs: OhosPreferencesProxy) {
    this.prefs = prefs;
  }

  getString(key: string, defValue: string | null): string | null {
    if (!this.prefs.hasSync(key)) {
      return defValue;
    }
    const v = this.prefs.getSync(key, defValue ?? '');
    if (typeof v !== 'string') {
      return defValue;
    }
    return v;
  }

  putString(key: string, value: string | null): void {
    if (value === null) {
      this.prefs.deleteSync(key);
    } else {
      this.prefs.putSync(key, value);
    }
    this.flushAsync();
  }

  getNumber(key: string, defValue: number): number {
    if (!this.prefs.hasSync(key)) {
      return defValue;
    }
    const v = this.prefs.getSync(key, defValue);
    if (typeof v !== 'number') {
      return defValue;
    }
    return v;
  }

  putNumber(key: string, value: number): void {
    this.prefs.putSync(key, value);
    this.flushAsync();
  }

  getBoolean(key: string, defValue: boolean): boolean {
    if (!this.prefs.hasSync(key)) {
      return defValue;
    }
    const v = this.prefs.getSync(key, defValue);
    if (typeof v !== 'boolean') {
      return defValue;
    }
    return v;
  }

  putBoolean(key: string, value: boolean): void {
    this.prefs.putSync(key, value);
    this.flushAsync();
  }

  has(key: string): boolean {
    return this.prefs.hasSync(key);
  }

  delete(key: string): void {
    this.prefs.deleteSync(key);
    this.flushAsync();
  }

  clear(): void {
    this.prefs.clearSync();
    this.flushAsync();
  }

  flush(): void {
    this.flushAsync();
  }

  /** Fire-and-forget flush to persist changes to disk. */
  private flushAsync(): void {
    this.prefs.flush().catch(() => {
      // Best-effort persistence; errors are silently ignored.
    });
  }
}
