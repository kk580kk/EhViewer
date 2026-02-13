/*
 * Copyright 2019 Hippo Seven
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
 * An entry inside an archive (zip, 7z, etc.).
 */
export interface ArchiveEntry {
  /** Relative path inside the archive. */
  readonly path: string;
  /** Extract this entry's content as raw bytes. */
  extract(): Promise<Uint8Array>;
}

/**
 * Extended entry that supports streaming extraction.
 * When available, the provider uses this for memory-efficient reading
 * and progress reporting.
 */
export interface StreamableArchiveEntry extends ArchiveEntry {
  /** Known uncompressed size in bytes (for progress calculation). */
  readonly uncompressedSize: number;
  /**
   * Open a streaming decompression read.
   * Yields decompressed chunks on-the-fly without buffering the entire entry.
   */
  openStream(): AsyncIterable<Uint8Array>;
}

/**
 * Type guard: check if an ArchiveEntry supports streaming extraction.
 */
export function isStreamable(entry: ArchiveEntry): entry is StreamableArchiveEntry {
  return typeof (entry as StreamableArchiveEntry).openStream === 'function'
    && typeof (entry as StreamableArchiveEntry).uncompressedSize === 'number';
}

/**
 * Abstraction over archive reading.
 *
 * Production: backed by a zip/7z library.
 * Tests: backed by in-memory data.
 */
export interface ArchiveReader {
  /**
   * Open an archive at the given file path and return its entries.
   * Only image entries should be included.
   */
  open(filePath: string): Promise<ArchiveEntry[]>;
  /** Release resources. */
  close(): void;
}

/**
 * Filesystem operations needed by ArchiveGalleryProvider for saving.
 */
export interface ArchiveFsOps {
  writeFileSync(path: string, data: Uint8Array): void;
  existsSync(path: string): boolean;
}

const naturalCmp = new NaturalComparator();

/**
 * Gallery provider that reads images from an archive file (zip, 7z).
 *
 * Mirrors the Android ArchiveGalleryProvider. On start(), it opens the
 * archive, filters image entries, sorts them by natural order, and
 * serves them on request.
 *
 * When entries support streaming (StreamableArchiveEntry), the provider
 * reads chunks on-the-fly with progress reporting, reducing peak memory usage.
 */
export class ArchiveGalleryProvider extends GalleryProvider {

  private readonly filePath: string;
  private readonly reader: ArchiveReader;
  private readonly fs: ArchiveFsOps;

  private entries: ArchiveEntry[] | null = null;
  private pageCount: number = STATE_WAIT;
  private error: string | null = null;

  /** Cache of already-extracted image data, keyed by page index. */
  private cache: Map<number, Uint8Array> = new Map();

  /** Set of page indices with active extractions (for cancellation). */
  private activeExtractions: Set<number> = new Set();

  constructor(filePath: string, reader: ArchiveReader, fs: ArchiveFsOps) {
    super();
    this.filePath = filePath;
    this.reader = reader;
    this.fs = fs;
  }

  override start(): void {
    super.start();
    this.openArchive();
  }

  override stop(): void {
    super.stop();
    this.reader.close();
    this.cache.clear();
    this.activeExtractions.clear();
  }

  override size(): number {
    return this.pageCount;
  }

  override getError(): string | null {
    return this.error;
  }

  override getImageFilename(index: number): string {
    if (this.entries !== null && index >= 0 && index < this.entries.length) {
      return getNameWithoutExtension(this.entries[index].path);
    }
    return index.toString();
  }

  override save(index: number, destPath: string): boolean {
    const data = this.cache.get(index);
    if (data === undefined) return false;
    try {
      this.fs.writeFileSync(destPath, data);
      return true;
    } catch (_e) {
      return false;
    }
  }

  override saveToDir(index: number, dir: string, filename: string): string | null {
    if (this.entries === null || index < 0 || index >= this.entries.length) {
      return null;
    }
    const ext = getExtension(this.entries[index].path);
    const destName = ext.length > 0 ? `${filename}.${ext}` : filename;
    const destPath = joinPath(dir, destName);
    return this.save(index, destPath) ? destPath : null;
  }

  protected override onRequest(index: number): void {
    const cached = this.cache.get(index);
    if (cached !== undefined) {
      this.notifyPageSucceed(index, cached);
      return;
    }
    this.notifyPageWait(index);
    this.extractEntry(index);
  }

  protected override onForceRequest(index: number): void {
    this.cache.delete(index);
    this.notifyPageWait(index);
    this.extractEntry(index);
  }

  protected override onCancelRequest(index: number): void {
    this.activeExtractions.delete(index);
  }

  // ---- Internal ----

  private openArchive(): void {
    this.reader.open(this.filePath).then(rawEntries => {
      // Filter to supported images and sort by natural path order
      const imageEntries = rawEntries.filter(e => isSupportedImageFile(e.path));
      imageEntries.sort((a, b) => naturalCmp.compare(a.path, b.path));

      this.entries = imageEntries;
      this.pageCount = imageEntries.length;
      this.notifyDataChanged();
    }).catch((e: Error) => {
      this.pageCount = STATE_ERROR;
      this.error = e.message ?? 'Failed to open archive';
      this.notifyDataChanged();
    });
  }

  private extractEntry(index: number): void {
    if (this.entries === null || index < 0 || index >= this.entries.length) {
      this.notifyPageFailed(index, 'Index out of range');
      return;
    }

    const entry = this.entries[index];

    // Use streaming extraction when available for memory efficiency + progress
    if (isStreamable(entry)) {
      this.extractStreaming(index, entry);
    } else {
      this.extractFull(index, entry);
    }
  }

  /**
   * Streaming extraction: read chunks on-the-fly, report progress,
   * and assemble the final buffer. Supports cancellation.
   */
  private extractStreaming(index: number, entry: StreamableArchiveEntry): void {
    this.activeExtractions.add(index);
    const totalSize = entry.uncompressedSize;

    (async () => {
      const chunks: Uint8Array[] = [];
      let receivedBytes = 0;

      for await (const chunk of entry.openStream()) {
        // Check cancellation / stopped
        if (!this.isStarted() || !this.activeExtractions.has(index)) {
          return;
        }

        chunks.push(chunk);
        receivedBytes += chunk.length;

        // Report progress
        if (totalSize > 0) {
          const percent = Math.min(receivedBytes / totalSize, 1.0);
          this.notifyPagePercent(index, percent);
        }
      }

      if (!this.isStarted() || !this.activeExtractions.has(index)) {
        return;
      }

      // Assemble final buffer
      const data = assembleChunks(chunks, receivedBytes);
      this.activeExtractions.delete(index);
      this.cache.set(index, data);
      this.notifyPageSucceed(index, data);
    })().catch((e: Error) => {
      this.activeExtractions.delete(index);
      if (!this.isStarted()) return;
      this.notifyPageFailed(index, e.message ?? 'Streaming extraction failed');
    });
  }

  /**
   * Full extraction: legacy path for entries that don't support streaming.
   */
  private extractFull(index: number, entry: ArchiveEntry): void {
    entry.extract().then(data => {
      if (!this.isStarted()) return;
      this.cache.set(index, data);
      this.notifyPageSucceed(index, data);
    }).catch((e: Error) => {
      if (!this.isStarted()) return;
      this.notifyPageFailed(index, e.message ?? 'Extraction failed');
    });
  }
}

/**
 * Concatenate chunks into a single Uint8Array.
 */
function assembleChunks(chunks: Uint8Array[], totalLen: number): Uint8Array {
  if (chunks.length === 1) {
    return chunks[0];
  }
  const result = new Uint8Array(totalLen);
  let offset = 0;
  for (const chunk of chunks) {
    result.set(chunk, offset);
    offset += chunk.length;
  }
  return result;
}
