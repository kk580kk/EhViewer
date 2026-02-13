/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import type { GalleryProviderListener } from './GalleryProvider.ets';

/**
 * Unified interface for accessing a gallery as an indexed sequence of
 * image pages.
 *
 * Mirrors Android's GalleryProvider2 — the app-level contract that the
 * UI (reader, save-to-file, etc.) depends on. Three concrete sources
 * implement this interface:
 *   - EhGalleryProvider   — online gallery via spider
 *   - DirGalleryProvider   — local directory of images
 *   - ArchiveGalleryProvider — images inside a zip/7z archive
 *
 * Consumers should program against this interface rather than a specific
 * implementation.
 */
export interface GalleryProvider2 {

  // ---- Lifecycle ----

  /** Start the provider (begin accepting page requests). */
  start(): void;

  /** Stop the provider (cancel pending work, release resources). */
  stop(): void;

  /** Whether the provider is currently started. */
  isStarted(): boolean;

  // ---- Page information ----

  /**
   * Return the number of pages, or a negative sentinel:
   *   STATE_WAIT  (-1) — page count not yet known
   *   STATE_ERROR (-2) — an error occurred
   */
  size(): number;

  /** Return a human-readable error string, or null if no error. */
  getError(): string | null;

  // ---- Reading position persistence ----

  /** Return the page to start/resume reading from. */
  getStartPage(): number;

  /** Persist the current reading position. */
  putStartPage(page: number): void;

  // ---- Image access ----

  /**
   * Return a filename (without extension) suitable for saving the image
   * at `index`.
   */
  getImageFilename(index: number): string;

  /**
   * Save the image at `index` by writing its bytes to `destPath`.
   * Returns true on success.
   */
  save(index: number, destPath: string): boolean;

  /**
   * Save the image at `index` into `dir` with the given base `filename`
   * (extension is appended automatically).
   * Returns the final file path, or null on failure.
   */
  saveToDir(index: number, dir: string, filename: string): string | null;

  // ---- Page request / cancel ----

  /** Request loading of the page at `index`. */
  request(index: number): void;

  /** Force-reload the page at `index` (bypass cache). */
  forceRequest(index: number): void;

  /** Cancel a pending request for the page at `index`. */
  cancelRequest(index: number): void;

  // ---- Listener management ----

  /** Register a listener for page state changes. */
  addListener(listener: GalleryProviderListener): void;

  /** Unregister a previously registered listener. */
  removeListener(listener: GalleryProviderListener): void;
}
