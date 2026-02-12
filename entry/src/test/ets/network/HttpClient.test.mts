import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import {
  HttpClient,
  encodeFormFields,
  buildMultipartBody,
  generateBoundary,
  buildEhHeaders,
} from '../../../main/ets/network/HttpClient.ets';
import type {
  HttpEngine,
  HttpRequest,
  HttpResponse,
} from '../../../main/ets/network/HttpClient.ets';

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
      engine2.response = { statusCode: 404, headers: {}, body: 'not found' };
      client.setEngine(engine2);
      const res = await client.get('https://example.com');
      assert.strictEqual(res.statusCode, 404);
      assert.strictEqual(engine.lastRequest, null); // original engine was not called
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
