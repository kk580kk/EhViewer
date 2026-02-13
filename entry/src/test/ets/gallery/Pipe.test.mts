import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

import { Pipe } from '../../../main/ets/gallery/Pipe.ets';

describe('Pipe', () => {
  it('should read data written before read()', async () => {
    const pipe = new Pipe();
    pipe.write(new Uint8Array([1, 2, 3]));
    pipe.closeWriter();

    const chunk = await pipe.read();
    assert.ok(chunk !== null);
    assert.deepStrictEqual(chunk, new Uint8Array([1, 2, 3]));

    const end = await pipe.read();
    assert.strictEqual(end, null);
  });

  it('should resolve pending read when data is written', async () => {
    const pipe = new Pipe();

    const readPromise = pipe.read();
    pipe.write(new Uint8Array([4, 5]));

    const chunk = await readPromise;
    assert.deepStrictEqual(chunk, new Uint8Array([4, 5]));
  });

  it('should return null when writer closes with no data', async () => {
    const pipe = new Pipe();

    const readPromise = pipe.read();
    pipe.closeWriter();

    const result = await readPromise;
    assert.strictEqual(result, null);
  });

  it('should handle multiple chunks in order', async () => {
    const pipe = new Pipe();
    pipe.write(new Uint8Array([1]));
    pipe.write(new Uint8Array([2]));
    pipe.write(new Uint8Array([3]));
    pipe.closeWriter();

    const c1 = await pipe.read();
    const c2 = await pipe.read();
    const c3 = await pipe.read();
    const end = await pipe.read();

    assert.deepStrictEqual(c1, new Uint8Array([1]));
    assert.deepStrictEqual(c2, new Uint8Array([2]));
    assert.deepStrictEqual(c3, new Uint8Array([3]));
    assert.strictEqual(end, null);
  });

  it('should skip empty writes', async () => {
    const pipe = new Pipe();
    pipe.write(new Uint8Array([]));
    pipe.write(new Uint8Array([10]));
    pipe.closeWriter();

    const chunk = await pipe.read();
    assert.deepStrictEqual(chunk, new Uint8Array([10]));
  });

  it('readAll() should concatenate all chunks', async () => {
    const pipe = new Pipe();
    pipe.write(new Uint8Array([1, 2]));
    pipe.write(new Uint8Array([3, 4, 5]));
    pipe.closeWriter();

    const all = await pipe.readAll();
    assert.ok(all !== null);
    assert.deepStrictEqual(all, new Uint8Array([1, 2, 3, 4, 5]));
  });

  it('readAll() should return null when no data written', async () => {
    const pipe = new Pipe();
    pipe.closeWriter();

    const result = await pipe.readAll();
    assert.strictEqual(result, null);
  });

  it('should throw when writing after writer is closed', () => {
    const pipe = new Pipe();
    pipe.closeWriter();
    assert.throws(() => pipe.write(new Uint8Array([1])), /writer is closed/);
  });

  it('should throw when writing after reader is closed', () => {
    const pipe = new Pipe();
    pipe.closeReader();
    assert.throws(() => pipe.write(new Uint8Array([1])), /reader is closed/);
  });

  it('should throw when reading after reader is closed', async () => {
    const pipe = new Pipe();
    pipe.closeReader();
    await assert.rejects(() => pipe.read(), /reader is closed/);
  });

  it('should report closed state correctly', () => {
    const pipe = new Pipe();
    assert.ok(!pipe.isWriterClosed());
    assert.ok(!pipe.isReaderClosed());

    pipe.closeWriter();
    assert.ok(pipe.isWriterClosed());
    assert.ok(!pipe.isReaderClosed());

    pipe.closeReader();
    assert.ok(pipe.isReaderClosed());
  });

  // ---- AsyncIterable support ----

  it('should be consumable via for-await-of', async () => {
    const pipe = new Pipe();
    pipe.write(new Uint8Array([1, 2]));
    pipe.write(new Uint8Array([3, 4]));
    pipe.closeWriter();

    const chunks: Uint8Array[] = [];
    for await (const chunk of pipe) {
      chunks.push(chunk);
    }

    assert.strictEqual(chunks.length, 2);
    assert.deepStrictEqual(chunks[0], new Uint8Array([1, 2]));
    assert.deepStrictEqual(chunks[1], new Uint8Array([3, 4]));
  });

  it('for-await-of should end when writer closes with no data', async () => {
    const pipe = new Pipe();
    pipe.closeWriter();

    const chunks: Uint8Array[] = [];
    for await (const chunk of pipe) {
      chunks.push(chunk);
    }

    assert.strictEqual(chunks.length, 0);
  });

  it('for-await-of should wait for deferred writes', async () => {
    const pipe = new Pipe();

    // Schedule writes after a microtask
    setTimeout(() => {
      pipe.write(new Uint8Array([10]));
      pipe.write(new Uint8Array([20]));
      pipe.closeWriter();
    }, 0);

    const chunks: Uint8Array[] = [];
    for await (const chunk of pipe) {
      chunks.push(chunk);
    }

    assert.strictEqual(chunks.length, 2);
    assert.deepStrictEqual(chunks[0], new Uint8Array([10]));
    assert.deepStrictEqual(chunks[1], new Uint8Array([20]));
  });

  // ---- fromAsyncIterable ----

  it('fromAsyncIterable should bridge an async generator to a Pipe', async () => {
    async function* source(): AsyncIterable<Uint8Array> {
      yield new Uint8Array([1, 2]);
      yield new Uint8Array([3, 4, 5]);
    }

    const pipe = Pipe.fromAsyncIterable(source());
    // Let the source be consumed
    await new Promise(resolve => setTimeout(resolve, 0));

    const all = await pipe.readAll();
    assert.ok(all !== null);
    assert.deepStrictEqual(all, new Uint8Array([1, 2, 3, 4, 5]));
  });

  it('fromAsyncIterable should close writer when source ends', async () => {
    async function* source(): AsyncIterable<Uint8Array> {
      yield new Uint8Array([99]);
    }

    const pipe = Pipe.fromAsyncIterable(source());
    await new Promise(resolve => setTimeout(resolve, 0));

    assert.ok(pipe.isWriterClosed());
  });

  it('fromAsyncIterable should stop consuming when reader is closed', async () => {
    let yielded = 0;
    async function* source(): AsyncIterable<Uint8Array> {
      for (let i = 0; i < 100; i++) {
        yielded++;
        yield new Uint8Array([i]);
        await new Promise(resolve => setTimeout(resolve, 0));
      }
    }

    const pipe = Pipe.fromAsyncIterable(source());
    // Read one chunk, then close reader
    const first = await pipe.read();
    assert.deepStrictEqual(first, new Uint8Array([0]));

    pipe.closeReader();
    // Let pending source iterations settle
    await new Promise(resolve => setTimeout(resolve, 50));

    // Source should have stopped early (not all 100 items)
    assert.ok(yielded < 100, `Expected early stop, but yielded ${yielded}`);
  });

  it('fromAsyncIterable should propagate source errors to reader', async () => {
    async function* failingSource(): AsyncIterable<Uint8Array> {
      yield new Uint8Array([1]);
      throw new Error('source broke');
    }

    const pipe = Pipe.fromAsyncIterable(failingSource());
    await new Promise(resolve => setTimeout(resolve, 0));

    // Should still get the first chunk
    const chunk = await pipe.read();
    assert.deepStrictEqual(chunk, new Uint8Array([1]));

    // Next read should throw the source error
    await assert.rejects(() => pipe.read(), /source broke/);
    assert.ok(pipe.isWriterClosed());
  });

  it('fromAsyncIterable should handle empty source', async () => {
    async function* empty(): AsyncIterable<Uint8Array> {
      // yields nothing
    }

    const pipe = Pipe.fromAsyncIterable(empty());
    await new Promise(resolve => setTimeout(resolve, 0));

    const result = await pipe.readAll();
    assert.strictEqual(result, null);
    assert.ok(pipe.isWriterClosed());
  });

  it('fromAsyncIterable pipe should be consumable via for-await-of', async () => {
    async function* source(): AsyncIterable<Uint8Array> {
      yield new Uint8Array([10, 20]);
      yield new Uint8Array([30]);
    }

    const pipe = Pipe.fromAsyncIterable(source());

    const chunks: Uint8Array[] = [];
    for await (const chunk of pipe) {
      chunks.push(chunk);
    }

    assert.strictEqual(chunks.length, 2);
    assert.deepStrictEqual(chunks[0], new Uint8Array([10, 20]));
    assert.deepStrictEqual(chunks[1], new Uint8Array([30]));
  });
});
