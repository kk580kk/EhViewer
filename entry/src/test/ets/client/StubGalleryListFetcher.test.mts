import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { StubGalleryListFetcher } from '../../../main/ets/client/StubGalleryListFetcher.ets';

describe('StubGalleryListFetcher', () => {
  it('should return default page size of items', async () => {
    const fetcher = new StubGalleryListFetcher();
    const result = await fetcher.fetchList('https://e-hentai.org/');
    assert.strictEqual(result.items.length, 25);
    assert.strictEqual(result.hasNextPage, true);
  });

  it('should respect custom page size', async () => {
    const fetcher = new StubGalleryListFetcher(10);
    const result = await fetcher.fetchList('https://e-hentai.org/');
    assert.strictEqual(result.items.length, 10);
  });

  it('should return items with valid gid and token', async () => {
    const fetcher = new StubGalleryListFetcher(5);
    const result = await fetcher.fetchList('https://e-hentai.org/');
    for (const item of result.items) {
      assert.ok(item.gid > 0);
      assert.ok(item.token.length > 0);
      assert.ok(item.title.length > 0);
      assert.ok(item.category > 0);
      assert.ok(item.uploader.length > 0);
    }
  });

  it('should have no next page for page 2', async () => {
    const fetcher = new StubGalleryListFetcher(5);
    const result = await fetcher.fetchList('https://e-hentai.org/?page=2');
    assert.strictEqual(result.hasNextPage, false);
  });

  it('should have next page for page 0 and 1', async () => {
    const fetcher = new StubGalleryListFetcher(5);
    const r0 = await fetcher.fetchList('https://e-hentai.org/');
    assert.strictEqual(r0.hasNextPage, true);

    const r1 = await fetcher.fetchList('https://e-hentai.org/?page=1');
    assert.strictEqual(r1.hasNextPage, true);
  });

  it('should generate different gids for different pages', async () => {
    const fetcher = new StubGalleryListFetcher(3);
    const page0 = await fetcher.fetchList('https://e-hentai.org/');
    const page1 = await fetcher.fetchList('https://e-hentai.org/?page=1');

    const gids0 = page0.items.map(i => i.gid);
    const gids1 = page1.items.map(i => i.gid);
    // No overlap between pages
    for (const gid of gids0) {
      assert.ok(!gids1.includes(gid), `gid ${gid} should not appear in both pages`);
    }
  });
});
