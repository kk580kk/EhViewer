import { describe, it, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { StatusCodeException } from '../../../main/ets/network/StatusCodeException.ets';

describe('StatusCodeException', () => {

  afterEach(() => {
    StatusCodeException.reset();
  });

  // ---- Basic construction ----

  describe('constructor', () => {
    it('should extend Error', () => {
      const e = new StatusCodeException(404);
      assert.ok(e instanceof Error);
      assert.strictEqual(e.name, 'StatusCodeException');
    });

    it('should store the response code', () => {
      const e = new StatusCodeException(502);
      assert.strictEqual(e.responseCode, 502);
    });

    it('should store the optional URL', () => {
      const e = new StatusCodeException(404, 'https://example.com/missing');
      assert.strictEqual(e.url, 'https://example.com/missing');
    });

    it('should have undefined URL when not provided', () => {
      const e = new StatusCodeException(500);
      assert.strictEqual(e.url, undefined);
    });
  });

  // ---- Message formatting ----

  describe('message', () => {
    it('should include code and description for known codes', () => {
      assert.strictEqual(new StatusCodeException(400).message, '400 Bad Request');
      assert.strictEqual(new StatusCodeException(401).message, '401 Unauthorized');
      assert.strictEqual(new StatusCodeException(403).message, '403 Forbidden');
      assert.strictEqual(new StatusCodeException(404).message, '404 Not Found');
      assert.strictEqual(new StatusCodeException(500).message, '500 Internal Server Error');
      assert.strictEqual(new StatusCodeException(502).message, '502 Bad Gateway');
      assert.strictEqual(new StatusCodeException(503).message, '503 Service Unavailable');
    });

    it('should use fallback for unknown codes', () => {
      assert.strictEqual(new StatusCodeException(418).message, 'Error response code: 418');
      assert.strictEqual(new StatusCodeException(599).message, 'Error response code: 599');
    });

    it('should include all 4xx codes from defaults', () => {
      const codes4xx = [400, 401, 402, 403, 404, 405, 406, 407, 408, 409,
        410, 411, 412, 413, 414, 415, 416, 417, 429];
      for (const code of codes4xx) {
        const e = new StatusCodeException(code);
        assert.ok(e.message.startsWith(`${code} `), `Expected message for ${code} to start with code`);
      }
    });

    it('should include all 5xx codes from defaults', () => {
      const codes5xx = [500, 501, 502, 503, 504, 505];
      for (const code of codes5xx) {
        const e = new StatusCodeException(code);
        assert.ok(e.message.startsWith(`${code} `), `Expected message for ${code} to start with code`);
      }
    });
  });

  // ---- isIdentifiedResponseCode ----

  describe('isIdentifiedResponseCode', () => {
    it('should be true for known status codes', () => {
      assert.strictEqual(new StatusCodeException(404).isIdentifiedResponseCode, true);
      assert.strictEqual(new StatusCodeException(500).isIdentifiedResponseCode, true);
      assert.strictEqual(new StatusCodeException(429).isIdentifiedResponseCode, true);
    });

    it('should be false for unknown status codes', () => {
      assert.strictEqual(new StatusCodeException(418).isIdentifiedResponseCode, false);
      assert.strictEqual(new StatusCodeException(299).isIdentifiedResponseCode, false);
      assert.strictEqual(new StatusCodeException(600).isIdentifiedResponseCode, false);
    });
  });

  // ---- isClientError / isServerError ----

  describe('isClientError', () => {
    it('should be true for 4xx codes', () => {
      assert.strictEqual(new StatusCodeException(400).isClientError, true);
      assert.strictEqual(new StatusCodeException(404).isClientError, true);
      assert.strictEqual(new StatusCodeException(499).isClientError, true);
    });

    it('should be false for non-4xx codes', () => {
      assert.strictEqual(new StatusCodeException(200).isClientError, false);
      assert.strictEqual(new StatusCodeException(301).isClientError, false);
      assert.strictEqual(new StatusCodeException(500).isClientError, false);
    });
  });

  describe('isServerError', () => {
    it('should be true for 5xx codes', () => {
      assert.strictEqual(new StatusCodeException(500).isServerError, true);
      assert.strictEqual(new StatusCodeException(503).isServerError, true);
      assert.strictEqual(new StatusCodeException(599).isServerError, true);
    });

    it('should be false for non-5xx codes', () => {
      assert.strictEqual(new StatusCodeException(200).isServerError, false);
      assert.strictEqual(new StatusCodeException(404).isServerError, false);
      assert.strictEqual(new StatusCodeException(600).isServerError, false);
    });
  });

  // ---- initialize() / reset() ----

  describe('initialize()', () => {
    it('should override default messages for given codes', () => {
      StatusCodeException.initialize({ 404: '找不到页面' });
      const e = new StatusCodeException(404);
      assert.strictEqual(e.message, '404 找不到页面');
      assert.strictEqual(e.isIdentifiedResponseCode, true);
    });

    it('should preserve defaults for codes not in custom map', () => {
      StatusCodeException.initialize({ 404: 'Custom 404' });
      const e500 = new StatusCodeException(500);
      assert.strictEqual(e500.message, '500 Internal Server Error');
    });

    it('should add new codes not in defaults', () => {
      StatusCodeException.initialize({ 418: "I'm a teapot" });
      const e = new StatusCodeException(418);
      assert.strictEqual(e.message, "418 I'm a teapot");
      assert.strictEqual(e.isIdentifiedResponseCode, true);
    });
  });

  describe('reset()', () => {
    it('should restore built-in default messages', () => {
      StatusCodeException.initialize({ 404: 'Custom' });
      StatusCodeException.reset();
      assert.strictEqual(new StatusCodeException(404).message, '404 Not Found');
    });

    it('should remove custom codes added via initialize', () => {
      StatusCodeException.initialize({ 418: 'Teapot' });
      StatusCodeException.reset();
      assert.strictEqual(new StatusCodeException(418).isIdentifiedResponseCode, false);
    });
  });

  // ---- instanceof ----

  describe('instanceof', () => {
    it('should be distinguishable from plain Error', () => {
      const e = new StatusCodeException(404);
      assert.ok(e instanceof StatusCodeException);
      assert.ok(e instanceof Error);
    });
  });
});
