import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

import { SpiderInfo, TOKEN_FAILED } from '../../../main/ets/spider/SpiderInfo.ets';
import { SpiderDen } from '../../../main/ets/spider/SpiderDen.ets';
import type { SpiderDenFsOps, ImageCache } from '../../../main/ets/spider/SpiderDen.ets';
import { SpiderQueen } from '../../../main/ets/spider/SpiderQueen.ets';
import type { PreviewFetcher, PageUrlResult } from '../../../main/ets/spider/SpiderQueen.ets';
import type { GalleryPageFetcher } from '../../../main/ets/client/EhEngineGalleryPageFetcher.ets';
import type { GalleryPageResult } from '../../../main/ets/client/parser/GalleryPageParser.ets';
import type { GalleryPageApiResult } from '../../../main/ets/client/parser/GalleryPageApiParser.ets';
import { PreviewSet } from '../../../main/ets/model/PreviewSet';
import type { GalleryPreview } from '../../../main/ets/model/GalleryPreview';
import { EhUrl } from '../../../main/ets/client/EhUrl.ets';
import { SettingsService } from '../../../main/ets/service/SettingsService.ets';
import { MemoryPreferencesStore } from '../../../main/ets/preferences/MemoryPreferencesStore.ets';

// ---- Mock PreviewSet ----

class MockPreviewSet extends PreviewSet {
  private items: { position: number; pageUrl: string }[] = [];

  addItem(position: number, pageUrl: string): void {
    this.items.push({ position, pageUrl });
  }

  size(): number {
    return this.items.length;
  }

  getPosition(index: number): number {
    return this.items[index].position;
  }

  getPageUrlAt(index: number): string {
    return this.items[index].pageUrl;
  }

  getGalleryPreview(_gid: number, _index: number): GalleryPreview {
    throw new Error('Not implemented');
  }
}

// ---- Mock GalleryPageFetcher ----

class MockPageFetcher implements GalleryPageFetcher {
  pageResults: Map<string, GalleryPageResult> = new Map();
  apiResults: Map<string, GalleryPageApiResult> = new Map();
  tokenResults: Map<string, string> = new Map();
  pageCallCount = 0;
  apiCallCount = 0;

  async getGalleryToken(gid: number, gtoken: string, page: number): Promise<string> {
    const key = `${gid}-${gtoken}-${page}`;
    return this.tokenResults.get(key) ?? 'token';
  }

  async getGalleryPage(pageUrl: string, _gid: number, _token: string): Promise<GalleryPageResult> {
    this.pageCallCount++;
    const result = this.pageResults.get(pageUrl);
    if (!result) {
      // Return a default for any URL that contains the pToken
      for (const [key, val] of this.pageResults) {
        if (pageUrl.includes(key)) return val;
      }
      throw new Error(`No mock page result for ${pageUrl}`);
    }
    return result;
  }

  async getGalleryPageApi(
    gid: number,
    index: number,
    pToken: string,
    showKey: string,
    _previousPToken: string | null,
  ): Promise<GalleryPageApiResult> {
    this.apiCallCount++;
    const key = `${gid}-${index}-${pToken}-${showKey}`;
    const result = this.apiResults.get(key);
    if (!result) {
      // Check for "Key mismatch" simulation
      for (const [k, v] of this.apiResults) {
        if (k.startsWith(`${gid}-${index}-${pToken}-`)) {
          if (k.endsWith(showKey)) return v;
        }
      }
      throw new Error('Key mismatch');
    }
    return result;
  }
}

// ---- Mock PreviewFetcher ----

class MockPreviewFetcher implements PreviewFetcher {
  results: Map<string, { previewSet: PreviewSet; previewPages: number }> = new Map();
  callCount = 0;

  async getPreviewSet(url: string): Promise<{ previewSet: PreviewSet; previewPages: number }> {
    this.callCount++;
    const result = this.results.get(url);
    if (!result) {
      // Try partial match
      for (const [key, val] of this.results) {
        if (url.includes(key)) return val;
      }
      throw new Error(`No mock preview result for ${url}`);
    }
    return result;
  }
}

// ---- Mock FS / Cache for SpiderDen ----

class MockFsOps implements SpiderDenFsOps {
  files: Map<string, string | Uint8Array> = new Map();
  dirs: Set<string> = new Set();

  existsSync(path: string): boolean { return this.files.has(path) || this.dirs.has(path); }
  mkdirSync(path: string): void { this.dirs.add(path); }
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

// ---- Helpers ----

function makeSpiderInfo(opts?: {
  gid?: number;
  token?: string;
  pages?: number;
  previewPages?: number;
  previewPerPage?: number;
  pTokens?: [number, string][];
}): SpiderInfo {
  const info = new SpiderInfo();
  info.gid = opts?.gid ?? 12345;
  info.token = opts?.token ?? 'abcdef1234';
  info.pages = opts?.pages ?? 100;
  info.previewPages = opts?.previewPages ?? 5;
  info.previewPerPage = opts?.previewPerPage ?? 20;
  for (const [idx, pt] of (opts?.pTokens ?? [])) {
    info.pTokenMap.set(idx, pt);
  }
  return info;
}

/**
 * Build a hex pToken from an index (GalleryPageUrlParser requires 10 hex chars).
 */
function hexToken(index: number): string {
  return index.toString(16).padStart(10, '0');
}

/** Build a page URL in the format that GalleryPageUrlParser expects. */
function makeEhPageUrl(gid: number, page: number, pToken: string): string {
  return `https://e-hentai.org/s/${pToken}/${gid}-${page + 1}`;
}

// ---- Tests ----

describe('SpiderQueen', () => {
  let fsOps: MockFsOps;
  let cache: MockImageCache;
  let spiderDen: SpiderDen;
  let pageFetcher: MockPageFetcher;
  let previewFetcher: MockPreviewFetcher;

  beforeEach(() => {
    SettingsService.initialize(new MemoryPreferencesStore());
    fsOps = new MockFsOps();
    cache = new MockImageCache();
    pageFetcher = new MockPageFetcher();
    previewFetcher = new MockPreviewFetcher();
  });

  function makeQueen(info: SpiderInfo): SpiderQueen {
    spiderDen = new SpiderDen(info.gid, '/downloads/gallery', fsOps, cache);
    return new SpiderQueen(info, spiderDen, pageFetcher, previewFetcher);
  }

  // ---- getPToken ----

  describe('getPToken', () => {
    it('returns cached pToken from SpiderInfo', async () => {
      const info = makeSpiderInfo({ pTokens: [[5, 'cachedtoken0']] });
      const queen = makeQueen(info);
      const token = await queen.getPToken(5);
      assert.strictEqual(token, 'cachedtoken0');
      assert.strictEqual(previewFetcher.callCount, 0);
    });

    it('skips TOKEN_FAILED and fetches from internet', async () => {
      const info = makeSpiderInfo({
        gid: 100,
        token: 'abcdef0100',
        pages: 40,
        previewPerPage: 20,
        previewPages: 2,
        pTokens: [[5, TOKEN_FAILED]],
      });
      const queen = makeQueen(info);

      // Setup mock preview response for page 0
      const previewSet = new MockPreviewSet();
      previewSet.addItem(0, makeEhPageUrl(100, 0, hexToken(0)));
      previewSet.addItem(1, makeEhPageUrl(100, 1, hexToken(1)));
      previewSet.addItem(5, makeEhPageUrl(100, 5, hexToken(5)));

      const detailUrl = EhUrl.getGalleryDetailUrl(100, 'abcdef0100', 0);
      previewFetcher.results.set(detailUrl, { previewSet, previewPages: 2 });

      const token = await queen.getPToken(5);
      assert.strictEqual(token, hexToken(5));
      assert.strictEqual(previewFetcher.callCount, 1);
    });

    it('throws for out of range index', async () => {
      const info = makeSpiderInfo({ pages: 10 });
      const queen = makeQueen(info);
      await assert.rejects(() => queen.getPToken(10), /out of range/);
      await assert.rejects(() => queen.getPToken(-1), /out of range/);
    });

    it('fetches pToken from correct preview page based on previewPerPage', async () => {
      const info = makeSpiderInfo({
        gid: 200,
        token: 'abcdef0200',
        pages: 60,
        previewPerPage: 20,
        previewPages: 3,
      });
      const queen = makeQueen(info);

      // Page 42 should be on preview page index 2 (42/20 = 2)
      const previewSet = new MockPreviewSet();
      previewSet.addItem(40, makeEhPageUrl(200, 40, hexToken(40)));
      previewSet.addItem(41, makeEhPageUrl(200, 41, hexToken(41)));
      previewSet.addItem(42, makeEhPageUrl(200, 42, hexToken(42)));

      const detailUrl = EhUrl.getGalleryDetailUrl(200, 'abcdef0200', 2);
      previewFetcher.results.set(detailUrl, { previewSet, previewPages: 3 });

      const token = await queen.getPToken(42);
      assert.strictEqual(token, hexToken(42));
    });

    it('updates previewPerPage from first preview page', async () => {
      const info = makeSpiderInfo({
        gid: 300,
        token: 'abcdef0300',
        pages: 50,
        previewPerPage: -1, // unknown
        previewPages: -1,
      });
      const queen = makeQueen(info);

      // 15 items on preview page 0 => previewPerPage = 15
      const previewSet = new MockPreviewSet();
      for (let i = 0; i < 15; i++) {
        previewSet.addItem(i, makeEhPageUrl(300, i, hexToken(i)));
      }
      const detailUrl = EhUrl.getGalleryDetailUrl(300, 'abcdef0300', 0);
      previewFetcher.results.set(detailUrl, { previewSet, previewPages: 4 });

      await queen.getPToken(3);
      assert.strictEqual(info.previewPerPage, 15);
      assert.strictEqual(info.previewPages, 4);
    });

    it('persists SpiderInfo to SpiderDen after fetching pToken', async () => {
      const info = makeSpiderInfo({
        gid: 400,
        token: 'abcdef0400',
        pages: 20,
        previewPerPage: 20,
        previewPages: 1,
      });
      const queen = makeQueen(info);

      const previewSet = new MockPreviewSet();
      previewSet.addItem(0, makeEhPageUrl(400, 0, hexToken(0)));

      const detailUrl = EhUrl.getGalleryDetailUrl(400, 'abcdef0400', 0);
      previewFetcher.results.set(detailUrl, { previewSet, previewPages: 1 });

      await queen.getPToken(0);

      // Verify SpiderInfo was written to SpiderDen
      const written = spiderDen.readSpiderInfo();
      assert.ok(written !== null);
      assert.strictEqual(written.pTokenMap.get(0), hexToken(0));
    });

    it('retries with updated previewIndex when first attempt misses', async () => {
      const info = makeSpiderInfo({
        gid: 500,
        token: 'abcdef0500',
        pages: 100,
        previewPerPage: 10, // initially wrong
        previewPages: 5,
      });
      const queen = makeQueen(info);

      // Page 25: with previewPerPage=10, first tries preview index 2
      const firstPreview = new MockPreviewSet();
      for (let i = 20; i < 30; i++) {
        firstPreview.addItem(i, makeEhPageUrl(500, i, hexToken(i)));
      }
      // page 25 IS on this page, so it should return without retry
      const detailUrl1 = EhUrl.getGalleryDetailUrl(500, 'abcdef0500', 2);
      previewFetcher.results.set(detailUrl1, { previewSet: firstPreview, previewPages: 5 });

      const token = await queen.getPToken(25);
      assert.strictEqual(token, hexToken(25));
      assert.strictEqual(previewFetcher.callCount, 1);
    });
  });

  // ---- getPageUrl ----

  describe('getPageUrl', () => {
    it('fetches page URL via HTML when no showKey', async () => {
      const info = makeSpiderInfo({
        gid: 1000,
        token: 'gt1000',
        pages: 10,
        pTokens: [[0, 'ptok0']],
      });
      const queen = makeQueen(info);

      const pageUrl = EhUrl.getPageUrl(1000, 0, 'ptok0');
      pageFetcher.pageResults.set(pageUrl, {
        imageUrl: 'https://hath.network/image0.jpg',
        skipHathKey: 'skip0',
        originImageUrl: 'https://hath.network/full0.jpg',
        showKey: 'showkey123',
      });

      const result = await queen.getPageUrl(0);

      assert.strictEqual(result.imageUrl, 'https://hath.network/image0.jpg');
      assert.strictEqual(result.skipHathKey, 'skip0');
      assert.strictEqual(result.originImageUrl, 'https://hath.network/full0.jpg');
      assert.strictEqual(pageFetcher.pageCallCount, 1);
      assert.strictEqual(pageFetcher.apiCallCount, 0);
      // showKey should be stored
      assert.strictEqual(queen.getShowKey(), 'showkey123');
    });

    it('uses API path when showKey is available', async () => {
      const info = makeSpiderInfo({
        gid: 1001,
        token: 'gt1001',
        pages: 10,
        pTokens: [[0, 'ptok0'], [1, 'ptok1']],
      });
      const queen = makeQueen(info);

      // First call establishes showKey via HTML
      const pageUrl0 = EhUrl.getPageUrl(1001, 0, 'ptok0');
      pageFetcher.pageResults.set(pageUrl0, {
        imageUrl: 'https://hath.network/img0.jpg',
        skipHathKey: '',
        originImageUrl: '',
        showKey: 'sk999',
      });
      await queen.getPageUrl(0);
      assert.strictEqual(queen.getShowKey(), 'sk999');

      // Second call should use API
      pageFetcher.apiResults.set('1001-1-ptok1-sk999', {
        imageUrl: 'https://hath.network/img1.jpg',
        skipHathKey: 'skip1',
        originImageUrl: 'https://hath.network/full1.jpg',
      });

      const result = await queen.getPageUrl(1);
      assert.strictEqual(result.imageUrl, 'https://hath.network/img1.jpg');
      assert.strictEqual(pageFetcher.apiCallCount, 1);
      // pageCallCount should still be 1 (only first call)
      assert.strictEqual(pageFetcher.pageCallCount, 1);
    });

    it('falls back to HTML when API throws Key mismatch', async () => {
      const info = makeSpiderInfo({
        gid: 1002,
        token: 'gt1002',
        pages: 10,
        pTokens: [[0, 'ptok0'], [1, 'ptok1']],
      });
      const queen = makeQueen(info);

      // First call sets showKey
      const pageUrl0 = EhUrl.getPageUrl(1002, 0, 'ptok0');
      pageFetcher.pageResults.set(pageUrl0, {
        imageUrl: 'https://img0.jpg',
        skipHathKey: '',
        originImageUrl: '',
        showKey: 'badkey',
      });
      await queen.getPageUrl(0);

      // API will fail with "Key mismatch" (no matching entry)
      // pageFetcher.apiResults is empty for 'badkey'

      // HTML fallback
      const pageUrl1 = EhUrl.getPageUrl(1002, 1, 'ptok1');
      pageFetcher.pageResults.set(pageUrl1, {
        imageUrl: 'https://img1.jpg',
        skipHathKey: 'sk1',
        originImageUrl: '',
        showKey: 'newkey',
      });

      const result = await queen.getPageUrl(1);
      assert.strictEqual(result.imageUrl, 'https://img1.jpg');
      assert.strictEqual(queen.getShowKey(), 'newkey');
      // API was attempted, then HTML fallback
      assert.strictEqual(pageFetcher.apiCallCount, 1);
      assert.strictEqual(pageFetcher.pageCallCount, 2);
    });

    it('resolves pToken before fetching page URL', async () => {
      const info = makeSpiderInfo({
        gid: 1003,
        token: 'abcdef1003',
        pages: 20,
        previewPerPage: 20,
        previewPages: 1,
      });
      const queen = makeQueen(info);

      // No cached pToken for page 3 — needs preview fetch
      const previewSet = new MockPreviewSet();
      for (let i = 0; i < 20; i++) {
        previewSet.addItem(i, makeEhPageUrl(1003, i, hexToken(i)));
      }
      const detailUrl = EhUrl.getGalleryDetailUrl(1003, 'abcdef1003', 0);
      previewFetcher.results.set(detailUrl, { previewSet, previewPages: 1 });

      // Setup page result
      const expectedPToken = hexToken(3);
      const pageUrl = EhUrl.getPageUrl(1003, 3, expectedPToken);
      pageFetcher.pageResults.set(pageUrl, {
        imageUrl: 'https://resolved.jpg',
        skipHathKey: '',
        originImageUrl: '',
        showKey: 'resolved_sk',
      });

      const result = await queen.getPageUrl(3);
      assert.strictEqual(result.imageUrl, 'https://resolved.jpg');
      assert.strictEqual(previewFetcher.callCount, 1);
    });

    it('passes previousPToken from SpiderInfo to API call', async () => {
      const info = makeSpiderInfo({
        gid: 1004,
        token: 'gt1004',
        pages: 10,
        pTokens: [[4, 'ptok4'], [5, 'ptok5']],
      });
      const queen = makeQueen(info);

      // Establish showKey first
      const pageUrl4 = EhUrl.getPageUrl(1004, 4, 'ptok4');
      pageFetcher.pageResults.set(pageUrl4, {
        imageUrl: 'https://img4.jpg',
        skipHathKey: '',
        originImageUrl: '',
        showKey: 'sk_test',
      });
      await queen.getPageUrl(4);

      // API call for page 5 should pass previousPToken = 'ptok4'
      pageFetcher.apiResults.set('1004-5-ptok5-sk_test', {
        imageUrl: 'https://img5.jpg',
        skipHathKey: '',
        originImageUrl: '',
      });

      const result = await queen.getPageUrl(5);
      assert.strictEqual(result.imageUrl, 'https://img5.jpg');
    });
  });

  // ---- Integration: getSpiderInfo ----

  describe('getSpiderInfo', () => {
    it('returns the SpiderInfo instance', () => {
      const info = makeSpiderInfo();
      const queen = makeQueen(info);
      assert.strictEqual(queen.getSpiderInfo(), info);
    });

    it('SpiderInfo is updated with newly fetched pTokens', async () => {
      const info = makeSpiderInfo({
        gid: 2000,
        token: 'abcdef2000',
        pages: 30,
        previewPerPage: 10,
        previewPages: 3,
      });
      const queen = makeQueen(info);

      const previewSet = new MockPreviewSet();
      previewSet.addItem(0, makeEhPageUrl(2000, 0, hexToken(100)));
      previewSet.addItem(1, makeEhPageUrl(2000, 1, hexToken(101)));
      previewSet.addItem(2, makeEhPageUrl(2000, 2, hexToken(102)));

      const detailUrl = EhUrl.getGalleryDetailUrl(2000, 'abcdef2000', 0);
      previewFetcher.results.set(detailUrl, { previewSet, previewPages: 3 });

      await queen.getPToken(1);

      // SpiderInfo should now have all preview tokens
      const si = queen.getSpiderInfo();
      assert.strictEqual(si.pTokenMap.get(0), hexToken(100));
      assert.strictEqual(si.pTokenMap.get(1), hexToken(101));
      assert.strictEqual(si.pTokenMap.get(2), hexToken(102));
    });
  });

  // ---- getShowKey ----

  describe('getShowKey', () => {
    it('is null initially', () => {
      const queen = makeQueen(makeSpiderInfo());
      assert.strictEqual(queen.getShowKey(), null);
    });

    it('is set after getPageUrl via HTML', async () => {
      const info = makeSpiderInfo({
        gid: 3000,
        token: 'gt3000',
        pages: 5,
        pTokens: [[0, 'pt0']],
      });
      const queen = makeQueen(info);

      const pageUrl = EhUrl.getPageUrl(3000, 0, 'pt0');
      pageFetcher.pageResults.set(pageUrl, {
        imageUrl: 'https://test.jpg',
        skipHathKey: '',
        originImageUrl: '',
        showKey: 'myshowkey',
      });

      await queen.getPageUrl(0);
      assert.strictEqual(queen.getShowKey(), 'myshowkey');
    });
  });
});
