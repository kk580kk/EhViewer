/*
 * Copyright 2024 EhViewer Contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { SettingsService } from '../service/SettingsService.ets';
import { getDownloadRoot } from './DownloadPathResolver.ets';
import type { FsOps } from '../util/FileUtils.ets';
import {
  joinPath,
  ensureDirectory,
  copyDirectoryContents,
  deleteDirectoryRecursively,
} from '../util/FileUtils.ets';

/**
 * Progress callback for download directory migration.
 */
export interface MigrateProgressCallback {
  /** Called after each gallery directory is migrated. */
  onProgress(migrated: number, total: number): void;
}

/**
 * Result of a migration operation.
 */
export interface MigrateResult {
  /** Whether the migration completed (even if some dirs failed). */
  success: boolean;
  /** Number of gallery directories successfully migrated. */
  migrated: number;
  /** Total number of gallery directories attempted. */
  total: number;
  /** Error message if success is false. */
  error?: string;
}

/**
 * Service that migrates all downloaded gallery directories from the current
 * download location to a new location.
 *
 * The migration process:
 *   1. Lists all subdirectories in the current download root.
 *   2. For each directory, copies all contents to the new location.
 *   3. Deletes the source directory after successful copy.
 *   4. Updates the download location setting to point to the new path.
 *
 * This service is designed to be testable: all filesystem operations go through
 * the FsOps interface, and settings through SettingsService.
 */
export class MigrateDownloadService {
  private readonly fs: FsOps;

  constructor(fs: FsOps) {
    this.fs = fs;
  }

  /**
   * Validate whether migration from current location to newPath is possible.
   *
   * @returns null if valid, or an error string describing the problem
   */
  validate(newPath: string): string | null {
    const oldPath = getDownloadRoot();
    if (oldPath === null) {
      return 'no_current_location';
    }
    if (oldPath === newPath) {
      return 'same_directory';
    }
    if (!this.fs.existsSync(oldPath)) {
      return 'source_not_found';
    }
    return null;
  }

  /**
   * Execute the migration from the current download location to newPath.
   *
   * @param newPath   Target directory path
   * @param callback  Optional progress callback
   * @returns Migration result
   */
  migrate(newPath: string, callback?: MigrateProgressCallback): MigrateResult {
    const oldPath = getDownloadRoot();
    if (oldPath === null) {
      return { success: false, migrated: 0, total: 0, error: 'no_current_location' };
    }

    if (oldPath === newPath) {
      return { success: false, migrated: 0, total: 0, error: 'same_directory' };
    }

    if (!this.fs.readdirSync) {
      return { success: false, migrated: 0, total: 0, error: 'fs_not_supported' };
    }

    // Ensure new directory exists
    if (!ensureDirectory(this.fs, newPath)) {
      return { success: false, migrated: 0, total: 0, error: 'cannot_create_target' };
    }

    // List all entries in old directory
    let entries: string[];
    try {
      entries = this.fs.readdirSync(oldPath);
    } catch (_e) {
      return { success: false, migrated: 0, total: 0, error: 'cannot_read_source' };
    }

    // Filter to directories only
    const galleryDirs: string[] = [];
    for (const name of entries) {
      const entryPath = joinPath(oldPath, name);
      try {
        if (this.fs.statSync(entryPath).isDirectory()) {
          galleryDirs.push(name);
        }
      } catch (_e) {
        // Skip entries we can't stat
      }
    }

    if (galleryDirs.length === 0) {
      return { success: true, migrated: 0, total: 0 };
    }

    let migrated = 0;
    const total = galleryDirs.length;

    for (const dirName of galleryDirs) {
      const srcPath = joinPath(oldPath, dirName);
      const dstPath = joinPath(newPath, dirName);

      // Create destination directory
      if (!ensureDirectory(this.fs, dstPath)) {
        continue;
      }

      // Copy contents
      if (copyDirectoryContents(this.fs, srcPath, dstPath)) {
        // Delete source after successful copy
        deleteDirectoryRecursively(this.fs, srcPath);
        migrated++;
      } else {
        // Clean up partially copied destination
        deleteDirectoryRecursively(this.fs, dstPath);
      }

      if (callback) {
        callback.onProgress(migrated, total);
      }
    }

    // Also migrate .nomedia file if present
    const noMediaPath = joinPath(oldPath, '.nomedia');
    if (this.fs.existsSync(noMediaPath)) {
      try {
        const dstNoMedia = joinPath(newPath, '.nomedia');
        if (this.fs.copyFileSync) {
          this.fs.copyFileSync(noMediaPath, dstNoMedia);
        }
      } catch (_e) {
        // Non-critical, ignore
      }
    }

    // Update download location setting
    if (migrated > 0) {
      SettingsService.setDownloadLocation(newPath);
    }

    return { success: true, migrated, total };
  }
}
