import { describe, it, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { AppConfig } from '../../main/ets/AppConfig.ets';
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
  return fs.mkdtempSync(path.join(os.tmpdir(), 'ehv-appconfig-'));
}

describe('AppConfig', () => {
  beforeEach(() => {
    tmpRoot = makeTmpRoot();
    ctxPaths = {
      filesDir: path.join(tmpRoot, 'files'),
      cacheDir: path.join(tmpRoot, 'cache'),
      tempDir: path.join(tmpRoot, 'temp'),
    };
    // Pre-create base dirs
    fs.mkdirSync(ctxPaths.filesDir, { recursive: true });
    fs.mkdirSync(ctxPaths.cacheDir, { recursive: true });
    fs.mkdirSync(ctxPaths.tempDir, { recursive: true });

    AppConfig.initialize(ctxPaths, nodeFsOps);
  });

  afterEach(() => {
    AppConfig.reset();
    fs.rmSync(tmpRoot, { recursive: true, force: true });
  });

  // ---- filesDir-based directories ----

  describe('getDownloadDir()', () => {
    it('should return filesDir/download and create it', () => {
      const dir = AppConfig.getDownloadDir();
      assert.ok(dir !== null);
      assert.strictEqual(dir, path.join(ctxPaths.filesDir, 'download'));
      assert.ok(fs.statSync(dir!).isDirectory());
    });
  });

  describe('getParseErrorDir()', () => {
    it('should return filesDir/parse_error and create it', () => {
      const dir = AppConfig.getParseErrorDir();
      assert.ok(dir !== null);
      assert.strictEqual(dir, path.join(ctxPaths.filesDir, 'parse_error'));
      assert.ok(fs.statSync(dir!).isDirectory());
    });
  });

  describe('getLogcatDir()', () => {
    it('should return filesDir/logcat and create it', () => {
      const dir = AppConfig.getLogcatDir();
      assert.ok(dir !== null);
      assert.strictEqual(dir, path.join(ctxPaths.filesDir, 'logcat'));
      assert.ok(fs.statSync(dir!).isDirectory());
    });
  });

  describe('getDataDir()', () => {
    it('should return filesDir/data and create it', () => {
      const dir = AppConfig.getDataDir();
      assert.ok(dir !== null);
      assert.strictEqual(dir, path.join(ctxPaths.filesDir, 'data'));
      assert.ok(fs.statSync(dir!).isDirectory());
    });
  });

  describe('getCrashDir()', () => {
    it('should return filesDir/crash and create it', () => {
      const dir = AppConfig.getCrashDir();
      assert.ok(dir !== null);
      assert.strictEqual(dir, path.join(ctxPaths.filesDir, 'crash'));
      assert.ok(fs.statSync(dir!).isDirectory());
    });
  });

  describe('getFilesSubDir()', () => {
    it('should create a custom subdirectory under filesDir', () => {
      const dir = AppConfig.getFilesSubDir('custom');
      assert.ok(dir !== null);
      assert.strictEqual(dir, path.join(ctxPaths.filesDir, 'custom'));
      assert.ok(fs.statSync(dir!).isDirectory());
    });
  });

  // ---- cacheDir-based directories ----

  describe('getTempDir()', () => {
    it('should return cacheDir/temp and create it', () => {
      const dir = AppConfig.getTempDir();
      assert.ok(dir !== null);
      assert.strictEqual(dir, path.join(ctxPaths.cacheDir, 'temp'));
      assert.ok(fs.statSync(dir!).isDirectory());
    });
  });

  describe('getImageDir()', () => {
    it('should return cacheDir/image and create it', () => {
      const dir = AppConfig.getImageDir();
      assert.ok(dir !== null);
      assert.strictEqual(dir, path.join(ctxPaths.cacheDir, 'image'));
      assert.ok(fs.statSync(dir!).isDirectory());
    });
  });

  // ---- Temp files ----

  describe('createTempFile()', () => {
    it('should create a temp file in cacheDir/temp', () => {
      const fp = AppConfig.createTempFile();
      assert.ok(fp !== null);
      assert.ok(fp!.startsWith(path.join(ctxPaths.cacheDir, 'temp')));
      assert.ok(fs.statSync(fp!).isFile());
    });

    it('should accept a custom extension', () => {
      const fp = AppConfig.createTempFile('png');
      assert.ok(fp !== null);
      assert.ok(fp!.endsWith('.png'));
    });
  });

  // ---- File in filesDir ----

  describe('getFileInFilesDir()', () => {
    it('should create and return a file path', () => {
      const fp = AppConfig.getFileInFilesDir('config.json');
      assert.ok(fp !== null);
      assert.strictEqual(fp, path.join(ctxPaths.filesDir, 'config.json'));
      assert.ok(fs.statSync(fp!).isFile());
    });
  });

  // ---- Error logging ----

  describe('saveParseErrorBody()', () => {
    it('should write message and body to a timestamped file', () => {
      AppConfig.saveParseErrorBody('Parse failed', '<html>bad</html>');
      const dir = path.join(ctxPaths.filesDir, 'parse_error');
      const files = fs.readdirSync(dir);
      assert.strictEqual(files.length, 1);
      assert.ok(files[0].endsWith('.txt'));
      const content = fs.readFileSync(path.join(dir, files[0]), 'utf-8');
      assert.ok(content.includes('Parse failed'));
      assert.ok(content.includes('<html>bad</html>'));
    });

    it('should handle null message', () => {
      AppConfig.saveParseErrorBody(null, 'body only');
      const dir = path.join(ctxPaths.filesDir, 'parse_error');
      const files = fs.readdirSync(dir);
      const content = fs.readFileSync(path.join(dir, files[0]), 'utf-8');
      assert.strictEqual(content, 'body only');
    });

    it('should handle null body', () => {
      AppConfig.saveParseErrorBody('message only', null);
      const dir = path.join(ctxPaths.filesDir, 'parse_error');
      const files = fs.readdirSync(dir);
      const content = fs.readFileSync(path.join(dir, files[0]), 'utf-8');
      assert.strictEqual(content, 'message only\n');
    });
  });

  describe('saveCrashLog()', () => {
    it('should write crash info to a timestamped file', () => {
      AppConfig.saveCrashLog('TypeError: cannot read property');
      const dir = path.join(ctxPaths.filesDir, 'crash');
      const files = fs.readdirSync(dir);
      assert.strictEqual(files.length, 1);
      const content = fs.readFileSync(path.join(dir, files[0]), 'utf-8');
      assert.ok(content.includes('TypeError: cannot read property'));
    });
  });

  // ---- Uninitialized ----

  describe('before initialization', () => {
    it('should return null when not initialized', () => {
      AppConfig.reset();
      assert.strictEqual(AppConfig.getDownloadDir(), null);
      assert.strictEqual(AppConfig.getTempDir(), null);
      assert.strictEqual(AppConfig.getFileInFilesDir('x'), null);
    });
  });
});
