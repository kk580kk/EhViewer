/*
 * Copyright 2019 Hippo Seven
 * Ported to HarmonyOS ArkTS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

/**
 * IoTaskPool — async concurrency pool for IO-bound tasks.
 *
 * ArkTS equivalent of Android's IoThreadPoolExecutor.
 * Controls how many async tasks run concurrently (default max: 32).
 * Tasks exceeding the limit are queued and executed as slots free up.
 *
 * Usage:
 *   // Fire-and-forget
 *   IoTaskPool.getInstance().execute(async () => {
 *     await fetchData();
 *   });
 *
 *   // Submit and await result
 *   const result = await IoTaskPool.getInstance().submit(async () => {
 *     return await parseHtml(body);
 *   });
 */

import { Logger } from './Logger.ets';

const log = Logger.tag('IoTaskPool');

/** Priority levels for queued tasks (lower value = higher priority). */
export const TaskPriority = {
  HIGH: 0,
  NORMAL: 1,
  LOW: 2,
} as const;

export type TaskPriority = (typeof TaskPriority)[keyof typeof TaskPriority];

/** Internal representation of a queued task. */
interface QueuedTask {
  run: () => Promise<void>;
  priority: TaskPriority;
}

/**
 * Async concurrency pool that limits the number of simultaneously
 * executing async IO tasks, equivalent to Java's IoThreadPoolExecutor.
 */
export class IoTaskPool {
  private static instance: IoTaskPool | null = null;

  private readonly maxConcurrency: number;
  private activeCount: number = 0;
  private queue: QueuedTask[] = [];
  private isShutdown: boolean = false;

  constructor(maxConcurrency: number = 32) {
    if (maxConcurrency < 1) {
      throw new Error(`maxConcurrency must be >= 1, got ${maxConcurrency}`);
    }
    this.maxConcurrency = maxConcurrency;
  }

  /** Get the singleton instance (max concurrency: 32). */
  static getInstance(): IoTaskPool {
    if (!IoTaskPool.instance) {
      IoTaskPool.instance = new IoTaskPool(32);
    }
    return IoTaskPool.instance;
  }

  /** Reset the singleton (for testing). */
  static resetInstance(): void {
    IoTaskPool.instance = null;
  }

  /**
   * Submit an async task and return a Promise for its result.
   * The task is queued if the pool is at capacity.
   *
   * @param task - async function to execute
   * @param priority - optional priority (default: NORMAL)
   * @returns Promise resolving to the task's return value
   * @throws Error if the pool has been shut down
   */
  submit<T>(task: () => Promise<T>, priority: TaskPriority = TaskPriority.NORMAL): Promise<T> {
    if (this.isShutdown) {
      return Promise.reject(new Error('IoTaskPool has been shut down'));
    }

    return new Promise<T>((resolve, reject) => {
      const wrapped = async (): Promise<void> => {
        try {
          const result = await task();
          resolve(result);
        } catch (e) {
          reject(e);
        }
      };

      this.enqueue({ run: wrapped, priority });
    });
  }

  /**
   * Execute a fire-and-forget async task.
   * Errors are logged but not propagated.
   *
   * @param task - async function to execute
   * @param priority - optional priority (default: NORMAL)
   * @throws Error if the pool has been shut down
   */
  execute(task: () => Promise<void>, priority: TaskPriority = TaskPriority.NORMAL): void {
    if (this.isShutdown) {
      throw new Error('IoTaskPool has been shut down');
    }

    const wrapped = async (): Promise<void> => {
      try {
        await task();
      } catch (e) {
        log.e('Unhandled error in execute() task', e instanceof Error ? e : new Error(String(e)));
      }
    };

    this.enqueue({ run: wrapped, priority });
  }

  /**
   * Shut down the pool. No new tasks will be accepted.
   * Already queued tasks will still be executed.
   *
   * @returns Promise that resolves when all queued tasks finish
   */
  async shutdown(): Promise<void> {
    this.isShutdown = true;
    // Wait until both active and queued tasks are drained
    if (this.activeCount === 0 && this.queue.length === 0) {
      return;
    }
    return new Promise<void>((resolve) => {
      const check = (): void => {
        if (this.activeCount === 0 && this.queue.length === 0) {
          resolve();
        } else {
          // Use microtask to avoid busy spinning; the drain loop
          // will call tryRunNext which eventually empties both.
          Promise.resolve().then(check);
        }
      };
      check();
    });
  }

  /** Returns true if the pool has been shut down. */
  isTerminated(): boolean {
    return this.isShutdown;
  }

  /** Number of tasks currently executing. */
  getActiveCount(): number {
    return this.activeCount;
  }

  /** Number of tasks waiting in the queue. */
  getQueueSize(): number {
    return this.queue.length;
  }

  /** Maximum number of concurrent tasks. */
  getMaxConcurrency(): number {
    return this.maxConcurrency;
  }

  // ---- Internal ----

  private enqueue(task: QueuedTask): void {
    if (this.activeCount < this.maxConcurrency) {
      this.runTask(task);
    } else {
      this.insertByPriority(task);
    }
  }

  /** Insert into queue maintaining priority order (lower value first). */
  private insertByPriority(task: QueuedTask): void {
    // Fast path: queue is empty or task has lowest priority
    if (this.queue.length === 0 || task.priority >= this.queue[this.queue.length - 1].priority) {
      this.queue.push(task);
      return;
    }
    // Find insertion point
    for (let i = 0; i < this.queue.length; i++) {
      if (task.priority < this.queue[i].priority) {
        this.queue.splice(i, 0, task);
        return;
      }
    }
    this.queue.push(task);
  }

  private runTask(task: QueuedTask): void {
    this.activeCount++;
    task.run().finally(() => {
      this.activeCount--;
      this.tryRunNext();
    });
  }

  private tryRunNext(): void {
    if (this.queue.length > 0 && this.activeCount < this.maxConcurrency) {
      const next = this.queue.shift()!;
      this.runTask(next);
    }
  }
}
