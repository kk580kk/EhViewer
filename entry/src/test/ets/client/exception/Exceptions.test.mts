import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { EhException } from '../../../../main/ets/client/exception/EhException.ets';
import { ParseException } from '../../../../main/ets/client/exception/ParseException.ets';
import { CancelledException } from '../../../../main/ets/client/exception/CancelledException.ets';
import { NoHAtHClientException } from '../../../../main/ets/client/exception/NoHAtHClientException.ets';
import { Image509Exception } from '../../../../main/ets/client/exception/Image509Exception.ets';
import { OffensiveException } from '../../../../main/ets/client/exception/OffensiveException.ets';
import { PiningException } from '../../../../main/ets/client/exception/PiningException.ets';

describe('Exception hierarchy', () => {

  // ---- EhException ----

  describe('EhException', () => {
    it('should extend Error', () => {
      const e = new EhException('test');
      assert.ok(e instanceof Error);
      assert.ok(e instanceof EhException);
    });

    it('should carry message', () => {
      const e = new EhException('something went wrong');
      assert.strictEqual(e.message, 'something went wrong');
    });

    it('should have correct name', () => {
      assert.strictEqual(new EhException('x').name, 'EhException');
    });

    it('should support cause', () => {
      const cause = new Error('root');
      const e = new EhException('wrapper', cause);
      assert.strictEqual(e.cause, cause);
    });

    it('should have undefined cause when not provided', () => {
      const e = new EhException('no cause');
      assert.strictEqual(e.cause, undefined);
    });
  });

  // ---- ParseException ----

  describe('ParseException', () => {
    it('should extend EhException', () => {
      const e = new ParseException('bad html', '<html>');
      assert.ok(e instanceof EhException);
      assert.ok(e instanceof Error);
    });

    it('should carry message and body', () => {
      const e = new ParseException('parse failed', '<div>broken');
      assert.strictEqual(e.message, 'parse failed');
      assert.strictEqual(e.body, '<div>broken');
    });

    it('should have correct name', () => {
      assert.strictEqual(new ParseException('x', '').name, 'ParseException');
    });

    it('should support cause', () => {
      const cause = new TypeError('unexpected token');
      const e = new ParseException('failed', '<body>', cause);
      assert.strictEqual(e.cause, cause);
    });
  });

  // ---- CancelledException ----

  describe('CancelledException', () => {
    it('should extend Error but NOT EhException', () => {
      const e = new CancelledException();
      assert.ok(e instanceof Error);
      assert.ok(!(e instanceof EhException));
    });

    it('should have fixed message "CANCELED"', () => {
      assert.strictEqual(new CancelledException().message, 'CANCELED');
    });

    it('should have correct name', () => {
      assert.strictEqual(new CancelledException().name, 'CancelledException');
    });
  });

  // ---- NoHAtHClientException ----

  describe('NoHAtHClientException', () => {
    it('should extend EhException', () => {
      const e = new NoHAtHClientException('no client');
      assert.ok(e instanceof EhException);
      assert.ok(e instanceof Error);
    });

    it('should carry custom message', () => {
      const e = new NoHAtHClientException('No H@H client available');
      assert.strictEqual(e.message, 'No H@H client available');
    });

    it('should have correct name', () => {
      assert.strictEqual(new NoHAtHClientException('x').name, 'NoHAtHClientException');
    });
  });

  // ---- Image509Exception ----

  describe('Image509Exception', () => {
    it('should extend EhException', () => {
      const e = new Image509Exception();
      assert.ok(e instanceof EhException);
      assert.ok(e instanceof Error);
    });

    it('should have fixed message "509"', () => {
      assert.strictEqual(new Image509Exception().message, '509');
    });

    it('should have correct name', () => {
      assert.strictEqual(new Image509Exception().name, 'Image509Exception');
    });
  });

  // ---- OffensiveException ----

  describe('OffensiveException', () => {
    it('should extend EhException', () => {
      const e = new OffensiveException();
      assert.ok(e instanceof EhException);
      assert.ok(e instanceof Error);
    });

    it('should have fixed message "OFFENSIVE"', () => {
      assert.strictEqual(new OffensiveException().message, 'OFFENSIVE');
    });

    it('should have correct name', () => {
      assert.strictEqual(new OffensiveException().name, 'OffensiveException');
    });
  });

  // ---- PiningException ----

  describe('PiningException', () => {
    it('should extend EhException', () => {
      const e = new PiningException();
      assert.ok(e instanceof EhException);
      assert.ok(e instanceof Error);
    });

    it('should have fixed message', () => {
      assert.strictEqual(new PiningException().message, 'pining for the fjords');
    });

    it('should have correct name', () => {
      assert.strictEqual(new PiningException().name, 'PiningException');
    });
  });

  // ---- Cross-cutting: instanceof discrimination ----

  describe('instanceof discrimination', () => {
    it('should distinguish different exception types', () => {
      const exceptions: Error[] = [
        new EhException('base'),
        new ParseException('parse', ''),
        new CancelledException(),
        new NoHAtHClientException('msg'),
        new Image509Exception(),
        new OffensiveException(),
        new PiningException(),
      ];

      // All are Error instances
      for (const e of exceptions) {
        assert.ok(e instanceof Error);
      }

      // All except CancelledException are EhException instances
      const ehExceptions = exceptions.filter(e => e instanceof EhException);
      assert.strictEqual(ehExceptions.length, 6);

      // Each has a unique name
      const names = exceptions.map(e => e.name);
      assert.strictEqual(new Set(names).size, names.length);
    });
  });

  // ---- ExceptionUtils backward compatibility ----

  describe('ExceptionUtils re-export compatibility', () => {
    it('should be the same EhException class from both paths', async () => {
      const { EhException: FromUtil } = await import('../../../../main/ets/util/ExceptionUtils.ets');
      const { EhException: FromException } = await import('../../../../main/ets/client/exception/EhException.ets');
      assert.strictEqual(FromUtil, FromException);
    });

    it('should pass instanceof across import paths', async () => {
      const { EhException: FromUtil } = await import('../../../../main/ets/util/ExceptionUtils.ets');
      const e = new FromUtil('cross-path');
      assert.ok(e instanceof EhException);
    });
  });
});
