import { describe, it, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import {
  joinPath,
  getParent,
  getFileName,
  getExtension,
  getNameWithoutExtension,
  ensureDirectory,
  ensureFile,
  createTempFile,
  deleteFile,
  writeToFile,
} from '../../../main/ets/util/FileUtils.ets';
import type { FsOps } from '../../../main/ets/util/FileUtils.ets';

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

function makeTmpRoot(): string {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'ehv-fileutils-'));
}

// ---- Pure path utility tests ----

describe('joinPath', () => {
  it('should join two segments', () => {
    assert.strictEqual(joinPath('/a', 'b'), '/a/b');
  });

  it('should strip trailing slash from base', () => {
    assert.strictEqual(joinPath('/a/', 'b'), '/a/b');
  });

  it('should strip leading slash from appended segment', () => {
    assert.strictEqual(joinPath('/a', '/b'), '/a/b');
  });

  it('should join multiple segments', () => {
    assert.strictEqual(joinPath('/a', 'b', 'c'), '/a/b/c');
  });

  it('should handle empty segments', () => {
    assert.strictEqual(joinPath('', '/a', '', 'b'), '/a/b');
  });

  it('should handle single segment', () => {
    assert.strictEqual(joinPath('/a'), '/a');
  });
});

describe('getParent', () => {
  it('should return parent directory', () => {
    assert.strictEqual(getParent('/a/b/c'), '/a/b');
  });

  it('should return empty for root-level path', () => {
    assert.strictEqual(getParent('/a'), '');
  });

  it('should return empty for no separator', () => {
    assert.strictEqual(getParent('file.txt'), '');
  });
});

describe('getFileName', () => {
  it('should return the last segment', () => {
    assert.strictEqual(getFileName('/a/b/file.txt'), 'file.txt');
  });

  it('should return the string itself if no separator', () => {
    assert.strictEqual(getFileName('file.txt'), 'file.txt');
  });
});

describe('getExtension', () => {
  it('should return the extension without dot', () => {
    assert.strictEqual(getExtension('/a/b/file.txt'), 'txt');
  });

  it('should return empty for no extension', () => {
    assert.strictEqual(getExtension('/a/b/file'), '');
  });

  it('should return last extension for multiple dots', () => {
    assert.strictEqual(getExtension('archive.tar.gz'), 'gz');
  });
});

describe('getNameWithoutExtension', () => {
  it('should strip the extension', () => {
    assert.strictEqual(getNameWithoutExtension('/a/b/file.txt'), 'file');
  });

  it('should return full name if no extension', () => {
    assert.strictEqual(getNameWithoutExtension('README'), 'README');
  });

  it('should strip only the last extension', () => {
    assert.strictEqual(getNameWithoutExtension('archive.tar.gz'), 'archive.tar');
  });
});

// ---- FS-backed utility tests ----

describe('ensureDirectory', () => {
  beforeEach(() => { tmpRoot = makeTmpRoot(); });
  afterEach(() => { fs.rmSync(tmpRoot, { recursive: true, force: true }); });

  it('should create a new directory', () => {
    const dir = path.join(tmpRoot, 'newdir');
    assert.strictEqual(ensureDirectory(nodeFsOps, dir), true);
    assert.ok(fs.statSync(dir).isDirectory());
  });

  it('should create nested directories', () => {
    const dir = path.join(tmpRoot, 'a', 'b', 'c');
    assert.strictEqual(ensureDirectory(nodeFsOps, dir), true);
    assert.ok(fs.statSync(dir).isDirectory());
  });

  it('should return true for existing directory', () => {
    const dir = path.join(tmpRoot, 'existing');
    fs.mkdirSync(dir);
    assert.strictEqual(ensureDirectory(nodeFsOps, dir), true);
  });

  it('should return false if path is a file', () => {
    const filePath = path.join(tmpRoot, 'afile');
    fs.writeFileSync(filePath, 'data');
    assert.strictEqual(ensureDirectory(nodeFsOps, filePath), false);
  });
});

describe('ensureFile', () => {
  beforeEach(() => { tmpRoot = makeTmpRoot(); });
  afterEach(() => { fs.rmSync(tmpRoot, { recursive: true, force: true }); });

  it('should create a new empty file', () => {
    const fp = path.join(tmpRoot, 'newfile.txt');
    assert.strictEqual(ensureFile(nodeFsOps, fp), true);
    assert.ok(fs.statSync(fp).isFile());
    assert.strictEqual(fs.readFileSync(fp, 'utf-8'), '');
  });

  it('should create parent directories', () => {
    const fp = path.join(tmpRoot, 'sub', 'dir', 'file.txt');
    assert.strictEqual(ensureFile(nodeFsOps, fp), true);
    assert.ok(fs.statSync(fp).isFile());
  });

  it('should return true for existing file', () => {
    const fp = path.join(tmpRoot, 'existing.txt');
    fs.writeFileSync(fp, 'content');
    assert.strictEqual(ensureFile(nodeFsOps, fp), true);
  });

  it('should return false if path is a directory', () => {
    const dir = path.join(tmpRoot, 'adir');
    fs.mkdirSync(dir);
    assert.strictEqual(ensureFile(nodeFsOps, dir), false);
  });
});

describe('createTempFile', () => {
  beforeEach(() => { tmpRoot = makeTmpRoot(); });
  afterEach(() => { fs.rmSync(tmpRoot, { recursive: true, force: true }); });

  it('should create a temp file in the given directory', () => {
    const result = createTempFile(nodeFsOps, tmpRoot);
    assert.ok(result !== null);
    assert.ok(fs.statSync(result!).isFile());
    assert.ok(result!.startsWith(tmpRoot));
    assert.ok(result!.endsWith('.tmp'));
  });

  it('should create a temp file with custom extension', () => {
    const result = createTempFile(nodeFsOps, tmpRoot, 'jpg');
    assert.ok(result !== null);
    assert.ok(result!.endsWith('.jpg'));
  });

  it('should return null for null directory', () => {
    assert.strictEqual(createTempFile(nodeFsOps, null), null);
  });

  it('should create the directory if needed', () => {
    const dir = path.join(tmpRoot, 'newtmp');
    const result = createTempFile(nodeFsOps, dir);
    assert.ok(result !== null);
    assert.ok(fs.statSync(dir).isDirectory());
  });
});

describe('deleteFile', () => {
  beforeEach(() => { tmpRoot = makeTmpRoot(); });
  afterEach(() => { fs.rmSync(tmpRoot, { recursive: true, force: true }); });

  it('should delete an existing file', () => {
    const fp = path.join(tmpRoot, 'todelete.txt');
    fs.writeFileSync(fp, 'data');
    assert.strictEqual(deleteFile(nodeFsOps, fp), true);
    assert.strictEqual(fs.existsSync(fp), false);
  });

  it('should return true for non-existent file', () => {
    assert.strictEqual(deleteFile(nodeFsOps, path.join(tmpRoot, 'nope')), true);
  });
});

describe('writeToFile', () => {
  beforeEach(() => { tmpRoot = makeTmpRoot(); });
  afterEach(() => { fs.rmSync(tmpRoot, { recursive: true, force: true }); });

  it('should write content to a file', () => {
    const fp = path.join(tmpRoot, 'output.txt');
    assert.strictEqual(writeToFile(nodeFsOps, fp, 'hello world'), true);
    assert.strictEqual(fs.readFileSync(fp, 'utf-8'), 'hello world');
  });

  it('should create parent directories', () => {
    const fp = path.join(tmpRoot, 'deep', 'nested', 'file.txt');
    assert.strictEqual(writeToFile(nodeFsOps, fp, 'data'), true);
    assert.strictEqual(fs.readFileSync(fp, 'utf-8'), 'data');
  });
});
