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
import { EhUrl } from './EhUrl.ets';
import { GalleryDetail } from '../model/GalleryDetail';
import type { GalleryDetailFetcher } from '../viewmodel/GalleryDetailViewModel';

/**
 * Gallery detail fetcher backed by EhEngine.
 * Use with GalleryDetailViewModel for real network detail loading.
 */
export class EhEngineGalleryDetailFetcher implements GalleryDetailFetcher {
  constructor(private readonly engine: EhEngine) {}

  async fetchDetail(gid: number, token: string): Promise<GalleryDetail> {
    const url = EhUrl.getGalleryDetailUrl(gid, token);
    return this.engine.getGalleryDetail(url);
  }
}
