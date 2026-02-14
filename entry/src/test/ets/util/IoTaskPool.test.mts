import { describe, it, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { IoTaskPool, TaskPriority } from '../../../main/ets/util/IoTaskPool.ets';

/** Helper: create a task that resolves after `ms` milliseconds. */
function delay(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/** Helper: create a task that tracks its execution. */
function tracked(id: string, log: string[], ms: number = 10): () => Promise<string> {
  return async () => {
    log.push(`start:${id}`);
    await delay(ms);
    log.push(`end:${id}`);
    return id;
  };
}

describe('IoTaskPool', () => {
  let pool: IoTaskPool;

  beforeEach(() => {
    IoTaskPool.resetInstance();
  });

  afterEach(async () => {
    if (pool && !pool.isTerminated()) {
      await pool.shutdown();
    }
  });

  // ---- Construction ----

  describe('construction', () => {
    it('should create pool with default concurrency of 32', () => {
      pool = new IoTaskPool();
      assert.strictEqual(pool.getMaxConcurrency(), 32);
      assert.strictEqual(pool.getActiveCount(), 0);
      assert.strictEqual(pool.getQueueSize(), 0);
    });

    it('should create pool with custom concurrency', () => {
      pool = new IoTaskPool(4);
      assert.strictEqual(pool.getMaxConcurrency(), 4);
    });

    it('should throw for concurrency < 1', () => {
      assert.throws(() => new IoTaskPool(0), /must be >= 1/);
      assert.throws(() => new IoTaskPool(-1), /must be >= 1/);
    });
  });

  // ---- Singleton ----

  describe('getInstance', () => {
    it('should return the same instance', () => {
      const a = IoTaskPool.getInstance();
      const b = IoTaskPool.getInstance();
      assert.strictEqual(a, b);
      pool = a; // for cleanup
    });

    it('should have max concurrency of 32', () => {
      pool = IoTaskPool.getInstance();
      assert.strictEqual(pool.getMaxConcurrency(), 32);
    });

    it('should return new instance after resetInstance', () => {
      const a = IoTaskPool.getInstance();
      IoTaskPool.resetInstance();
      const b = IoTaskPool.getInstance();
      assert.notStrictEqual(a, b);
      pool = b;
      // Clean up old instance
      a.shutdown();
    });
  });

  // ---- submit ----

  describe('submit', () => {
    it('should execute a task and return its result', async () => {
      pool = new IoTaskPool(2);
      const result = await pool.submit(async () => 42);
      assert.strictEqual(result, 42);
    });

    it('should propagate task errors', async () => {
      pool = new IoTaskPool(2);
      await assert.rejects(
        () => pool.submit(async () => { throw new Error('boom'); }),
        { message: 'boom' },
      );
    });

    it('should execute tasks concurrently up to the limit', async () => {
      pool = new IoTaskPool(2);
      const log: string[] = [];

      const p1 = pool.submit(tracked('A', log, 30));
      const p2 = pool.submit(tracked('B', log, 30));
      const p3 = pool.submit(tracked('C', log, 30));

      // A and B should start immediately (concurrency=2), C waits
      await delay(5);
      assert.ok(log.includes('start:A'), 'A should have started');
      assert.ok(log.includes('start:B'), 'B should have started');
      assert.ok(!log.includes('start:C'), 'C should be queued');
      assert.strictEqual(pool.getActiveCount(), 2);
      assert.strictEqual(pool.getQueueSize(), 1);

      // Wait for all to finish
      const results = await Promise.all([p1, p2, p3]);
      assert.deepStrictEqual(results, ['A', 'B', 'C']);
      assert.strictEqual(pool.getActiveCount(), 0);
      assert.strictEqual(pool.getQueueSize(), 0);
    });

    it('should reject when pool is shut down', async () => {
      pool = new IoTaskPool(2);
      await pool.shutdown();
      await assert.rejects(
        () => pool.submit(async () => 1),
        /shut down/,
      );
    });
  });

  // ---- execute ----

  describe('execute', () => {
    it('should run a fire-and-forget task', async () => {
      pool = new IoTaskPool(2);
      let executed = false;
      pool.execute(async () => { executed = true; });
      await delay(20);
      assert.strictEqual(executed, true);
    });

    it('should not throw on task errors (fire and forget)', async () => {
      pool = new IoTaskPool(2);
      // execute() should swallow errors and log them
      pool.execute(async () => { throw new Error('silent'); });
      await delay(20);
      // If we get here without unhandled rejection, the test passes
      assert.strictEqual(pool.getActiveCount(), 0);
    });

    it('should throw when pool is shut down', async () => {
      pool = new IoTaskPool(2);
      await pool.shutdown();
      assert.throws(
        () => pool.execute(async () => {}),
        /shut down/,
      );
    });
  });

  // ---- Priority ----

  describe('priority', () => {
    it('should execute higher priority tasks first when queued', async () => {
      pool = new IoTaskPool(1); // Only 1 slot
      const order: string[] = [];

      // Fill the single slot with a slow task
      pool.submit(async () => {
        await delay(50);
        order.push('blocker');
      });

      // Queue tasks with different priorities
      // These are all queued because the pool is full
      pool.submit(async () => { order.push('low'); }, TaskPriority.LOW);
      pool.submit(async () => { order.push('high'); }, TaskPriority.HIGH);
      pool.submit(async () => { order.push('normal'); }, TaskPriority.NORMAL);

      await pool.shutdown();

      // After 'blocker', high should run first, then normal, then low
      assert.strictEqual(order[0], 'blocker');
      assert.strictEqual(order[1], 'high');
      assert.strictEqual(order[2], 'normal');
      assert.strictEqual(order[3], 'low');
    });

    it('should maintain FIFO order for same-priority tasks', async () => {
      pool = new IoTaskPool(1);
      const order: string[] = [];

      // Fill the slot
      pool.submit(async () => { await delay(30); });

      // Queue 3 NORMAL tasks
      pool.submit(async () => { order.push('first'); });
      pool.submit(async () => { order.push('second'); });
      pool.submit(async () => { order.push('third'); });

      await pool.shutdown();
      assert.deepStrictEqual(order, ['first', 'second', 'third']);
    });
  });

  // ---- shutdown ----

  describe('shutdown', () => {
    it('should resolve immediately when pool is idle', async () => {
      pool = new IoTaskPool(2);
      await pool.shutdown();
      assert.strictEqual(pool.isTerminated(), true);
    });

    it('should wait for active tasks to complete', async () => {
      pool = new IoTaskPool(2);
      let finished = false;
      pool.submit(async () => {
        await delay(30);
        finished = true;
      });
      await pool.shutdown();
      assert.strictEqual(finished, true);
    });

    it('should drain queued tasks before resolving', async () => {
      pool = new IoTaskPool(1);
      const results: number[] = [];

      pool.submit(async () => { await delay(10); results.push(1); });
      pool.submit(async () => { results.push(2); });
      pool.submit(async () => { results.push(3); });

      await pool.shutdown();
      assert.deepStrictEqual(results, [1, 2, 3]);
    });
  });

  // ---- Concurrency stress ----

  describe('concurrency', () => {
    it('should never exceed max concurrency under load', async () => {
      const maxConcurrency = 4;
      pool = new IoTaskPool(maxConcurrency);
      let peakActive = 0;

      const tasks = Array.from({ length: 20 }, (_, i) =>
        pool.submit(async () => {
          const current = pool.getActiveCount();
          if (current > peakActive) peakActive = current;
          assert.ok(current <= maxConcurrency,
            `Active count ${current} exceeded max ${maxConcurrency}`);
          await delay(5 + Math.random() * 10);
          return i;
        }),
      );

      const results = await Promise.all(tasks);
      assert.strictEqual(results.length, 20);
      assert.ok(peakActive > 1, 'Should have had concurrent execution');
      assert.ok(peakActive <= maxConcurrency, `Peak ${peakActive} exceeded max ${maxConcurrency}`);
    });

    it('should handle rapid submit/complete cycles', async () => {
      pool = new IoTaskPool(8);
      const promises: Promise<number>[] = [];

      for (let i = 0; i < 100; i++) {
        promises.push(pool.submit(async () => i));
      }

      const results = await Promise.all(promises);
      assert.strictEqual(results.length, 100);
      // All values should be present (order may vary due to concurrency)
      const sorted = [...results].sort((a, b) => a - b);
      assert.deepStrictEqual(sorted, Array.from({ length: 100 }, (_, i) => i));
    });
  });
});
