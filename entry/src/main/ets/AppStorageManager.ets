/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { joinPath, ensureDirectory } from './util/FileUtils.ets';
import type { FsOps } from './util/FileUtils.ets';
import type { AppContextPaths } from './AppConfig.ets';

// ---- Storage category subdirectory names ----

const DOWNLOAD = 'download';
const TEMP = 'temp';
const IMAGE = 'image';
const SHARE = 'share';
const DATA = 'data';
const CACHE = 'cache';

/**
 * Describes the kind of storage for a given path.
 *
 *  - PERSISTENT: data that survives cache clears (under filesDir)
 *  - CACHE:      data that can be evicted by the system (under cacheDir)
 *  - TEMP:       short-lived data (under tempDir / cacheDir)
 */
export type StorageType = 'persistent' | 'cache' | 'temp';

/**
 * Metadata about a resolved storage path.
 */
export interface StoragePathInfo {
  /** Absolute path to the directory. */
  path: string;
  /** What kind of storage this represents. */
  type: StorageType;
  /** Logical name (e.g. 'download', 'share'). */
  name: string;
}

/**
 * Centralized manager for application storage paths.
 *
 * Provides a single entry point for all storage locations used across
 * the app: download directories, cache paths, sharing staging areas,
 * and other app data.
 *
 * The manager builds on top of {@link AppContextPaths} (populated from
 * the HarmonyOS UIAbilityContext) and the {@link FsOps} abstraction.
 *
 * Usage:
 * ```
 *   AppStorageManager.initialize(ctxPaths, fsOps);
 *   const dlDir = AppStorageManager.getDownloadDir();
 *   const shareDir = AppStorageManager.getShareTempDir();
 * ```
 */
export class AppStorageManager {

  private static paths: AppContextPaths | null = null;
  private static fs: FsOps | null = null;

  /**
   * Initialize with platform context paths and filesystem adapter.
   * Must be called once during app startup, before any other method.
   */
  static initialize(paths: AppContextPaths, fs: FsOps): void {
    AppStorageManager.paths = paths;
    AppStorageManager.fs = fs;
  }

  /** Reset state (for testing only). */
  static reset(): void {
    AppStorageManager.paths = null;
    AppStorageManager.fs = null;
  }

  // ---- Persistent storage (under filesDir) ----

  /**
   * Download directory for gallery data.
   * Persistent — survives cache clears.
   */
  static getDownloadDir(): string | null {
    return AppStorageManager.ensurePersistentDir(DOWNLOAD);
  }

  /**
   * Application data directory for databases, exports, etc.
   * Persistent.
   */
  static getDataDir(): string | null {
    return AppStorageManager.ensurePersistentDir(DATA);
  }

  // ---- Cache storage (under cacheDir) ----

  /**
   * Temporary cache directory for transient files.
   * May be evicted by the system when storage is low.
   */
  static getCacheTempDir(): string | null {
    return AppStorageManager.ensureCacheDir(TEMP);
  }

  /**
   * Cached image directory.
   */
  static getImageCacheDir(): string | null {
    return AppStorageManager.ensureCacheDir(IMAGE);
  }

  /**
   * General cache directory.
   */
  static getCacheDir(): string | null {
    return AppStorageManager.ensureCacheDir(CACHE);
  }

  // ---- Sharing staging (under cacheDir) ----

  /**
   * Staging directory for files that are about to be shared
   * via {@link FileShareHelper}. Temporary, should be cleaned
   * periodically.
   */
  static getShareTempDir(): string | null {
    return AppStorageManager.ensureCacheDir(SHARE);
  }

  // ---- Temp directory (under tempDir) ----

  /**
   * System-managed temporary directory. Content may be deleted by the
   * system at any time after the app exits.
   */
  static getTempDir(): string | null {
    const base = AppStorageManager.paths?.tempDir;
    if (!base || !AppStorageManager.fs) return null;
    return ensureDirectory(AppStorageManager.fs, base) ? base : null;
  }

  // ---- Custom subdirectory ----

  /**
   * Get (or create) a named subdirectory under the persistent storage.
   */
  static getPersistentSubDir(name: string): string | null {
    return AppStorageManager.ensurePersistentDir(name);
  }

  /**
   * Get (or create) a named subdirectory under the cache storage.
   */
  static getCacheSubDir(name: string): string | null {
    return AppStorageManager.ensureCacheDir(name);
  }

  // ---- Introspection ----

  /**
   * Return metadata about all standard storage paths.
   * Useful for diagnostics and settings display.
   */
  static getAllPaths(): StoragePathInfo[] {
    const result: StoragePathInfo[] = [];

    const persistent: Array<[string, string]> = [
      ['download', DOWNLOAD],
      ['data', DATA],
    ];
    for (const [name, sub] of persistent) {
      const p = AppStorageManager.ensurePersistentDir(sub);
      if (p) result.push({ path: p, type: 'persistent', name });
    }

    const cache: Array<[string, string]> = [
      ['cache_temp', TEMP],
      ['image_cache', IMAGE],
      ['share', SHARE],
      ['cache', CACHE],
    ];
    for (const [name, sub] of cache) {
      const p = AppStorageManager.ensureCacheDir(sub);
      if (p) result.push({ path: p, type: 'cache', name });
    }

    const tempDir = AppStorageManager.getTempDir();
    if (tempDir) result.push({ path: tempDir, type: 'temp', name: 'temp' });

    return result;
  }

  /**
   * Check whether the manager has been initialized.
   */
  static isInitialized(): boolean {
    return AppStorageManager.paths !== null && AppStorageManager.fs !== null;
  }

  // ---- Internal helpers ----

  private static ensurePersistentDir(name: string): string | null {
    const base = AppStorageManager.paths?.filesDir;
    if (!base || !AppStorageManager.fs) return null;
    const dir = joinPath(base, name);
    return ensureDirectory(AppStorageManager.fs, dir) ? dir : null;
  }

  private static ensureCacheDir(name: string): string | null {
    const base = AppStorageManager.paths?.cacheDir;
    if (!base || !AppStorageManager.fs) return null;
    const dir = joinPath(base, name);
    return ensureDirectory(AppStorageManager.fs, dir) ? dir : null;
  }
}
