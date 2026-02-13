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
import type { GalleryPageResult } from './parser/GalleryPageParser.ets';
import type { GalleryPageApiResult } from './parser/GalleryPageApiParser.ets';

/**
 * Abstraction for fetching gallery page data (image URLs, tokens).
 * Used by the download/spider module for image downloading.
 * Injected to allow testing without real network calls.
 */
export interface GalleryPageFetcher {
  /** Get a page token for a gallery page index. */
  getGalleryToken(gid: number, gtoken: string, page: number): Promise<string>;

  /** Get image URL from a gallery page HTML URL. */
  getGalleryPage(pageUrl: string, gid: number, token: string): Promise<GalleryPageResult>;

  /** Get image URL via the showpage API (for sequential page loading). */
  getGalleryPageApi(
    gid: number,
    index: number,
    pToken: string,
    showKey: string,
    previousPToken: string | null
  ): Promise<GalleryPageApiResult>;
}

/**
 * Gallery page fetcher backed by EhEngine.
 * Use with SpiderQueen / download module for real network image loading.
 */
export class EhEngineGalleryPageFetcher implements GalleryPageFetcher {
  readonly engine: EhEngine;

  constructor(engine: EhEngine) {
    this.engine = engine;
  }

  async getGalleryToken(gid: number, gtoken: string, page: number): Promise<string> {
    return this.engine.getGalleryToken(gid, gtoken, page);
  }

  async getGalleryPage(pageUrl: string, gid: number, token: string): Promise<GalleryPageResult> {
    return this.engine.getGalleryPage(pageUrl, gid, token);
  }

  async getGalleryPageApi(
    gid: number,
    index: number,
    pToken: string,
    showKey: string,
    previousPToken: string | null
  ): Promise<GalleryPageApiResult> {
    return this.engine.getGalleryPageApi(gid, index, pToken, showKey, previousPToken);
  }
}
