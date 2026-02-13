/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { GalleryInfo } from '../model/GalleryInfo';
import { EhConfig } from './EhConfig';
import type { GalleryListFetcher, GalleryListResult } from '../viewmodel/GalleryListViewModel';

/**
 * Stub fetcher that generates mock gallery list data for development.
 * Replace with EhEngineGalleryListFetcher when network layer is integrated.
 */
export class StubGalleryListFetcher implements GalleryListFetcher {
  private readonly pageSize: number;

  constructor(pageSize: number = 25) {
    this.pageSize = pageSize;
  }

  async fetchList(url: string): Promise<GalleryListResult> {
    // Simulate network delay
    await new Promise<void>((resolve) => {
      const id = setTimeout(() => { resolve(); clearTimeout(id); }, 300);
    });

    // Parse page index from URL
    const pageMatch = url.match(/[?&]page=(\d+)/);
    const page = pageMatch ? parseInt(pageMatch[1], 10) : 0;

    const categories = [
      EhConfig.DOUJINSHI, EhConfig.MANGA, EhConfig.ARTIST_CG,
      EhConfig.GAME_CG, EhConfig.WESTERN, EhConfig.NON_H,
      EhConfig.IMAGE_SET, EhConfig.COSPLAY,
    ];

    const items: GalleryInfo[] = [];
    const startGid = (page + 1) * 1000;
    for (let i = 0; i < this.pageSize; i++) {
      const gi = new GalleryInfo();
      gi.gid = startGid + i;
      gi.token = `tok_${gi.gid}`;
      gi.title = `[Artist ${gi.gid % 10}] Gallery Collection Vol.${gi.gid}`;
      gi.thumb = `https://via.placeholder.com/250x350?text=G${gi.gid}`;
      gi.category = categories[i % categories.length];
      gi.uploader = `uploader_${(gi.gid % 5) + 1}`;
      gi.rating = 2.5 + (gi.gid % 5) * 0.5;
      gi.posted = '2024-01-15';
      gi.pages = 20 + (gi.gid % 30);
      gi.generateSLang();
      items.push(gi);
    }

    // Simulate 3 pages total
    const hasNextPage = page < 2;
    return { items, hasNextPage };
  }
}
