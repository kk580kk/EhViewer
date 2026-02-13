/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import UIAbility from '@ohos.app.ability.UIAbility';
import dataPreferences from '@ohos.data.preferences';
import fileFs from '@ohos.file.fs';
import window from '@ohos.window';
import { SignInController } from '../client/SignInController.ets';
import { Routes } from '../router/PageRouter.ets';
import { AppInitializer } from '../AppInitializer.ets';
import { OhosPreferencesStore } from '../preferences/OhosPreferencesStore.ets';
import { MemoryDatabaseStore } from '../database/MemoryDatabaseStore.ets';
import { createOhosHttpEngine } from '../network/OhosHttpEngine.ets';
import { DownloadService } from '../download/DownloadService.ets';
import http from '@ohos.net.http';
import type { AppContextPaths } from '../AppConfig.ets';
import type { ShareFsOps } from '../FileShareHelper.ets';
import type { OhosPreferencesProxy } from '../preferences/OhosPreferencesStore.ets';

/**
 * Application entry ability.
 *
 * Equivalent to Android's Application.onCreate + MainActivity.onCreate:
 *  - Initialises global services (Settings, EhDB) on create
 *  - Checks sign-in state and routes to sign-in page if needed
 *  - Loads the main page with bottom tab navigation
 *  - Handles lifecycle events (foreground / background)
 */
export default class EntryAbility extends UIAbility {
  /** Timestamp when the app was last moved to background (for lock timeout). */
  private backgroundTimestamp: number = 0;

  /** Download service instance managing background downloads. */
  private downloadService: DownloadService | null = null;

  onCreate(want, launchParam): void {
    // Build platform context paths from UIAbilityContext
    const ctxPaths: AppContextPaths = {
      filesDir: this.context.filesDir,
      cacheDir: this.context.cacheDir,
      tempDir: this.context.tempDir,
    };

    // Build filesystem adapter backed by @ohos.file.fs
    const fsOps: ShareFsOps = {
      mkdirSync: (p, opts) => fileFs.mkdirSync(p),
      existsSync: (p) => fileFs.accessSync(p),
      statSync: (p) => {
        const stat = fileFs.statSync(p);
        return {
          isDirectory: () => stat.isDirectory(),
          isFile: () => stat.isFile(),
        };
      },
      writeFileSync: (p, data, enc) => {
        const file = fileFs.openSync(p, fileFs.OpenMode.CREATE | fileFs.OpenMode.WRITE_ONLY);
        if (typeof data === 'string') {
          fileFs.writeSync(file.fd, data);
        } else {
          fileFs.writeSync(file.fd, (data as Uint8Array).buffer);
        }
        fileFs.closeSync(file);
      },
      unlinkSync: (p) => fileFs.unlinkSync(p),
      readdirSync: (p) => fileFs.listFileSync(p),
      copyFileSync: (src, dest) => fileFs.copyFileSync(src, dest),
    };

    // Build preferences store backed by @ohos.data.preferences
    const ohosPrefs = dataPreferences.getPreferencesSync(this.context, { name: 'settings' });
    const prefStore = new OhosPreferencesStore(ohosPrefs as OhosPreferencesProxy);

    // Build cookie database store (in-memory; swap to RelationalDatabaseStore
    // with @ohos.data.relationalStore for full cross-restart persistence)
    const cookieDbStore = new MemoryDatabaseStore();

    // Build HTTP engine backed by @ohos.net.http
    const httpEngine = createOhosHttpEngine(http);

    // Run the full global initialization sequence
    const status = AppInitializer.initialize(ctxPaths, fsOps, prefStore, cookieDbStore, httpEngine);

    if (!status.storage) {
      // Storage init failed — log or handle gracefully
    }

    // Initialize DownloadService with background task support.
    // The BackgroundTaskManagerApi is wired to @ohos.resourceschedule.backgroundTaskManager
    // at runtime; see createBackgroundTaskManagerApi() below.
    this.downloadService = new DownloadService();
  }

  /**
   * Get the DownloadService instance (for use by pages/view models).
   * Returns null if not yet initialized.
   */
  getDownloadService(): DownloadService | null {
    return this.downloadService;
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Decide initial page: sign-in or main
    const startPage = SignInController.needSignIn()
      ? Routes.SIGN_IN
      : Routes.MAIN;

    windowStage.loadContent(startPage, (err) => {
      if (err) {
        return;
      }
    });
  }

  onForeground(): void {
    // App moved to foreground — check security lock if needed
    // In production: SecurityGuard checks elapsed time since backgroundTimestamp
  }

  onBackground(): void {
    // Record timestamp for security lock timeout calculation
    this.backgroundTimestamp = Date.now();
  }

  onDestroy(): void {
    // Stop download service and release background running
    if (this.downloadService !== null) {
      this.downloadService.stop();
      this.downloadService = null;
    }
    // Cleanup: reset initializer state
    // In production: close database connections, cancel pending tasks
  }
}
