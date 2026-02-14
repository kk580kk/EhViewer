import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import {
  HttpClient,
  encodeFormFields,
  buildMultipartBody,
  generateBoundary,
  buildEhHeaders,
  resolveUrl,
} from '../../../main/ets/network/HttpClient.ets';
import type {
  HttpEngine,
  HttpRequest,
  HttpResponse,
} from '../../../main/ets/network/HttpClient.ets';
import { StatusCodeException } from '../../../main/ets/network/StatusCodeException.ets';

// ---- Mock engine ----

class MockEngine implements HttpEngine {
  lastRequest: HttpRequest | null = null;
  response: HttpResponse = { statusCode: 200, headers: {}, body: '' };
  shouldReject = false;
  rejectError: Error = new Error('network error');

  async execute(request: HttpRequest): Promise<HttpResponse> {
    this.lastRequest = request;
    if (this.shouldReject) {
      throw this.rejectError;
    }
    return this.response;
  }
}

/**
 * A mock engine that returns different responses based on the request URL.
 * Used for testing redirect chains and E-Hentai scenarios.
 */
class RoutingMockEngine implements HttpEngine {
  requests: HttpRequest[] = [];
  private routes: Map<string, HttpResponse> = new Map();
  private fallback: HttpResponse = { statusCode: 200, headers: {}, body: '' };

  on(url: string, response: HttpResponse): void {
    this.routes.set(url, response);
  }

  setFallback(response: HttpResponse): void {
    this.fallback = response;
  }

  async execute(request: HttpRequest): Promise<HttpResponse> {
    this.requests.push(request);
    return this.routes.get(request.url) ?? this.fallback;
  }
}

// ---- Tests ----

describe('HttpClient', () => {
  let engine: MockEngine;
  let client: HttpClient;

  beforeEach(() => {
    engine = new MockEngine();
    client = new HttpClient({ engine });
  });

  describe('default headers', () => {
    it('should include Chrome User-Agent, Accept, Accept-Language', async () => {
      await client.get('https://example.com');
      const h = engine.lastRequest!.headers!;
      assert.ok(h['User-Agent'].includes('Chrome'));
      assert.ok(h['Accept'].includes('text/html'));
      assert.ok(h['Accept-Language'].includes('en-US'));
    });

    it('should allow overriding default headers', async () => {
      await client.get('https://example.com', { 'Accept': 'application/json' });
      assert.strictEqual(engine.lastRequest!.headers!['Accept'], 'application/json');
    });

    it('should allow custom default headers in constructor', () => {
      const custom = new HttpClient({
        engine,
        defaultHeaders: { 'X-Custom': 'hello' },
      });
      custom.get('https://example.com');
      // The custom header is merged
      assert.strictEqual(engine.lastRequest!.headers!['X-Custom'], 'hello');
    });
  });

  describe('get()', () => {
    it('should send a GET request to the given URL', async () => {
      engine.response = { statusCode: 200, headers: { 'Content-Type': 'text/html' }, body: '<html/>' };
      const res = await client.get('https://e-hentai.org/');
      assert.strictEqual(res.statusCode, 200);
      assert.strictEqual(res.body, '<html/>');
      assert.strictEqual(engine.lastRequest!.method, 'GET');
      assert.strictEqual(engine.lastRequest!.url, 'https://e-hentai.org/');
    });

    it('should propagate network errors', async () => {
      engine.shouldReject = true;
      engine.rejectError = new Error('ECONNREFUSED');
      await assert.rejects(() => client.get('https://example.com'), { message: 'ECONNREFUSED' });
    });
  });

  describe('postForm()', () => {
    it('should send POST with form body descriptor', async () => {
      await client.postForm('https://example.com/login', [
        { key: 'UserName', value: 'test' },
        { key: 'PassWord', value: 'secret' },
      ]);
      const req = engine.lastRequest!;
      assert.strictEqual(req.method, 'POST');
      assert.strictEqual(req.body!.type, 'form');
      assert.strictEqual(req.body!.formFields!.length, 2);
      assert.strictEqual(req.body!.formFields![0].key, 'UserName');
    });
  });

  describe('postJson()', () => {
    it('should send POST with JSON body', async () => {
      const json = JSON.stringify({ method: 'gdata', gidlist: [[1, 'abc']] });
      await client.postJson('https://example.com/api.php', json);
      const req = engine.lastRequest!;
      assert.strictEqual(req.method, 'POST');
      assert.strictEqual(req.body!.type, 'json');
      assert.strictEqual(req.body!.content, json);
    });
  });

  describe('postMultipart()', () => {
    it('should send POST with multipart body descriptor', async () => {
      await client.postMultipart('https://example.com/upload', [
        { name: 'sfile', filename: 'a.jpg', contentType: 'image/jpeg', data: new Uint8Array([0xFF, 0xD8]) },
        { name: 'f_sfile', data: 'File Search' },
      ]);
      const req = engine.lastRequest!;
      assert.strictEqual(req.method, 'POST');
      assert.strictEqual(req.body!.type, 'multipart');
      assert.strictEqual(req.body!.parts!.length, 2);
      assert.strictEqual(req.body!.parts![0].name, 'sfile');
      assert.strictEqual(req.body!.parts![1].data, 'File Search');
    });
  });

  describe('timeouts', () => {
    it('should use default 30s timeouts', async () => {
      await client.get('https://example.com');
      assert.strictEqual(engine.lastRequest!.connectTimeoutMs, 30_000);
      assert.strictEqual(engine.lastRequest!.readTimeoutMs, 30_000);
    });

    it('should use custom timeouts from constructor', async () => {
      const c = new HttpClient({ engine, connectTimeoutMs: 5000, readTimeoutMs: 10000 });
      await c.get('https://example.com');
      assert.strictEqual(engine.lastRequest!.connectTimeoutMs, 5000);
      assert.strictEqual(engine.lastRequest!.readTimeoutMs, 10000);
    });

    it('should allow per-request timeout override', async () => {
      await client.execute({
        url: 'https://example.com',
        method: 'GET',
        connectTimeoutMs: 1000,
        readTimeoutMs: 2000,
      });
      assert.strictEqual(engine.lastRequest!.connectTimeoutMs, 1000);
      assert.strictEqual(engine.lastRequest!.readTimeoutMs, 2000);
    });
  });

  describe('setEngine()', () => {
    it('should replace the engine at runtime', async () => {
      const engine2 = new MockEngine();
      engine2.response = { statusCode: 200, headers: {}, body: 'ok' };
      client.setEngine(engine2);
      const res = await client.get('https://example.com');
      assert.strictEqual(res.statusCode, 200);
      assert.strictEqual(engine.lastRequest, null); // original engine was not called
    });
  });

  describe('postRaw()', () => {
    it('should send POST with raw body and content type', async () => {
      await client.postRaw('https://example.com/data', '<xml/>', 'application/xml');
      const req = engine.lastRequest!;
      assert.strictEqual(req.method, 'POST');
      assert.strictEqual(req.body!.type, 'raw');
      assert.strictEqual(req.body!.content, '<xml/>');
      assert.strictEqual(req.body!.contentType, 'application/xml');
    });
  });

  describe('put()', () => {
    it('should send PUT with JSON body', async () => {
      const json = JSON.stringify({ id: 1 });
      await client.put('https://example.com/items/1', json);
      const req = engine.lastRequest!;
      assert.strictEqual(req.method, 'PUT');
      assert.strictEqual(req.body!.type, 'json');
      assert.strictEqual(req.body!.content, json);
    });
  });

  describe('delete()', () => {
    it('should send DELETE request', async () => {
      await client.delete('https://example.com/items/1');
      const req = engine.lastRequest!;
      assert.strictEqual(req.method, 'DELETE');
      assert.strictEqual(req.body, undefined);
    });

    it('should pass custom headers', async () => {
      await client.delete('https://example.com/items/1', { 'X-Token': 'abc' });
      assert.strictEqual(engine.lastRequest!.headers!['X-Token'], 'abc');
    });
  });

  describe('execute() with headers from request', () => {
    it('should include Referer and Origin when provided', async () => {
      await client.get('https://e-hentai.org/', {
        'Referer': 'https://e-hentai.org',
        'Origin': 'https://e-hentai.org',
      });
      const h = engine.lastRequest!.headers!;
      assert.strictEqual(h['Referer'], 'https://e-hentai.org');
      assert.strictEqual(h['Origin'], 'https://e-hentai.org');
    });
  });

  describe('status code error handling', () => {
    it('should throw StatusCodeException for 4xx by default', async () => {
      engine.response = { statusCode: 404, headers: {}, body: 'not found' };
      await assert.rejects(
        () => client.get('https://example.com/missing'),
        (err: unknown) => {
          assert.ok(err instanceof StatusCodeException);
          assert.strictEqual((err as StatusCodeException).responseCode, 404);
          assert.strictEqual((err as StatusCodeException).url, 'https://example.com/missing');
          return true;
        },
      );
    });

    it('should throw StatusCodeException for 5xx by default', async () => {
      engine.response = { statusCode: 500, headers: {}, body: 'server error' };
      await assert.rejects(
        () => client.get('https://example.com/api'),
        (err: unknown) => {
          assert.ok(err instanceof StatusCodeException);
          assert.strictEqual((err as StatusCodeException).responseCode, 500);
          return true;
        },
      );
    });

    it('should throw StatusCodeException for 400', async () => {
      engine.response = { statusCode: 400, headers: {}, body: 'bad request' };
      await assert.rejects(
        () => client.postJson('https://example.com/api', '{}'),
        (err: unknown) => {
          assert.ok(err instanceof StatusCodeException);
          assert.strictEqual((err as StatusCodeException).responseCode, 400);
          return true;
        },
      );
    });

    it('should not throw for 2xx responses', async () => {
      engine.response = { statusCode: 200, headers: {}, body: 'ok' };
      const res = await client.get('https://example.com');
      assert.strictEqual(res.statusCode, 200);
    });

    it('should not throw for 3xx responses without Location header', async () => {
      engine.response = { statusCode: 301, headers: {}, body: '' };
      const res = await client.get('https://example.com');
      assert.strictEqual(res.statusCode, 301);
    });

    it('should not throw when throwOnErrorStatus is false', async () => {
      const lenientClient = new HttpClient({ engine, throwOnErrorStatus: false });
      engine.response = { statusCode: 404, headers: {}, body: 'not found' };
      const res = await lenientClient.get('https://example.com/missing');
      assert.strictEqual(res.statusCode, 404);
      assert.strictEqual(res.body, 'not found');
    });

    it('should not throw for 500 when throwOnErrorStatus is false', async () => {
      const lenientClient = new HttpClient({ engine, throwOnErrorStatus: false });
      engine.response = { statusCode: 500, headers: {}, body: 'error' };
      const res = await lenientClient.get('https://example.com/api');
      assert.strictEqual(res.statusCode, 500);
    });

    it('should still save cookies before throwing on error status', async () => {
      const saved: { url: string; cookies: unknown[] }[] = [];
      const jar: import('../../../main/ets/network/CookieRepository.ets').CookieJar = {
        loadForRequest() { return []; },
        saveFromResponse(url: string, cookies: unknown[]) {
          saved.push({ url, cookies });
        },
      };
      client.setCookieJar(jar);
      engine.response = {
        statusCode: 401,
        headers: { 'Set-Cookie': 'session=expired; Path=/' },
        body: 'unauthorized',
      };
      await assert.rejects(
        () => client.get('https://example.com/protected'),
        (err: unknown) => err instanceof StatusCodeException,
      );
      // Cookies should have been saved even though error was thrown
      assert.strictEqual(saved.length, 1);
    });

    it('should include URL in StatusCodeException', async () => {
      engine.response = { statusCode: 403, headers: {}, body: '' };
      await assert.rejects(
        () => client.get('https://example.com/forbidden'),
        (err: unknown) => {
          assert.ok(err instanceof StatusCodeException);
          assert.strictEqual((err as StatusCodeException).url, 'https://example.com/forbidden');
          assert.strictEqual((err as StatusCodeException).isClientError, true);
          assert.strictEqual((err as StatusCodeException).isServerError, false);
          return true;
        },
      );
    });

    it('should identify server errors correctly', async () => {
      engine.response = { statusCode: 502, headers: {}, body: '' };
      await assert.rejects(
        () => client.get('https://example.com/api'),
        (err: unknown) => {
          assert.ok(err instanceof StatusCodeException);
          assert.strictEqual((err as StatusCodeException).isServerError, true);
          assert.strictEqual((err as StatusCodeException).isClientError, false);
          return true;
        },
      );
    });
  });

  describe('cookie jar integration', () => {
    it('should attach cookies from the jar to requests', async () => {
      const jar: import('../../../main/ets/network/CookieRepository.ets').CookieJar = {
        loadForRequest(_url: string) {
          return [
            { name: 'sid', value: 'abc123', expiresAt: Date.now() + 86400000, domain: 'example.com', path: '/', secure: false, httpOnly: false, persistent: true, hostOnly: true },
          ];
        },
        saveFromResponse() {},
      };
      client.setCookieJar(jar);
      await client.get('https://example.com/');
      assert.strictEqual(engine.lastRequest!.headers!['Cookie'], 'sid=abc123');
    });

    it('should save Set-Cookie headers from response', async () => {
      const saved: { url: string; cookies: unknown[] }[] = [];
      const jar: import('../../../main/ets/network/CookieRepository.ets').CookieJar = {
        loadForRequest() { return []; },
        saveFromResponse(url: string, cookies: unknown[]) {
          saved.push({ url, cookies });
        },
      };
      client.setCookieJar(jar);
      engine.response = {
        statusCode: 200,
        headers: { 'Set-Cookie': 'token=xyz; Path=/; HttpOnly' },
        body: 'ok',
      };
      await client.get('https://example.com/login');
      assert.strictEqual(saved.length, 1);
      assert.strictEqual(saved[0].url, 'https://example.com/login');
      assert.ok(saved[0].cookies.length > 0);
    });

    it('should not attach cookies when jar is null', async () => {
      client.setCookieJar(null);
      await client.get('https://example.com/');
      assert.strictEqual(engine.lastRequest!.headers!['Cookie'], undefined);
    });
  });
});

describe('encodeFormFields()', () => {
  it('should encode key-value pairs', () => {
    const result = encodeFormFields([
      { key: 'UserName', value: 'hello world' },
      { key: 'PassWord', value: 'a&b=c' },
    ]);
    assert.strictEqual(result, 'UserName=hello%20world&PassWord=a%26b%3Dc');
  });

  it('should return empty string for empty array', () => {
    assert.strictEqual(encodeFormFields([]), '');
  });
});

describe('buildMultipartBody()', () => {
  it('should produce valid multipart body with boundary', () => {
    const { contentType, payload } = buildMultipartBody('TestBoundary123', [
      { name: 'field1', data: 'value1' },
      { name: 'file', filename: 'test.txt', contentType: 'text/plain', data: 'file content' },
    ]);
    assert.strictEqual(contentType, 'multipart/form-data; boundary=TestBoundary123');
    assert.ok(payload.includes('--TestBoundary123\r\n'));
    assert.ok(payload.includes('name="field1"'));
    assert.ok(payload.includes('value1'));
    assert.ok(payload.includes('filename="test.txt"'));
    assert.ok(payload.includes('Content-Type: text/plain'));
    assert.ok(payload.includes('file content'));
    assert.ok(payload.includes('--TestBoundary123--'));
  });
});

describe('generateBoundary()', () => {
  it('should start with expected prefix', () => {
    const b = generateBoundary();
    assert.ok(b.startsWith('----EhViewerBoundary'));
  });

  it('should produce different values on each call', () => {
    const a = generateBoundary();
    const b = generateBoundary();
    assert.notStrictEqual(a, b);
  });
});

describe('buildEhHeaders()', () => {
  it('should include Referer when provided', () => {
    const h = buildEhHeaders('https://e-hentai.org');
    assert.strictEqual(h['Referer'], 'https://e-hentai.org');
    assert.strictEqual(h['Origin'], undefined);
  });

  it('should include both Referer and Origin', () => {
    const h = buildEhHeaders('https://e-hentai.org', 'https://e-hentai.org');
    assert.strictEqual(h['Referer'], 'https://e-hentai.org');
    assert.strictEqual(h['Origin'], 'https://e-hentai.org');
  });

  it('should return empty object when no args', () => {
    const h = buildEhHeaders();
    assert.deepStrictEqual(h, {});
  });
});
