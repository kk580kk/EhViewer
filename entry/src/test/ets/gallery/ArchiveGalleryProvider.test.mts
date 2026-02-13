import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

import { ArchiveGalleryProvider } from '../../../main/ets/gallery/ArchiveGalleryProvider.ets';
import type {
  ArchiveReader,
  ArchiveEntry,
  ArchiveFsOps,
} from '../../../main/ets/gallery/ArchiveGalleryProvider.ets';
import { STATE_ERROR, STATE_WAIT } from '../../../main/ets/gallery/GalleryProvider.ets';
import type { GalleryProviderListener } from '../../../main/ets/gallery/GalleryProvider.ets';

// ---- Helper: flush pending microtasks ----

async function flush(): Promise<void> {
  await new Promise(resolve => setTimeout(resolve, 0));
}

// ---- In-memory ArchiveEntry ----

class MemoryArchiveEntry implements ArchiveEntry {
  readonly path: string;
  private readonly data: Uint8Array;

  constructor(path: string, data: Uint8Array) {
    this.path = path;
    this.data = data;
  }

  async extract(): Promise<Uint8Array> {
    return this.data;
  }
}

// ---- Failing ArchiveEntry (extract() rejects) ----

class FailingArchiveEntry implements ArchiveEntry {
  readonly path: string;
  private readonly errorMsg: string;

  constructor(path: string, errorMsg: string) {
    this.path = path;
    this.errorMsg = errorMsg;
  }

  async extract(): Promise<Uint8Array> {
    throw new Error(this.errorMsg);
  }
}

// ---- In-memory ArchiveReader ----

class MemoryArchiveReader implements ArchiveReader {
  private entries: ArchiveEntry[] = [];
  private shouldFail = false;
  private failMessage = '';
  closed = false;

  setEntries(entries: ArchiveEntry[]): void {
    this.entries = entries;
  }

  setFailOnOpen(message: string): void {
    this.shouldFail = true;
    this.failMessage = message;
  }

  async open(_filePath: string): Promise<ArchiveEntry[]> {
    if (this.shouldFail) {
      throw new Error(this.failMessage);
    }
    return this.entries;
  }

  close(): void {
    this.closed = true;
  }
}

// ---- In-memory ArchiveFsOps ----

class MemoryFs implements ArchiveFsOps {
  private files: Map<string, Uint8Array> = new Map();

  writeFileSync(path: string, data: Uint8Array): void {
    this.files.set(path, data);
  }

  existsSync(path: string): boolean {
    return this.files.has(path);
  }

  getFile(path: string): Uint8Array | undefined {
    return this.files.get(path);
  }
}

// ---- Test listener ----

class TestListener implements GalleryProviderListener {
  dataChangedCount = 0;
  pageWaits: number[] = [];
  pagePercents: { index: number; percent: number }[] = [];
  pageSucceeds: { index: number; data: Uint8Array }[] = [];
  pageFails: { index: number; error: string }[] = [];

  onDataChanged(): void { this.dataChangedCount++; }
  onPageWait(index: number): void { this.pageWaits.push(index); }
  onPagePercent(index: number, percent: number): void { this.pagePercents.push({ index, percent }); }
  onPageSucceed(index: number, data: Uint8Array): void { this.pageSucceeds.push({ index, data }); }
  onPageFailed(index: number, error: string): void { this.pageFails.push({ index, error }); }
}

// ---- Tests ----

describe('ArchiveGalleryProvider', () => {
  let reader: MemoryArchiveReader;
  let fs: MemoryFs;
  let listener: TestListener;
  const ARCHIVE_PATH = '/archives/test.zip';

  beforeEach(() => {
    reader = new MemoryArchiveReader();
    fs = new MemoryFs();
    listener = new TestListener();
  });

  function createProvider(): ArchiveGalleryProvider {
    const p = new ArchiveGalleryProvider(ARCHIVE_PATH, reader, fs);
    p.addListener(listener);
    return p;
  }

  // ---- Opening archive ----

  it('should report STATE_WAIT before start', () => {
    const provider = createProvider();
    assert.strictEqual(provider.size(), STATE_WAIT);
  });

  it('should open archive and report page count on start', async () => {
    reader.setEntries([
      new MemoryArchiveEntry('page1.jpg', new Uint8Array([1])),
      new MemoryArchiveEntry('page2.png', new Uint8Array([2])),
    ]);

    const provider = createProvider();
    provider.start();
    await flush();

    assert.strictEqual(provider.size(), 2);
    assert.strictEqual(listener.dataChangedCount, 1);
  });

  it('should filter non-image entries from archive', async () => {
    reader.setEntries([
      new MemoryArchiveEntry('image.jpg', new Uint8Array([1])),
      new MemoryArchiveEntry('readme.txt', new Uint8Array([2])),
      new MemoryArchiveEntry('data.json', new Uint8Array([3])),
      new MemoryArchiveEntry('photo.png', new Uint8Array([4])),
    ]);

    const provider = createProvider();
    provider.start();
    await flush();

    assert.strictEqual(provider.size(), 2);
  });

  it('should sort entries by natural path order', async () => {
    reader.setEntries([
      new MemoryArchiveEntry('page10.jpg', new Uint8Array([10])),
      new MemoryArchiveEntry('page2.jpg', new Uint8Array([2])),
      new MemoryArchiveEntry('page1.jpg', new Uint8Array([1])),
    ]);

    const provider = createProvider();
    provider.start();
    await flush();

    assert.strictEqual(provider.size(), 3);
    // Natural order: page1 < page2 < page10
    assert.strictEqual(provider.getImageFilename(0), 'page1');
    assert.strictEqual(provider.getImageFilename(1), 'page2');
    assert.strictEqual(provider.getImageFilename(2), 'page10');
  });

  it('should handle empty archive', async () => {
    reader.setEntries([]);

    const provider = createProvider();
    provider.start();
    await flush();

    assert.strictEqual(provider.size(), 0);
    assert.strictEqual(provider.getError(), null);
    assert.strictEqual(listener.dataChangedCount, 1);
  });

  it('should report STATE_ERROR when archive fails to open', async () => {
    reader.setFailOnOpen('Corrupted archive');

    const provider = createProvider();
    provider.start();
    await flush();

    assert.strictEqual(provider.size(), STATE_ERROR);
    assert.strictEqual(provider.getError(), 'Corrupted archive');
    assert.strictEqual(listener.dataChangedCount, 1);
  });

  // ---- Requesting pages ----

  it('should extract and serve page data on request', async () => {
    const imgData = new Uint8Array([0xFF, 0xD8, 0xFF]);
    reader.setEntries([
      new MemoryArchiveEntry('photo.jpg', imgData),
    ]);

    const provider = createProvider();
    provider.start();
    await flush();

    provider.request(0);
    await flush();

    assert.strictEqual(listener.pageWaits.length, 1);
    assert.strictEqual(listener.pageSucceeds.length, 1);
    assert.deepStrictEqual(listener.pageSucceeds[0].data, imgData);
  });

  it('should serve cached data without re-extracting', async () => {
    let extractCount = 0;
    const imgData = new Uint8Array([1, 2, 3]);
    const entry: ArchiveEntry = {
      path: 'img.jpg',
      async extract(): Promise<Uint8Array> {
        extractCount++;
        return imgData;
      },
    };
    reader.setEntries([entry]);

    const provider = createProvider();
    provider.start();
    await flush();

    // First request: extracts
    provider.request(0);
    await flush();
    assert.strictEqual(extractCount, 1);
    assert.strictEqual(listener.pageSucceeds.length, 1);

    // Second request: served from cache (no wait notification, direct succeed)
    provider.request(0);
    // Cache hit is synchronous — no flush needed
    assert.strictEqual(extractCount, 1); // Not extracted again
    assert.strictEqual(listener.pageSucceeds.length, 2);
  });

  it('should fail for out-of-range index', async () => {
    reader.setEntries([
      new MemoryArchiveEntry('img.jpg', new Uint8Array([1])),
    ]);

    const provider = createProvider();
    provider.start();
    await flush();

    provider.request(5);

    assert.strictEqual(listener.pageFails.length, 1);
    assert.ok(listener.pageFails[0].error.includes('out of range'));
  });

  it('should fail for negative index', async () => {
    reader.setEntries([
      new MemoryArchiveEntry('img.jpg', new Uint8Array([1])),
    ]);

    const provider = createProvider();
    provider.start();
    await flush();

    provider.request(-1);

    assert.strictEqual(listener.pageFails.length, 1);
  });

  it('should fail when entries are not yet loaded', () => {
    // Don't start — entries stay null
    const provider = createProvider();
    provider.request(0);

    assert.strictEqual(listener.pageFails.length, 1);
  });

  it('should notify failure when extraction rejects', async () => {
    reader.setEntries([
      new FailingArchiveEntry('broken.jpg', 'Decompression error'),
    ]);

    const provider = createProvider();
    provider.start();
    await flush();

    provider.request(0);
    await flush();

    assert.strictEqual(listener.pageFails.length, 1);
    assert.strictEqual(listener.pageFails[0].error, 'Decompression error');
  });

  // ---- forceRequest ----

  it('forceRequest should bypass cache and re-extract', async () => {
    let extractCount = 0;
    const imgData = new Uint8Array([1, 2, 3]);
    const entry: ArchiveEntry = {
      path: 'img.jpg',
      async extract(): Promise<Uint8Array> {
        extractCount++;
        return imgData;
      },
    };
    reader.setEntries([entry]);

    const provider = createProvider();
    provider.start();
    await flush();

    // First request
    provider.request(0);
    await flush();
    assert.strictEqual(extractCount, 1);

    // Force request: re-extracts
    provider.forceRequest(0);
    await flush();
    assert.strictEqual(extractCount, 2);
    assert.strictEqual(listener.pageSucceeds.length, 2);
  });

  // ---- getImageFilename ----

  it('should return filename without extension', async () => {
    reader.setEntries([
      new MemoryArchiveEntry('subdir/photo.jpg', new Uint8Array([1])),
    ]);

    const provider = createProvider();
    provider.start();
    await flush();

    assert.strictEqual(provider.getImageFilename(0), 'photo');
  });

  it('should return index as string for invalid index', async () => {
    reader.setEntries([]);

    const provider = createProvider();
    provider.start();
    await flush();

    assert.strictEqual(provider.getImageFilename(99), '99');
  });

  // ---- save / saveToDir ----

  it('should save cached image to destination path', async () => {
    const imgData = new Uint8Array([10, 20, 30]);
    reader.setEntries([
      new MemoryArchiveEntry('pic.png', imgData),
    ]);

    const provider = createProvider();
    provider.start();
    await flush();

    // Extract first to populate cache
    provider.request(0);
    await flush();

    const result = provider.save(0, '/tmp/saved.png');
    assert.ok(result);
    assert.deepStrictEqual(fs.getFile('/tmp/saved.png'), imgData);
  });

  it('should return false when saving uncached index', async () => {
    reader.setEntries([
      new MemoryArchiveEntry('pic.png', new Uint8Array([1])),
    ]);

    const provider = createProvider();
    provider.start();
    await flush();

    // Don't request — nothing in cache
    const result = provider.save(0, '/tmp/saved.png');
    assert.ok(!result);
  });

  it('should save image to directory with correct extension', async () => {
    const imgData = new Uint8Array([4, 5, 6]);
    reader.setEntries([
      new MemoryArchiveEntry('gallery/photo.jpeg', imgData),
    ]);

    const provider = createProvider();
    provider.start();
    await flush();

    provider.request(0);
    await flush();

    const path = provider.saveToDir(0, '/output', 'saved_pic');
    assert.strictEqual(path, '/output/saved_pic.jpeg');
    assert.deepStrictEqual(fs.getFile('/output/saved_pic.jpeg'), imgData);
  });

  it('should return null for saveToDir with invalid index', async () => {
    reader.setEntries([]);

    const provider = createProvider();
    provider.start();
    await flush();

    assert.strictEqual(provider.saveToDir(0, '/output', 'file'), null);
  });

  // ---- stop ----

  it('should close reader and clear cache on stop', async () => {
    reader.setEntries([
      new MemoryArchiveEntry('img.jpg', new Uint8Array([1])),
    ]);

    const provider = createProvider();
    provider.start();
    await flush();

    provider.request(0);
    await flush();

    provider.stop();

    assert.ok(reader.closed);
    assert.ok(!provider.isStarted());
  });

  it('should ignore extraction result after stop', async () => {
    let resolveExtract: ((data: Uint8Array) => void) | null = null;
    const entry: ArchiveEntry = {
      path: 'slow.jpg',
      extract(): Promise<Uint8Array> {
        return new Promise(resolve => { resolveExtract = resolve; });
      },
    };
    reader.setEntries([entry]);

    const provider = createProvider();
    provider.start();
    await flush();

    provider.request(0);
    // Stop before extraction completes
    provider.stop();

    // Now resolve the extraction
    resolveExtract!(new Uint8Array([1, 2, 3]));
    await flush();

    // Should NOT get a succeed notification (provider was stopped)
    assert.strictEqual(listener.pageSucceeds.length, 0);
  });

  // ---- cancelRequest ----

  it('cancelRequest should not throw', async () => {
    reader.setEntries([
      new MemoryArchiveEntry('img.jpg', new Uint8Array([1])),
    ]);

    const provider = createProvider();
    provider.start();
    await flush();

    // Should not throw
    provider.cancelRequest(0);
  });

  // ---- Archive with subdirectory paths ----

  it('should handle entries with subdirectory paths', async () => {
    reader.setEntries([
      new MemoryArchiveEntry('vol1/ch01/page2.jpg', new Uint8Array([2])),
      new MemoryArchiveEntry('vol1/ch01/page1.jpg', new Uint8Array([1])),
      new MemoryArchiveEntry('vol1/ch02/page1.png', new Uint8Array([3])),
    ]);

    const provider = createProvider();
    provider.start();
    await flush();

    assert.strictEqual(provider.size(), 3);
    // Natural sort of full paths
    assert.strictEqual(provider.getImageFilename(0), 'page1');
    assert.strictEqual(provider.getImageFilename(1), 'page2');
    assert.strictEqual(provider.getImageFilename(2), 'page1');
  });
});
