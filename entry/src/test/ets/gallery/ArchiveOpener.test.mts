import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import * as zlib from 'node:zlib';

import {
  ArchiveOpener,
  detectFormatByExtension,
  detectFormatByMagic,
} from '../../../main/ets/gallery/ArchiveOpener.ets';
import type { ArchiveEntry } from '../../../main/ets/gallery/ArchiveGalleryProvider.ets';
import type {
  ArchiveFileHandle,
  ArchiveFileOpener,
  Inflater,
  InflaterFactory,
} from '../../../main/ets/gallery/StreamingZipReader.ets';

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

// ---- Minimal ZIP builder ----

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

    for (const entry of this.entries) {
      const nameBytes = new TextEncoder().encode(entry.name);
      const uncompressed = entry.data;
      const crc = crc32(uncompressed);
      const compressed = entry.method === 8
        ? new Uint8Array(zlib.deflateRawSync(Buffer.from(uncompressed)))
        : uncompressed;

      const header = new Uint8Array(30);
      const hv = new DataView(header.buffer);
      hv.setUint32(0, 0x04034b50, true);
      hv.setUint16(4, 20, true);
      hv.setUint16(8, entry.method, true);
      hv.setUint32(14, crc, true);
      hv.setUint32(18, compressed.length, true);
      hv.setUint32(22, uncompressed.length, true);
      hv.setUint16(26, nameBytes.length, true);

      cdEntries.push({
        name: nameBytes,
        method: entry.method,
        crc32: crc,
        compressedSize: compressed.length,
        uncompressedSize: uncompressed.length,
        localOffset: offset,
      });

      parts.push(header, nameBytes, compressed);
      offset += header.length + nameBytes.length + compressed.length;
    }

    const cdStart = offset;
    for (const cd of cdEntries) {
      const cdHeader = new Uint8Array(46);
      const cv = new DataView(cdHeader.buffer);
      cv.setUint32(0, 0x02014b50, true);
      cv.setUint16(4, 20, true);
      cv.setUint16(6, 20, true);
      cv.setUint16(10, cd.method, true);
      cv.setUint32(16, cd.crc32, true);
      cv.setUint32(20, cd.compressedSize, true);
      cv.setUint32(24, cd.uncompressedSize, true);
      cv.setUint16(28, cd.name.length, true);
      cv.setUint32(42, cd.localOffset, true);

      parts.push(cdHeader, cd.name);
      offset += cdHeader.length + cd.name.length;
    }
    const cdEnd = offset;

    const eocd = new Uint8Array(22);
    const ev = new DataView(eocd.buffer);
    ev.setUint32(0, 0x06054b50, true);
    ev.setUint16(8, cdEntries.length, true);
    ev.setUint16(10, cdEntries.length, true);
    ev.setUint32(12, cdEnd - cdStart, true);
    ev.setUint32(16, cdStart, true);
    parts.push(eocd);

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

// ---- In-memory file handle ----

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

// ---- In-memory file opener ----

class MemoryFileOpener implements ArchiveFileOpener {
  private files: Map<string, Uint8Array> = new Map();
  handles: MemoryFileHandle[] = [];

  addFile(path: string, data: Uint8Array): void {
    this.files.set(path, data);
  }

  async open(filePath: string): Promise<ArchiveFileHandle> {
    const data = this.files.get(filePath);
    if (!data) throw new Error(`File not found: ${filePath}`);
    const handle = new MemoryFileHandle(data);
    this.handles.push(handle);
    return handle;
  }
}

// ---- Node.js Inflater ----

class NodeInflater implements Inflater {
  private chunks: Buffer[] = [];

  inflate(data: Uint8Array): Uint8Array {
    this.chunks.push(Buffer.from(data));
    return new Uint8Array(0);
  }

  finish(): Uint8Array {
    const compressed = Buffer.concat(this.chunks);
    if (compressed.length === 0) return new Uint8Array(0);
    return new Uint8Array(zlib.inflateRawSync(compressed));
  }
}

class NodeInflaterFactory implements InflaterFactory {
  create(): Inflater {
    return new NodeInflater();
  }
}

// ---- Tests ----

describe('detectFormatByExtension', () => {
  it('should detect .zip', () => {
    assert.strictEqual(detectFormatByExtension('/path/to/file.zip'), 'zip');
  });

  it('should detect .ZIP (case insensitive)', () => {
    assert.strictEqual(detectFormatByExtension('/path/to/FILE.ZIP'), 'zip');
  });

  it('should detect .cbz as zip', () => {
    assert.strictEqual(detectFormatByExtension('archive.cbz'), 'zip');
  });

  it('should detect .7z', () => {
    assert.strictEqual(detectFormatByExtension('/path/to/file.7z'), '7z');
  });

  it('should return unknown for unsupported extensions', () => {
    assert.strictEqual(detectFormatByExtension('/path/to/file.rar'), 'unknown');
    assert.strictEqual(detectFormatByExtension('/path/to/file.tar'), 'unknown');
    assert.strictEqual(detectFormatByExtension('/path/to/file.txt'), 'unknown');
  });
});

describe('detectFormatByMagic', () => {
  it('should detect ZIP by PK signature', () => {
    const header = new Uint8Array([0x50, 0x4B, 0x03, 0x04, 0x00, 0x00]);
    assert.strictEqual(detectFormatByMagic(header), 'zip');
  });

  it('should detect 7z by magic bytes', () => {
    const header = new Uint8Array([0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C]);
    assert.strictEqual(detectFormatByMagic(header), '7z');
  });

  it('should return unknown for unrecognized magic bytes', () => {
    const header = new Uint8Array([0x00, 0x00, 0x00, 0x00, 0x00, 0x00]);
    assert.strictEqual(detectFormatByMagic(header), 'unknown');
  });

  it('should return unknown for empty buffer', () => {
    assert.strictEqual(detectFormatByMagic(new Uint8Array(0)), 'unknown');
  });

  it('should prefer 7z over zip when 7z magic matches', () => {
    // 7z magic is checked first
    const header = new Uint8Array([0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C]);
    assert.strictEqual(detectFormatByMagic(header), '7z');
  });
});

describe('ArchiveOpener', () => {
  let opener: MemoryFileOpener;
  let inflaterFactory: NodeInflaterFactory;

  beforeEach(() => {
    opener = new MemoryFileOpener();
    inflaterFactory = new NodeInflaterFactory();
  });

  function createArchiveOpener(): ArchiveOpener {
    return new ArchiveOpener(opener, inflaterFactory);
  }

  // ---- ZIP support ----

  it('should open .zip files and return image entries', async () => {
    const builder = new ZipBuilder();
    builder.addStored('page1.jpg', new Uint8Array([1, 2, 3]));
    builder.addStored('page2.png', new Uint8Array([4, 5, 6]));
    builder.addStored('readme.txt', new Uint8Array([7, 8, 9]));
    opener.addFile('/test/archive.zip', builder.build());

    const archiveOpener = createArchiveOpener();
    const entries = await archiveOpener.open('/test/archive.zip');

    assert.strictEqual(entries.length, 2);
    archiveOpener.close();
  });

  it('should open .cbz files as zip', async () => {
    const builder = new ZipBuilder();
    builder.addStored('cover.jpg', new Uint8Array([10, 20]));
    opener.addFile('/test/comic.cbz', builder.build());

    const archiveOpener = createArchiveOpener();
    const entries = await archiveOpener.open('/test/comic.cbz');

    assert.strictEqual(entries.length, 1);
    assert.strictEqual(entries[0].path, 'cover.jpg');
    archiveOpener.close();
  });

  it('should extract data from zip entries correctly', async () => {
    const imgData = new Uint8Array([0xFF, 0xD8, 0xFF, 0xE0]);
    const builder = new ZipBuilder();
    builder.addStored('photo.jpg', imgData);
    opener.addFile('/test/test.zip', builder.build());

    const archiveOpener = createArchiveOpener();
    const entries = await archiveOpener.open('/test/test.zip');
    const data = await entries[0].extract();

    assert.deepStrictEqual(data, imgData);
    archiveOpener.close();
  });

  it('should handle deflated zip entries', async () => {
    const imgData = new Uint8Array(256);
    for (let i = 0; i < 256; i++) imgData[i] = i & 0xFF;

    const builder = new ZipBuilder();
    builder.addDeflated('compressed.jpg', imgData);
    opener.addFile('/test/compressed.zip', builder.build());

    const archiveOpener = createArchiveOpener();
    const entries = await archiveOpener.open('/test/compressed.zip');
    const data = await entries[0].extract();

    assert.deepStrictEqual(data, imgData);
    archiveOpener.close();
  });

  // ---- 7z: unsupported ----

  it('should throw for .7z files with descriptive message', async () => {
    // Fake 7z file with correct magic bytes
    const fake7z = new Uint8Array([0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C, 0x00, 0x00]);
    opener.addFile('/test/archive.7z', fake7z);

    const archiveOpener = createArchiveOpener();

    await assert.rejects(
      () => archiveOpener.open('/test/archive.7z'),
      (err: Error) => {
        assert.ok(err.message.includes('7z'));
        assert.ok(err.message.includes('not yet available'));
        return true;
      },
    );
    archiveOpener.close();
  });

  // ---- Unknown format ----

  it('should throw for unrecognized format by extension and magic', async () => {
    const randomData = new Uint8Array([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06]);
    opener.addFile('/test/archive.rar', randomData);

    const archiveOpener = createArchiveOpener();

    await assert.rejects(
      () => archiveOpener.open('/test/archive.rar'),
      (err: Error) => {
        assert.ok(err.message.includes('Unrecognized'));
        return true;
      },
    );
    archiveOpener.close();
  });

  // ---- Magic-byte fallback ----

  it('should detect zip by magic bytes when extension is unknown', async () => {
    const builder = new ZipBuilder();
    builder.addStored('image.jpg', new Uint8Array([1, 2, 3]));
    const zipData = builder.build();
    // Use a non-standard extension
    opener.addFile('/test/archive.dat', zipData);

    const archiveOpener = createArchiveOpener();
    const entries = await archiveOpener.open('/test/archive.dat');

    assert.strictEqual(entries.length, 1);
    archiveOpener.close();
  });

  it('should detect 7z by magic bytes when extension is unknown', async () => {
    const fake7z = new Uint8Array([0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C, 0x00, 0x00]);
    opener.addFile('/test/archive.dat', fake7z);

    const archiveOpener = createArchiveOpener();

    await assert.rejects(
      () => archiveOpener.open('/test/archive.dat'),
      (err: Error) => {
        assert.ok(err.message.includes('7z'));
        return true;
      },
    );
    archiveOpener.close();
  });

  // ---- Resource cleanup ----

  it('should close delegate reader on close()', async () => {
    const builder = new ZipBuilder();
    builder.addStored('img.jpg', new Uint8Array([1]));
    opener.addFile('/test/test.zip', builder.build());

    const archiveOpener = createArchiveOpener();
    await archiveOpener.open('/test/test.zip');
    archiveOpener.close();

    // The file handle opened by the delegate should be closed
    const lastHandle = opener.handles[opener.handles.length - 1];
    assert.ok(lastHandle.closed);
  });

  it('should handle close without open', () => {
    const archiveOpener = createArchiveOpener();
    // Should not throw
    archiveOpener.close();
  });

  it('should handle double close', async () => {
    const builder = new ZipBuilder();
    builder.addStored('img.jpg', new Uint8Array([1]));
    opener.addFile('/test/test.zip', builder.build());

    const archiveOpener = createArchiveOpener();
    await archiveOpener.open('/test/test.zip');
    archiveOpener.close();
    // Second close should not throw
    archiveOpener.close();
  });
});
