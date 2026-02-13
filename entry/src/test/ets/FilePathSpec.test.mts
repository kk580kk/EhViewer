import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  SHARE_DIR,
  TEMP_DIR,
  IMAGE_DIR,
  DOWNLOAD_DIR,
  SUPPORT_IMAGE_EXTENSIONS,
  sanitizeFilename,
  formatGalleryDirname,
  formatDownloadImageFilename,
  isSupportedImageExtension,
  normalizeImageExtension,
  formatEhGalleryImageFilename,
} from '../../main/ets/FilePathSpec.ets';

describe('FilePathSpec', () => {

  // ---- Constants ----

  it('directory constants are non-empty strings', () => {
    assert.ok(SHARE_DIR.length > 0);
    assert.ok(TEMP_DIR.length > 0);
    assert.ok(IMAGE_DIR.length > 0);
    assert.ok(DOWNLOAD_DIR.length > 0);
  });

  it('SUPPORT_IMAGE_EXTENSIONS all start with dot', () => {
    assert.ok(SUPPORT_IMAGE_EXTENSIONS.length > 0);
    for (const ext of SUPPORT_IMAGE_EXTENSIONS) {
      assert.ok(ext.startsWith('.'), `Extension should start with dot: ${ext}`);
    }
  });

  // ---- sanitizeFilename ----

  describe('sanitizeFilename', () => {
    it('returns name unchanged for simple strings', () => {
      assert.equal(sanitizeFilename('hello'), 'hello');
    });

    it('replaces forward slash with underscore', () => {
      const result = sanitizeFilename('a/b');
      assert.ok(result !== null);
      assert.ok(!result!.includes('/'));
    });

    it('replaces backslash with underscore', () => {
      const result = sanitizeFilename('a\\b');
      assert.ok(result !== null);
      assert.ok(!result!.includes('\\'));
    });

    it('replaces multiple illegal chars', () => {
      const result = sanitizeFilename('a:b*c?d"e<f>g|h');
      assert.ok(result !== null);
      assert.ok(!result!.includes(':'));
      assert.ok(!result!.includes('*'));
      assert.ok(!result!.includes('?'));
      assert.ok(!result!.includes('"'));
      assert.ok(!result!.includes('<'));
      assert.ok(!result!.includes('>'));
      assert.ok(!result!.includes('|'));
    });

    it('strips leading dots', () => {
      const result = sanitizeFilename('...hidden');
      assert.ok(result !== null);
      assert.ok(!result!.startsWith('.'));
    });

    it('returns null for empty string', () => {
      assert.equal(sanitizeFilename(''), null);
    });

    it('returns null for string of only illegal chars + dots', () => {
      assert.equal(sanitizeFilename('...'), null);
    });

    it('trims whitespace', () => {
      const result = sanitizeFilename('  hello  ');
      assert.equal(result, 'hello');
    });

    it('truncates to 255 characters', () => {
      const long = 'a'.repeat(300);
      const result = sanitizeFilename(long);
      assert.ok(result !== null);
      assert.equal(result!.length, 255);
    });
  });

  // ---- formatGalleryDirname ----

  describe('formatGalleryDirname', () => {
    it('produces gid-prefixed dirname', () => {
      const dirname = formatGalleryDirname(12345, 'My Gallery Title');
      assert.ok(dirname.startsWith('12345-'));
    });

    it('sanitizes path separators', () => {
      const dirname = formatGalleryDirname(1, 'a/b\\c');
      assert.ok(!dirname.includes('/'));
      assert.ok(!dirname.includes('\\'));
    });

    it('handles empty title gracefully', () => {
      const dirname = formatGalleryDirname(42, '');
      assert.ok(dirname.includes('42'));
    });
  });

  // ---- formatDownloadImageFilename ----

  describe('formatDownloadImageFilename', () => {
    it('zero-based index produces 1-based 8-digit filename', () => {
      assert.equal(formatDownloadImageFilename(0, '.jpg'), '00000001.jpg');
      assert.equal(formatDownloadImageFilename(1, '.png'), '00000002.png');
      assert.equal(formatDownloadImageFilename(999, '.gif'), '00001000.gif');
    });
  });

  // ---- isSupportedImageExtension ----

  describe('isSupportedImageExtension', () => {
    it('accepts known extensions', () => {
      assert.ok(isSupportedImageExtension('.jpg'));
      assert.ok(isSupportedImageExtension('.jpeg'));
      assert.ok(isSupportedImageExtension('.png'));
      assert.ok(isSupportedImageExtension('.gif'));
    });

    it('is case-insensitive', () => {
      assert.ok(isSupportedImageExtension('.JPG'));
      assert.ok(isSupportedImageExtension('.PNG'));
    });

    it('rejects unknown extensions', () => {
      assert.ok(!isSupportedImageExtension('.bmp'));
      assert.ok(!isSupportedImageExtension('.webp'));
      assert.ok(!isSupportedImageExtension('jpg')); // missing dot
    });
  });

  // ---- normalizeImageExtension ----

  describe('normalizeImageExtension', () => {
    it('returns supported extension as-is (lowered)', () => {
      assert.equal(normalizeImageExtension('.jpg'), '.jpg');
      assert.equal(normalizeImageExtension('.png'), '.png');
    });

    it('returns first supported extension for unknown', () => {
      assert.equal(normalizeImageExtension('.unknown'), SUPPORT_IMAGE_EXTENSIONS[0]);
    });
  });

  // ---- formatEhGalleryImageFilename ----

  describe('formatEhGalleryImageFilename', () => {
    it('formats gid-token-index', () => {
      assert.equal(formatEhGalleryImageFilename(123, 'abc', 0), '123-abc-00000001');
      assert.equal(formatEhGalleryImageFilename(123, 'abc', 1), '123-abc-00000002');
      assert.equal(formatEhGalleryImageFilename(1, 'token', 99), '1-token-00000100');
    });
  });
});
