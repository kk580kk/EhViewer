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
import window from '@ohos.window';
import { SignInController } from '../client/SignInController.ets';
import { Routes } from '../router/PageRouter.ets';
import { AppInitializer } from '../AppInitializer.ets';

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

  onCreate(want, launchParam): void {
    // Run the full global initialization sequence
    const status = AppInitializer.initialize();

    if (!status.settings) {
      // Settings init failed — log or handle gracefully
    }
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
    // Cleanup: reset initializer state
    // In production: close database connections, cancel pending tasks
  }
}
