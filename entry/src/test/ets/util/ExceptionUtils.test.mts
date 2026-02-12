import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import {
  ExceptionUtils,
  EhException,
  StatusCodeException,
} from '../../../main/ets/util/ExceptionUtils.ets';

describe('ExceptionUtils', () => {

  beforeEach(() => {
    ExceptionUtils.initialize({
      invalidUrl: 'Invalid URL',
      timeout: 'Timeout',
      unknownHost: 'Unknown host',
      badStatusCode: 'Bad status code: {0}',
      redirection: 'Too many redirections',
      socket: 'Network error',
      unknown: 'Unknown error',
    });
  });

  describe('getReadableString', () => {
    it('should handle EhException', () => {
      const e = new EhException('custom message');
      assert.strictEqual(ExceptionUtils.getReadableString(e), 'custom message');
    });

    it('should handle StatusCodeException', () => {
      const e = new StatusCodeException(404, 'Not Found');
      const msg = ExceptionUtils.getReadableString(e);
      assert.strictEqual(msg, 'Bad status code: 404, Not Found');
    });

    it('should handle StatusCodeException without identified message', () => {
      const e = new StatusCodeException(500);
      const msg = ExceptionUtils.getReadableString(e);
      assert.strictEqual(msg, 'Bad status code: 500');
    });

    it('should handle timeout errors', () => {
      const e = new Error('Connection timeout');
      assert.strictEqual(ExceptionUtils.getReadableString(e), 'Timeout');
    });

    it('should handle network errors', () => {
      const e = new Error('ECONNREFUSED 127.0.0.1:443');
      assert.strictEqual(ExceptionUtils.getReadableString(e), 'Network error');
    });

    it('should handle unknown host errors', () => {
      const e = new Error('getaddrinfo ENOTFOUND example.com');
      assert.strictEqual(ExceptionUtils.getReadableString(e), 'Unknown host');
    });

    it('should handle redirection errors', () => {
      const e = new Error('Too many follow-up requests: 21');
      assert.strictEqual(ExceptionUtils.getReadableString(e), 'Too many redirections');
    });

    it('should return unknown for generic errors', () => {
      const e = new Error('something weird');
      assert.strictEqual(ExceptionUtils.getReadableString(e), 'Unknown error');
    });
  });

  describe('throwIfFatal', () => {
    it('should re-throw stack overflow RangeError', () => {
      const e = new RangeError('Maximum call stack size exceeded');
      assert.throws(() => ExceptionUtils.throwIfFatal(e), RangeError);
    });

    it('should not throw for regular errors', () => {
      assert.doesNotThrow(() => ExceptionUtils.throwIfFatal(new Error('ok')));
      assert.doesNotThrow(() => ExceptionUtils.throwIfFatal(new TypeError('nope')));
      assert.doesNotThrow(() => ExceptionUtils.throwIfFatal(new RangeError('number out of range')));
    });
  });

  describe('EhException', () => {
    it('should have correct name', () => {
      const e = new EhException('test');
      assert.strictEqual(e.name, 'EhException');
      assert.strictEqual(e.message, 'test');
      assert.ok(e instanceof Error);
    });
  });

  describe('StatusCodeException', () => {
    it('should store response code', () => {
      const e = new StatusCodeException(403, 'Forbidden');
      assert.strictEqual(e.responseCode, 403);
      assert.strictEqual(e.identified, true);
      assert.strictEqual(e.message, 'Forbidden');
    });

    it('should handle unidentified codes', () => {
      const e = new StatusCodeException(418);
      assert.strictEqual(e.responseCode, 418);
      assert.strictEqual(e.identified, false);
    });
  });
});
