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
import { isSupportedImageFile } from './GalleryProvider.ets';

// ---- ZIP format constants ----

const EOCD_SIGNATURE = 0x06054b50;
const CD_SIGNATURE = 0x02014b50;
const LOCAL_HEADER_SIGNATURE = 0x04034b50;
const LOCAL_HEADER_FIXED_SIZE = 30;

const COMPRESSION_STORED = 0;
const COMPRESSION_DEFLATE = 8;

/** Maximum bytes to scan backwards from EOF to find the EOCD record. */
const EOCD_MAX_SCAN = 65536 + 22;

/** Chunk size for streaming reads during extraction. */
const STREAM_CHUNK_SIZE = 65536;

// ---- Dependency interfaces ----

/**
 * Random-access byte reading for the archive file.
 * Production: backed by @ohos.file.fs or similar.
 * Tests: backed by in-memory buffer.
 */
export interface ArchiveFileHandle {
  /** Read `length` bytes starting at `offset`. */
  read(offset: number, length: number): Promise<Uint8Array>;
  /** Total file size in bytes. */
  readonly size: number;
  /** Release the file handle. */
  close(): void;
}

/**
 * Factory to open an archive file by path.
 */
export interface ArchiveFileOpener {
  open(filePath: string): Promise<ArchiveFileHandle>;
}

/**
 * Streaming DEFLATE decompressor.
 * Accepts compressed chunks and yields decompressed output.
 */
export interface Inflater {
  /** Push a compressed chunk. Returns decompressed output (may be empty). */
  inflate(data: Uint8Array): Uint8Array;
  /** Signal end of input. Returns any remaining decompressed data. */
  finish(): Uint8Array;
}

/**
 * Factory for creating Inflater instances.
 * Production: uses @ohos.zlib or pako.
 * Tests: uses node:zlib.
 */
export interface InflaterFactory {
  create(): Inflater;
}

// ---- ZIP Central Directory entry (parsed) ----

interface CentralDirEntry {
  fileName: string;
  compressionMethod: number;
  compressedSize: number;
  uncompressedSize: number;
  localHeaderOffset: number;
}

// ---- StreamingZipEntry ----

/**
 * A single entry in a ZIP archive that supports both full extraction and
 * streaming chunk-by-chunk decompression.
 */
class StreamingZipEntry implements ArchiveEntry {
  readonly path: string;
  readonly uncompressedSize: number;

  private readonly handle: ArchiveFileHandle;
  private readonly inflaterFactory: InflaterFactory;
  private readonly cdEntry: CentralDirEntry;

  constructor(
    handle: ArchiveFileHandle,
    inflaterFactory: InflaterFactory,
    cdEntry: CentralDirEntry,
  ) {
    this.handle = handle;
    this.inflaterFactory = inflaterFactory;
    this.cdEntry = cdEntry;
    this.path = cdEntry.fileName;
    this.uncompressedSize = cdEntry.uncompressedSize;
  }

  /**
   * Extract full entry content at once.
   */
  async extract(): Promise<Uint8Array> {
    const chunks: Uint8Array[] = [];
    let totalLen = 0;
    for await (const chunk of this.openStream()) {
      chunks.push(chunk);
      totalLen += chunk.length;
    }
    // Fast path: single chunk
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

  /**
   * Open a streaming decompression read.
   * Yields decompressed chunks on-the-fly without buffering the entire entry.
   * This is the core streaming API for memory-efficient archive reading.
   */
  async *openStream(): AsyncIterable<Uint8Array> {
    // Read the local file header to find the actual data offset
    const dataOffset = await this.getDataOffset();
    const { compressedSize, compressionMethod } = this.cdEntry;

    if (compressionMethod === COMPRESSION_STORED) {
      // Stored: no compression, just read raw bytes in chunks
      let remaining = compressedSize;
      let readPos = dataOffset;
      while (remaining > 0) {
        const chunkLen = Math.min(STREAM_CHUNK_SIZE, remaining);
        const chunk = await this.handle.read(readPos, chunkLen);
        yield chunk;
        readPos += chunk.length;
        remaining -= chunk.length;
      }
    } else if (compressionMethod === COMPRESSION_DEFLATE) {
      // Deflate: read compressed chunks and inflate on-the-fly
      const inflater = this.inflaterFactory.create();
      let remaining = compressedSize;
      let readPos = dataOffset;

      while (remaining > 0) {
        const chunkLen = Math.min(STREAM_CHUNK_SIZE, remaining);
        const compressed = await this.handle.read(readPos, chunkLen);
        const decompressed = inflater.inflate(compressed);
        if (decompressed.length > 0) {
          yield decompressed;
        }
        readPos += compressed.length;
        remaining -= compressed.length;
      }

      const final = inflater.finish();
      if (final.length > 0) {
        yield final;
      }
    } else {
      throw new Error(`Unsupported compression method: ${compressionMethod}`);
    }
  }

  /**
   * Read the local file header to determine where compressed data begins.
   */
  private async getDataOffset(): Promise<number> {
    const headerBuf = await this.handle.read(
      this.cdEntry.localHeaderOffset,
      LOCAL_HEADER_FIXED_SIZE,
    );
    const view = new DataView(headerBuf.buffer, headerBuf.byteOffset, headerBuf.byteLength);
    const sig = view.getUint32(0, true);
    if (sig !== LOCAL_HEADER_SIGNATURE) {
      throw new Error('Invalid local file header signature');
    }
    const fileNameLen = view.getUint16(26, true);
    const extraLen = view.getUint16(28, true);
    return this.cdEntry.localHeaderOffset + LOCAL_HEADER_FIXED_SIZE + fileNameLen + extraLen;
  }
}

// ---- ZIP parsing helpers ----

function readUint16LE(buf: Uint8Array, offset: number): number {
  return buf[offset] | (buf[offset + 1] << 8);
}

function readUint32LE(buf: Uint8Array, offset: number): number {
  return (buf[offset] | (buf[offset + 1] << 8) |
    (buf[offset + 2] << 16) | (buf[offset + 3] << 24)) >>> 0;
}

/**
 * Find the End of Central Directory record by scanning backwards from EOF.
 * Returns the offset of the EOCD signature within the buffer.
 */
function findEOCD(buf: Uint8Array): number {
  // EOCD is at least 22 bytes; signature at the start
  for (let i = buf.length - 22; i >= 0; i--) {
    if (readUint32LE(buf, i) === EOCD_SIGNATURE) {
      return i;
    }
  }
  return -1;
}

/**
 * Parse the Central Directory from the given buffer starting at `offset`.
 * Returns parsed entries.
 */
function parseCentralDirectory(buf: Uint8Array, offset: number, count: number): CentralDirEntry[] {
  const entries: CentralDirEntry[] = [];
  let pos = offset;

  for (let i = 0; i < count; i++) {
    if (pos + 46 > buf.length) break;
    const sig = readUint32LE(buf, pos);
    if (sig !== CD_SIGNATURE) break;

    const compressionMethod = readUint16LE(buf, pos + 10);
    const compressedSize = readUint32LE(buf, pos + 20);
    const uncompressedSize = readUint32LE(buf, pos + 24);
    const fileNameLen = readUint16LE(buf, pos + 28);
    const extraLen = readUint16LE(buf, pos + 30);
    const commentLen = readUint16LE(buf, pos + 32);
    const localHeaderOffset = readUint32LE(buf, pos + 42);

    const fileNameBytes = buf.slice(pos + 46, pos + 46 + fileNameLen);
    const fileName = new TextDecoder().decode(fileNameBytes);

    entries.push({
      fileName,
      compressionMethod,
      compressedSize,
      uncompressedSize,
      localHeaderOffset,
    });

    pos += 46 + fileNameLen + extraLen + commentLen;
  }

  return entries;
}

// ---- StreamingZipReader ----

/**
 * Streaming ZIP archive reader that parses ZIP files and provides
 * chunk-by-chunk decompression of image entries.
 *
 * Key features:
 * - Reads the ZIP central directory for efficient random access to entries
 * - Decompresses entries on-the-fly via async generator (streaming)
 * - Supports STORED (no compression) and DEFLATE methods
 * - Uses dependency injection for file I/O and decompression (testable)
 *
 * Usage:
 * ```
 * const reader = new StreamingZipReader(fileOpener, inflaterFactory);
 * const entries = await reader.open('/path/to/archive.zip');
 * for await (const chunk of (entries[0] as StreamingZipEntry).openStream()) {
 *   // process chunk
 * }
 * reader.close();
 * ```
 */
export class StreamingZipReader implements ArchiveReader {
  private readonly fileOpener: ArchiveFileOpener;
  private readonly inflaterFactory: InflaterFactory;
  private handle: ArchiveFileHandle | null = null;

  constructor(fileOpener: ArchiveFileOpener, inflaterFactory: InflaterFactory) {
    this.fileOpener = fileOpener;
    this.inflaterFactory = inflaterFactory;
  }

  /**
   * Open a ZIP archive and return its image entries.
   * Parses the central directory for O(1) access to each entry's data.
   *
   * @param filePath Path to the ZIP file
   * @returns Array of archive entries with streaming support
   */
  async open(filePath: string): Promise<ArchiveEntry[]> {
    this.handle = await this.fileOpener.open(filePath);
    const fileSize = this.handle.size;

    // Read the tail of the file to find the EOCD
    const scanLen = Math.min(EOCD_MAX_SCAN, fileSize);
    const tailBuf = await this.handle.read(fileSize - scanLen, scanLen);
    const eocdOffset = findEOCD(tailBuf);
    if (eocdOffset < 0) {
      throw new Error('Not a valid ZIP file: EOCD not found');
    }

    // Parse EOCD
    const totalEntries = readUint16LE(tailBuf, eocdOffset + 10);
    const cdSize = readUint32LE(tailBuf, eocdOffset + 12);
    const cdOffset = readUint32LE(tailBuf, eocdOffset + 16);

    // Read and parse the Central Directory
    const cdBuf = await this.handle.read(cdOffset, cdSize);
    const cdEntries = parseCentralDirectory(cdBuf, 0, totalEntries);

    // Filter to supported image entries and wrap as StreamingZipEntry
    const imageEntries: ArchiveEntry[] = [];
    for (const cd of cdEntries) {
      // Skip directories
      if (cd.fileName.endsWith('/')) continue;
      if (!isSupportedImageFile(cd.fileName)) continue;

      imageEntries.push(
        new StreamingZipEntry(this.handle, this.inflaterFactory, cd),
      );
    }

    return imageEntries;
  }

  close(): void {
    if (this.handle !== null) {
      this.handle.close();
      this.handle = null;
    }
  }
}

// Re-export StreamingZipEntry type for streaming access
export type { StreamingZipEntry };
