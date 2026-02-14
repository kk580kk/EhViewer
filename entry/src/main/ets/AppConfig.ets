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

import { ReadableTime } from './util/ReadableTime.ets';
import {
  joinPath,
  ensureDirectory,
  ensureFile,
  createTempFile,
  writeToFile,
} from './util/FileUtils.ets';
import type { FsOps } from './util/FileUtils.ets';

// ---- Subdirectory names ----

const DOWNLOAD = 'download';
const TEMP = 'temp';
const IMAGE = 'image';
const SHARE = 'share';
const PARSE_ERROR = 'parse_error';
const LOGCAT = 'logcat';
const DATA = 'data';
const CRASH = 'crash';

// ---- Context paths interface ----

/**
 * Platform paths injected during initialization.
 *
 * HarmonyOS: populated from UIAbilityContext
 *   - filesDir   → context.filesDir
 *   - cacheDir   → context.cacheDir
 *   - tempDir    → context.tempDir
 *
 * Tests: populated with temporary directories.
 */
export interface AppContextPaths {
  /** Persistent internal files directory (e.g. context.filesDir). */
  filesDir: string;
  /** System-managed cache directory (e.g. context.cacheDir). */
  cacheDir: string;
  /** Temporary directory (e.g. context.tempDir). */
  tempDir: string;
}

// ---- AppConfig ----

/**
 * Application-level file path manager.
 *
 * Mirrors the Android {@code AppConfig} class.
 * All directory getters lazily create the directory on first access.
 */
export class AppConfig {

  private static paths: AppContextPaths | null = null;
  private static fs: FsOps | null = null;

  /**
   * Must be called once during app startup (e.g. in EntryAbility.onCreate).
   */
  static initialize(paths: AppContextPaths, fs: FsOps): void {
    AppConfig.paths = paths;
    AppConfig.fs = fs;
  }

  /** Reset state (for testing only). */
  static reset(): void {
    AppConfig.paths = null;
    AppConfig.fs = null;
  }

  // ---- Persistent directories (under filesDir) ----

  /** Default download directory. */
  static getDownloadDir(): string | null {
    return AppConfig.getDirInFilesDir(DOWNLOAD);
  }

  /** Parse error dump directory. */
  static getParseErrorDir(): string | null {
    return AppConfig.getDirInFilesDir(PARSE_ERROR);
  }

  /** Logcat dump directory. */
  static getLogcatDir(): string | null {
    return AppConfig.getDirInFilesDir(LOGCAT);
  }

  /** Application data directory. */
  static getDataDir(): string | null {
    return AppConfig.getDirInFilesDir(DATA);
  }

  /** Crash dump directory. */
  static getCrashDir(): string | null {
    return AppConfig.getDirInFilesDir(CRASH);
  }

  /**
   * Get (or create) a named subdirectory under filesDir.
   */
  static getFilesSubDir(name: string): string | null {
    return AppConfig.getDirInFilesDir(name);
  }

  // ---- Cache directories (under cacheDir) ----

  /** Temporary files cache directory. */
  static getTempDir(): string | null {
    return AppConfig.getDirInCacheDir(TEMP);
  }

  /** Cached image directory. */
  static getImageDir(): string | null {
    return AppConfig.getDirInCacheDir(IMAGE);
  }

  /** Share staging directory (temporary files prepared for sharing). */
  static getShareDir(): string | null {
    return AppConfig.getDirInCacheDir(SHARE);
  }

  // ---- Temp file creation ----

  /**
   * Create a temp file in the cache temp directory.
   * Returns the full path or null on failure.
   */
  static createTempFile(extension?: string): string | null {
    const dir = AppConfig.getTempDir();
    return createTempFile(AppConfig.fs!, dir, extension);
  }

  // ---- File in directory ----

  /**
   * Get (or create) a file inside filesDir.
   */
  static getFileInFilesDir(filename: string): string | null {
    const base = AppConfig.paths?.filesDir;
    if (!base) return null;
    const filePath = joinPath(base, filename);
    return ensureFile(AppConfig.fs!, filePath) ? filePath : null;
  }

  // ---- Error logging ----

  /**
   * Save a parse error body for later debugging.
   * Mirrors Android's {@code AppConfig.saveParseErrorBody}.
   */
  static saveParseErrorBody(message: string | null, body: string | null): void {
    const dir = AppConfig.getParseErrorDir();
    if (dir === null) return;

    const timestamp = ReadableTime.getFilenamableTime(Date.now());
    const filePath = joinPath(dir, `${timestamp}.txt`);
    let content = '';
    if (message !== null) {
      content += message + '\n';
    }
    if (body !== null) {
      content += body;
    }
    writeToFile(AppConfig.fs!, filePath, content);
  }

  /**
   * Save a crash log for later debugging.
   */
  static saveCrashLog(errorMessage: string): void {
    const dir = AppConfig.getCrashDir();
    if (dir === null) return;

    const timestamp = ReadableTime.getFilenamableTime(Date.now());
    const filePath = joinPath(dir, `${timestamp}.txt`);
    writeToFile(AppConfig.fs!, filePath, errorMessage);
  }

  // ---- Internal helpers ----

  private static getDirInFilesDir(name: string): string | null {
    const base = AppConfig.paths?.filesDir;
    if (!base) return null;
    const dir = joinPath(base, name);
    return ensureDirectory(AppConfig.fs!, dir) ? dir : null;
  }

  private static getDirInCacheDir(name: string): string | null {
    const base = AppConfig.paths?.cacheDir;
    if (!base) return null;
    const dir = joinPath(base, name);
    return ensureDirectory(AppConfig.fs!, dir) ? dir : null;
  }
}
