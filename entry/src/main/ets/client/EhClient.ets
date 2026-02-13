/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { EhEngine } from './EhEngine.ets';
import { EhSignIn } from './EhSignIn.ets';
import { EhEngineGalleryListFetcher } from './EhEngineGalleryListFetcher.ets';
import { EhEngineGalleryDetailFetcher } from './EhEngineGalleryDetailFetcher.ets';
import type { GalleryListFetcher } from '../viewmodel/GalleryListViewModel';
import type { GalleryDetailFetcher } from '../viewmodel/GalleryDetailViewModel';
import type { HttpClient } from '../network/HttpClient.ets';
import type { EhCookieStore } from './EhCookieStore.ets';

/**
 * EhClient — application-level singleton that provides unified access
 * to EhEngine capabilities for UI, download, and gallery modules.
 *
 * Initialised during app bootstrap (AppInitializer) after EhHttpClient
 * and SignInController are ready. Consumers call:
 *   - EhClient.getEngine()  — for direct EhEngine access (download, spider)
 *   - EhClient.galleryListFetcher()  — for GalleryListViewModel
 *   - EhClient.galleryDetailFetcher() — for GalleryDetailViewModel
 */
export class EhClient {
  private static engine: EhEngine | null = null;

  /**
   * Initialize the singleton with pre-built HttpClient and EhCookieStore.
   * Constructs an EhSignIn and EhEngine internally.
   */
  static initialize(httpClient: HttpClient, cookieStore: EhCookieStore): void {
    const signIn = new EhSignIn(httpClient, cookieStore);
    EhClient.engine = new EhEngine(httpClient, signIn);
  }

  /** Initialize with a pre-built EhEngine (for testing). */
  static initializeWith(engine: EhEngine): void {
    EhClient.engine = engine;
  }

  /** Whether the singleton has been initialized. */
  static isInitialized(): boolean {
    return EhClient.engine !== null;
  }

  /** Get the shared EhEngine instance. */
  static getEngine(): EhEngine {
    if (!EhClient.engine) {
      throw new Error('EhClient not initialized. Call initialize() first.');
    }
    return EhClient.engine;
  }

  /** Create a GalleryListFetcher backed by EhEngine. */
  static galleryListFetcher(): GalleryListFetcher {
    return new EhEngineGalleryListFetcher(EhClient.getEngine());
  }

  /** Create a GalleryDetailFetcher backed by EhEngine. */
  static galleryDetailFetcher(): GalleryDetailFetcher {
    return new EhEngineGalleryDetailFetcher(EhClient.getEngine());
  }

  /** Reset state (for testing). */
  static reset(): void {
    EhClient.engine = null;
  }
}
