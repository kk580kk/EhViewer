/*
 * Copyright 2024 EhViewer Contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import type { ArchiveReader, ArchiveEntry } from './ArchiveGalleryProvider.ets';
import { StreamingZipReader } from './StreamingZipReader.ets';
import type { ArchiveFileOpener, InflaterFactory } from './StreamingZipReader.ets';

/**
 * Supported archive formats.
 */
export type ArchiveFormat = 'zip' | '7z' | 'unknown';

// ---- Magic byte signatures ----

/** ZIP files start with PK\x03\x04 (local file header) or PK\x05\x06 (empty archive). */
const ZIP_MAGIC_PK = new Uint8Array([0x50, 0x4B]);

/** 7z files start with '7z\xBC\xAF\x27\x1C'. */
const SEVENZ_MAGIC = new Uint8Array([0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C]);

// ---- Format detection ----

/**
 * Detect archive format from file extension.
 */
export function detectFormatByExtension(filePath: string): ArchiveFormat {
  const lower = filePath.toLowerCase();
  if (lower.endsWith('.zip') || lower.endsWith('.cbz')) {
    return 'zip';
  }
  if (lower.endsWith('.7z')) {
    return '7z';
  }
  return 'unknown';
}

/**
 * Detect archive format from magic bytes at the start of the file.
 * Requires at least 6 bytes to detect 7z; 2 bytes for zip.
 */
export function detectFormatByMagic(header: Uint8Array): ArchiveFormat {
  if (header.length >= SEVENZ_MAGIC.length && matchesPrefix(header, SEVENZ_MAGIC)) {
    return '7z';
  }
  if (header.length >= ZIP_MAGIC_PK.length && matchesPrefix(header, ZIP_MAGIC_PK)) {
    return 'zip';
  }
  return 'unknown';
}

function matchesPrefix(data: Uint8Array, prefix: Uint8Array): boolean {
  for (let i = 0; i < prefix.length; i++) {
    if (data[i] !== prefix[i]) return false;
  }
  return true;
}

// ---- ArchiveOpener ----

/**
 * Unified archive opener that detects the archive format and delegates
 * to the appropriate reader implementation.
 *
 * Currently supported:
 *   - ZIP / CBZ — via StreamingZipReader
 *
 * Planned (not yet available in ArkTS):
 *   - 7z — requires native NAPI module or pure-TS LZMA implementation
 *
 * Usage:
 * ```
 * const opener = new ArchiveOpener(fileOpener, inflaterFactory);
 * const entries = await opener.open('/path/to/archive.zip');
 * // ... use entries ...
 * opener.close();
 * ```
 */
export class ArchiveOpener implements ArchiveReader {
  private readonly fileOpener: ArchiveFileOpener;
  private readonly inflaterFactory: InflaterFactory;

  /** The underlying reader, created during open(). */
  private delegate: ArchiveReader | null = null;

  constructor(fileOpener: ArchiveFileOpener, inflaterFactory: InflaterFactory) {
    this.fileOpener = fileOpener;
    this.inflaterFactory = inflaterFactory;
  }

  /**
   * Open an archive file. Detects the format and delegates to the
   * appropriate reader.
   *
   * @param filePath Path to the archive file
   * @returns Image entries from the archive
   * @throws Error if the format is unsupported or unrecognized
   */
  async open(filePath: string): Promise<ArchiveEntry[]> {
    // First try extension-based detection
    let format = detectFormatByExtension(filePath);

    // For unknown extensions, try magic-byte detection
    if (format === 'unknown') {
      const handle = await this.fileOpener.open(filePath);
      try {
        const header = await handle.read(0, Math.min(6, handle.size));
        format = detectFormatByMagic(header);
      } finally {
        handle.close();
      }
    }

    switch (format) {
      case 'zip': {
        const reader = new StreamingZipReader(this.fileOpener, this.inflaterFactory);
        this.delegate = reader;
        return reader.open(filePath);
      }
      case '7z':
        // TODO: Implement 7z support once an ArkTS-compatible LZMA/7z
        // library becomes available (native NAPI module or pure-TS).
        throw new Error(
          'Unsupported archive format: 7z. ' +
          '7z decompression is not yet available in ArkTS. ' +
          'Please use ZIP/CBZ format instead.'
        );
      default:
        throw new Error(`Unrecognized archive format for file: ${filePath}`);
    }
  }

  close(): void {
    if (this.delegate !== null) {
      this.delegate.close();
      this.delegate = null;
    }
  }
}
