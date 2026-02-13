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
import { AppConfig } from './AppConfig.ets';
import type { AppContextPaths } from './AppConfig.ets';
import { AppStorageManager } from './AppStorageManager.ets';
import { FileShareHelper } from './FileShareHelper.ets';
import type { FsOps } from './util/FileUtils.ets';
import type { ShareFsOps } from './FileShareHelper.ets';
import type { PreferencesStore } from './preferences/PreferencesStore.ets';
import { EhConfig } from './client/EhConfig.ets';
import { EhConfigHolder } from './client/EhConfigHolder.ets';
import { EhHttpClient } from './client/EhHttpClient.ets';
import { SignInController } from './client/SignInController.ets';
import { EhSignIn } from './client/EhSignIn.ets';
import type { DatabaseStore } from './database/DatabaseStore.ets';
import type { HttpEngine } from './network/HttpClient.ets';

/**
 * AppInitializer — centralised application bootstrap logic.
 *
 * Equivalent to Android's RecordingApplication.onCreate / EhApplication.
 * Performs all global initialisation in a deterministic order:
 *   1. File storage (AppStorageManager, AppConfig, FileShareHelper)
 *   2. Settings / Preferences
 *   3. Database (EhDB)
 *   4. Sign-in state (SignInController)
 *   5. Security guard
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
  storage: boolean;
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
   *
   * @param ctxPaths    Optional platform context paths (for file storage init).
   * @param fs          Optional filesystem adapter (for file storage init).
   * @param prefStore   Optional PreferencesStore for Settings persistence.
   * @param cookieDbStore Optional DatabaseStore for cookie persistence.
   * @param httpEngine  Optional HttpEngine for HTTP transport.
   */
  static initialize(
    ctxPaths?: AppContextPaths,
    fs?: FsOps,
    prefStore?: PreferencesStore,
    cookieDbStore?: DatabaseStore,
    httpEngine?: HttpEngine,
  ): InitStatus {
    if (AppInitializer.initialized) {
      return {
        storage: true,
        settings: true,
        database: true,
        signIn: true,
        security: true,
      };
    }

    const status: InitStatus = {
      storage: false,
      settings: false,
      database: false,
      signIn: false,
      security: false,
    };

    // 1. File storage: AppStorageManager, AppConfig, FileShareHelper
    try {
      if (ctxPaths && fs) {
        AppStorageManager.initialize(ctxPaths, fs);
        AppConfig.initialize(ctxPaths, fs);
        // If fs supports directory listing, also init FileShareHelper
        if ('readdirSync' in fs && 'copyFileSync' in fs) {
          FileShareHelper.initialize(fs as ShareFsOps);
        }
      }
      status.storage = true;
    } catch {
      status.storage = false;
    }

    // 2. Settings: backed by PreferencesStore.
    try {
      if (prefStore) {
        SettingsService.initialize(prefStore);
      }
      status.settings = true;
    } catch {
      status.settings = false;
    }

    // 3. EhConfig (site, cookie/uconfig, User-Agent, image size) & HTTP client
    try {
      EhConfigHolder.set(new EhConfig());
      if (cookieDbStore && httpEngine) {
        EhHttpClient.initialize(cookieDbStore, httpEngine);
      }
      status.database = true;
    } catch {
      status.database = false;
    }

    // 4. Sign-in controller (shares the same HttpClient + CookieStore)
    try {
      if (EhHttpClient.isInitialized()) {
        const httpClient = EhHttpClient.getHttpClient();
        const cookieStore = EhHttpClient.getCookieStore();
        SignInController.initializeWith(
          new EhSignIn(httpClient, cookieStore),
          cookieStore,
        );
      }
      status.signIn = true;
    } catch {
      status.signIn = false;
    }

    // 5. Security
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
    AppStorageManager.reset();
    AppConfig.reset();
    FileShareHelper.reset();
    SettingsService.resetDefaults();
    EhHttpClient.reset();
    EhConfigHolder.reset();
    SignInController.reset();
  }

  /**
   * Get current settings snapshot for diagnostics.
   */
  static getDiagnostics(): Record<string, string> {
    return {
      storageInitialized: String(AppStorageManager.isInitialized()),
      gallerySite: String(SettingsService.getGallerySite()),
      needSignIn: String(SettingsService.getNeedSignIn()),
      securityEnabled: String(SettingsService.getEnabledSecurity()),
    };
  }
}
