import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

import { DirGalleryProvider } from '../../../main/ets/gallery/DirGalleryProvider.ets';
import type { DirGalleryFsOps } from '../../../main/ets/gallery/DirGalleryProvider.ets';
import { STATE_ERROR } from '../../../main/ets/gallery/GalleryProvider.ets';
import type { GalleryProviderListener } from '../../../main/ets/gallery/GalleryProvider.ets';

// ---- In-memory filesystem mock ----

class MemoryFs implements DirGalleryFsOps {
  private dirs: Map<string, string[]> = new Map();
  private files: Map<string, Uint8Array> = new Map();

  addDir(path: string, names: string[]): void {
    this.dirs.set(path, names);
  }

  addFile(path: string, data: Uint8Array): void {
    this.files.set(path, data);
  }

  readdirSync(dirPath: string): string[] {
    const names = this.dirs.get(dirPath);
    if (names === undefined) throw new Error(`Not a directory: ${dirPath}`);
    return names;
  }

  readFileSync(path: string): Uint8Array {
    const data = this.files.get(path);
    if (data === undefined) throw new Error(`File not found: ${path}`);
    return data;
  }

  writeFileSync(path: string, data: Uint8Array): void {
    this.files.set(path, data);
  }

  existsSync(path: string): boolean {
    return this.dirs.has(path) || this.files.has(path);
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

describe('DirGalleryProvider', () => {
  let fs: MemoryFs;
  let listener: TestListener;
  const DIR = '/gallery/test';

  beforeEach(() => {
    fs = new MemoryFs();
    listener = new TestListener();
  });

  function createProvider(): DirGalleryProvider {
    const p = new DirGalleryProvider(DIR, fs);
    p.addListener(listener);
    return p;
  }

  it('should scan directory and report page count on start', () => {
    fs.addDir(DIR, ['002.jpg', '001.png', 'readme.txt', '003.gif']);
    fs.addFile(`${DIR}/001.png`, new Uint8Array([1]));
    fs.addFile(`${DIR}/002.jpg`, new Uint8Array([2]));
    fs.addFile(`${DIR}/003.gif`, new Uint8Array([3]));

    const provider = createProvider();
    provider.start();

    assert.strictEqual(provider.size(), 3);
    assert.strictEqual(listener.dataChangedCount, 1);
  });

  it('should sort files by natural order', () => {
    fs.addDir(DIR, ['page10.jpg', 'page2.jpg', 'page1.jpg']);
    fs.addFile(`${DIR}/page1.jpg`, new Uint8Array([1]));
    fs.addFile(`${DIR}/page2.jpg`, new Uint8Array([2]));
    fs.addFile(`${DIR}/page10.jpg`, new Uint8Array([10]));

    const provider = createProvider();
    provider.start();

    assert.strictEqual(provider.size(), 3);
    // Natural order: page1 < page2 < page10
    assert.strictEqual(provider.getImageFilename(0), 'page1');
    assert.strictEqual(provider.getImageFilename(1), 'page2');
    assert.strictEqual(provider.getImageFilename(2), 'page10');
  });

  it('should filter out non-image files', () => {
    fs.addDir(DIR, ['img.jpg', 'doc.txt', 'data.json', 'pic.png']);
    fs.addFile(`${DIR}/img.jpg`, new Uint8Array([1]));
    fs.addFile(`${DIR}/pic.png`, new Uint8Array([2]));

    const provider = createProvider();
    provider.start();

    assert.strictEqual(provider.size(), 2);
  });

  it('should report STATE_ERROR for non-existent directory', () => {
    const provider = createProvider();
    provider.start();

    assert.strictEqual(provider.size(), STATE_ERROR);
    assert.ok(provider.getError() !== null);
    assert.strictEqual(listener.dataChangedCount, 1);
  });

  it('should serve image data on request', () => {
    const imgData = new Uint8Array([0xFF, 0xD8, 0xFF]);
    fs.addDir(DIR, ['photo.jpg']);
    fs.addFile(`${DIR}/photo.jpg`, imgData);

    const provider = createProvider();
    provider.start();
    provider.request(0);

    assert.strictEqual(listener.pageWaits.length, 1);
    assert.strictEqual(listener.pageSucceeds.length, 1);
    assert.deepStrictEqual(listener.pageSucceeds[0].data, imgData);
  });

  it('should fail for out-of-range index', () => {
    fs.addDir(DIR, ['img.jpg']);
    fs.addFile(`${DIR}/img.jpg`, new Uint8Array([1]));

    const provider = createProvider();
    provider.start();
    provider.request(5);

    assert.strictEqual(listener.pageFails.length, 1);
  });

  it('should handle empty directory', () => {
    fs.addDir(DIR, []);

    const provider = createProvider();
    provider.start();

    assert.strictEqual(provider.size(), 0);
    assert.strictEqual(provider.getError(), null);
  });

  it('should return image filename without extension', () => {
    fs.addDir(DIR, ['photo.jpg']);
    fs.addFile(`${DIR}/photo.jpg`, new Uint8Array([1]));

    const provider = createProvider();
    provider.start();

    assert.strictEqual(provider.getImageFilename(0), 'photo');
  });

  it('should return index as string for invalid index', () => {
    fs.addDir(DIR, []);

    const provider = createProvider();
    provider.start();

    assert.strictEqual(provider.getImageFilename(99), '99');
  });

  it('should save image to destination path', () => {
    const imgData = new Uint8Array([1, 2, 3]);
    fs.addDir(DIR, ['img.png']);
    fs.addFile(`${DIR}/img.png`, imgData);

    const provider = createProvider();
    provider.start();

    const result = provider.save(0, '/tmp/saved.png');
    assert.ok(result);
    assert.deepStrictEqual(fs.getFile('/tmp/saved.png'), imgData);
  });

  it('should save image to directory with filename', () => {
    const imgData = new Uint8Array([4, 5, 6]);
    fs.addDir(DIR, ['pic.jpeg']);
    fs.addFile(`${DIR}/pic.jpeg`, imgData);

    const provider = createProvider();
    provider.start();

    const path = provider.saveToDir(0, '/output', 'saved_pic');
    assert.strictEqual(path, '/output/saved_pic.jpeg');
    assert.deepStrictEqual(fs.getFile('/output/saved_pic.jpeg'), imgData);
  });

  it('should return false when saving invalid index', () => {
    fs.addDir(DIR, []);

    const provider = createProvider();
    provider.start();

    assert.ok(!provider.save(0, '/tmp/x.jpg'));
  });

  it('should cancel request correctly', () => {
    fs.addDir(DIR, ['img.jpg']);
    fs.addFile(`${DIR}/img.jpg`, new Uint8Array([1]));

    const provider = createProvider();
    provider.start();
    // cancelRequest is a no-op for sync provider, just verify no crash
    provider.cancelRequest(0);
  });

  it('forceRequest should behave same as request', () => {
    const imgData = new Uint8Array([7, 8, 9]);
    fs.addDir(DIR, ['img.png']);
    fs.addFile(`${DIR}/img.png`, imgData);

    const provider = createProvider();
    provider.start();
    provider.forceRequest(0);

    assert.strictEqual(listener.pageSucceeds.length, 1);
    assert.deepStrictEqual(listener.pageSucceeds[0].data, imgData);
  });
});
