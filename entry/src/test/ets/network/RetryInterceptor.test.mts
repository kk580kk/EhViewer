import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import {
  ExponentialBackoffRetry,
  sleep,
} from '../../../main/ets/network/RetryInterceptor.ets';
import type { RetryStrategy } from '../../../main/ets/network/RetryInterceptor.ets';
import { StatusCodeException } from '../../../main/ets/network/StatusCodeException.ets';
import { HttpClient } from '../../../main/ets/network/HttpClient.ets';
import type {
  HttpEngine,
  HttpRequest,
  HttpResponse,
} from '../../../main/ets/network/HttpClient.ets';

// ---- Mocks ----

/** Engine that fails N times then succeeds. */
class FailThenSucceedEngine implements HttpEngine {
  callCount = 0;
  private failCount: number;
  private failError: Error;
  private successResponse: HttpResponse;

  constructor(failCount: number, failError: Error, successResponse?: HttpResponse) {
    this.failCount = failCount;
    this.failError = failError;
    this.successResponse = successResponse ?? { statusCode: 200, headers: {}, body: 'ok' };
  }

  async execute(_request: HttpRequest): Promise<HttpResponse> {
    this.callCount++;
    if (this.callCount <= this.failCount) {
      throw this.failError;
    }
    return this.successResponse;
  }
}

/**
 * Engine that returns HTTP error responses N times, then returns success.
 * Used for testing retry on status codes (where HttpClient throws StatusCodeException).
 */
class StatusFailEngine implements HttpEngine {
  callCount = 0;
  private failCount: number;
  private failStatusCode: number;
  private successResponse: HttpResponse;

  constructor(failCount: number, failStatusCode: number, successResponse?: HttpResponse) {
    this.failCount = failCount;
    this.failStatusCode = failStatusCode;
    this.successResponse = successResponse ?? { statusCode: 200, headers: {}, body: 'ok' };
  }

  async execute(_request: HttpRequest): Promise<HttpResponse> {
    this.callCount++;
    if (this.callCount <= this.failCount) {
      return { statusCode: this.failStatusCode, headers: {}, body: '' };
    }
    return this.successResponse;
  }
}

/** Engine that always fails with a given error. */
class AlwaysFailEngine implements HttpEngine {
  callCount = 0;
  private failError: Error;

  constructor(failError: Error) {
    this.failError = failError;
  }

  async execute(_request: HttpRequest): Promise<HttpResponse> {
    this.callCount++;
    throw this.failError;
  }
}

/** Engine that always returns a given status code. */
class AlwaysStatusEngine implements HttpEngine {
  callCount = 0;
  private statusCode: number;

  constructor(statusCode: number) {
    this.statusCode = statusCode;
  }

  async execute(_request: HttpRequest): Promise<HttpResponse> {
    this.callCount++;
    return { statusCode: this.statusCode, headers: {}, body: '' };
  }
}

// ---- ExponentialBackoffRetry unit tests ----

describe('ExponentialBackoffRetry', () => {
  let strategy: ExponentialBackoffRetry;

  beforeEach(() => {
    strategy = new ExponentialBackoffRetry({
      maxRetries: 3,
      baseDelayMs: 100,
      maxDelayMs: 5000,
      jitterFactor: 0, // disable jitter for deterministic tests
    });
  });

  describe('network errors', () => {
    it('should retry on network error', () => {
      const delay = strategy.shouldRetry(0, new Error('network error'));
      assert.ok(delay >= 0, 'should return a non-negative delay');
    });

    it('should retry on ECONNREFUSED', () => {
      const delay = strategy.shouldRetry(0, new Error('ECONNREFUSED'));
      assert.ok(delay >= 0);
    });

    it('should retry on ECONNRESET', () => {
      const delay = strategy.shouldRetry(0, new Error('ECONNRESET'));
      assert.ok(delay >= 0);
    });

    it('should retry on timeout error', () => {
      const delay = strategy.shouldRetry(0, new Error('timeout'));
      assert.ok(delay >= 0);
    });

    it('should retry on socket error', () => {
      const delay = strategy.shouldRetry(0, new Error('socket hang up'));
      assert.ok(delay >= 0);
    });

    it('should stop retrying after maxRetries', () => {
      const delay = strategy.shouldRetry(3, new Error('network error'));
      assert.strictEqual(delay, -1);
    });
  });

  describe('server errors (5xx)', () => {
    it('should retry on 500 Internal Server Error', () => {
      const delay = strategy.shouldRetry(0, new StatusCodeException(500));
      assert.ok(delay >= 0);
    });

    it('should retry on 502 Bad Gateway', () => {
      const delay = strategy.shouldRetry(0, new StatusCodeException(502));
      assert.ok(delay >= 0);
    });

    it('should retry on 503 Service Unavailable', () => {
      const delay = strategy.shouldRetry(0, new StatusCodeException(503));
      assert.ok(delay >= 0);
    });

    it('should retry on 504 Gateway Timeout', () => {
      const delay = strategy.shouldRetry(0, new StatusCodeException(504));
      assert.ok(delay >= 0);
    });

    it('should stop after maxRetries on 5xx', () => {
      const delay = strategy.shouldRetry(3, new StatusCodeException(500));
      assert.strictEqual(delay, -1);
    });
  });

  describe('client errors (4xx)', () => {
    it('should NOT retry on 400 Bad Request', () => {
      assert.strictEqual(strategy.shouldRetry(0, new StatusCodeException(400)), -1);
    });

    it('should NOT retry on 401 Unauthorized', () => {
      assert.strictEqual(strategy.shouldRetry(0, new StatusCodeException(401)), -1);
    });

    it('should NOT retry on 403 Forbidden', () => {
      assert.strictEqual(strategy.shouldRetry(0, new StatusCodeException(403)), -1);
    });

    it('should NOT retry on 404 Not Found', () => {
      assert.strictEqual(strategy.shouldRetry(0, new StatusCodeException(404)), -1);
    });

    it('should retry on 408 Request Timeout', () => {
      const delay = strategy.shouldRetry(0, new StatusCodeException(408));
      assert.ok(delay >= 0);
    });

    it('should retry on 429 Too Many Requests with longer delay', () => {
      const delay429 = strategy.shouldRetry(0, new StatusCodeException(429));
      const delay500 = strategy.shouldRetry(0, new StatusCodeException(500));
      assert.ok(delay429 >= 0);
      assert.ok(delay429 > delay500, '429 should have longer delay than 500');
    });
  });

  describe('509 Bandwidth Limit (E-Hentai specific)', () => {
    it('should NEVER retry on 509', () => {
      assert.strictEqual(strategy.shouldRetry(0, new StatusCodeException(509)), -1);
    });

    it('should not retry 509 even on first attempt', () => {
      const aggressive = new ExponentialBackoffRetry({ maxRetries: 10 });
      assert.strictEqual(aggressive.shouldRetry(0, new StatusCodeException(509)), -1);
    });
  });

  describe('exponential backoff', () => {
    it('should increase delay with each attempt', () => {
      const delay0 = strategy.shouldRetry(0, new StatusCodeException(500));
      const delay1 = strategy.shouldRetry(1, new StatusCodeException(500));
      const delay2 = strategy.shouldRetry(2, new StatusCodeException(500));
      assert.ok(delay0 < delay1, `delay0=${delay0} should be < delay1=${delay1}`);
      assert.ok(delay1 < delay2, `delay1=${delay1} should be < delay2=${delay2}`);
    });

    it('should cap delay at maxDelayMs', () => {
      const shortMax = new ExponentialBackoffRetry({
        maxRetries: 10,
        baseDelayMs: 10000,
        maxDelayMs: 15000,
        jitterFactor: 0,
      });
      const delay = shortMax.shouldRetry(5, new StatusCodeException(500));
      assert.ok(delay <= 15000, `delay=${delay} should be <= maxDelayMs=15000`);
    });
  });

  describe('unknown errors', () => {
    it('should NOT retry on unknown error types', () => {
      assert.strictEqual(strategy.shouldRetry(0, new Error('some business error')), -1);
    });

    it('should NOT retry on non-Error values', () => {
      assert.strictEqual(strategy.shouldRetry(0, 'string error'), -1);
      assert.strictEqual(strategy.shouldRetry(0, null), -1);
      assert.strictEqual(strategy.shouldRetry(0, 42), -1);
    });
  });
});

// ---- Integration: HttpClient with RetryStrategy ----

describe('HttpClient with RetryStrategy', () => {
  it('should retry on network error and succeed', async () => {
    const engine = new FailThenSucceedEngine(2, new Error('network error'));
    const client = new HttpClient({
      engine,
      retryStrategy: new ExponentialBackoffRetry({
        maxRetries: 3,
        baseDelayMs: 1, // minimal delay for tests
        jitterFactor: 0,
      }),
    });

    const res = await client.get('https://example.com');
    assert.strictEqual(res.statusCode, 200);
    assert.strictEqual(res.body, 'ok');
    assert.strictEqual(engine.callCount, 3); // 2 failures + 1 success
  });

  it('should retry on 500 and succeed', async () => {
    const engine = new StatusFailEngine(2, 500);
    const client = new HttpClient({
      engine,
      retryStrategy: new ExponentialBackoffRetry({
        maxRetries: 3,
        baseDelayMs: 1,
        jitterFactor: 0,
      }),
    });

    const res = await client.get('https://example.com');
    assert.strictEqual(res.statusCode, 200);
    assert.strictEqual(engine.callCount, 3);
  });

  it('should retry on 503 and succeed', async () => {
    const engine = new StatusFailEngine(1, 503);
    const client = new HttpClient({
      engine,
      retryStrategy: new ExponentialBackoffRetry({
        maxRetries: 3,
        baseDelayMs: 1,
        jitterFactor: 0,
      }),
    });

    const res = await client.get('https://example.com');
    assert.strictEqual(res.statusCode, 200);
    assert.strictEqual(engine.callCount, 2);
  });

  it('should NOT retry on 509 and throw immediately', async () => {
    const engine = new AlwaysStatusEngine(509);
    const client = new HttpClient({
      engine,
      retryStrategy: new ExponentialBackoffRetry({
        maxRetries: 3,
        baseDelayMs: 1,
        jitterFactor: 0,
      }),
    });

    await assert.rejects(
      () => client.get('https://example.com'),
      (err: unknown) => {
        assert.ok(err instanceof StatusCodeException);
        assert.strictEqual(err.responseCode, 509);
        return true;
      },
    );
    assert.strictEqual(engine.callCount, 1, 'should only attempt once for 509');
  });

  it('should NOT retry on 404', async () => {
    const engine = new AlwaysStatusEngine(404);
    const client = new HttpClient({
      engine,
      retryStrategy: new ExponentialBackoffRetry({
        maxRetries: 3,
        baseDelayMs: 1,
        jitterFactor: 0,
      }),
    });

    await assert.rejects(
      () => client.get('https://example.com'),
      (err: unknown) => {
        assert.ok(err instanceof StatusCodeException);
        assert.strictEqual(err.responseCode, 404);
        return true;
      },
    );
    assert.strictEqual(engine.callCount, 1, 'should only attempt once for 404');
  });

  it('should exhaust retries then throw on persistent 500', async () => {
    const engine = new AlwaysStatusEngine(500);
    const client = new HttpClient({
      engine,
      retryStrategy: new ExponentialBackoffRetry({
        maxRetries: 3,
        baseDelayMs: 1,
        jitterFactor: 0,
      }),
    });

    await assert.rejects(
      () => client.get('https://example.com'),
      (err: unknown) => {
        assert.ok(err instanceof StatusCodeException);
        assert.strictEqual(err.responseCode, 500);
        return true;
      },
    );
    // 1 original + 3 retries = 4 total attempts
    assert.strictEqual(engine.callCount, 4);
  });

  it('should exhaust retries then throw on persistent network error', async () => {
    const engine = new AlwaysFailEngine(new Error('ECONNREFUSED'));
    const client = new HttpClient({
      engine,
      retryStrategy: new ExponentialBackoffRetry({
        maxRetries: 2,
        baseDelayMs: 1,
        jitterFactor: 0,
      }),
    });

    await assert.rejects(
      () => client.get('https://example.com'),
      { message: 'ECONNREFUSED' },
    );
    // 1 original + 2 retries = 3 total
    assert.strictEqual(engine.callCount, 3);
  });

  it('should work without retry strategy (no change to existing behaviour)', async () => {
    const engine = new AlwaysStatusEngine(500);
    const client = new HttpClient({ engine });

    await assert.rejects(
      () => client.get('https://example.com'),
      (err: unknown) => {
        assert.ok(err instanceof StatusCodeException);
        return true;
      },
    );
    assert.strictEqual(engine.callCount, 1);
  });

  it('should support setRetryStrategy() at runtime', async () => {
    const engine = new StatusFailEngine(1, 500);
    const client = new HttpClient({ engine });

    // Without retry: should fail on first 500
    await assert.rejects(() => client.get('https://example.com'));
    assert.strictEqual(engine.callCount, 1);

    // Reset and add retry strategy
    engine.callCount = 0;
    client.setRetryStrategy(new ExponentialBackoffRetry({
      maxRetries: 3,
      baseDelayMs: 1,
      jitterFactor: 0,
    }));

    const res = await client.get('https://example.com');
    assert.strictEqual(res.statusCode, 200);
    assert.strictEqual(engine.callCount, 2);
  });

  it('should retry on 429 with longer delay', async () => {
    const engine = new StatusFailEngine(1, 429);
    const client = new HttpClient({
      engine,
      retryStrategy: new ExponentialBackoffRetry({
        maxRetries: 3,
        baseDelayMs: 1,
        jitterFactor: 0,
      }),
    });

    const res = await client.get('https://example.com');
    assert.strictEqual(res.statusCode, 200);
    assert.strictEqual(engine.callCount, 2);
  });
});

// ---- sleep utility ----

describe('sleep()', () => {
  it('should resolve after the given delay', async () => {
    const start = Date.now();
    await sleep(50);
    const elapsed = Date.now() - start;
    assert.ok(elapsed >= 40, `expected >= 40ms, got ${elapsed}ms`);
  });

  it('should resolve immediately for 0ms', async () => {
    const start = Date.now();
    await sleep(0);
    const elapsed = Date.now() - start;
    assert.ok(elapsed < 50, `expected < 50ms, got ${elapsed}ms`);
  });
});

// ---- StatusCodeException 509 ----

describe('StatusCodeException 509 support', () => {
  it('should recognize 509 as an identified response code', () => {
    const ex = new StatusCodeException(509);
    assert.ok(ex.isIdentifiedResponseCode);
    assert.ok(ex.message.includes('509'));
    assert.ok(ex.message.includes('Bandwidth'));
  });
});
