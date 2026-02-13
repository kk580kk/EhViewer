/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { Logger } from '../util/Logger.ets';
import type { BackgroundTaskHandle } from '../download/DownloadService.ets';

const log = Logger.tag('OhosBackgroundTaskHandle');

/**
 * Abstraction over HarmonyOS backgroundTaskManager APIs.
 *
 * Production: pass a real implementation backed by
 * @ohos.resourceschedule.backgroundTaskManager.
 * Tests: supply a mock/spy.
 */
export interface BackgroundTaskManagerApi {
  /**
   * Start a continuous background running task (e.g. data transfer).
   * Maps to backgroundTaskManager.startBackgroundRunning(context, bgMode, wantAgent).
   *
   * @returns Promise that resolves when background running is granted.
   */
  startBackgroundRunning(): Promise<void>;

  /**
   * Stop background running.
   * Maps to backgroundTaskManager.stopBackgroundRunning(context).
   *
   * @returns Promise that resolves when background running is released.
   */
  stopBackgroundRunning(): Promise<void>;
}

/**
 * HarmonyOS implementation of BackgroundTaskHandle.
 *
 * Wraps the platform backgroundTaskManager API so that DownloadService can
 * request/cancel background execution without directly depending on
 * HarmonyOS system APIs.
 *
 * Key behaviors:
 * - Tracks running state to avoid redundant start/stop calls
 * - Logs errors but does not throw (best-effort background running)
 * - Safe to call requestBackgroundRunning() multiple times (idempotent)
 */
export class OhosBackgroundTaskHandle implements BackgroundTaskHandle {
  private readonly api: BackgroundTaskManagerApi;
  private running: boolean = false;

  constructor(api: BackgroundTaskManagerApi) {
    this.api = api;
  }

  requestBackgroundRunning(): void {
    if (this.running) {
      return;
    }
    this.running = true;
    this.api.startBackgroundRunning().catch((err: Error) => {
      log.e('Failed to start background running: ' + err.message);
      this.running = false;
    });
  }

  cancelBackgroundRunning(): void {
    if (!this.running) {
      return;
    }
    this.running = false;
    this.api.stopBackgroundRunning().catch((err: Error) => {
      log.e('Failed to stop background running: ' + err.message);
    });
  }

  /** Whether background running is currently active (for testing). */
  isRunning(): boolean {
    return this.running;
  }
}
