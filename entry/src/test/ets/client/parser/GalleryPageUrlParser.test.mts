import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { GalleryPageUrlParser } from '../../../../main/ets/client/parser/GalleryPageUrlParser.ets';

describe('GalleryPageUrlParser', () => {
  it('should parse e-hentai gallery page URL (strict)', () => {
    const r = GalleryPageUrlParser.parse('https://e-hentai.org/s/7b87643838/530350-1', true);
    assert.ok(r !== null);
    assert.strictEqual(r!.gid, 530350);
    assert.strictEqual(r!.pToken, '7b87643838');
    assert.strictEqual(r!.page, 0);
  });

  it('should parse exhentai gallery page URL (strict)', () => {
    const r = GalleryPageUrlParser.parse('https://exhentai.org/s/7b87643838/530350-1', true);
    assert.ok(r !== null);
    assert.strictEqual(r!.gid, 530350);
    assert.strictEqual(r!.pToken, '7b87643838');
    assert.strictEqual(r!.page, 0);
  });

  it('should return null for path-only URL when strict', () => {
    const r = GalleryPageUrlParser.parse('7b87643838/530350-1', true);
    assert.strictEqual(r, null);
  });

  it('should parse path-only URL when not strict', () => {
    const r = GalleryPageUrlParser.parse('7b87643838/530350-1', false);
    assert.ok(r !== null);
    assert.strictEqual(r!.gid, 530350);
    assert.strictEqual(r!.pToken, '7b87643838');
    assert.strictEqual(r!.page, 0);
  });

  it('should parse path with s/ prefix when not strict', () => {
    const r = GalleryPageUrlParser.parse('s/7b87643838/530350-1', false);
    assert.ok(r !== null);
    assert.strictEqual(r!.gid, 530350);
    assert.strictEqual(r!.pToken, '7b87643838');
    assert.strictEqual(r!.page, 0);
  });

  it('should return null for invalid gid in path when not strict', () => {
    const r = GalleryPageUrlParser.parse('7b87643838/530350a-1', false);
    assert.strictEqual(r, null);
  });

  it('should default to strict when parse called with one argument', () => {
    const r = GalleryPageUrlParser.parse('https://e-hentai.org/s/7b87643838/530350-1');
    assert.ok(r !== null);
    assert.strictEqual(r!.gid, 530350);
    assert.strictEqual(r!.page, 0);
  });

  it('should return null for null url', () => {
    assert.strictEqual(GalleryPageUrlParser.parse(null), null);
  });

  it('should parse lofi host (strict)', () => {
    const r = GalleryPageUrlParser.parse('https://lofi.e-hentai.org/s/7b87643838/530350-2', true);
    assert.ok(r !== null);
    assert.strictEqual(r!.gid, 530350);
    assert.strictEqual(r!.pToken, '7b87643838');
    assert.strictEqual(r!.page, 1);
  });
});
