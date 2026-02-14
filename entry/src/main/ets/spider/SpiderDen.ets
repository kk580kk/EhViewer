/*
 * Copyright 2016 Hippo Seven
 * Ported to HarmonyOS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { SpiderInfo } from './SpiderInfo.ets';
import { joinPath, getExtension, ensureDirectory } from '../util/FileUtils.ets';
import type { FsOps } from '../util/FileUtils.ets';

/**
 * Extended filesystem operations needed by SpiderDen.
 * Adds read and list capabilities on top of base FsOps.
 */
export interface SpiderDenFsOps extends FsOps {
  readFileSync(path: string, encoding?: string): string | Uint8Array;
  readdirSync(dirPath: string): string[];
  writeFileBinarySync(path: string, data: Uint8Array): void;
}

/**
 * Image cache abstraction.
 *
 * Production: backed by a disk cache (LRU).
 * Tests: backed by an in-memory Map.
 */
export interface ImageCache {
  get(key: string): Uint8Array | null;
  put(key: string, data: Uint8Array): void;
  contains(key: string): boolean;
  remove(key: string): void;
}

export const MODE_READ = 0;
export const MODE_DOWNLOAD = 1;

const SPIDER_INFO_FILENAME = '.ehviewer';
const IMAGE_EXTENSIONS = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];

/**
 * Spider "den" — manages file storage and caching for a gallery download.
 *
 * Mirrors the Android SpiderDen:
 *  - Reads/writes SpiderInfo from the gallery download directory
 *  - Checks download directory and cache for already-downloaded images
 *  - Saves new images to download directory or cache (depending on mode)
 *  - Provides cache key generation
 */
export class SpiderDen {

  private readonly gid: number;
  private readonly downloadDir: string | null;
  private readonly fs: SpiderDenFsOps;
  private readonly cache: ImageCache | null;
  private mode: number = MODE_READ;

  constructor(gid: number, downloadDir: string | null, fs: SpiderDenFsOps, cache: ImageCache | null) {
    this.gid = gid;
    this.downloadDir = downloadDir;
    this.fs = fs;
    this.cache = cache;
  }

  setMode(mode: number): void {
    this.mode = mode;
  }

  getMode(): number {
    return this.mode;
  }

  // ---- Cache key ----

  static getImageKey(gid: number, index: number): string {
    return `${gid}-${index}`;
  }

  // ---- SpiderInfo persistence ----

  /**
   * Read SpiderInfo from the gallery download directory.
   * Returns null if directory or file doesn't exist, or parsing fails.
   */
  readSpiderInfo(): SpiderInfo | null {
    if (this.downloadDir === null) return null;
    const filePath = joinPath(this.downloadDir, SPIDER_INFO_FILENAME);
    try {
      if (!this.fs.existsSync(filePath)) return null;
      const text = this.fs.readFileSync(filePath, 'utf-8') as string;
      return SpiderInfo.read(text);
    } catch (_e) {
      return null;
    }
  }

  /**
   * Write SpiderInfo to the gallery download directory.
   * Returns true on success.
   */
  writeSpiderInfo(info: SpiderInfo): boolean {
    if (this.downloadDir === null) return false;
    if (!ensureDirectory(this.fs, this.downloadDir)) return false;
    const filePath = joinPath(this.downloadDir, SPIDER_INFO_FILENAME);
    try {
      this.fs.writeFileSync(filePath, info.write(), 'utf-8');
      return true;
    } catch (_e) {
      return false;
    }
  }

  // ---- Image read ----

  /**
   * Check whether an image for the given index already exists
   * (either in the download directory or in cache).
   */
  containImage(index: number): boolean {
    // Check download dir
    if (this.downloadDir !== null) {
      const file = this.findImageFile(index);
      if (file !== null) return true;
    }
    // Check cache
    if (this.cache !== null) {
      return this.cache.contains(SpiderDen.getImageKey(this.gid, index));
    }
    return false;
  }

  /**
   * Read an image from download directory or cache.
   * Returns null if not found.
   */
  readImage(index: number): Uint8Array | null {
    // Try download dir first
    if (this.downloadDir !== null) {
      const filePath = this.findImageFile(index);
      if (filePath !== null) {
        try {
          return this.fs.readFileSync(filePath) as Uint8Array;
        } catch (_e) {
          // fall through to cache
        }
      }
    }
    // Try cache
    if (this.cache !== null) {
      return this.cache.get(SpiderDen.getImageKey(this.gid, index));
    }
    return null;
  }

  // ---- Image write ----

  /**
   * Save image data for the given index.
   *
   * In MODE_DOWNLOAD: saves to the download directory.
   * In MODE_READ: saves to the cache only.
   *
   * @param extension File extension without dot (e.g. 'jpg').
   * Returns true on success.
   */
  saveImage(index: number, data: Uint8Array, extension: string): boolean {
    const key = SpiderDen.getImageKey(this.gid, index);

    if (this.mode === MODE_DOWNLOAD && this.downloadDir !== null) {
      // Save to download dir
      if (!ensureDirectory(this.fs, this.downloadDir)) return false;
      const filename = this.buildImageFilename(index, extension);
      const filePath = joinPath(this.downloadDir, filename);
      try {
        this.fs.writeFileBinarySync(filePath, data);
        // Also put in cache for reading
        if (this.cache !== null) {
          this.cache.put(key, data);
        }
        return true;
      } catch (_e) {
        return false;
      }
    }

    // MODE_READ or no download dir — save to cache only
    if (this.cache !== null) {
      this.cache.put(key, data);
      return true;
    }
    return false;
  }

  /**
   * Remove a cached/saved image for the given index.
   */
  removeImage(index: number): void {
    // Remove from cache
    if (this.cache !== null) {
      this.cache.remove(SpiderDen.getImageKey(this.gid, index));
    }
    // Remove from download dir
    if (this.downloadDir !== null) {
      const filePath = this.findImageFile(index);
      if (filePath !== null) {
        try {
          this.fs.unlinkSync(filePath);
        } catch (_e) {
          // ignore
        }
      }
    }
  }

  // ---- Helpers ----

  getDownloadDir(): string | null {
    return this.downloadDir;
  }

  private buildImageFilename(index: number, extension: string): string {
    const paddedIndex = (index + 1).toString().padStart(8, '0');
    const ext = extension.length > 0 ? `.${extension}` : '.jpg';
    return `${this.gid}-${paddedIndex}${ext}`;
  }

  /**
   * Find the full path of an existing image file for the given index.
   * Checks all supported extensions. Returns null if not found.
   */
  private findImageFile(index: number): string | null {
    if (this.downloadDir === null) return null;

    const prefix = `${this.gid}-${(index + 1).toString().padStart(8, '0')}`;
    try {
      const files = this.fs.readdirSync(this.downloadDir);
      for (const name of files) {
        if (!name.startsWith(prefix)) continue;
        const ext = '.' + getExtension(name).toLowerCase();
        if (IMAGE_EXTENSIONS.includes(ext)) {
          return joinPath(this.downloadDir, name);
        }
      }
    } catch (_e) {
      // directory may not exist
    }
    return null;
  }
}
