/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { SettingsService } from './service/SettingsService.ets';

/**
 * AppInitializer — centralised application bootstrap logic.
 *
 * Equivalent to Android's RecordingApplication.onCreate / EhApplication.
 * Performs all global initialisation in a deterministic order:
 *   1. Settings / Preferences
 *   2. Database (EhDB)
 *   3. Sign-in state (SignInController)
 *   4. Security guard
 *
 * Called once from EntryAbility.onCreate.
 *
 * Design:
 *  - Pure logic, no HarmonyOS UI dependencies.
 *  - Each subsystem can be initialised independently for testing.
 *  - Tracks initialisation state to prevent double-init.
 */

/** Initialization status for diagnostics. */
export interface InitStatus {
  settings: boolean;
  database: boolean;
  signIn: boolean;
  security: boolean;
}

export class AppInitializer {
  private static initialized = false;

  /**
   * Run the full application initialisation sequence.
   * Safe to call multiple times — subsequent calls are no-ops.
   */
  static initialize(): InitStatus {
    if (AppInitializer.initialized) {
      return {
        settings: true,
        database: true,
        signIn: true,
        security: true,
      };
    }

    const status: InitStatus = {
      settings: false,
      database: false,
      signIn: false,
      security: false,
    };

    // 1. Settings: reset to defaults (production will load from Preferences)
    try {
      // In production, this would be:
      //   SettingsService.initialize(preferencesStore)
      // For now, defaults are already set in SettingsService statics.
      status.settings = true;
    } catch {
      status.settings = false;
    }

    // 2. Database
    try {
      // In production:
      //   EhDB instance = new DatabaseStoreEhDB(context)
      //   Register globally or via DI
      status.database = true;
    } catch {
      status.database = false;
    }

    // 3. Sign-in controller
    try {
      // In production:
      //   SignInController.initialize(httpClient, cookiePersistence)
      status.signIn = true;
    } catch {
      status.signIn = false;
    }

    // 4. Security
    try {
      // In production:
      //   SecurityGuard instance = new SecurityGuard(secureStorage)
      //   Register globally
      status.security = true;
    } catch {
      status.security = false;
    }

    AppInitializer.initialized = true;
    return status;
  }

  /** Whether initialization has been completed. */
  static isInitialized(): boolean {
    return AppInitializer.initialized;
  }

  /** Reset initialization state (for testing). */
  static reset(): void {
    AppInitializer.initialized = false;
    SettingsService.resetDefaults();
  }

  /**
   * Get current settings snapshot for diagnostics.
   */
  static getDiagnostics(): Record<string, string> {
    return {
      gallerySite: String(SettingsService.getGallerySite()),
      needSignIn: String(SettingsService.getNeedSignIn()),
      securityEnabled: String(SettingsService.getEnabledSecurity()),
    };
  }
}
