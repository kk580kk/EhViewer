import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { Logger, LogLevel, BufferSink, HiLogSink } from '../../../main/ets/util/Logger.ets';
import type { LogSink, LogEntry, HiLogApi } from '../../../main/ets/util/Logger.ets';

describe('Logger', () => {
  beforeEach(() => {
    Logger.reset();
  });

  describe('tag()', () => {
    it('should create a logger instance', () => {
      const log = Logger.tag('Test');
      assert.ok(log !== null);
    });
  });

  describe('log levels', () => {
    it('should write entries at or above global level', () => {
      const sink = new BufferSink();
      Logger.setSinks([]);
      Logger.addSink(sink);
      Logger.setLevel(LogLevel.WARN);

      const log = Logger.tag('Test');
      log.v('verbose');
      log.d('debug');
      log.i('info');
      log.w('warn');
      log.e('error');

      const entries = sink.getEntries();
      assert.strictEqual(entries.length, 2);
      assert.strictEqual(entries[0].level, LogLevel.WARN);
      assert.strictEqual(entries[1].level, LogLevel.ERROR);
    });

    it('should accept all levels when set to VERBOSE', () => {
      const sink = new BufferSink();
      Logger.setSinks([]);
      Logger.addSink(sink);
      Logger.setLevel(LogLevel.VERBOSE);

      const log = Logger.tag('T');
      log.v('v');
      log.d('d');
      log.i('i');
      log.w('w');
      log.e('e');

      assert.strictEqual(sink.getEntries().length, 5);
    });

    it('should suppress all when set to NONE', () => {
      const sink = new BufferSink();
      Logger.setSinks([]);
      Logger.addSink(sink);
      Logger.setLevel(LogLevel.NONE);

      const log = Logger.tag('T');
      log.e('should not appear');
      assert.strictEqual(sink.getEntries().length, 0);
    });
  });

  describe('log entries', () => {
    it('should include tag and message', () => {
      const sink = new BufferSink();
      Logger.setSinks([sink]);

      Logger.tag('MyTag').i('hello');

      const entries = sink.getEntries();
      assert.strictEqual(entries.length, 1);
      assert.strictEqual(entries[0].tag, 'MyTag');
      assert.strictEqual(entries[0].message, 'hello');
      assert.strictEqual(entries[0].level, LogLevel.INFO);
    });

    it('should include error when provided', () => {
      const sink = new BufferSink();
      Logger.setSinks([sink]);

      const err = new Error('test error');
      Logger.tag('E').e('failed', err);

      const entry = sink.getEntries()[0];
      assert.strictEqual(entry.error, err);
    });

    it('should have a timestamp', () => {
      const sink = new BufferSink();
      Logger.setSinks([sink]);

      const before = Date.now();
      Logger.tag('T').d('msg');
      const after = Date.now();

      const ts = sink.getEntries()[0].timestamp;
      assert.ok(ts >= before && ts <= after);
    });
  });

  describe('BufferSink', () => {
    it('should respect maxEntries limit', () => {
      const sink = new BufferSink(3);
      Logger.setSinks([sink]);

      const log = Logger.tag('T');
      log.d('1');
      log.d('2');
      log.d('3');
      log.d('4');

      const entries = sink.getEntries();
      assert.strictEqual(entries.length, 3);
      assert.strictEqual(entries[0].message, '2');
      assert.strictEqual(entries[2].message, '4');
    });

    it('should clear entries', () => {
      const sink = new BufferSink();
      Logger.setSinks([sink]);
      Logger.tag('T').d('msg');
      assert.strictEqual(sink.getEntries().length, 1);
      sink.clear();
      assert.strictEqual(sink.getEntries().length, 0);
    });

    it('should dump entries as string', () => {
      const sink = new BufferSink();
      Logger.setSinks([sink]);
      Logger.tag('Tag').i('hello world');
      const dump = sink.dump();
      assert.ok(dump.includes('I/Tag'));
      assert.ok(dump.includes('hello world'));
    });

    it('should include stack trace in dump for errors', () => {
      const sink = new BufferSink();
      Logger.setSinks([sink]);
      Logger.tag('T').e('fail', new Error('oops'));
      const dump = sink.dump();
      assert.ok(dump.includes('oops'));
    });
  });

  describe('global buffer', () => {
    it('should always write to global buffer regardless of sinks', () => {
      Logger.setSinks([]); // no sinks
      Logger.tag('T').i('buffered');
      const buffer = Logger.getBuffer();
      const entries = buffer.getEntries();
      assert.ok(entries.length >= 1);
      assert.strictEqual(entries[entries.length - 1].message, 'buffered');
    });
  });

  describe('getLevel / setLevel', () => {
    it('should get and set level', () => {
      Logger.setLevel(LogLevel.ERROR);
      assert.strictEqual(Logger.getLevel(), LogLevel.ERROR);
    });
  });

  describe('HiLogSink', () => {
    /** Captures calls made to the mock hilog API. */
    interface HiLogCall {
      method: string;
      domain: number;
      tag: string;
      message: string;
    }

    function createMockHiLog(): { api: HiLogApi; calls: HiLogCall[] } {
      const calls: HiLogCall[] = [];
      const capture = (method: string) =>
        (domain: number, tag: string, _format: string, ...args: Object[]): void => {
          calls.push({ method, domain, tag, message: String(args[0] ?? '') });
        };
      return {
        calls,
        api: {
          debug: capture('debug'),
          info: capture('info'),
          warn: capture('warn'),
          error: capture('error'),
        },
      };
    }

    it('should forward DEBUG level to hilog.debug', () => {
      const { api, calls } = createMockHiLog();
      const sink = new HiLogSink(api, 0x0001);
      Logger.setSinks([sink]);

      Logger.tag('Test').d('debug message');

      assert.strictEqual(calls.length, 1);
      assert.strictEqual(calls[0].method, 'debug');
      assert.strictEqual(calls[0].domain, 0x0001);
      assert.strictEqual(calls[0].tag, 'Test');
      assert.ok(calls[0].message.includes('debug message'));
    });

    it('should forward INFO level to hilog.info', () => {
      const { api, calls } = createMockHiLog();
      const sink = new HiLogSink(api, 0x0002);
      Logger.setSinks([sink]);

      Logger.tag('Net').i('connected');

      assert.strictEqual(calls.length, 1);
      assert.strictEqual(calls[0].method, 'info');
      assert.strictEqual(calls[0].domain, 0x0002);
      assert.strictEqual(calls[0].tag, 'Net');
    });

    it('should forward WARN level to hilog.warn', () => {
      const { api, calls } = createMockHiLog();
      const sink = new HiLogSink(api);
      Logger.setSinks([sink]);

      Logger.tag('W').w('low memory');

      assert.strictEqual(calls.length, 1);
      assert.strictEqual(calls[0].method, 'warn');
    });

    it('should forward ERROR level to hilog.error', () => {
      const { api, calls } = createMockHiLog();
      const sink = new HiLogSink(api);
      Logger.setSinks([sink]);

      Logger.tag('E').e('crash', new Error('oops'));

      assert.strictEqual(calls.length, 1);
      assert.strictEqual(calls[0].method, 'error');
      assert.ok(calls[0].message.includes('crash'));
      assert.ok(calls[0].message.includes('oops'));
    });

    it('should forward VERBOSE level to hilog.debug', () => {
      const { api, calls } = createMockHiLog();
      const sink = new HiLogSink(api);
      Logger.setSinks([sink]);

      Logger.tag('V').v('trace');

      assert.strictEqual(calls.length, 1);
      assert.strictEqual(calls[0].method, 'debug');
    });

    it('should respect global log level filter', () => {
      const { api, calls } = createMockHiLog();
      const sink = new HiLogSink(api);
      Logger.setSinks([sink]);
      Logger.setLevel(LogLevel.ERROR);

      Logger.tag('T').d('should be filtered');
      Logger.tag('T').e('should pass');

      assert.strictEqual(calls.length, 1);
      assert.strictEqual(calls[0].method, 'error');
    });
  });
});
