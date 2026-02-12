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

/**
 * Application entry ability.
 *
 * Equivalent to Android's Application.onCreate + MainActivity.onCreate:
 *  - Initialises global services (Settings, EhDB) on create
 *  - Loads the main page with bottom tab navigation
 *  - Handles lifecycle events (foreground / background)
 */
export default class EntryAbility extends UIAbility {
  onCreate(want, launchParam): void {
    // Global initialisation placeholder:
    //  - SettingsService.initialize(context)
    //  - EhDB.initialize(context)
    //  - SecurityGuard setup
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      if (err) {
        return;
      }
    });
  }

  onForeground(): void {
    // App moved to foreground — check security lock if needed
    // if (SecurityGuard.shouldShowLockScreen()) { ... }
  }

  onBackground(): void {
    // App moved to background — record timestamp for lock timeout
  }

  onDestroy(): void {
    // Cleanup: close database connections, cancel pending tasks
  }
}
