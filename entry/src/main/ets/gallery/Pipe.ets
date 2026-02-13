/*
 * Copyright 2019 Hippo Seven
 * Ported to HarmonyOS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

/**
 * Asynchronous byte pipe: one writer pushes chunks, one reader pulls them.
 *
 * Mirrors the Android Pipe class but uses Promises instead of
 * synchronized wait/notify (ArkTS is single-threaded per context).
 *
 * Writer calls write() to enqueue data, then closeWriter() when done.
 * Reader calls read() which resolves when data is available, or
 * returns null when the writer has closed and no data remains.
 */
export class Pipe {

  private chunks: Uint8Array[] = [];
  private writerClosed = false;
  private readerClosed = false;

  /** Error set by the writer to propagate to the reader. */
  private writerError: Error | null = null;

  /** Pending reader waiting for data. */
  private pendingRead: {
    resolve: (value: Uint8Array | null) => void;
    reject: (err: Error) => void;
  } | null = null;

  /**
   * Write a chunk of data into the pipe.
   * Throws if writer or reader is already closed.
   */
  write(data: Uint8Array): void {
    if (this.writerClosed) {
      throw new Error('Pipe: writer is closed');
    }
    if (this.readerClosed) {
      throw new Error('Pipe: reader is closed');
    }
    if (data.length === 0) {
      return;
    }

    if (this.pendingRead !== null) {
      const { resolve } = this.pendingRead;
      this.pendingRead = null;
      resolve(data);
    } else {
      this.chunks.push(data);
    }
  }

  /**
   * Read the next chunk from the pipe.
   * Returns null when the writer has closed and all data has been consumed.
   */
  async read(): Promise<Uint8Array | null> {
    if (this.readerClosed) {
      throw new Error('Pipe: reader is closed');
    }

    if (this.chunks.length > 0) {
      return this.chunks.shift()!;
    }

    if (this.writerClosed) {
      if (this.writerError !== null) {
        throw this.writerError;
      }
      return null;
    }

    return new Promise<Uint8Array | null>((resolve, reject) => {
      this.pendingRead = { resolve, reject };
    });
  }

  /**
   * Read all remaining data as a single concatenated Uint8Array.
   * Returns null if no data was ever written and writer is closed.
   */
  async readAll(): Promise<Uint8Array | null> {
    const parts: Uint8Array[] = [];
    let chunk = await this.read();
    while (chunk !== null) {
      parts.push(chunk);
      chunk = await this.read();
    }
    if (parts.length === 0) {
      return null;
    }
    if (parts.length === 1) {
      return parts[0];
    }
    const totalLength = parts.reduce((sum, p) => sum + p.length, 0);
    const result = new Uint8Array(totalLength);
    let offset = 0;
    for (const part of parts) {
      result.set(part, offset);
      offset += part.length;
    }
    return result;
  }

  /**
   * Signal that no more data will be written.
   * Any pending or future read() will resolve to null once existing
   * buffered data has been consumed.
   */
  closeWriter(): void {
    this.writerClosed = true;
    if (this.pendingRead !== null) {
      const { resolve } = this.pendingRead;
      this.pendingRead = null;
      resolve(null);
    }
  }

  /**
   * Close the writer with an error. The error is propagated to the reader:
   * any pending or future read() will reject with this error.
   */
  closeWriterWithError(error: Error): void {
    this.writerClosed = true;
    this.writerError = error;
    if (this.pendingRead !== null) {
      const { reject } = this.pendingRead;
      this.pendingRead = null;
      reject(error);
    }
  }

  /**
   * Signal that the reader is no longer interested.
   * Subsequent writes will throw.
   */
  closeReader(): void {
    this.readerClosed = true;
    this.chunks = [];
    this.pendingRead = null;
  }

  isWriterClosed(): boolean {
    return this.writerClosed;
  }

  isReaderClosed(): boolean {
    return this.readerClosed;
  }

  /**
   * Makes the Pipe an AsyncIterable so it can be consumed with `for await...of`.
   * Each iteration yields the next available chunk; iteration ends when the
   * writer closes and all buffered data has been consumed.
   */
  async *[Symbol.asyncIterator](): AsyncIterableIterator<Uint8Array> {
    let chunk = await this.read();
    while (chunk !== null) {
      yield chunk;
      chunk = await this.read();
    }
  }

  /**
   * Create a Pipe fed by an AsyncIterable source.
   * The source is consumed eagerly; when it completes (or throws) the
   * writer side is closed automatically.
   * If the reader side is closed early, consumption of the source stops.
   */
  static fromAsyncIterable(source: AsyncIterable<Uint8Array>): Pipe {
    const pipe = new Pipe();
    (async () => {
      try {
        for await (const chunk of source) {
          if (pipe.isReaderClosed()) {
            break;
          }
          pipe.write(chunk);
        }
        if (!pipe.isWriterClosed()) {
          pipe.closeWriter();
        }
      } catch (e) {
        if (!pipe.isWriterClosed()) {
          if (pipe.isReaderClosed()) {
            pipe.closeWriter();
          } else {
            pipe.closeWriterWithError(e instanceof Error ? e : new Error(String(e)));
          }
        }
      }
    })();
    return pipe;
  }
}
