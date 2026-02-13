import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { OhosBackgroundTaskHandle } from '../../../main/ets/platform/OhosBackgroundTaskHandle.ets';
import type { BackgroundTaskManagerApi } from '../../../main/ets/platform/OhosBackgroundTaskHandle.ets';

// ---------------------------------------------------------------------------
// Mock implementation
// ---------------------------------------------------------------------------

class MockBackgroundTaskManagerApi implements BackgroundTaskManagerApi {
  startCount = 0;
  stopCount = 0;
  shouldFailStart = false;
  shouldFailStop = false;

  async startBackgroundRunning(): Promise<void> {
    this.startCount++;
    if (this.shouldFailStart) {
      throw new Error('startBackgroundRunning failed');
    }
  }

  async stopBackgroundRunning(): Promise<void> {
    this.stopCount++;
    if (this.shouldFailStop) {
      throw new Error('stopBackgroundRunning failed');
    }
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe('OhosBackgroundTaskHandle', () => {
  let api: MockBackgroundTaskManagerApi;
  let handle: OhosBackgroundTaskHandle;

  beforeEach(() => {
    api = new MockBackgroundTaskManagerApi();
    handle = new OhosBackgroundTaskHandle(api);
  });

  // =========================================================================
  // Basic lifecycle
  // =========================================================================

  describe('requestBackgroundRunning', () => {
    it('should call api.startBackgroundRunning', async () => {
      handle.requestBackgroundRunning();
      // Wait for the async call to settle
      await Promise.resolve();
      assert.strictEqual(api.startCount, 1);
    });

    it('should set running state to true', () => {
      handle.requestBackgroundRunning();
      assert.strictEqual(handle.isRunning(), true);
    });

    it('should be idempotent when already running', async () => {
      handle.requestBackgroundRunning();
      handle.requestBackgroundRunning();
      await Promise.resolve();
      assert.strictEqual(api.startCount, 1);
    });
  });

  describe('cancelBackgroundRunning', () => {
    it('should call api.stopBackgroundRunning', async () => {
      handle.requestBackgroundRunning();
      await Promise.resolve();
      handle.cancelBackgroundRunning();
      await Promise.resolve();
      assert.strictEqual(api.stopCount, 1);
    });

    it('should set running state to false', async () => {
      handle.requestBackgroundRunning();
      await Promise.resolve();
      handle.cancelBackgroundRunning();
      assert.strictEqual(handle.isRunning(), false);
    });

    it('should be no-op when not running', async () => {
      handle.cancelBackgroundRunning();
      await Promise.resolve();
      assert.strictEqual(api.stopCount, 0);
    });

    it('should be idempotent when called multiple times', async () => {
      handle.requestBackgroundRunning();
      await Promise.resolve();
      handle.cancelBackgroundRunning();
      handle.cancelBackgroundRunning();
      await Promise.resolve();
      assert.strictEqual(api.stopCount, 1);
    });
  });

  describe('isRunning', () => {
    it('should return false initially', () => {
      assert.strictEqual(handle.isRunning(), false);
    });

    it('should return true after request', () => {
      handle.requestBackgroundRunning();
      assert.strictEqual(handle.isRunning(), true);
    });

    it('should return false after cancel', () => {
      handle.requestBackgroundRunning();
      handle.cancelBackgroundRunning();
      assert.strictEqual(handle.isRunning(), false);
    });
  });

  // =========================================================================
  // Error handling
  // =========================================================================

  describe('error handling', () => {
    it('should reset running state on start failure', async () => {
      api.shouldFailStart = true;
      handle.requestBackgroundRunning();
      // Wait for the async rejection to be caught
      await new Promise(resolve => setTimeout(resolve, 10));
      assert.strictEqual(handle.isRunning(), false);
    });

    it('should not throw on start failure', () => {
      api.shouldFailStart = true;
      // Should not throw synchronously
      assert.doesNotThrow(() => {
        handle.requestBackgroundRunning();
      });
    });

    it('should not throw on stop failure', async () => {
      handle.requestBackgroundRunning();
      await Promise.resolve();
      api.shouldFailStop = true;
      // Should not throw synchronously
      assert.doesNotThrow(() => {
        handle.cancelBackgroundRunning();
      });
    });

    it('should allow retry after start failure', async () => {
      api.shouldFailStart = true;
      handle.requestBackgroundRunning();
      await new Promise(resolve => setTimeout(resolve, 10));
      assert.strictEqual(handle.isRunning(), false);

      // Retry should work
      api.shouldFailStart = false;
      handle.requestBackgroundRunning();
      await Promise.resolve();
      assert.strictEqual(handle.isRunning(), true);
      assert.strictEqual(api.startCount, 2);
    });
  });

  // =========================================================================
  // Request/cancel cycle
  // =========================================================================

  describe('request/cancel cycle', () => {
    it('should support multiple start/stop cycles', async () => {
      handle.requestBackgroundRunning();
      await Promise.resolve();
      handle.cancelBackgroundRunning();
      await Promise.resolve();
      handle.requestBackgroundRunning();
      await Promise.resolve();
      handle.cancelBackgroundRunning();
      await Promise.resolve();

      assert.strictEqual(api.startCount, 2);
      assert.strictEqual(api.stopCount, 2);
      assert.strictEqual(handle.isRunning(), false);
    });
  });
});
