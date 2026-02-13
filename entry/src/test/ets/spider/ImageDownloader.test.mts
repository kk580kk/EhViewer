import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

import { SpiderInfo } from '../../../main/ets/spider/SpiderInfo.ets';
import { SpiderDen, MODE_DOWNLOAD } from '../../../main/ets/spider/SpiderDen.ets';
import type { SpiderDenFsOps, ImageCache } from '../../../main/ets/spider/SpiderDen.ets';
import { SpiderQueen } from '../../../main/ets/spider/SpiderQueen.ets';
import type { PreviewFetcher } from '../../../main/ets/spider/SpiderQueen.ets';
import {
  ImageDownloader,
  PageState,
} from '../../../main/ets/spider/ImageDownloader.ets';
import type {
  ImageFetcher,
  ImageFetchResult,
  ImageDownloadListener,
} from '../../../main/ets/spider/ImageDownloader.ets';
import type { GalleryPageFetcher } from '../../../main/ets/client/EhEngineGalleryPageFetcher.ets';
import type { GalleryPageResult } from '../../../main/ets/client/parser/GalleryPageParser.ets';
import type { GalleryPageApiResult } from '../../../main/ets/client/parser/GalleryPageApiParser.ets';
import { PreviewSet } from '../../../main/ets/model/PreviewSet';
import type { GalleryPreview } from '../../../main/ets/model/GalleryPreview';
import { EhUrl } from '../../../main/ets/client/EhUrl.ets';
import { SettingsService } from '../../../main/ets/service/SettingsService.ets';
import { MemoryPreferencesStore } from '../../../main/ets/preferences/MemoryPreferencesStore.ets';

// ---- Mock implementations ----

class MockFsOps implements SpiderDenFsOps {
  files: Map<string, string | Uint8Array> = new Map();
  dirs: Set<string> = new Set();

  existsSync(path: string): boolean { return this.files.has(path) || this.dirs.has(path); }
  mkdirSync(path: string): void { this.dirs.add(path); }
  statSync(path: string): { isDirectory(): boolean; isFile(): boolean } {
    if (this.dirs.has(path)) return { isDirectory: () => true, isFile: () => false };
    return { isDirectory: () => false, isFile: () => true };
  }
  writeFileSync(path: string, data: string, _encoding?: string): void { this.files.set(path, data); }
  unlinkSync(path: string): void { this.files.delete(path); }
  readFileSync(path: string, _encoding?: string): string | Uint8Array {
    const data = this.files.get(path);
    if (data === undefined) throw new Error('ENOENT');
    return data;
  }
  readdirSync(dirPath: string): string[] {
    const result: string[] = [];
    for (const path of this.files.keys()) {
      if (path.startsWith(dirPath + '/')) {
        result.push(path.substring(dirPath.length + 1));
      }
    }
    return result;
  }
  writeFileBinarySync(path: string, data: Uint8Array): void { this.files.set(path, data); }
}

class MockImageCache implements ImageCache {
  store: Map<string, Uint8Array> = new Map();
  get(key: string): Uint8Array | null { return this.store.get(key) ?? null; }
  put(key: string, data: Uint8Array): void { this.store.set(key, data); }
  contains(key: string): boolean { return this.store.has(key); }
  remove(key: string): void { this.store.delete(key); }
}

class MockPreviewSet extends PreviewSet {
  private items: { position: number; pageUrl: string }[] = [];
  addItem(position: number, pageUrl: string): void { this.items.push({ position, pageUrl }); }
  size(): number { return this.items.length; }
  getPosition(index: number): number { return this.items[index].position; }
  getPageUrlAt(index: number): string { return this.items[index].pageUrl; }
  getGalleryPreview(_gid: number, _index: number): GalleryPreview { throw new Error('Not implemented'); }
}

class MockPageFetcher implements GalleryPageFetcher {
  /** Map from pageUrl to result (for HTML fetch). */
  pageResults: Map<string, GalleryPageResult> = new Map();

  async getGalleryToken(_gid: number, _gtoken: string, _page: number): Promise<string> {
    return 'token';
  }
  async getGalleryPage(pageUrl: string, _gid: number, _token: string): Promise<GalleryPageResult> {
    for (const [key, val] of this.pageResults) {
      if (pageUrl.includes(key) || key === pageUrl) return val;
    }
    throw new Error(`No mock page result for ${pageUrl}`);
  }
  async getGalleryPageApi(
    _gid: number, _index: number, _pToken: string,
    _showKey: string, _previousPToken: string | null,
  ): Promise<GalleryPageApiResult> {
    throw new Error('Key mismatch'); // force HTML fallback for simplicity
  }
}

class MockPreviewFetcher implements PreviewFetcher {
  results: Map<string, { previewSet: PreviewSet; previewPages: number }> = new Map();
  async getPreviewSet(url: string): Promise<{ previewSet: PreviewSet; previewPages: number }> {
    for (const [key, val] of this.results) {
      if (url.includes(key) || key === url) return val;
    }
    throw new Error(`No mock preview result for ${url}`);
  }
}

/** Mock ImageFetcher that returns configurable results per URL. */
class MockImageFetcher implements ImageFetcher {
  results: Map<string, ImageFetchResult> = new Map();
  fetchCount = 0;
  fetchedUrls: string[] = [];

  setResult(url: string, data: Uint8Array, contentType: string = 'image/jpeg'): void {
    this.results.set(url, { data, contentType });
  }

  /** Set a result that matches any URL containing the substring. */
  setDefaultResult(data: Uint8Array, contentType: string = 'image/jpeg'): void {
    this.results.set('*', { data, contentType });
  }

  async fetchImage(url: string, _referer?: string): Promise<ImageFetchResult> {
    this.fetchCount++;
    this.fetchedUrls.push(url);
    const exact = this.results.get(url);
    if (exact) return exact;
    const fallback = this.results.get('*');
    if (fallback) return fallback;
    throw new Error(`No mock fetch result for ${url}`);
  }
}

/** Records all listener calls for assertions. */
class SpyListener implements ImageDownloadListener {
  pageStarts: { index: number; total: number }[] = [];
  pageSuccesses: { index: number; finished: number; downloaded: number; total: number }[] = [];
  pageFailures: { index: number; error: string; finished: number; downloaded: number; total: number }[] = [];
  finishCalls: { finished: number; downloaded: number; total: number }[] = [];

  onPageStart(index: number, total: number): void {
    this.pageStarts.push({ index, total });
  }
  onPageSuccess(index: number, finished: number, downloaded: number, total: number): void {
    this.pageSuccesses.push({ index, finished, downloaded, total });
  }
  onPageFailure(index: number, error: string, finished: number, downloaded: number, total: number): void {
    this.pageFailures.push({ index, error, finished, downloaded, total });
  }
  onFinish(finished: number, downloaded: number, total: number): void {
    this.finishCalls.push({ finished, downloaded, total });
  }
}

// ---- Helpers ----

function hexToken(index: number): string {
  return index.toString(16).padStart(10, '0');
}

function makeEhPageUrl(gid: number, page: number, pToken: string): string {
  return `https://e-hentai.org/s/${pToken}/${gid}-${page + 1}`;
}

function makeSpiderInfo(gid: number, pages: number): SpiderInfo {
  const info = new SpiderInfo();
  info.gid = gid;
  info.token = `token_${gid}`;
  info.pages = pages;
  info.previewPages = 1;
  info.previewPerPage = pages;
  // Pre-populate pTokens so SpiderQueen doesn't need to fetch previews
  for (let i = 0; i < pages; i++) {
    info.pTokenMap.set(i, hexToken(i));
  }
  return info;
}

function makeImageData(size: number = 100): Uint8Array {
  const data = new Uint8Array(size);
  // Fill with non-zero binary data (simulates real image)
  for (let i = 0; i < size; i++) {
    data[i] = (i % 255) + 1;
  }
  return data;
}

// ---- Tests ----

describe('ImageDownloader', () => {
  let fsOps: MockFsOps;
  let cache: MockImageCache;
  let pageFetcher: MockPageFetcher;
  let previewFetcher: MockPreviewFetcher;
  let imageFetcher: MockImageFetcher;
  let spy: SpyListener;

  const GID = 12345;
  const DOWNLOAD_DIR = '/downloads/gallery';

  beforeEach(() => {
    SettingsService.initialize(new MemoryPreferencesStore());
    fsOps = new MockFsOps();
    cache = new MockImageCache();
    pageFetcher = new MockPageFetcher();
    previewFetcher = new MockPreviewFetcher();
    imageFetcher = new MockImageFetcher();
    spy = new SpyListener();
  });

  function setup(pages: number): { queen: SpiderQueen; den: SpiderDen; downloader: ImageDownloader } {
    const info = makeSpiderInfo(GID, pages);
    const den = new SpiderDen(GID, DOWNLOAD_DIR, fsOps, cache);

    // Register HTML page results for each page
    for (let i = 0; i < pages; i++) {
      const pToken = hexToken(i);
      const pageUrl = EhUrl.getPageUrl(GID, i, pToken);
      pageFetcher.pageResults.set(pageUrl, {
        imageUrl: `https://hath.network/image${i}.jpg`,
        skipHathKey: '',
        originImageUrl: '',
        showKey: 'sk1',
      });
    }

    // Set a default image fetch result
    imageFetcher.setDefaultResult(makeImageData());

    const queen = new SpiderQueen(info, den, pageFetcher, previewFetcher);
    const downloader = new ImageDownloader(queen, den, imageFetcher);
    downloader.addListener(spy);
    return { queen, den, downloader };
  }

  // ---- Basic sequential download ----

  describe('downloadAll', () => {
    it('downloads all pages sequentially', async () => {
      const { downloader } = setup(3);
      await downloader.downloadAll();

      assert.strictEqual(downloader.getFinished(), 3);
      assert.strictEqual(downloader.getDownloaded(), 3);
      assert.strictEqual(spy.finishCalls.length, 1);
      assert.deepStrictEqual(spy.finishCalls[0], { finished: 3, downloaded: 3, total: 3 });
    });

    it('notifies onPageStart for each page in order', async () => {
      const { downloader } = setup(3);
      await downloader.downloadAll();

      assert.strictEqual(spy.pageStarts.length, 3);
      assert.strictEqual(spy.pageStarts[0].index, 0);
      assert.strictEqual(spy.pageStarts[1].index, 1);
      assert.strictEqual(spy.pageStarts[2].index, 2);
      for (const ps of spy.pageStarts) {
        assert.strictEqual(ps.total, 3);
      }
    });

    it('notifies onPageSuccess with incremental progress', async () => {
      const { downloader } = setup(3);
      await downloader.downloadAll();

      assert.strictEqual(spy.pageSuccesses.length, 3);
      assert.deepStrictEqual(spy.pageSuccesses[0], { index: 0, finished: 1, downloaded: 1, total: 3 });
      assert.deepStrictEqual(spy.pageSuccesses[1], { index: 1, finished: 2, downloaded: 2, total: 3 });
      assert.deepStrictEqual(spy.pageSuccesses[2], { index: 2, finished: 3, downloaded: 3, total: 3 });
    });

    it('writes image files to SpiderDen download dir', async () => {
      const { den, downloader } = setup(2);
      await downloader.downloadAll();

      assert.ok(den.containImage(0));
      assert.ok(den.containImage(1));
    });

    it('sets SpiderDen to download mode', async () => {
      const { den, downloader } = setup(1);
      await downloader.downloadAll();
      assert.strictEqual(den.getMode(), MODE_DOWNLOAD);
    });

    it('sets page states correctly after completion', async () => {
      const { downloader } = setup(3);
      await downloader.downloadAll();

      const states = downloader.getPageStates();
      assert.strictEqual(states.length, 3);
      assert.strictEqual(states[0], PageState.FINISHED);
      assert.strictEqual(states[1], PageState.FINISHED);
      assert.strictEqual(states[2], PageState.FINISHED);
    });
  });

  // ---- Skip already downloaded pages ----

  describe('skip existing pages', () => {
    it('skips pages already in SpiderDen', async () => {
      const { den, downloader } = setup(3);

      // Pre-save page 1
      den.setMode(MODE_DOWNLOAD);
      den.saveImage(1, makeImageData(), 'jpg');

      await downloader.downloadAll();

      // Page 1 should not have been fetched
      assert.strictEqual(imageFetcher.fetchCount, 2); // only pages 0 and 2
      assert.strictEqual(spy.pageStarts.length, 2); // no onPageStart for page 1
      // But success should be reported for all 3
      assert.strictEqual(spy.pageSuccesses.length, 3);
      assert.strictEqual(downloader.getFinished(), 3);
    });

    it('reports correct progress when skipping', async () => {
      const { den, downloader } = setup(3);

      // Pre-save pages 0 and 1
      den.setMode(MODE_DOWNLOAD);
      den.saveImage(0, makeImageData(), 'jpg');
      den.saveImage(1, makeImageData(), 'jpg');

      await downloader.downloadAll();

      // Page 0: finished=1, page 1: finished=2, page 2: finished=3
      assert.strictEqual(spy.pageSuccesses.length, 3);
      assert.strictEqual(spy.pageSuccesses[0].finished, 1);
      assert.strictEqual(spy.pageSuccesses[1].finished, 2);
      assert.strictEqual(spy.pageSuccesses[2].finished, 3);
    });
  });

  // ---- Failure handling ----

  describe('failure handling', () => {
    it('reports page failure when image fetch throws', async () => {
      const { downloader } = setup(2);

      // Override: page 0 will fail (no result)
      imageFetcher.results.clear();
      imageFetcher.setResult('https://hath.network/image1.jpg', makeImageData());
      // image0 has no result -> throws

      await downloader.downloadAll();

      assert.strictEqual(spy.pageFailures.length, 1);
      assert.strictEqual(spy.pageFailures[0].index, 0);
      assert.strictEqual(downloader.getFinished(), 1); // only page 1 succeeded
      assert.strictEqual(downloader.getDownloaded(), 2); // both attempted
    });

    it('continues to next page after failure', async () => {
      const { downloader } = setup(3);

      // Make page 1 fail
      imageFetcher.results.clear();
      imageFetcher.setResult('https://hath.network/image0.jpg', makeImageData());
      // page 1 will fail
      imageFetcher.setResult('https://hath.network/image2.jpg', makeImageData());

      await downloader.downloadAll();

      assert.strictEqual(downloader.getFinished(), 2); // pages 0 and 2
      assert.strictEqual(spy.pageFailures.length, 1);
      assert.strictEqual(spy.pageFailures[0].index, 1);
      assert.strictEqual(spy.finishCalls[0].finished, 2);
    });

    it('reports correct states after partial failure', async () => {
      const { downloader } = setup(3);

      imageFetcher.results.clear();
      imageFetcher.setResult('https://hath.network/image0.jpg', makeImageData());
      imageFetcher.setResult('https://hath.network/image2.jpg', makeImageData());

      await downloader.downloadAll();

      const states = downloader.getPageStates();
      assert.strictEqual(states[0], PageState.FINISHED);
      assert.strictEqual(states[1], PageState.FAILED);
      assert.strictEqual(states[2], PageState.FINISHED);
    });

    it('retries failed pages up to maxRetries', async () => {
      const info = makeSpiderInfo(GID, 1);
      const den = new SpiderDen(GID, DOWNLOAD_DIR, fsOps, cache);
      const pToken = hexToken(0);
      const pageUrl = EhUrl.getPageUrl(GID, 0, pToken);
      pageFetcher.pageResults.set(pageUrl, {
        imageUrl: 'https://hath.network/retry.jpg',
        skipHathKey: '',
        originImageUrl: '',
        showKey: 'sk1',
      });

      let callCount = 0;
      const failingFetcher: ImageFetcher = {
        async fetchImage(_url: string): Promise<ImageFetchResult> {
          callCount++;
          if (callCount <= 2) throw new Error('Network error');
          return { data: makeImageData(), contentType: 'image/jpeg' };
        },
      };

      const queen = new SpiderQueen(info, den, pageFetcher, previewFetcher);
      const downloader = new ImageDownloader(queen, den, failingFetcher, 2);
      downloader.addListener(spy);

      await downloader.downloadAll();

      // Should have been called 3 times (initial + 2 retries)
      assert.strictEqual(callCount, 3);
      assert.strictEqual(downloader.getFinished(), 1);
      assert.strictEqual(spy.pageFailures.length, 0);
    });

    it('fails after exhausting retries', async () => {
      const info = makeSpiderInfo(GID, 1);
      const den = new SpiderDen(GID, DOWNLOAD_DIR, fsOps, cache);
      const pToken = hexToken(0);
      const pageUrl = EhUrl.getPageUrl(GID, 0, pToken);
      pageFetcher.pageResults.set(pageUrl, {
        imageUrl: 'https://hath.network/fail.jpg',
        skipHathKey: '',
        originImageUrl: '',
        showKey: 'sk1',
      });

      const failingFetcher: ImageFetcher = {
        async fetchImage(_url: string): Promise<ImageFetchResult> {
          throw new Error('Persistent error');
        },
      };

      const queen = new SpiderQueen(info, den, pageFetcher, previewFetcher);
      const downloader = new ImageDownloader(queen, den, failingFetcher, 1);
      downloader.addListener(spy);

      await downloader.downloadAll();

      assert.strictEqual(downloader.getFinished(), 0);
      assert.strictEqual(spy.pageFailures.length, 1);
      assert.ok(spy.pageFailures[0].error.includes('Persistent error'));
    });
  });

  // ---- Cancellation ----

  describe('cancellation', () => {
    it('stops downloading after cancel is called', async () => {
      const { downloader } = setup(5);

      // Cancel after page 1 completes
      let pageCount = 0;
      downloader.addListener({
        onPageStart(): void {},
        onPageSuccess(): void {
          pageCount++;
          if (pageCount >= 2) downloader.cancel();
        },
        onPageFailure(): void {},
        onFinish(): void {},
      });

      await downloader.downloadAll();

      assert.ok(downloader.isCancelled());
      // Should have downloaded at most 2 pages (pages 0 and 1)
      assert.ok(downloader.getFinished() <= 2);
      assert.ok(downloader.getFinished() >= 2); // exactly 2
      assert.strictEqual(spy.finishCalls.length, 1);
    });

    it('cancel before downloadAll results in immediate finish', async () => {
      const { downloader } = setup(3);
      downloader.cancel();
      await downloader.downloadAll();

      assert.strictEqual(downloader.getFinished(), 0);
      assert.strictEqual(spy.finishCalls.length, 1);
      assert.deepStrictEqual(spy.finishCalls[0], { finished: 0, downloaded: 0, total: 3 });
    });
  });

  // ---- Edge cases ----

  describe('edge cases', () => {
    it('handles zero pages gracefully', async () => {
      const info = makeSpiderInfo(GID, 0);
      const den = new SpiderDen(GID, DOWNLOAD_DIR, fsOps, cache);
      const queen = new SpiderQueen(info, den, pageFetcher, previewFetcher);
      const downloader = new ImageDownloader(queen, den, imageFetcher);
      downloader.addListener(spy);

      await downloader.downloadAll();

      assert.strictEqual(spy.finishCalls.length, 1);
      assert.deepStrictEqual(spy.finishCalls[0], { finished: 0, downloaded: 0, total: 0 });
    });

    it('handles single page gallery', async () => {
      const { downloader } = setup(1);
      await downloader.downloadAll();

      assert.strictEqual(downloader.getFinished(), 1);
      assert.strictEqual(spy.pageSuccesses.length, 1);
      assert.strictEqual(spy.finishCalls.length, 1);
    });

    it('maps content types to correct extensions', async () => {
      const info = makeSpiderInfo(GID, 3);
      const den = new SpiderDen(GID, DOWNLOAD_DIR, fsOps, cache);

      for (let i = 0; i < 3; i++) {
        const pToken = hexToken(i);
        const pageUrl = EhUrl.getPageUrl(GID, i, pToken);
        pageFetcher.pageResults.set(pageUrl, {
          imageUrl: `https://hath.network/img${i}`,
          skipHathKey: '',
          originImageUrl: '',
          showKey: 'sk1',
        });
      }

      // Different content types for each page
      imageFetcher.setResult('https://hath.network/img0', makeImageData(), 'image/png');
      imageFetcher.setResult('https://hath.network/img1', makeImageData(), 'image/gif');
      imageFetcher.setResult('https://hath.network/img2', makeImageData(), 'image/webp');

      const queen = new SpiderQueen(info, den, pageFetcher, previewFetcher);
      const downloader = new ImageDownloader(queen, den, imageFetcher);
      downloader.addListener(spy);

      await downloader.downloadAll();

      assert.strictEqual(downloader.getFinished(), 3);

      // Verify files were written with correct extensions
      const files = fsOps.readdirSync(DOWNLOAD_DIR);
      const hasExtension = (ext: string) => files.some(f => f.endsWith(ext));
      assert.ok(hasExtension('.png'), 'Expected a .png file');
      assert.ok(hasExtension('.gif'), 'Expected a .gif file');
      assert.ok(hasExtension('.webp'), 'Expected a .webp file');
    });

    it('prefers originImageUrl when available', async () => {
      const info = makeSpiderInfo(GID, 1);
      const den = new SpiderDen(GID, DOWNLOAD_DIR, fsOps, cache);
      const pToken = hexToken(0);
      const pageUrl = EhUrl.getPageUrl(GID, 0, pToken);
      pageFetcher.pageResults.set(pageUrl, {
        imageUrl: 'https://hath.network/normal.jpg',
        skipHathKey: '',
        originImageUrl: 'https://hath.network/original.jpg',
        showKey: 'sk1',
      });

      imageFetcher.setResult('https://hath.network/original.jpg', makeImageData());

      const queen = new SpiderQueen(info, den, pageFetcher, previewFetcher);
      const downloader = new ImageDownloader(queen, den, imageFetcher);

      await downloader.downloadAll();

      assert.strictEqual(imageFetcher.fetchedUrls[0], 'https://hath.network/original.jpg');
    });

    it('falls back to imageUrl when originImageUrl is empty', async () => {
      const info = makeSpiderInfo(GID, 1);
      const den = new SpiderDen(GID, DOWNLOAD_DIR, fsOps, cache);
      const pToken = hexToken(0);
      const pageUrl = EhUrl.getPageUrl(GID, 0, pToken);
      pageFetcher.pageResults.set(pageUrl, {
        imageUrl: 'https://hath.network/normal.jpg',
        skipHathKey: '',
        originImageUrl: '',
        showKey: 'sk1',
      });

      imageFetcher.setResult('https://hath.network/normal.jpg', makeImageData());

      const queen = new SpiderQueen(info, den, pageFetcher, previewFetcher);
      const downloader = new ImageDownloader(queen, den, imageFetcher);

      await downloader.downloadAll();

      assert.strictEqual(imageFetcher.fetchedUrls[0], 'https://hath.network/normal.jpg');
    });
  });

  // ---- Listener management ----

  describe('listener management', () => {
    it('supports multiple listeners', async () => {
      const { downloader } = setup(1);
      const spy2 = new SpyListener();
      downloader.addListener(spy2);

      await downloader.downloadAll();

      assert.strictEqual(spy.finishCalls.length, 1);
      assert.strictEqual(spy2.finishCalls.length, 1);
    });

    it('removeListener stops notifications', async () => {
      const { downloader } = setup(1);
      downloader.removeListener(spy);

      await downloader.downloadAll();

      assert.strictEqual(spy.finishCalls.length, 0);
    });
  });
});
