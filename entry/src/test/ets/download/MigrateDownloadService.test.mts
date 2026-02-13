import { describe, it, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { MigrateDownloadService } from '../../../main/ets/download/MigrateDownloadService.ets';
import type { MigrateProgressCallback } from '../../../main/ets/download/MigrateDownloadService.ets';
import { SettingsService } from '../../../main/ets/service/SettingsService.ets';
import { AppConfig } from '../../../main/ets/AppConfig.ets';
import type { FsOps } from '../../../main/ets/util/FileUtils.ets';
import type { AppContextPaths } from '../../../main/ets/AppConfig.ets';

// ---- Node.js fs adapter ----

const nodeFsOps: FsOps = {
  mkdirSync: (p, opts) => fs.mkdirSync(p, opts),
  existsSync: (p) => fs.existsSync(p),
  statSync: (p) => fs.statSync(p),
  writeFileSync: (p, data, enc) => fs.writeFileSync(p, data, { encoding: (enc as BufferEncoding) ?? 'utf-8' }),
  unlinkSync: (p) => fs.unlinkSync(p),
  readdirSync: (p) => fs.readdirSync(p),
  copyFileSync: (src, dst) => fs.copyFileSync(src, dst),
  rmdirSync: (p, opts) => fs.rmSync(p, opts),
  readFileSync: (p, enc) => fs.readFileSync(p, { encoding: enc as BufferEncoding }),
};

// ---- Helpers ----

let tmpRoot: string;
let oldDir: string;
let newDir: string;

function makeTmpRoot(): string {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'ehv-migrate-'));
}

function rmRecursive(dir: string): void {
  if (fs.existsSync(dir)) {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

function writeFile(filePath: string, content: string): void {
  const dir = path.dirname(filePath);
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(filePath, content, 'utf-8');
}

function readFile(filePath: string): string {
  return fs.readFileSync(filePath, 'utf-8');
}

describe('MigrateDownloadService', () => {
  beforeEach(() => {
    tmpRoot = makeTmpRoot();
    oldDir = path.join(tmpRoot, 'old-download');
    newDir = path.join(tmpRoot, 'new-download');
    fs.mkdirSync(oldDir, { recursive: true });
    fs.mkdirSync(newDir, { recursive: true });

    const ctxPaths: AppContextPaths = {
      filesDir: path.join(tmpRoot, 'files'),
      cacheDir: path.join(tmpRoot, 'cache'),
      tempDir: path.join(tmpRoot, 'temp'),
    };
    fs.mkdirSync(ctxPaths.filesDir, { recursive: true });
    fs.mkdirSync(ctxPaths.cacheDir, { recursive: true });
    fs.mkdirSync(ctxPaths.tempDir, { recursive: true });

    AppConfig.initialize(ctxPaths, nodeFsOps);
    SettingsService.resetDefaults();
    SettingsService.setDownloadLocation(oldDir);
  });

  afterEach(() => {
    rmRecursive(tmpRoot);
  });

  // ---- validate ----

  describe('validate', () => {
    it('returns null for valid migration', () => {
      const service = new MigrateDownloadService(nodeFsOps);
      assert.equal(service.validate(newDir), null);
    });

    it('returns error when same directory', () => {
      const service = new MigrateDownloadService(nodeFsOps);
      assert.equal(service.validate(oldDir), 'same_directory');
    });

    it('returns error when no current location', () => {
      SettingsService.setDownloadLocation(null);
      AppConfig.reset();
      const service = new MigrateDownloadService(nodeFsOps);
      assert.equal(service.validate(newDir), 'no_current_location');
    });
  });

  // ---- migrate ----

  describe('migrate', () => {
    it('migrates gallery directories to new location', () => {
      // Create gallery directories in old location
      writeFile(path.join(oldDir, '12345-TestGallery', '00000001.jpg'), 'image1');
      writeFile(path.join(oldDir, '12345-TestGallery', '00000002.png'), 'image2');
      writeFile(path.join(oldDir, '12345-TestGallery', '.ehviewer'), 'spiderinfo');
      writeFile(path.join(oldDir, '67890-AnotherGallery', '00000001.jpg'), 'image3');

      const service = new MigrateDownloadService(nodeFsOps);
      const result = service.migrate(newDir);

      assert.equal(result.success, true);
      assert.equal(result.migrated, 2);
      assert.equal(result.total, 2);

      // Verify files were moved to new location
      assert.equal(readFile(path.join(newDir, '12345-TestGallery', '00000001.jpg')), 'image1');
      assert.equal(readFile(path.join(newDir, '12345-TestGallery', '00000002.png')), 'image2');
      assert.equal(readFile(path.join(newDir, '12345-TestGallery', '.ehviewer')), 'spiderinfo');
      assert.equal(readFile(path.join(newDir, '67890-AnotherGallery', '00000001.jpg')), 'image3');

      // Verify old directories were removed
      assert.equal(fs.existsSync(path.join(oldDir, '12345-TestGallery')), false);
      assert.equal(fs.existsSync(path.join(oldDir, '67890-AnotherGallery')), false);
    });

    it('updates download location setting after migration', () => {
      writeFile(path.join(oldDir, '111-Gallery', '00000001.jpg'), 'img');

      const service = new MigrateDownloadService(nodeFsOps);
      service.migrate(newDir);

      assert.equal(SettingsService.getDownloadLocation(), newDir);
    });

    it('does not update setting when no directories migrated', () => {
      // Old dir is empty
      const service = new MigrateDownloadService(nodeFsOps);
      const result = service.migrate(newDir);

      assert.equal(result.success, true);
      assert.equal(result.migrated, 0);
      assert.equal(SettingsService.getDownloadLocation(), oldDir);
    });

    it('returns error for same directory', () => {
      const service = new MigrateDownloadService(nodeFsOps);
      const result = service.migrate(oldDir);

      assert.equal(result.success, false);
      assert.equal(result.error, 'same_directory');
    });

    it('returns error when no current location', () => {
      SettingsService.setDownloadLocation(null);
      AppConfig.reset();
      const service = new MigrateDownloadService(nodeFsOps);
      const result = service.migrate(newDir);

      assert.equal(result.success, false);
      assert.equal(result.error, 'no_current_location');
    });

    it('skips non-directory files in source', () => {
      writeFile(path.join(oldDir, '12345-Gallery', '00000001.jpg'), 'img');
      writeFile(path.join(oldDir, '.nomedia'), '');
      writeFile(path.join(oldDir, 'some-file.txt'), 'content');

      const service = new MigrateDownloadService(nodeFsOps);
      const result = service.migrate(newDir);

      assert.equal(result.success, true);
      assert.equal(result.migrated, 1);
      assert.equal(result.total, 1);
    });

    it('migrates .nomedia file', () => {
      writeFile(path.join(oldDir, '12345-Gallery', '00000001.jpg'), 'img');
      writeFile(path.join(oldDir, '.nomedia'), '');

      const service = new MigrateDownloadService(nodeFsOps);
      service.migrate(newDir);

      assert.equal(fs.existsSync(path.join(newDir, '.nomedia')), true);
    });

    it('reports progress via callback', () => {
      writeFile(path.join(oldDir, '111-A', '00000001.jpg'), 'a');
      writeFile(path.join(oldDir, '222-B', '00000001.jpg'), 'b');
      writeFile(path.join(oldDir, '333-C', '00000001.jpg'), 'c');

      const progressCalls: { migrated: number; total: number }[] = [];
      const callback: MigrateProgressCallback = {
        onProgress(migrated: number, total: number): void {
          progressCalls.push({ migrated, total });
        },
      };

      const service = new MigrateDownloadService(nodeFsOps);
      const result = service.migrate(newDir, callback);

      assert.equal(result.migrated, 3);
      assert.equal(progressCalls.length, 3);
      // Each call should report the correct total
      for (const call of progressCalls) {
        assert.equal(call.total, 3);
      }
      // Last call should have all migrated
      assert.equal(progressCalls[progressCalls.length - 1].migrated, 3);
    });

    it('handles nested subdirectories', () => {
      writeFile(path.join(oldDir, '12345-Gallery', 'subdir', 'nested.jpg'), 'nested');
      writeFile(path.join(oldDir, '12345-Gallery', 'top.jpg'), 'top');

      const service = new MigrateDownloadService(nodeFsOps);
      const result = service.migrate(newDir);

      assert.equal(result.success, true);
      assert.equal(result.migrated, 1);
      assert.equal(readFile(path.join(newDir, '12345-Gallery', 'top.jpg')), 'top');
      assert.equal(readFile(path.join(newDir, '12345-Gallery', 'subdir', 'nested.jpg')), 'nested');
    });

    it('returns error when fs does not support readdirSync', () => {
      const limitedFs: FsOps = {
        mkdirSync: nodeFsOps.mkdirSync,
        existsSync: nodeFsOps.existsSync,
        statSync: nodeFsOps.statSync,
        writeFileSync: nodeFsOps.writeFileSync,
        unlinkSync: nodeFsOps.unlinkSync,
        // readdirSync intentionally omitted
      };

      const service = new MigrateDownloadService(limitedFs);
      const result = service.migrate(newDir);

      assert.equal(result.success, false);
      assert.equal(result.error, 'fs_not_supported');
    });
  });
});
