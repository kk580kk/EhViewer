/*
 * Copyright 2019 Hippo Seven
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.hippo.ehviewer.gallery;

import androidx.annotation.NonNull;
import com.hippo.streampipe.InputStreamPipe;
import com.hippo.streampipe.OutputStreamPipe;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

/**
 * A thread-safe, bounded ring-buffer pipe that connects an {@link OutputStream}
 * (producer) to an {@link InputStream} (consumer) across threads.
 * <p>
 * Also provides adapters to the {@link InputStreamPipe} and {@link OutputStreamPipe}
 * interfaces used by the spider download/cache system.
 */
public class Pipe {

  private final int capacity;
  private final byte[] buffer;

  private int head = 0;
  private int tail = 0;
  private boolean full = false;

  private boolean inClosed = false;
  private boolean outClosed = false;

  private final InputStream inputStream = new PipeInputStream();
  private final OutputStream outputStream = new PipeOutputStream();

  public Pipe(int capacity) {
    if (capacity <= 0) {
      throw new IllegalArgumentException("capacity must be positive: " + capacity);
    }
    this.capacity = capacity;
    this.buffer = new byte[capacity];
  }

  public InputStream getInputStream() {
    return inputStream;
  }

  public OutputStream getOutputStream() {
    return outputStream;
  }

  /**
   * Returns an {@link InputStreamPipe} adapter backed by this Pipe's InputStream.
   * This allows the Pipe to be used where InputStreamPipe is expected (e.g. SpiderQueen decode).
   */
  public InputStreamPipe getInputStreamPipe() {
    return new PipeInputStreamPipe();
  }

  /**
   * Returns an {@link OutputStreamPipe} adapter backed by this Pipe's OutputStream.
   * This allows the Pipe to be used where OutputStreamPipe is expected (e.g. SpiderDen write).
   */
  public OutputStreamPipe getOutputStreamPipe() {
    return new PipeOutputStreamPipe();
  }

  /**
   * Returns the number of bytes currently available for reading without blocking.
   */
  synchronized int available() {
    if (full) {
      return capacity;
    }
    if (tail >= head) {
      return tail - head;
    }
    return capacity - head + tail;
  }

  private class PipeInputStream extends InputStream {
    @Override
    public int read() throws IOException {
      synchronized (Pipe.this) {
        for (;;) {
          if (inClosed) {
            throw new IOException("The InputStream is closed");
          }

          if (head == tail && !full) {
            if (outClosed) {
              return -1;
            } else {
              try {
                Pipe.this.wait();
              } catch (InterruptedException e) {
                throw new IOException("The thread interrupted", e);
              }
            }
          } else {
            int b = buffer[head] & 0xFF;
            head++;
            if (head == capacity) {
              head = 0;
            }
            full = false;
            Pipe.this.notifyAll();
            return b;
          }
        }
      }
    }

    @Override
    public int read(@NonNull byte[] b, int off, int len) throws IOException {
      if (b == null) {
        throw new NullPointerException("b == null");
      }
      if (off < 0 || len < 0 || off + len > b.length) {
        throw new IndexOutOfBoundsException();
      }
      synchronized (Pipe.this) {
        for (;;) {
          if (inClosed) {
            throw new IOException("The InputStream is closed");
          }
          if (len == 0) {
            return 0;
          }

          if (head == tail && !full) {
            if (outClosed) {
              return -1;
            } else {
              try {
                Pipe.this.wait();
              } catch (InterruptedException e) {
                throw new IOException("The thread interrupted", e);
              }
            }
          } else {
            int read = Math.min(len, (head < tail ? tail : capacity) - head);
            System.arraycopy(buffer, head, b, off, read);
            head += read;
            if (head == capacity) {
              head = 0;
            }
            full = false;
            Pipe.this.notifyAll();
            return read;
          }
        }
      }
    }

    @Override
    public int available() {
      return Pipe.this.available();
    }

    @Override
    public void close() {
      synchronized (Pipe.this) {
        inClosed = true;
        Pipe.this.notifyAll();
      }
    }
  }

  private class PipeOutputStream extends OutputStream {
    @Override
    public void write(int b) throws IOException {
      synchronized (Pipe.this) {
        for (;;) {
          if (outClosed) {
            throw new IOException("The OutputStream is closed");
          }
          if (inClosed) {
            throw new IOException("The InputStream is closed");
          }

          if (head == tail && full) {
            try {
              Pipe.this.wait();
            } catch (InterruptedException e) {
              throw new IOException("The thread interrupted", e);
            }
          } else {
            buffer[tail] = (byte) b;
            tail++;
            if (tail == capacity) {
              tail = 0;
            }
            if (head == tail) {
              full = true;
            }
            Pipe.this.notifyAll();
            return;
          }
        }
      }
    }

    @Override
    public void write(@NonNull byte[] b, int off, int len) throws IOException {
      if (b == null) {
        throw new NullPointerException("b == null");
      }
      if (off < 0 || len < 0 || off + len > b.length) {
        throw new IndexOutOfBoundsException();
      }
      synchronized (Pipe.this) {
        while (len != 0) {
          if (outClosed) {
            throw new IOException("The OutputStream is closed");
          }
          if (inClosed) {
            throw new IOException("The InputStream is closed");
          }

          if (head == tail && full) {
            try {
              Pipe.this.wait();
            } catch (InterruptedException e) {
              throw new IOException("The thread interrupted", e);
            }
          } else {
            int write = Math.min(len, (head <= tail ? capacity : head) - tail);
            System.arraycopy(b, off, buffer, tail, write);
            off += write;
            len -= write;
            tail += write;
            if (tail == capacity) {
              tail = 0;
            }
            if (head == tail) {
              full = true;
            }
            Pipe.this.notifyAll();
          }
        }
      }
    }

    @Override
    public void close() {
      synchronized (Pipe.this) {
        outClosed = true;
        Pipe.this.notifyAll();
      }
    }
  }

  /**
   * Adapter that exposes this Pipe's InputStream as an {@link InputStreamPipe}.
   * Single-use: the underlying stream can only be consumed once.
   */
  private class PipeInputStreamPipe implements InputStreamPipe {
    @Override
    public void obtain() {
      // No resource acquisition needed for in-memory pipe
    }

    @Override
    public void release() {
      // No resource release needed for in-memory pipe
    }

    @NonNull
    @Override
    public InputStream open() {
      return inputStream;
    }

    @Override
    public void close() {
      inputStream.close();
    }
  }

  /**
   * Adapter that exposes this Pipe's OutputStream as an {@link OutputStreamPipe}.
   * Single-use: the underlying stream can only be written once.
   */
  private class PipeOutputStreamPipe implements OutputStreamPipe {
    @Override
    public void obtain() {
      // No resource acquisition needed for in-memory pipe
    }

    @Override
    public void release() {
      // No resource release needed for in-memory pipe
    }

    @NonNull
    @Override
    public OutputStream open() {
      return outputStream;
    }

    @Override
    public void close() {
      outputStream.close();
    }
  }
}
