import { describe, it, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { FileShareHelper } from '../../main/ets/FileShareHelper.ets';
import type { ShareFsOps } from '../../main/ets/FileShareHelper.ets';
import { AppStorageManager } from '../../main/ets/AppStorageManager.ets';
import type { AppContextPaths } from '../../main/ets/AppConfig.ets';

// ---- Node.js fs adapter with share capabilities ----

const nodeShareFsOps: ShareFsOps = {
  mkdirSync: (p, opts) => fs.mkdirSync(p, opts),
  existsSync: (p) => fs.existsSync(p),
  statSync: (p) => fs.statSync(p),
  writeFileSync: (p, data, enc) => fs.writeFileSync(p, data, { encoding: (enc as BufferEncoding) ?? 'utf-8' }),
  unlinkSync: (p) => fs.unlinkSync(p),
  readdirSync: (p) => fs.readdirSync(p),
  copyFileSync: (src, dest) => fs.copyFileSync(src, dest),
};

// ---- Test helpers ----

let tmpRoot: string;
let ctxPaths: AppContextPaths;

function makeTmpRoot(): string {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'ehv-fileshare-'));
}

describe('FileShareHelper', () => {
  beforeEach(() => {
    tmpRoot = makeTmpRoot();
    ctxPaths = {
      filesDir: path.join(tmpRoot, 'files'),
      cacheDir: path.join(tmpRoot, 'cache'),
      tempDir: path.join(tmpRoot, 'temp'),
    };
    fs.mkdirSync(ctxPaths.filesDir, { recursive: true });
    fs.mkdirSync(ctxPaths.cacheDir, { recursive: true });
    fs.mkdirSync(ctxPaths.tempDir, { recursive: true });

    AppStorageManager.initialize(ctxPaths, nodeShareFsOps);
    FileShareHelper.initialize(nodeShareFsOps);
  });

  afterEach(() => {
    FileShareHelper.reset();
    AppStorageManager.reset();
    fs.rmSync(tmpRoot, { recursive: true, force: true });
  });

  // ---- getMimeType ----

  describe('getMimeType()', () => {
    it('should return image/jpeg for .jpg', () => {
      assert.strictEqual(FileShareHelper.getMimeType('photo.jpg'), 'image/jpeg');
    });

    it('should return image/jpeg for .jpeg', () => {
      assert.strictEqual(FileShareHelper.getMimeType('photo.jpeg'), 'image/jpeg');
    });

    it('should return image/png for .png', () => {
      assert.strictEqual(FileShareHelper.getMimeType('image.png'), 'image/png');
    });

    it('should return image/gif for .gif', () => {
      assert.strictEqual(FileShareHelper.getMimeType('animation.gif'), 'image/gif');
    });

    it('should return image/webp for .webp', () => {
      assert.strictEqual(FileShareHelper.getMimeType('photo.webp'), 'image/webp');
    });

    it('should return application/pdf for .pdf', () => {
      assert.strictEqual(FileShareHelper.getMimeType('doc.pdf'), 'application/pdf');
    });

    it('should return application/zip for .zip', () => {
      assert.strictEqual(FileShareHelper.getMimeType('archive.zip'), 'application/zip');
    });

    it('should return default for unknown extension', () => {
      assert.strictEqual(FileShareHelper.getMimeType('file.xyz'), 'application/octet-stream');
    });

    it('should return default for null', () => {
      assert.strictEqual(FileShareHelper.getMimeType(null), 'application/octet-stream');
    });

    it('should return default for empty string', () => {
      assert.strictEqual(FileShareHelper.getMimeType(''), 'application/octet-stream');
    });

    it('should be case insensitive on extension', () => {
      assert.strictEqual(FileShareHelper.getMimeType('photo.JPG'), 'image/jpeg');
      assert.strictEqual(FileShareHelper.getMimeType('image.PNG'), 'image/png');
    });

    it('should handle full paths', () => {
      assert.strictEqual(FileShareHelper.getMimeType('/data/storage/share/photo.jpg'), 'image/jpeg');
    });
  });

  // ---- prepareFileForShare ----

  describe('prepareFileForShare()', () => {
    it('should copy file to share temp dir and return result', () => {
      // Create a source file
      const srcDir = path.join(tmpRoot, 'source');
      fs.mkdirSync(srcDir, { recursive: true });
      const srcFile = path.join(srcDir, 'test.jpg');
      fs.writeFileSync(srcFile, 'fake image data');

      const result = FileShareHelper.prepareFileForShare(srcFile);
      assert.ok(result !== null);
      assert.strictEqual(result!.filename, 'test.jpg');
      assert.strictEqual(result!.mimeType, 'image/jpeg');
      assert.ok(result!.uri.startsWith('file://'));
      assert.ok(result!.uri.includes('/share/'));

      // Verify file was actually copied
      const shareDir = AppStorageManager.getShareTempDir()!;
      const copiedFile = path.join(shareDir, 'test.jpg');
      assert.ok(fs.existsSync(copiedFile));
      assert.strictEqual(fs.readFileSync(copiedFile, 'utf-8'), 'fake image data');
    });

    it('should return null when not initialized', () => {
      FileShareHelper.reset();
      assert.strictEqual(FileShareHelper.prepareFileForShare('/some/file.jpg'), null);
    });
  });

  // ---- createShareWant ----

  describe('createShareWant()', () => {
    it('should create a want descriptor for file sharing', () => {
      const srcDir = path.join(tmpRoot, 'source');
      fs.mkdirSync(srcDir, { recursive: true });
      const srcFile = path.join(srcDir, 'gallery.png');
      fs.writeFileSync(srcFile, 'png data');

      const want = FileShareHelper.createShareWant(srcFile);
      assert.ok(want !== null);
      assert.strictEqual(want!.action, 'ohos.want.action.select');
      assert.strictEqual(want!.type, 'image/png');
      assert.ok(want!.uri!.includes('gallery.png'));
      assert.ok(want!.parameters!['shareFileName'] === 'gallery.png');
    });

    it('should allow MIME type override', () => {
      const srcDir = path.join(tmpRoot, 'source');
      fs.mkdirSync(srcDir, { recursive: true });
      const srcFile = path.join(srcDir, 'file.dat');
      fs.writeFileSync(srcFile, 'data');

      const want = FileShareHelper.createShareWant(srcFile, 'image/jpeg');
      assert.ok(want !== null);
      assert.strictEqual(want!.type, 'image/jpeg');
    });

    it('should return null for nonexistent source file', () => {
      const want = FileShareHelper.createShareWant('/nonexistent/file.jpg');
      assert.strictEqual(want, null);
    });
  });

  // ---- createImageShareWant ----

  describe('createImageShareWant()', () => {
    it('should default to image/jpeg for unknown extension', () => {
      const srcDir = path.join(tmpRoot, 'source');
      fs.mkdirSync(srcDir, { recursive: true });
      const srcFile = path.join(srcDir, 'image.dat');
      fs.writeFileSync(srcFile, 'data');

      const want = FileShareHelper.createImageShareWant(srcFile);
      assert.ok(want !== null);
      assert.strictEqual(want!.type, 'image/jpeg');
    });

    it('should preserve known image MIME type', () => {
      const srcDir = path.join(tmpRoot, 'source');
      fs.mkdirSync(srcDir, { recursive: true });
      const srcFile = path.join(srcDir, 'photo.png');
      fs.writeFileSync(srcFile, 'png data');

      const want = FileShareHelper.createImageShareWant(srcFile);
      assert.ok(want !== null);
      assert.strictEqual(want!.type, 'image/png');
    });
  });

  // ---- cleanShareTempDir ----

  describe('cleanShareTempDir()', () => {
    it('should delete all files in the share temp directory', () => {
      const shareDir = AppStorageManager.getShareTempDir()!;
      fs.writeFileSync(path.join(shareDir, 'a.tmp'), 'a');
      fs.writeFileSync(path.join(shareDir, 'b.tmp'), 'b');
      fs.writeFileSync(path.join(shareDir, 'c.tmp'), 'c');

      const count = FileShareHelper.cleanShareTempDir();
      assert.strictEqual(count, 3);

      // Verify all files are gone
      const remaining = fs.readdirSync(shareDir);
      assert.strictEqual(remaining.length, 0);
    });

    it('should return 0 when directory is empty', () => {
      AppStorageManager.getShareTempDir(); // ensure dir exists
      assert.strictEqual(FileShareHelper.cleanShareTempDir(), 0);
    });

    it('should return 0 when not initialized', () => {
      FileShareHelper.reset();
      assert.strictEqual(FileShareHelper.cleanShareTempDir(), 0);
    });
  });
});
