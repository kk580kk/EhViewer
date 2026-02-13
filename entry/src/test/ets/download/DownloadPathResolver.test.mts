import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { GalleryInfo } from '../../../main/ets/model/GalleryInfo.ets';
import { MemoryEhDB } from '../../../main/ets/database/MemoryEhDB.ets';
import { SettingsService } from '../../../main/ets/service/SettingsService.ets';
import { MemoryPreferencesStore } from '../../../main/ets/preferences/MemoryPreferencesStore.ets';
import { AppConfig } from '../../../main/ets/AppConfig.ets';
import type { FsOps } from '../../../main/ets/util/FileUtils.ets';
import type { AppContextPaths } from '../../../main/ets/AppConfig.ets';
import {
  getDownloadRoot,
  getGalleryDownloadDir,
  ensureGalleryDownloadDir,
} from '../../../main/ets/download/DownloadPathResolver.ets';

// ---- Node.js fs adapter ----

const nodeFsOps: FsOps = {
  mkdirSync: (p, opts) => fs.mkdirSync(p, opts),
  existsSync: (p) => fs.existsSync(p),
  statSync: (p) => fs.statSync(p),
  writeFileSync: (p, data, enc) => fs.writeFileSync(p, data, { encoding: (enc as BufferEncoding) ?? 'utf-8' }),
  unlinkSync: (p) => fs.unlinkSync(p),
};

// ---- Helpers ----

function makeGallery(gid: number, title: string = `Gallery ${gid}`): GalleryInfo {
  const gi = new GalleryInfo();
  gi.gid = gid;
  gi.token = `tok_${gid}`;
  gi.title = title;
  gi.category = 2;
  gi.uploader = 'test_user';
  gi.rating = 4.0;
  return gi;
}

let tmpRoot: string;
let ctxPaths: AppContextPaths;
let db: MemoryEhDB;

function makeTmpRoot(): string {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'ehv-dlpath-'));
}

function rmRecursive(dir: string): void {
  if (fs.existsSync(dir)) {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

describe('DownloadPathResolver', () => {
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

    AppConfig.initialize(ctxPaths, nodeFsOps);
    SettingsService.resetDefaults();
    db = new MemoryEhDB();
  });

  // ---- getDownloadRoot ----

  describe('getDownloadRoot', () => {
    it('returns default download dir when no custom location set', () => {
      const root = getDownloadRoot();
      assert.ok(root !== null);
      assert.ok(root!.includes('download'));
    });

    it('returns custom location when set', () => {
      const customDir = path.join(tmpRoot, 'custom-dl');
      SettingsService.setDownloadLocation(customDir);
      const root = getDownloadRoot();
      assert.equal(root, customDir);
    });

    it('falls back to default when custom location is empty string', () => {
      SettingsService.setDownloadLocation('');
      const root = getDownloadRoot();
      assert.ok(root !== null);
      assert.ok(root!.includes('download'));
    });
  });

  // ---- getGalleryDownloadDir ----

  describe('getGalleryDownloadDir', () => {
    it('returns path combining download root and formatted dirname', () => {
      const gi = makeGallery(12345, 'My Test Gallery');
      const dir = getGalleryDownloadDir(gi, db);
      assert.ok(dir !== null);
      assert.ok(dir!.includes('12345-'));
      assert.ok(dir!.includes('My Test Gallery'));
    });

    it('persists dirname to db on first call', () => {
      const gi = makeGallery(42, 'Title');
      getGalleryDownloadDir(gi, db);
      const dirname = db.getDownloadDirname(42);
      assert.ok(dirname !== null);
      assert.ok(dirname!.startsWith('42-'));
    });

    it('reuses persisted dirname on subsequent calls', () => {
      const gi = makeGallery(7, 'Original');
      db.putDownloadDirname(7, '7-Custom Name');
      const dir = getGalleryDownloadDir(gi, db);
      assert.ok(dir !== null);
      assert.ok(dir!.endsWith('7-Custom Name'));
    });

    it('re-sanitizes persisted dirname with illegal chars', () => {
      const gi = makeGallery(9, 'Title');
      db.putDownloadDirname(9, '9-bad/name');
      const dir = getGalleryDownloadDir(gi, db);
      assert.ok(dir !== null);
      assert.ok(!dir!.includes('/name')); // slash removed from dirname part
      // Verify db was updated with sanitized version
      const stored = db.getDownloadDirname(9);
      assert.ok(stored !== null);
      assert.ok(!stored!.includes('/'));
    });

    it('returns null when no download root available', () => {
      AppConfig.reset();
      SettingsService.resetDefaults();
      const gi = makeGallery(1, 'Title');
      const dir = getGalleryDownloadDir(gi, db);
      assert.equal(dir, null);
    });

    it('uses custom download location', () => {
      const customDir = path.join(tmpRoot, 'my-downloads');
      SettingsService.setDownloadLocation(customDir);
      const gi = makeGallery(100, 'Custom Dir Gallery');
      const dir = getGalleryDownloadDir(gi, db);
      assert.ok(dir !== null);
      assert.ok(dir!.startsWith(customDir));
    });
  });

  // ---- ensureGalleryDownloadDir ----

  describe('ensureGalleryDownloadDir', () => {
    it('creates the directory on disk and returns the path', () => {
      const gi = makeGallery(55, 'Created Dir');
      const dir = ensureGalleryDownloadDir(gi, db, nodeFsOps);
      assert.ok(dir !== null);
      assert.ok(fs.existsSync(dir!));
      assert.ok(fs.statSync(dir!).isDirectory());

      rmRecursive(tmpRoot);
    });

    it('returns null when no download root available', () => {
      AppConfig.reset();
      SettingsService.resetDefaults();
      const gi = makeGallery(1, 'Title');
      const dir = ensureGalleryDownloadDir(gi, db, nodeFsOps);
      assert.equal(dir, null);
    });

    it('returns the path when directory already exists', () => {
      const gi = makeGallery(77, 'Existing Dir');
      // First call creates
      const dir1 = ensureGalleryDownloadDir(gi, db, nodeFsOps);
      assert.ok(dir1 !== null);
      // Second call should still return the same path
      const dir2 = ensureGalleryDownloadDir(gi, db, nodeFsOps);
      assert.equal(dir1, dir2);

      rmRecursive(tmpRoot);
    });
  });
});
