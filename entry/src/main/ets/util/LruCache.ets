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
 * A simple LRU (Least Recently Used) cache with both entry-count and
 * byte-size limits.  When either limit is exceeded the least-recently
 * used entries are evicted.
 *
 * `sizeOf` is called for every value to determine its byte cost.
 * If omitted every entry counts as 1 byte (i.e. only maxEntries matters).
 */
export class LruCache<K, V> {

  private readonly maxEntries: number;
  private readonly maxBytes: number;
  private readonly sizeOf: (value: V) => number;

  /** Insertion-order map; most-recently used entry is moved to the end. */
  private readonly map: Map<K, V> = new Map();
  private currentBytes: number = 0;

  constructor(
    maxEntries: number,
    maxBytes: number = Number.MAX_SAFE_INTEGER,
    sizeOf: (value: V) => number = () => 1,
  ) {
    if (maxEntries < 1) throw new Error('maxEntries must be >= 1');
    if (maxBytes < 1) throw new Error('maxBytes must be >= 1');
    this.maxEntries = maxEntries;
    this.maxBytes = maxBytes;
    this.sizeOf = sizeOf;
  }

  /** Number of entries currently in the cache. */
  get size(): number {
    return this.map.size;
  }

  /** Total byte cost of all cached values. */
  get bytes(): number {
    return this.currentBytes;
  }

  /**
   * Retrieve a value, marking it as most-recently used.
   * Returns `undefined` if the key is not in the cache.
   */
  get(key: K): V | undefined {
    const value = this.map.get(key);
    if (value === undefined) return undefined;
    // Move to end (most-recently used)
    this.map.delete(key);
    this.map.set(key, value);
    return value;
  }

  /** Returns `true` if the key exists in the cache (does NOT update recency). */
  has(key: K): boolean {
    return this.map.has(key);
  }

  /**
   * Insert or update an entry. If the cache exceeds its limits the
   * least-recently used entries are evicted.
   */
  put(key: K, value: V): void {
    // Remove old entry if present (so byte accounting stays correct).
    if (this.map.has(key)) {
      const old = this.map.get(key)!;
      this.currentBytes -= this.sizeOf(old);
      this.map.delete(key);
    }

    const cost = this.sizeOf(value);
    this.map.set(key, value);
    this.currentBytes += cost;

    this.trimToLimits();
  }

  /** Remove a single entry. Returns `true` if the key was present. */
  delete(key: K): boolean {
    const value = this.map.get(key);
    if (value === undefined) return false;
    this.currentBytes -= this.sizeOf(value);
    this.map.delete(key);
    return true;
  }

  /** Remove all entries. */
  clear(): void {
    this.map.clear();
    this.currentBytes = 0;
  }

  /** Iterate over keys in LRU order (oldest first). */
  keys(): IterableIterator<K> {
    return this.map.keys();
  }

  // ---- internal ----

  private trimToLimits(): void {
    while (this.map.size > this.maxEntries || this.currentBytes > this.maxBytes) {
      const oldest = this.map.keys().next();
      if (oldest.done) break;
      this.delete(oldest.value);
    }
  }
}
