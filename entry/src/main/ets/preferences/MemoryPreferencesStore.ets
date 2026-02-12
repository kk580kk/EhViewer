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

import type { PreferencesStore } from './PreferencesStore.ets';

type PrefValue = string | number | boolean;

/**
 * In-memory implementation of PreferencesStore.
 *
 * Useful for unit tests and scenarios where persistence is not required.
 * All data is lost when the instance is discarded.
 */
export class MemoryPreferencesStore implements PreferencesStore {
  private data: Map<string, PrefValue> = new Map();

  getString(key: string, defValue: string | null): string | null {
    const v = this.data.get(key);
    if (v === undefined) return defValue;
    if (typeof v !== 'string') return defValue;
    return v;
  }

  putString(key: string, value: string | null): void {
    if (value === null) {
      this.data.delete(key);
    } else {
      this.data.set(key, value);
    }
  }

  getNumber(key: string, defValue: number): number {
    const v = this.data.get(key);
    if (v === undefined) return defValue;
    if (typeof v !== 'number') return defValue;
    return v;
  }

  putNumber(key: string, value: number): void {
    this.data.set(key, value);
  }

  getBoolean(key: string, defValue: boolean): boolean {
    const v = this.data.get(key);
    if (v === undefined) return defValue;
    if (typeof v !== 'boolean') return defValue;
    return v;
  }

  putBoolean(key: string, value: boolean): void {
    this.data.set(key, value);
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

  flush(): void {
    // No-op for in-memory store.
  }
}
