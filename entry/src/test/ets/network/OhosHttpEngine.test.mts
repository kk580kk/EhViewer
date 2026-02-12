import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import {
  OhosHttpEngine,
  createOhosHttpEngine,
} from '../../../main/ets/network/OhosHttpEngine.ets';
import type {
  OhosHttpSession,
  OhosHttpRequestOptions,
  OhosHttpResponse,
} from '../../../main/ets/network/OhosHttpEngine.ets';
import type { HttpRequest } from '../../../main/ets/network/HttpClient.ets';

// ---- Mock session ----

class MockOhosSession implements OhosHttpSession {
  lastUrl: string = '';
  lastOptions: OhosHttpRequestOptions | null = null;
  destroyed = false;
  response: OhosHttpResponse = { responseCode: 200, header: {}, result: '' };
  shouldReject = false;

  async request(url: string, options: OhosHttpRequestOptions): Promise<OhosHttpResponse> {
    this.lastUrl = url;
    this.lastOptions = options;
    if (this.shouldReject) {
      throw new Error('network failure');
    }
    return this.response;
  }

  destroy(): void {
    this.destroyed = true;
  }
}

// ---- Tests ----

describe('OhosHttpEngine', () => {
  let session: MockOhosSession;
  let engine: OhosHttpEngine;

  beforeEach(() => {
    session = new MockOhosSession();
    engine = new OhosHttpEngine(() => session);
  });

  describe('execute() basic GET', () => {
    it('should pass URL and method to the session', async () => {
      const req: HttpRequest = {
        url: 'https://e-hentai.org/',
        method: 'GET',
        headers: { 'Accept': 'text/html' },
        connectTimeoutMs: 5000,
        readTimeoutMs: 10000,
      };
      session.response = { responseCode: 200, header: { 'Content-Type': 'text/html' }, result: '<html/>' };

      const res = await engine.execute(req);

      assert.strictEqual(session.lastUrl, 'https://e-hentai.org/');
      assert.strictEqual(session.lastOptions!.method, 'GET');
      assert.strictEqual(session.lastOptions!.connectTimeout, 5000);
      assert.strictEqual(session.lastOptions!.readTimeout, 10000);
      assert.strictEqual(session.lastOptions!.header!['Accept'], 'text/html');
      assert.strictEqual(res.statusCode, 200);
      assert.strictEqual(res.body, '<html/>');
      assert.strictEqual(res.headers['Content-Type'], 'text/html');
    });

    it('should not set extraData for GET requests', async () => {
      await engine.execute({ url: 'https://example.com', method: 'GET' });
      assert.strictEqual(session.lastOptions!.extraData, undefined);
    });
  });

  describe('execute() POST with JSON body', () => {
    it('should set Content-Type and extraData for JSON', async () => {
      const json = '{"method":"gdata"}';
      await engine.execute({
        url: 'https://example.com/api.php',
        method: 'POST',
        headers: {},
        body: { type: 'json', content: json },
      });
      assert.strictEqual(session.lastOptions!.extraData, json);
      assert.strictEqual(session.lastOptions!.header!['Content-Type'], 'application/json');
    });

    it('should allow custom content type for JSON body', async () => {
      await engine.execute({
        url: 'https://example.com/api',
        method: 'POST',
        headers: {},
        body: { type: 'json', content: '{}', contentType: 'application/vnd.api+json' },
      });
      assert.strictEqual(session.lastOptions!.header!['Content-Type'], 'application/vnd.api+json');
    });
  });

  describe('execute() POST with form body', () => {
    it('should encode form fields and set content type', async () => {
      await engine.execute({
        url: 'https://example.com/login',
        method: 'POST',
        headers: {},
        body: {
          type: 'form',
          formFields: [
            { key: 'user', value: 'hello world' },
            { key: 'pass', value: 'a&b' },
          ],
        },
      });
      assert.strictEqual(session.lastOptions!.extraData, 'user=hello%20world&pass=a%26b');
      assert.strictEqual(session.lastOptions!.header!['Content-Type'], 'application/x-www-form-urlencoded');
    });
  });

  describe('execute() POST with multipart body', () => {
    it('should build multipart payload with boundary', async () => {
      await engine.execute({
        url: 'https://example.com/upload',
        method: 'POST',
        headers: {},
        body: {
          type: 'multipart',
          parts: [
            { name: 'field', data: 'value' },
          ],
        },
      });
      const ct = session.lastOptions!.header!['Content-Type'];
      assert.ok(ct.startsWith('multipart/form-data; boundary='));
      assert.ok(session.lastOptions!.extraData!.includes('name="field"'));
      assert.ok(session.lastOptions!.extraData!.includes('value'));
    });
  });

  describe('execute() POST with raw body', () => {
    it('should pass raw content and content type', async () => {
      await engine.execute({
        url: 'https://example.com/data',
        method: 'POST',
        headers: {},
        body: { type: 'raw', content: '<xml/>', contentType: 'application/xml' },
      });
      assert.strictEqual(session.lastOptions!.extraData, '<xml/>');
      assert.strictEqual(session.lastOptions!.header!['Content-Type'], 'application/xml');
    });
  });

  describe('session lifecycle', () => {
    it('should destroy session after successful request', async () => {
      await engine.execute({ url: 'https://example.com', method: 'GET' });
      assert.strictEqual(session.destroyed, true);
    });

    it('should destroy session even on error', async () => {
      session.shouldReject = true;
      try {
        await engine.execute({ url: 'https://example.com', method: 'GET' });
      } catch {
        // expected
      }
      assert.strictEqual(session.destroyed, true);
    });

    it('should propagate network errors', async () => {
      session.shouldReject = true;
      await assert.rejects(
        () => engine.execute({ url: 'https://example.com', method: 'GET' }),
        { message: 'network failure' },
      );
    });
  });

  describe('header normalization', () => {
    it('should normalize array header values to comma-separated string', async () => {
      session.response = {
        responseCode: 200,
        header: { 'Set-Cookie': ['a=1', 'b=2'] as unknown as string },
        result: '',
      };
      const res = await engine.execute({ url: 'https://example.com', method: 'GET' });
      assert.strictEqual(res.headers['Set-Cookie'], 'a=1, b=2');
    });

    it('should handle missing headers gracefully', async () => {
      session.response = {
        responseCode: 200,
        header: undefined as unknown as Record<string, string>,
        result: '',
      };
      const res = await engine.execute({ url: 'https://example.com', method: 'GET' });
      assert.deepStrictEqual(res.headers, {});
    });

    it('should handle empty result', async () => {
      session.response = {
        responseCode: 204,
        header: {},
        result: undefined as unknown as string,
      };
      const res = await engine.execute({ url: 'https://example.com', method: 'DELETE' });
      assert.strictEqual(res.body, '');
      assert.strictEqual(res.statusCode, 204);
    });
  });
});

describe('createOhosHttpEngine()', () => {
  it('should create an engine using the httpModule factory', async () => {
    const mockSession = new MockOhosSession();
    mockSession.response = { responseCode: 200, header: {}, result: 'ok' };

    const httpModule = {
      createHttp(): OhosHttpSession {
        return mockSession;
      },
    };

    const engine = createOhosHttpEngine(httpModule);
    const res = await engine.execute({ url: 'https://example.com', method: 'GET' });
    assert.strictEqual(res.statusCode, 200);
    assert.strictEqual(res.body, 'ok');
    assert.strictEqual(mockSession.destroyed, true);
  });
});
