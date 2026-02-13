import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { GalleryListUrlParser } from '../../../../main/ets/client/parser/GalleryListUrlParser.ets';
import { ListUrlBuilder } from '../../../../main/ets/model/ListUrlBuilder.ets';

describe('GalleryListUrlParser', () => {
  it('should parse normal E host', () => {
    const builder = GalleryListUrlParser.parse('https://e-hentai.org/');
    assert.ok(builder !== null);
  });

  it('should parse normal EX host', () => {
    const builder = GalleryListUrlParser.parse('https://exhentai.org/');
    assert.ok(builder !== null);
  });

  it('should parse uploader URL', () => {
    const builder = GalleryListUrlParser.parse('https://e-hentai.org/uploader/testuser');
    assert.ok(builder !== null);
    assert.strictEqual(builder!.getMode(), ListUrlBuilder.MODE_UPLOADER);
    assert.strictEqual(builder!.getKeyword(), 'testuser');
  });

  it('should parse tag URL', () => {
    const builder = GalleryListUrlParser.parse('https://e-hentai.org/tag/artist:test');
    assert.ok(builder !== null);
    assert.strictEqual(builder!.getMode(), ListUrlBuilder.MODE_TAG);
    assert.strictEqual(builder!.getKeyword(), 'artist:test');
  });

  it('should return null for invalid host', () => {
    const builder = GalleryListUrlParser.parse('https://example.com/');
    assert.strictEqual(builder, null);
  });

  it('should return null for invalid URL', () => {
    const builder = GalleryListUrlParser.parse('not a url');
    assert.strictEqual(builder, null);
  });

  it('should parse tag with trailing path segment', () => {
    const builder = GalleryListUrlParser.parse('https://e-hentai.org/tag/artist:test/1');
    assert.ok(builder !== null);
    assert.strictEqual(builder!.getMode(), ListUrlBuilder.MODE_TAG);
    assert.strictEqual(builder!.getKeyword(), 'artist:test');
  });

  it('should parse uploader with trailing path segment', () => {
    const builder = GalleryListUrlParser.parse('https://e-hentai.org/uploader/testuser/1');
    assert.ok(builder !== null);
    assert.strictEqual(builder!.getMode(), ListUrlBuilder.MODE_UPLOADER);
    assert.strictEqual(builder!.getKeyword(), 'testuser');
  });

  it('should parse page from query string', () => {
    const builder = GalleryListUrlParser.parse('https://e-hentai.org/?page=2');
    assert.ok(builder !== null);
    assert.strictEqual(builder!.getPageIndex(), 2);
  });

  it('should parse page from uploader path', () => {
    const builder = GalleryListUrlParser.parse('https://e-hentai.org/uploader/testuser/3');
    assert.ok(builder !== null);
    assert.strictEqual(builder!.getMode(), ListUrlBuilder.MODE_UPLOADER);
    assert.strictEqual(builder!.getKeyword(), 'testuser');
    assert.strictEqual(builder!.getPageIndex(), 3);
  });

  it('should parse page from tag path', () => {
    const builder = GalleryListUrlParser.parse('https://e-hentai.org/tag/artist:test/2');
    assert.ok(builder !== null);
    assert.strictEqual(builder!.getMode(), ListUrlBuilder.MODE_TAG);
    assert.strictEqual(builder!.getKeyword(), 'artist:test');
    assert.strictEqual(builder!.getPageIndex(), 2);
  });

  it('should parse category with page in query', () => {
    const builder = GalleryListUrlParser.parse('https://e-hentai.org/1?page=1');
    assert.ok(builder !== null);
    assert.strictEqual(builder!.getCategory(), 1);
    assert.strictEqual(builder!.getPageIndex(), 1);
  });
});
