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

import type { GalleryProvider2 } from './GalleryProvider2.ets';

/**
 * Base gallery provider — abstract implementation of the GalleryProvider2
 * interface, providing listener management and request routing.
 *
 * Subclasses:
 *   - EhGalleryProvider   — online gallery via spider
 *   - DirGalleryProvider   — local directory of images
 *   - ArchiveGalleryProvider — images inside a zip/7z archive
 */

/** Returned by size() when page count is not yet known. */
export const STATE_WAIT = -1;

/** Returned by size() when an error occurred. */
export const STATE_ERROR = -2;

/** Sentinel for "no page index". */
export const INVALID_INDEX = -1;

/** Supported image file extensions (with leading dot, lower-case). */
export const SUPPORT_IMAGE_EXTENSIONS: string[] = [
  '.jpg',
  '.jpeg',
  '.png',
  '.gif',
];

/**
 * Check whether a filename has a supported image extension.
 */
export function isSupportedImageFile(name: string): boolean {
  const lower = name.toLowerCase();
  return SUPPORT_IMAGE_EXTENSIONS.some(ext => lower.endsWith(ext));
}

/**
 * Listener for gallery page state changes.
 * The UI layer implements this to react to data becoming available.
 */
export interface GalleryProviderListener {
  /** The overall data (page count) changed. */
  onDataChanged(): void;
  /** A specific page's data changed (image ready or updated). */
  onPageDataChanged?(index: number): void;
  /** A page is waiting to be loaded. */
  onPageWait(index: number): void;
  /** A page has loading progress (0.0 – 1.0). */
  onPagePercent(index: number, percent: number): void;
  /** A page's image data is ready. */
  onPageSucceed(index: number, data: Uint8Array): void;
  /** A page failed to load. */
  onPageFailed(index: number, error: string): void;
}

export abstract class GalleryProvider implements GalleryProvider2 {

  private listeners: GalleryProviderListener[] = [];
  private started = false;

  // ---- Lifecycle ----

  /** Start the provider (begin accepting requests). */
  start(): void {
    this.started = true;
  }

  /** Stop the provider (cancel pending work, release resources). */
  stop(): void {
    this.started = false;
  }

  isStarted(): boolean {
    return this.started;
  }

  // ---- Listener management ----

  addListener(listener: GalleryProviderListener): void {
    if (!this.listeners.includes(listener)) {
      this.listeners.push(listener);
    }
  }

  removeListener(listener: GalleryProviderListener): void {
    const idx = this.listeners.indexOf(listener);
    if (idx >= 0) {
      this.listeners.splice(idx, 1);
    }
  }

  // ---- Abstract: subclass must implement ----

  /**
   * Return the number of pages, or STATE_WAIT / STATE_ERROR.
   */
  abstract size(): number;

  /**
   * Return a human-readable error string, or null if no error.
   */
  abstract getError(): string | null;

  /**
   * Return the page to start reading from (persisted across sessions).
   */
  getStartPage(): number {
    return 0;
  }

  /**
   * Persist the current reading position.
   */
  putStartPage(_page: number): void {
    // default: no-op
  }

  /**
   * Return a filename (without extension) suitable for saving page `index`.
   */
  abstract getImageFilename(index: number): string;

  /**
   * Save the image at `index` by writing its bytes to `destPath`.
   * Returns true on success.
   */
  abstract save(index: number, destPath: string): boolean;

  /**
   * Save the image at `index` into `dir` with the given base `filename`
   * (extension is appended automatically).
   * Returns the final file path, or null on failure.
   */
  abstract saveToDir(index: number, dir: string, filename: string): string | null;

  // ---- Request interface (called by UI / reader) ----

  /** Request loading of page `index`. */
  request(index: number): void {
    this.onRequest(index);
  }

  /** Force-reload page `index` (ignore cache). */
  forceRequest(index: number): void {
    this.onForceRequest(index);
  }

  /** Cancel a pending request for page `index`. */
  cancelRequest(index: number): void {
    this.onCancelRequest(index);
  }

  // ---- Abstract request handlers ----

  protected abstract onRequest(index: number): void;
  protected abstract onForceRequest(index: number): void;
  protected abstract onCancelRequest(index: number): void;

  // ---- Notification helpers (called by subclass) ----

  protected notifyDataChanged(): void {
    for (const l of this.listeners) {
      l.onDataChanged();
    }
  }

  protected notifyPageDataChanged(index: number): void {
    for (const l of this.listeners) {
      l.onPageDataChanged?.(index);
    }
  }

  protected notifyPageWait(index: number): void {
    for (const l of this.listeners) {
      l.onPageWait(index);
    }
  }

  protected notifyPagePercent(index: number, percent: number): void {
    for (const l of this.listeners) {
      l.onPagePercent(index, percent);
    }
  }

  protected notifyPageSucceed(index: number, data: Uint8Array): void {
    for (const l of this.listeners) {
      l.onPageSucceed(index, data);
    }
  }

  protected notifyPageFailed(index: number, error: string): void {
    for (const l of this.listeners) {
      l.onPageFailed(index, error);
    }
  }
}
