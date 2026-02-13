/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { HttpClient } from '../network/HttpClient.ets';
import type { HttpEngine } from '../network/HttpClient.ets';
import { CookieDatabase } from '../network/CookieDatabase.ets';
import { EhConfigHolder } from './EhConfigHolder.ets';
import { EhCookieStore } from './EhCookieStore.ets';
import type { DatabaseStore } from '../database/DatabaseStore.ets';

/**
 * EhHttpClient — application-level singleton that wires together:
 *   - CookieDatabase (persistent cookie storage backed by DatabaseStore)
 *   - EhCookieStore (app-specific cookie logic: auth persistence, tips cookie)
 *   - HttpClient (HTTP transport with automatic cookie attach/save)
 *
 * After `initialize()`, all HTTP requests made through `getHttpClient()`
 * automatically carry persisted cookies and save new ones from responses.
 */
export class EhHttpClient {
  private static cookieDb: CookieDatabase | null = null;
  private static cookieStore: EhCookieStore | null = null;
  private static httpClient: HttpClient | null = null;

  /**
   * Initialize the singleton with a DatabaseStore and HttpEngine.
   *
   * @param dbStore   Database for cookie persistence (production: RelationalDatabaseStore).
   * @param engine    HTTP transport engine (production: OhosHttpEngine).
   */
  static initialize(dbStore: DatabaseStore, engine: HttpEngine): void {
    const cookieDb = new CookieDatabase(dbStore);
    const cookieStore = new EhCookieStore(cookieDb);
    const config = EhConfigHolder.get();
    const httpClient = new HttpClient({
      engine,
      cookieJar: cookieStore,
      defaultHeaders: { 'User-Agent': config.userAgent },
    });

    EhHttpClient.cookieDb = cookieDb;
    EhHttpClient.cookieStore = cookieStore;
    EhHttpClient.httpClient = httpClient;
  }

  /** Get the shared HttpClient (cookies are automatically managed). */
  static getHttpClient(): HttpClient {
    if (!EhHttpClient.httpClient) {
      throw new Error('EhHttpClient not initialized. Call initialize() first.');
    }
    return EhHttpClient.httpClient;
  }

  /** Get the shared EhCookieStore (for sign-in checks, sign-out, etc.). */
  static getCookieStore(): EhCookieStore {
    if (!EhHttpClient.cookieStore) {
      throw new Error('EhHttpClient not initialized. Call initialize() first.');
    }
    return EhHttpClient.cookieStore;
  }

  /** Whether the singleton has been initialized. */
  static isInitialized(): boolean {
    return EhHttpClient.httpClient !== null;
  }

  /** Reset state (for testing). */
  static reset(): void {
    EhHttpClient.cookieDb = null;
    EhHttpClient.cookieStore = null;
    EhHttpClient.httpClient = null;
  }
}
