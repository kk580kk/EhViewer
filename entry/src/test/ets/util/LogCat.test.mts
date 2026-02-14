import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { LogCat } from '../../../main/ets/util/LogCat.ets';
import { Logger, LogLevel } from '../../../main/ets/util/Logger.ets';
import type { FsOps } from '../../../main/ets/util/FileUtils.ets';

/** In-memory filesystem mock for testing file writes. */
function createMockFs(): FsOps & { files: Map<string, string> } {
  const files = new Map<string, string>();
  const dirs = new Set<string>();
  return {
    files,
    mkdirSync(path: string, _options?: { recursive?: boolean }): void {
      dirs.add(path);
    },
    existsSync(path: string): boolean {
      return files.has(path) || dirs.has(path);
    },
    statSync(path: string) {
      return {
        isDirectory: () => dirs.has(path),
        isFile: () => files.has(path),
      };
    },
    writeFileSync(path: string, data: string | Uint8Array, _encoding?: string): void {
      files.set(path, typeof data === 'string' ? data : new TextDecoder().decode(data));
    },
    unlinkSync(path: string): void {
      files.delete(path);
    },
  };
}

describe('LogCat', () => {
  beforeEach(() => {
    Logger.reset();
  });

  it('should save buffered logs to a file', () => {
    Logger.setSinks([]);
    const log = Logger.tag('App');
    log.i('started');
    log.d('loading data');
    log.e('something failed', new Error('test'));

    const fs = createMockFs();
    const result = LogCat.save(fs, '/tmp/logcat.txt');

    assert.strictEqual(result, true);
    const content = fs.files.get('/tmp/logcat.txt');
    assert.ok(content !== undefined);
    assert.ok(content!.includes('I/App'));
    assert.ok(content!.includes('started'));
    assert.ok(content!.includes('D/App'));
    assert.ok(content!.includes('loading data'));
    assert.ok(content!.includes('E/App'));
    assert.ok(content!.includes('something failed'));
    assert.ok(content!.includes('test'));
  });

  it('should save empty content when no logs exist', () => {
    const fs = createMockFs();
    const result = LogCat.save(fs, '/tmp/empty.txt');

    assert.strictEqual(result, true);
    const content = fs.files.get('/tmp/empty.txt');
    assert.ok(content !== undefined);
    assert.strictEqual(content!, '');
  });

  it('should return false when fs write fails', () => {
    Logger.setSinks([]);
    Logger.tag('T').i('data');

    const fs = createMockFs();
    // Override writeFileSync to throw
    fs.writeFileSync = (): void => {
      throw new Error('disk full');
    };

    const result = LogCat.save(fs, '/fail/logcat.txt');
    assert.strictEqual(result, false);
  });

  it('should respect log level filter in buffer', () => {
    Logger.setSinks([]);
    Logger.setLevel(LogLevel.WARN);
    const log = Logger.tag('F');
    log.d('filtered out');
    log.w('warning');
    log.e('error');

    const fs = createMockFs();
    LogCat.save(fs, '/tmp/filtered.txt');

    const content = fs.files.get('/tmp/filtered.txt')!;
    assert.ok(!content.includes('filtered out'));
    assert.ok(content.includes('warning'));
    assert.ok(content.includes('error'));
  });
});
