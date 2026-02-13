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
import type { GalleryListFetcher, GalleryListResult } from '../viewmodel/GalleryListViewModel';

/**
 * Gallery list fetcher backed by EhEngine.
 * Use with GalleryListViewModel for real network list loading.
 */
export class EhEngineGalleryListFetcher implements GalleryListFetcher {
  readonly engine: EhEngine;

  constructor(engine: EhEngine) {
    this.engine = engine;
  }

  async fetchList(url: string): Promise<GalleryListResult> {
    const result = await this.engine.getGalleryList(url, true);
    return {
      items: result.galleryInfoList,
      hasNextPage: result.nextPage > 0,
    };
  }
}
