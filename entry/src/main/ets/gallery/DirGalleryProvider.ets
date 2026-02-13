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

import {
  GalleryProvider,
  STATE_ERROR,
  STATE_WAIT,
  isSupportedImageFile,
} from './GalleryProvider.ets';
import { NaturalComparator } from '../util/NaturalComparator.ets';
import {
  getExtension,
  getNameWithoutExtension,
  joinPath,
} from '../util/FileUtils.ets';

/**
 * Filesystem operations needed by DirGalleryProvider.
 *
 * Production: backed by @ohos.file.fs
 * Tests: backed by node:fs or an in-memory implementation.
 */
export interface DirGalleryFsOps {
  /** List file names in a directory. */
  readdirSync(dirPath: string): string[];
  /** Read a file as binary. */
  readFileSync(path: string): Uint8Array;
  /** Write binary data to a file (create or overwrite). */
  writeFileSync(path: string, data: Uint8Array): void;
  /** Check whether a path exists. */
  existsSync(path: string): boolean;
}

/**
 * Sorting mode for image file names.
 * - 'name_natural': numbers within names are compared numerically.
 * - 'name_lexicographic': pure string comparison.
 */
export type SortMode = 'name_natural' | 'name_lexicographic';

/**
 * Sort direction.
 */
export type SortOrder = 'asc' | 'desc';

/** Configuration for sorting the image file list. */
export interface SortConfig {
  mode?: SortMode;
  order?: SortOrder;
}

const naturalCmp = new NaturalComparator();

/**
 * Gallery provider that reads images from a local directory.
 *
 * Mirrors the Android DirGalleryProvider. On start(), it scans the
 * directory for supported image files, sorts them by natural order,
 * and serves them on request.
 */
export class DirGalleryProvider extends GalleryProvider {

  private readonly dirPath: string;
  private readonly fs: DirGalleryFsOps;
  private readonly sortMode: SortMode;
  private readonly sortOrder: SortOrder;

  /** Sorted list of image file names (relative to dirPath). */
  private fileList: string[] | null = null;
  private pageCount: number = STATE_WAIT;
  private error: string | null = null;

  /** Queue of pending request indices. */
  private pendingRequests: number[] = [];

  constructor(dirPath: string, fs: DirGalleryFsOps, sortConfig?: SortConfig) {
    super();
    this.dirPath = dirPath;
    this.fs = fs;
    this.sortMode = sortConfig?.mode ?? 'name_natural';
    this.sortOrder = sortConfig?.order ?? 'asc';
  }

  override start(): void {
    super.start();
    this.scanDirectory();
  }

  override stop(): void {
    super.stop();
    this.pendingRequests = [];
  }

  override size(): number {
    return this.pageCount;
  }

  override getError(): string | null {
    return this.error;
  }

  override getImageFilename(index: number): string {
    if (this.fileList !== null && index >= 0 && index < this.fileList.length) {
      return getNameWithoutExtension(this.fileList[index]);
    }
    return index.toString();
  }

  override save(index: number, destPath: string): boolean {
    const data = this.readImageData(index);
    if (data === null) return false;
    try {
      this.fs.writeFileSync(destPath, data);
      return true;
    } catch (_e) {
      return false;
    }
  }

  override saveToDir(index: number, dir: string, filename: string): string | null {
    if (this.fileList === null || index < 0 || index >= this.fileList.length) {
      return null;
    }
    const ext = getExtension(this.fileList[index]);
    const destName = ext.length > 0 ? `${filename}.${ext}` : filename;
    const destPath = joinPath(dir, destName);
    return this.save(index, destPath) ? destPath : null;
  }

  protected override onRequest(index: number): void {
    this.notifyPageWait(index);
    this.processRequest(index);
  }

  protected override onForceRequest(index: number): void {
    this.onRequest(index);
  }

  protected override onCancelRequest(index: number): void {
    const idx = this.pendingRequests.indexOf(index);
    if (idx >= 0) {
      this.pendingRequests.splice(idx, 1);
    }
  }

  // ---- Pagination ----

  /**
   * Return a slice of the sorted file name list.
   *
   * Useful for UI thumbnail grids that display a page of results at a time.
   *
   * @param offset 0-based start index (clamped to valid range).
   * @param limit  Maximum number of names to return (clamped to remaining items).
   * @returns Array of file names (without directory prefix) in sorted order,
   *          or an empty array if the provider has not been started or the
   *          directory could not be read.
   */
  getFileNames(offset: number, limit: number): string[] {
    if (this.fileList === null || limit <= 0) return [];
    const start = Math.max(0, Math.min(offset, this.fileList.length));
    const end = Math.min(start + limit, this.fileList.length);
    return this.fileList.slice(start, end);
  }

  // ---- Internal ----

  private scanDirectory(): void {
    try {
      if (!this.fs.existsSync(this.dirPath)) {
        this.pageCount = STATE_ERROR;
        this.error = 'Directory does not exist';
        this.notifyDataChanged();
        return;
      }

      const allNames = this.fs.readdirSync(this.dirPath);
      const imageNames = allNames.filter(name => isSupportedImageFile(name));
      this.sortFileList(imageNames);

      this.fileList = imageNames;
      this.pageCount = imageNames.length;
      this.notifyDataChanged();
    } catch (e) {
      this.pageCount = STATE_ERROR;
      this.error = e instanceof Error ? e.message : 'Failed to scan directory';
      this.notifyDataChanged();
    }
  }

  /** Sort the file list in-place according to the configured mode and order. */
  private sortFileList(names: string[]): void {
    const ascending = this.sortOrder === 'asc';

    if (this.sortMode === 'name_lexicographic') {
      names.sort((a, b) => {
        const cmp = a.toLowerCase().localeCompare(b.toLowerCase());
        return ascending ? cmp : -cmp;
      });
    } else {
      // Default: NAME_NATURAL
      names.sort((a, b) => {
        const cmp = naturalCmp.compare(a, b);
        return ascending ? cmp : -cmp;
      });
    }
  }

  private processRequest(index: number): void {
    const data = this.readImageData(index);
    if (data !== null) {
      this.notifyPageSucceed(index, data);
    } else {
      this.notifyPageFailed(index, this.error ?? 'Failed to read image');
    }
  }

  private readImageData(index: number): Uint8Array | null {
    if (this.fileList === null || index < 0 || index >= this.fileList.length) {
      return null;
    }
    try {
      const filePath = joinPath(this.dirPath, this.fileList[index]);
      return this.fs.readFileSync(filePath);
    } catch (_e) {
      return null;
    }
  }
}
