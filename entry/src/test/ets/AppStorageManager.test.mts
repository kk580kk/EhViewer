import { describe, it, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { AppStorageManager } from '../../main/ets/AppStorageManager.ets';
import type { AppContextPaths } from '../../main/ets/AppConfig.ets';
import type { FsOps } from '../../main/ets/util/FileUtils.ets';

// ---- Node.js fs adapter ----

const nodeFsOps: FsOps = {
  mkdirSync: (p, opts) => fs.mkdirSync(p, opts),
  existsSync: (p) => fs.existsSync(p),
  statSync: (p) => fs.statSync(p),
  writeFileSync: (p, data, enc) => fs.writeFileSync(p, data, { encoding: (enc as BufferEncoding) ?? 'utf-8' }),
  unlinkSync: (p) => fs.unlinkSync(p),
};

// ---- Test helpers ----

let tmpRoot: string;
let ctxPaths: AppContextPaths;

function makeTmpRoot(): string {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'ehv-storagemgr-'));
}

describe('AppStorageManager', () => {
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

    AppStorageManager.initialize(ctxPaths, nodeFsOps);
  });

  afterEach(() => {
    AppStorageManager.reset();
    fs.rmSync(tmpRoot, { recursive: true, force: true });
  });

  // ---- isInitialized ----

  describe('isInitialized()', () => {
    it('should return true after initialize', () => {
      assert.strictEqual(AppStorageManager.isInitialized(), true);
    });

    it('should return false after reset', () => {
      AppStorageManager.reset();
      assert.strictEqual(AppStorageManager.isInitialized(), false);
    });
  });

  // ---- Persistent directories ----

  describe('getDownloadDir()', () => {
    it('should create filesDir/download', () => {
      const dir = AppStorageManager.getDownloadDir();
      assert.ok(dir !== null);
      assert.strictEqual(dir, path.join(ctxPaths.filesDir, 'download'));
      assert.ok(fs.statSync(dir!).isDirectory());
    });
  });

  describe('getDataDir()', () => {
    it('should create filesDir/data', () => {
      const dir = AppStorageManager.getDataDir();
      assert.ok(dir !== null);
      assert.strictEqual(dir, path.join(ctxPaths.filesDir, 'data'));
      assert.ok(fs.statSync(dir!).isDirectory());
    });
  });

  // ---- Cache directories ----

  describe('getCacheTempDir()', () => {
    it('should create cacheDir/temp', () => {
      const dir = AppStorageManager.getCacheTempDir();
      assert.ok(dir !== null);
      assert.strictEqual(dir, path.join(ctxPaths.cacheDir, 'temp'));
      assert.ok(fs.statSync(dir!).isDirectory());
    });
  });

  describe('getImageCacheDir()', () => {
    it('should create cacheDir/image', () => {
      const dir = AppStorageManager.getImageCacheDir();
      assert.ok(dir !== null);
      assert.strictEqual(dir, path.join(ctxPaths.cacheDir, 'image'));
      assert.ok(fs.statSync(dir!).isDirectory());
    });
  });

  describe('getCacheDir()', () => {
    it('should create cacheDir/cache', () => {
      const dir = AppStorageManager.getCacheDir();
      assert.ok(dir !== null);
      assert.strictEqual(dir, path.join(ctxPaths.cacheDir, 'cache'));
      assert.ok(fs.statSync(dir!).isDirectory());
    });
  });

  // ---- Share temp ----

  describe('getShareTempDir()', () => {
    it('should create cacheDir/share', () => {
      const dir = AppStorageManager.getShareTempDir();
      assert.ok(dir !== null);
      assert.strictEqual(dir, path.join(ctxPaths.cacheDir, 'share'));
      assert.ok(fs.statSync(dir!).isDirectory());
    });
  });

  // ---- Temp directory ----

  describe('getTempDir()', () => {
    it('should return the system temp directory', () => {
      const dir = AppStorageManager.getTempDir();
      assert.ok(dir !== null);
      assert.strictEqual(dir, ctxPaths.tempDir);
    });
  });

  // ---- Custom subdirectories ----

  describe('getPersistentSubDir()', () => {
    it('should create a custom subdirectory under filesDir', () => {
      const dir = AppStorageManager.getPersistentSubDir('custom');
      assert.ok(dir !== null);
      assert.strictEqual(dir, path.join(ctxPaths.filesDir, 'custom'));
      assert.ok(fs.statSync(dir!).isDirectory());
    });
  });

  describe('getCacheSubDir()', () => {
    it('should create a custom subdirectory under cacheDir', () => {
      const dir = AppStorageManager.getCacheSubDir('thumbs');
      assert.ok(dir !== null);
      assert.strictEqual(dir, path.join(ctxPaths.cacheDir, 'thumbs'));
      assert.ok(fs.statSync(dir!).isDirectory());
    });
  });

  // ---- getAllPaths ----

  describe('getAllPaths()', () => {
    it('should return all standard storage paths', () => {
      const paths = AppStorageManager.getAllPaths();
      assert.ok(paths.length > 0);

      const names = paths.map(p => p.name);
      assert.ok(names.includes('download'));
      assert.ok(names.includes('data'));
      assert.ok(names.includes('cache_temp'));
      assert.ok(names.includes('image_cache'));
      assert.ok(names.includes('share'));
      assert.ok(names.includes('temp'));
    });

    it('should categorize paths correctly', () => {
      const paths = AppStorageManager.getAllPaths();
      const downloadInfo = paths.find(p => p.name === 'download');
      assert.ok(downloadInfo);
      assert.strictEqual(downloadInfo!.type, 'persistent');

      const shareInfo = paths.find(p => p.name === 'share');
      assert.ok(shareInfo);
      assert.strictEqual(shareInfo!.type, 'cache');

      const tempInfo = paths.find(p => p.name === 'temp');
      assert.ok(tempInfo);
      assert.strictEqual(tempInfo!.type, 'temp');
    });
  });

  // ---- Idempotency ----

  describe('idempotency', () => {
    it('should return the same path across multiple calls', () => {
      const dir1 = AppStorageManager.getDownloadDir();
      const dir2 = AppStorageManager.getDownloadDir();
      assert.strictEqual(dir1, dir2);
    });
  });

  // ---- Uninitialized ----

  describe('before initialization', () => {
    it('should return null for all paths when not initialized', () => {
      AppStorageManager.reset();
      assert.strictEqual(AppStorageManager.getDownloadDir(), null);
      assert.strictEqual(AppStorageManager.getDataDir(), null);
      assert.strictEqual(AppStorageManager.getCacheTempDir(), null);
      assert.strictEqual(AppStorageManager.getShareTempDir(), null);
      assert.strictEqual(AppStorageManager.getTempDir(), null);
    });
  });
});
