import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import * as zlib from 'node:zlib';

import { StreamingZipReader } from '../../../main/ets/gallery/StreamingZipReader.ets';
import type {
  ArchiveFileHandle,
  ArchiveFileOpener,
  Inflater,
  InflaterFactory,
  StreamingZipEntry,
} from '../../../main/ets/gallery/StreamingZipReader.ets';
import type { ArchiveEntry } from '../../../main/ets/gallery/ArchiveGalleryProvider.ets';

// ---- In-memory ZIP builder ----

/**
 * Minimal in-memory ZIP file builder for testing.
 * Supports STORED and DEFLATE compression methods.
 */
class ZipBuilder {
  private entries: { name: string; data: Uint8Array; method: number }[] = [];

  addStored(name: string, data: Uint8Array): void {
    this.entries.push({ name, data, method: 0 });
  }

  addDeflated(name: string, data: Uint8Array): void {
    this.entries.push({ name, data, method: 8 });
  }

  build(): Uint8Array {
    const parts: Uint8Array[] = [];
    const cdEntries: {
      name: Uint8Array;
      method: number;
      crc32: number;
      compressedSize: number;
      uncompressedSize: number;
      localOffset: number;
    }[] = [];

    let offset = 0;

    // Write local file headers + data
    for (const entry of this.entries) {
      const nameBytes = new TextEncoder().encode(entry.name);
      const uncompressed = entry.data;
      const crc = crc32(uncompressed);
      let compressed: Uint8Array;

      if (entry.method === 8) {
        // DEFLATE: use raw deflate (no zlib header)
        compressed = zlib.deflateRawSync(Buffer.from(uncompressed));
      } else {
        compressed = uncompressed;
      }

      // Local file header (30 bytes + name + data)
      const header = new Uint8Array(30);
      const hv = new DataView(header.buffer);
      hv.setUint32(0, 0x04034b50, true); // signature
      hv.setUint16(4, 20, true);          // version needed
      hv.setUint16(6, 0, true);           // flags
      hv.setUint16(8, entry.method, true); // compression method
      hv.setUint16(10, 0, true);           // mod time
      hv.setUint16(12, 0, true);           // mod date
      hv.setUint32(14, crc, true);         // crc32
      hv.setUint32(18, compressed.length, true); // compressed size
      hv.setUint32(22, uncompressed.length, true); // uncompressed size
      hv.setUint16(26, nameBytes.length, true); // name length
      hv.setUint16(28, 0, true);           // extra length

      cdEntries.push({
        name: nameBytes,
        method: entry.method,
        crc32: crc,
        compressedSize: compressed.length,
        uncompressedSize: uncompressed.length,
        localOffset: offset,
      });

      parts.push(header);
      parts.push(nameBytes);
      parts.push(compressed);
      offset += header.length + nameBytes.length + compressed.length;
    }

    // Central directory
    const cdStart = offset;
    for (const cd of cdEntries) {
      const cdHeader = new Uint8Array(46);
      const cv = new DataView(cdHeader.buffer);
      cv.setUint32(0, 0x02014b50, true);  // signature
      cv.setUint16(4, 20, true);           // version made by
      cv.setUint16(6, 20, true);           // version needed
      cv.setUint16(8, 0, true);            // flags
      cv.setUint16(10, cd.method, true);   // compression method
      cv.setUint16(12, 0, true);           // mod time
      cv.setUint16(14, 0, true);           // mod date
      cv.setUint32(16, cd.crc32, true);    // crc32
      cv.setUint32(20, cd.compressedSize, true);
      cv.setUint32(24, cd.uncompressedSize, true);
      cv.setUint16(28, cd.name.length, true);
      cv.setUint16(30, 0, true);           // extra length
      cv.setUint16(32, 0, true);           // comment length
      cv.setUint16(34, 0, true);           // disk number
      cv.setUint16(36, 0, true);           // internal attrs
      cv.setUint32(38, 0, true);           // external attrs
      cv.setUint32(42, cd.localOffset, true);

      parts.push(cdHeader);
      parts.push(cd.name);
      offset += cdHeader.length + cd.name.length;
    }
    const cdEnd = offset;

    // End of Central Directory
    const eocd = new Uint8Array(22);
    const ev = new DataView(eocd.buffer);
    ev.setUint32(0, 0x06054b50, true);  // signature
    ev.setUint16(4, 0, true);           // disk number
    ev.setUint16(6, 0, true);           // cd disk number
    ev.setUint16(8, cdEntries.length, true);  // cd entries on disk
    ev.setUint16(10, cdEntries.length, true); // total cd entries
    ev.setUint32(12, cdEnd - cdStart, true);  // cd size
    ev.setUint32(16, cdStart, true);          // cd offset
    ev.setUint16(20, 0, true);                // comment length
    parts.push(eocd);

    // Concatenate all parts
    const totalSize = parts.reduce((sum, p) => sum + p.length, 0);
    const result = new Uint8Array(totalSize);
    let pos = 0;
    for (const part of parts) {
      result.set(part, pos);
      pos += part.length;
    }
    return result;
  }
}

// ---- CRC32 ----

function crc32(data: Uint8Array): number {
  let crc = 0xFFFFFFFF;
  for (let i = 0; i < data.length; i++) {
    crc ^= data[i];
    for (let j = 0; j < 8; j++) {
      crc = (crc >>> 1) ^ (crc & 1 ? 0xEDB88320 : 0);
    }
  }
  return (crc ^ 0xFFFFFFFF) >>> 0;
}

// ---- In-memory ArchiveFileHandle ----

class MemoryFileHandle implements ArchiveFileHandle {
  private readonly data: Uint8Array;
  readonly size: number;
  closed = false;

  constructor(data: Uint8Array) {
    this.data = data;
    this.size = data.length;
  }

  async read(offset: number, length: number): Promise<Uint8Array> {
    return this.data.slice(offset, offset + length);
  }

  close(): void {
    this.closed = true;
  }
}

// ---- In-memory ArchiveFileOpener ----

class MemoryFileOpener implements ArchiveFileOpener {
  private files: Map<string, Uint8Array> = new Map();
  lastOpenedHandle: MemoryFileHandle | null = null;

  addFile(path: string, data: Uint8Array): void {
    this.files.set(path, data);
  }

  async open(filePath: string): Promise<ArchiveFileHandle> {
    const data = this.files.get(filePath);
    if (!data) throw new Error(`File not found: ${filePath}`);
    this.lastOpenedHandle = new MemoryFileHandle(data);
    return this.lastOpenedHandle;
  }
}

// ---- Node.js Inflater using zlib ----

class NodeInflater implements Inflater {
  private chunks: Buffer[] = [];

  inflate(data: Uint8Array): Uint8Array {
    // Accumulate — node:zlib inflateRaw is synchronous only for full data
    // For streaming, we accumulate and decompress on finish
    this.chunks.push(Buffer.from(data));
    return new Uint8Array(0);
  }

  finish(): Uint8Array {
    const compressed = Buffer.concat(this.chunks);
    if (compressed.length === 0) return new Uint8Array(0);
    const result = zlib.inflateRawSync(compressed);
    return new Uint8Array(result);
  }
}

class NodeInflaterFactory implements InflaterFactory {
  create(): Inflater {
    return new NodeInflater();
  }
}

// ---- Helper: collect async iterable ----

async function collectStream(iterable: AsyncIterable<Uint8Array>): Promise<Uint8Array> {
  const chunks: Uint8Array[] = [];
  let total = 0;
  for await (const chunk of iterable) {
    chunks.push(chunk);
    total += chunk.length;
  }
  if (chunks.length === 1) return chunks[0];
  const result = new Uint8Array(total);
  let off = 0;
  for (const c of chunks) {
    result.set(c, off);
    off += c.length;
  }
  return result;
}

// ---- Tests ----

describe('StreamingZipReader', () => {
  let opener: MemoryFileOpener;
  let inflaterFactory: NodeInflaterFactory;
  const ZIP_PATH = '/test/archive.zip';

  beforeEach(() => {
    opener = new MemoryFileOpener();
    inflaterFactory = new NodeInflaterFactory();
  });

  function createReader(): StreamingZipReader {
    return new StreamingZipReader(opener, inflaterFactory);
  }

  // ---- Opening and entry discovery ----

  it('should find image entries in a ZIP file', async () => {
    const builder = new ZipBuilder();
    builder.addStored('image1.jpg', new Uint8Array([1, 2, 3]));
    builder.addStored('image2.png', new Uint8Array([4, 5, 6]));
    builder.addStored('readme.txt', new Uint8Array([7, 8, 9]));
    opener.addFile(ZIP_PATH, builder.build());

    const reader = createReader();
    const entries = await reader.open(ZIP_PATH);

    assert.strictEqual(entries.length, 2);
    reader.close();
  });

  it('should skip directories', async () => {
    const builder = new ZipBuilder();
    builder.addStored('dir/', new Uint8Array(0));
    builder.addStored('dir/photo.jpg', new Uint8Array([1, 2, 3]));
    opener.addFile(ZIP_PATH, builder.build());

    const reader = createReader();
    const entries = await reader.open(ZIP_PATH);

    assert.strictEqual(entries.length, 1);
    assert.strictEqual(entries[0].path, 'dir/photo.jpg');
    reader.close();
  });

  it('should handle case-insensitive extensions', async () => {
    const builder = new ZipBuilder();
    builder.addStored('PHOTO.JPG', new Uint8Array([1]));
    builder.addStored('image.Png', new Uint8Array([2]));
    builder.addStored('pic.GIF', new Uint8Array([3]));
    opener.addFile(ZIP_PATH, builder.build());

    const reader = createReader();
    const entries = await reader.open(ZIP_PATH);

    assert.strictEqual(entries.length, 3);
    reader.close();
  });

  it('should throw for invalid ZIP data', async () => {
    opener.addFile(ZIP_PATH, new Uint8Array([0, 0, 0, 0]));
    const reader = createReader();

    await assert.rejects(
      () => reader.open(ZIP_PATH),
      { message: /EOCD not found/ },
    );
    reader.close();
  });

  // ---- Stored entries (no compression) ----

  it('should extract stored entry via extract()', async () => {
    const data = new Uint8Array([10, 20, 30, 40, 50]);
    const builder = new ZipBuilder();
    builder.addStored('test.jpg', data);
    opener.addFile(ZIP_PATH, builder.build());

    const reader = createReader();
    const entries = await reader.open(ZIP_PATH);
    const result = await entries[0].extract();

    assert.deepStrictEqual(result, data);
    reader.close();
  });

  it('should stream stored entry via openStream()', async () => {
    const data = new Uint8Array([1, 2, 3, 4, 5, 6, 7, 8]);
    const builder = new ZipBuilder();
    builder.addStored('test.jpg', data);
    opener.addFile(ZIP_PATH, builder.build());

    const reader = createReader();
    const entries = await reader.open(ZIP_PATH);
    const entry = entries[0] as StreamingZipEntry;
    const result = await collectStream(entry.openStream());

    assert.deepStrictEqual(result, data);
    reader.close();
  });

  it('should expose uncompressedSize', async () => {
    const data = new Uint8Array(100);
    data.fill(42);
    const builder = new ZipBuilder();
    builder.addStored('test.jpg', data);
    opener.addFile(ZIP_PATH, builder.build());

    const reader = createReader();
    const entries = await reader.open(ZIP_PATH);
    const entry = entries[0] as StreamingZipEntry;

    assert.strictEqual(entry.uncompressedSize, 100);
    reader.close();
  });

  // ---- Deflated entries ----

  it('should extract deflated entry via extract()', async () => {
    const data = new Uint8Array(256);
    for (let i = 0; i < 256; i++) data[i] = i & 0xFF;

    const builder = new ZipBuilder();
    builder.addDeflated('compressed.jpg', data);
    opener.addFile(ZIP_PATH, builder.build());

    const reader = createReader();
    const entries = await reader.open(ZIP_PATH);
    const result = await entries[0].extract();

    assert.deepStrictEqual(result, data);
    reader.close();
  });

  it('should stream deflated entry via openStream()', async () => {
    const data = new Uint8Array(1024);
    for (let i = 0; i < 1024; i++) data[i] = i % 251;

    const builder = new ZipBuilder();
    builder.addDeflated('compressed.png', data);
    opener.addFile(ZIP_PATH, builder.build());

    const reader = createReader();
    const entries = await reader.open(ZIP_PATH);
    const entry = entries[0] as StreamingZipEntry;
    const result = await collectStream(entry.openStream());

    assert.deepStrictEqual(result, data);
    reader.close();
  });

  // ---- Multiple entries + random access ----

  it('should support random access to entries', async () => {
    const data0 = new Uint8Array([10, 20, 30]);
    const data1 = new Uint8Array([40, 50, 60]);
    const data2 = new Uint8Array([70, 80, 90]);

    const builder = new ZipBuilder();
    builder.addStored('a.jpg', data0);
    builder.addStored('b.png', data1);
    builder.addStored('c.gif', data2);
    opener.addFile(ZIP_PATH, builder.build());

    const reader = createReader();
    const entries = await reader.open(ZIP_PATH);

    // Access in reverse order
    assert.deepStrictEqual(await entries[2].extract(), data2);
    assert.deepStrictEqual(await entries[0].extract(), data0);
    assert.deepStrictEqual(await entries[1].extract(), data1);

    // Access same entry twice
    assert.deepStrictEqual(await entries[1].extract(), data1);
    reader.close();
  });

  // ---- Large data ----

  it('should handle large stored entries', async () => {
    const data = new Uint8Array(100_000);
    for (let i = 0; i < data.length; i++) data[i] = i & 0xFF;

    const builder = new ZipBuilder();
    builder.addStored('large.jpg', data);
    opener.addFile(ZIP_PATH, builder.build());

    const reader = createReader();
    const entries = await reader.open(ZIP_PATH);
    const result = await entries[0].extract();

    assert.strictEqual(result.length, 100_000);
    assert.deepStrictEqual(result, data);
    reader.close();
  });

  it('should handle large deflated entries', async () => {
    const data = new Uint8Array(100_000);
    for (let i = 0; i < data.length; i++) data[i] = i % 127;

    const builder = new ZipBuilder();
    builder.addDeflated('large.png', data);
    opener.addFile(ZIP_PATH, builder.build());

    const reader = createReader();
    const entries = await reader.open(ZIP_PATH);
    const result = await entries[0].extract();

    assert.strictEqual(result.length, 100_000);
    assert.deepStrictEqual(result, data);
    reader.close();
  });

  // ---- Mixed compression methods ----

  it('should handle mixed stored and deflated entries', async () => {
    const storedData = new Uint8Array([1, 2, 3]);
    const deflateData = new Uint8Array(200);
    for (let i = 0; i < 200; i++) deflateData[i] = i % 50;

    const builder = new ZipBuilder();
    builder.addStored('stored.jpg', storedData);
    builder.addDeflated('deflated.png', deflateData);
    opener.addFile(ZIP_PATH, builder.build());

    const reader = createReader();
    const entries = await reader.open(ZIP_PATH);

    assert.strictEqual(entries.length, 2);
    assert.deepStrictEqual(await entries[0].extract(), storedData);
    assert.deepStrictEqual(await entries[1].extract(), deflateData);
    reader.close();
  });

  // ---- Resource cleanup ----

  it('should close file handle on close()', async () => {
    const builder = new ZipBuilder();
    builder.addStored('test.jpg', new Uint8Array([1]));
    opener.addFile(ZIP_PATH, builder.build());

    const reader = createReader();
    await reader.open(ZIP_PATH);
    reader.close();

    assert.ok(opener.lastOpenedHandle!.closed);
  });

  it('should handle close without open', () => {
    const reader = createReader();
    // Should not throw
    reader.close();
  });

  // ---- Streaming yields multiple chunks for large stored data ----

  it('should yield multiple chunks for large stored entries', async () => {
    // Create data larger than STREAM_CHUNK_SIZE (65536)
    const data = new Uint8Array(200_000);
    for (let i = 0; i < data.length; i++) data[i] = i & 0xFF;

    const builder = new ZipBuilder();
    builder.addStored('big.jpg', data);
    opener.addFile(ZIP_PATH, builder.build());

    const reader = createReader();
    const entries = await reader.open(ZIP_PATH);
    const entry = entries[0] as StreamingZipEntry;

    let chunkCount = 0;
    const chunks: Uint8Array[] = [];
    let total = 0;
    for await (const chunk of entry.openStream()) {
      chunkCount++;
      chunks.push(chunk);
      total += chunk.length;
    }

    // Should have been split into multiple chunks
    assert.ok(chunkCount > 1, `Expected multiple chunks, got ${chunkCount}`);
    assert.strictEqual(total, data.length);

    // Verify assembled data matches
    const assembled = new Uint8Array(total);
    let off = 0;
    for (const c of chunks) {
      assembled.set(c, off);
      off += c.length;
    }
    assert.deepStrictEqual(assembled, data);
    reader.close();
  });

  // ---- Empty archive (only non-image files) ----

  it('should return empty entries for archive with no images', async () => {
    const builder = new ZipBuilder();
    builder.addStored('readme.txt', new Uint8Array([1]));
    builder.addStored('data.json', new Uint8Array([2]));
    opener.addFile(ZIP_PATH, builder.build());

    const reader = createReader();
    const entries = await reader.open(ZIP_PATH);

    assert.strictEqual(entries.length, 0);
    reader.close();
  });
});
