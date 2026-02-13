/*
 * Copyright 2024 EhViewer Contributors
 * Ported to HarmonyOS ArkTS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

/**
 * Central specification for application file and path conventions.
 *
 * Download and gallery modules must use these constants and helpers so that:
 * - Downloaded galleries live under a root download dir in directories named
 *   `{gid}-{sanitized_title}`.
 * - Images inside a gallery directory are named with an 8-digit index plus
 *   extension (e.g. `00000001.jpg`).
 * - EhGallery display/save filenames (no extension) use
 *   `{gid}-{token}-{index_8d}`.
 * - Directory names for cache, share, temp, image save, and download are
 *   consistent across AppConfig and any path resolution.
 */

// ---- Directory name constants ----

/** Subdir under cache for temporary file sharing. */
export const SHARE_DIR = 'share';
/** Subdir under cache for temp files. */
export const TEMP_DIR = 'temp';
/** Subdir for image save location. */
export const IMAGE_DIR = 'image';
/** Subdir for default download root. */
export const DOWNLOAD_DIR = 'download';

/**
 * Supported image file extensions for gallery and download, with leading dot.
 * Order may be used as default when extension is unknown.
 */
export const SUPPORT_IMAGE_EXTENSIONS: readonly string[] = [
  '.jpg',
  '.jpeg',
  '.png',
  '.gif',
];

// ---- Characters illegal in filenames ----

/** Characters that are stripped from filenames during sanitization. */
const ILLEGAL_FILENAME_CHARS = /[/\\:*?"<>|\x00-\x1f]/g;

/**
 * Sanitize a string for use as a filename.
 *
 * Replaces path separators and other illegal characters with '_',
 * trims leading/trailing whitespace, and truncates to a reasonable
 * max length (255 chars, the common filesystem limit).
 *
 * Returns the sanitized string, or null if the result would be empty.
 */
export function sanitizeFilename(name: string): string | null {
  let sanitized = name.replace(ILLEGAL_FILENAME_CHARS, '_');
  sanitized = sanitized.trim();
  // Remove leading dots (hidden files on Unix)
  while (sanitized.startsWith('.')) {
    sanitized = sanitized.slice(1);
  }
  sanitized = sanitized.trim();
  if (sanitized.length === 0) {
    return null;
  }
  // Truncate to 255 characters (common FS limit)
  if (sanitized.length > 255) {
    sanitized = sanitized.slice(0, 255);
  }
  return sanitized;
}

// ---- Gallery download directory ----

/**
 * Build the gallery download directory name: `{gid}-{suitableTitle}`,
 * sanitized for filesystem use.
 *
 * @param gid gallery id
 * @param suitableTitle title suitable for display (e.g. from EhUtils.getSuitableTitle)
 * @returns sanitized dirname
 */
export function formatGalleryDirname(gid: number, suitableTitle: string): string {
  const raw = `${gid}-${suitableTitle}`;
  const sanitized = sanitizeFilename(raw);
  return sanitized !== null ? sanitized : raw;
}

// ---- Downloaded image filename (on disk) ----

/**
 * Format for a single image file inside a gallery download directory:
 * 8-digit 1-based index plus extension (e.g. 00000001.jpg).
 *
 * @param index 0-based page index
 * @param extensionWithDot extension including dot (e.g. ".jpg")
 * @returns filename for the image file
 */
export function formatDownloadImageFilename(index: number, extensionWithDot: string): string {
  const num = (index + 1).toString().padStart(8, '0');
  return `${num}${extensionWithDot}`;
}

/**
 * Check whether the given extension (with dot) is one of the supported image types.
 */
export function isSupportedImageExtension(extensionWithDot: string): boolean {
  const lower = extensionWithDot.toLowerCase();
  return SUPPORT_IMAGE_EXTENSIONS.some(ext => ext === lower);
}

/**
 * Normalize an extension to a supported one; returns the first supported
 * extension if unknown.
 *
 * @param extensionWithDot extension including dot
 * @returns a supported extension (with dot)
 */
export function normalizeImageExtension(extensionWithDot: string): string {
  if (isSupportedImageExtension(extensionWithDot)) {
    return extensionWithDot.toLowerCase();
  }
  return SUPPORT_IMAGE_EXTENSIONS[0];
}

// ---- EhGallery display / save filename (no extension) ----

/**
 * Display/save filename for EhGallery (online) images, without extension.
 * Format: `{gid}-{token}-{index_8d}`.
 *
 * @param gid gallery id
 * @param token gallery token
 * @param index 0-based page index
 * @returns filename without extension
 */
export function formatEhGalleryImageFilename(gid: number, token: string, index: number): string {
  const num = (index + 1).toString().padStart(8, '0');
  return `${gid}-${token}-${num}`;
}
