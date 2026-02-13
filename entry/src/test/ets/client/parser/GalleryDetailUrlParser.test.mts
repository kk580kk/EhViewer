import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { GalleryDetailUrlParser } from '../../../../main/ets/client/parser/GalleryDetailUrlParser.ets';

describe('GalleryDetailUrlParser', () => {
  it('should parse e-hentai detail URL (strict)', () => {
    const r = GalleryDetailUrlParser.parse('https://e-hentai.org/g/12345/abcdef0123/');
    assert.ok(r !== null);
    assert.strictEqual(r!.gid, 12345);
    assert.strictEqual(r!.token, 'abcdef0123');
  });

  it('should parse exhentai detail URL (strict)', () => {
    const r = GalleryDetailUrlParser.parse('https://exhentai.org/g/99999/1234567890/');
    assert.ok(r !== null);
    assert.strictEqual(r!.gid, 99999);
    assert.strictEqual(r!.token, '1234567890');
  });

  it('should parse mpv URL (strict)', () => {
    const r = GalleryDetailUrlParser.parse('https://e-hentai.org/mpv/12345/abcdef0123/');
    assert.ok(r !== null);
    assert.strictEqual(r!.gid, 12345);
    assert.strictEqual(r!.token, 'abcdef0123');
  });

  it('should return null for invalid host (strict)', () => {
    const r = GalleryDetailUrlParser.parse('https://example.com/g/12345/abcdef0123/');
    assert.strictEqual(r, null);
  });

  it('should parse non-strict URL', () => {
    const r = GalleryDetailUrlParser.parse('12345/abcdef0123/', false);
    assert.ok(r !== null);
    assert.strictEqual(r!.gid, 12345);
    assert.strictEqual(r!.token, 'abcdef0123');
  });

  it('should return null for null input', () => {
    const r = GalleryDetailUrlParser.parse(null);
    assert.strictEqual(r, null);
  });

  it('should parse lofi host (strict)', () => {
    const r = GalleryDetailUrlParser.parse('https://lofi.e-hentai.org/g/12345/abcdef0123/');
    assert.ok(r !== null);
    assert.strictEqual(r!.gid, 12345);
  });

  it('should return null when token is too short', () => {
    const r = GalleryDetailUrlParser.parse('https://e-hentai.org/g/12345/abcdef/');
    assert.strictEqual(r, null);
  });
});
