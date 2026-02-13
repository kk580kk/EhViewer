/*
 * Copyright 2016 Hippo Seven
 * Ported to HarmonyOS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { SpiderInfo, TOKEN_FAILED } from './SpiderInfo.ets';
import { SpiderDen } from './SpiderDen.ets';
import { EhUrl } from '../client/EhUrl.ets';
import { GalleryPageUrlParser } from '../client/parser/GalleryPageUrlParser.ets';
import type { GalleryPageFetcher } from '../client/EhEngineGalleryPageFetcher.ets';
import type { PreviewSet } from '../model/PreviewSet';

/**
 * Abstraction for fetching preview data from a gallery detail page.
 * Used by SpiderQueen to resolve pTokens for page indices.
 */
export interface PreviewFetcher {
  getPreviewSet(url: string): Promise<{ previewSet: PreviewSet; previewPages: number }>;
}

/**
 * Result of resolving a page's image URL.
 */
export interface PageUrlResult {
  imageUrl: string;
  skipHathKey: string;
  originImageUrl: string;
}

/**
 * SpiderQueen — orchestrates fetching image page URLs for a gallery.
 *
 * Given a SpiderInfo (containing gid, token, and cached pTokens),
 * resolves page tokens and fetches image URLs via EhEngine.
 *
 * Mirrors the core pToken-resolution and page-fetch logic from the
 * Android SpiderQueen, adapted for async/await.
 */
export class SpiderQueen {
  private readonly spiderInfo: SpiderInfo;
  private readonly spiderDen: SpiderDen;
  private readonly pageFetcher: GalleryPageFetcher;
  private readonly previewFetcher: PreviewFetcher;
  private showKey: string | null = null;

  constructor(
    spiderInfo: SpiderInfo,
    spiderDen: SpiderDen,
    pageFetcher: GalleryPageFetcher,
    previewFetcher: PreviewFetcher,
  ) {
    this.spiderInfo = spiderInfo;
    this.spiderDen = spiderDen;
    this.pageFetcher = pageFetcher;
    this.previewFetcher = previewFetcher;
  }

  getSpiderInfo(): SpiderInfo {
    return this.spiderInfo;
  }

  getShowKey(): string | null {
    return this.showKey;
  }

  /**
   * Get the pToken for a page index.
   * Returns from SpiderInfo cache if available, otherwise fetches from internet.
   */
  async getPToken(index: number): Promise<string> {
    if (index < 0 || index >= this.spiderInfo.pages) {
      throw new Error(`Page index out of range: ${index}`);
    }

    const cached = this.spiderInfo.pTokenMap.get(index);
    if (cached !== undefined && cached !== TOKEN_FAILED) {
      return cached;
    }

    return this.fetchPTokenFromInternet(index);
  }

  /**
   * Get the image URL for a page index.
   *
   * Strategy (mirrors Android SpiderWorker):
   *  1. Resolve pToken for the page
   *  2. If showKey is available, try the showpage API first
   *  3. Fall back to fetching the HTML page (which also yields a showKey)
   */
  async getPageUrl(index: number): Promise<PageUrlResult> {
    const pToken = await this.getPToken(index);

    // Try API path if we have a showKey
    if (this.showKey !== null) {
      try {
        const previousPToken = index > 0
          ? (this.spiderInfo.pTokenMap.get(index - 1) ?? null)
          : null;
        const result = await this.pageFetcher.getGalleryPageApi(
          this.spiderInfo.gid, index, pToken, this.showKey, previousPToken,
        );
        return {
          imageUrl: result.imageUrl,
          skipHathKey: result.skipHathKey,
          originImageUrl: result.originImageUrl,
        };
      } catch (e: unknown) {
        // Key mismatch — clear showKey and fall through to HTML fetch
        if (e instanceof Error && e.message === 'Key mismatch') {
          this.showKey = null;
        } else {
          throw e;
        }
      }
    }

    // Fetch via HTML page
    const pageUrl = EhUrl.getPageUrl(this.spiderInfo.gid, index, pToken);
    const result = await this.pageFetcher.getGalleryPage(
      pageUrl, this.spiderInfo.gid, this.spiderInfo.token,
    );
    this.showKey = result.showKey;
    return {
      imageUrl: result.imageUrl,
      skipHathKey: result.skipHathKey,
      originImageUrl: result.originImageUrl,
    };
  }

  // ---- Internal pToken resolution ----

  /**
   * Fetch the pToken for a page by loading the appropriate gallery preview page.
   * If the first attempt fails (e.g. previewPerPage changed), retries once.
   */
  private async fetchPTokenFromInternet(index: number): Promise<string> {
    const previewIndex = this.computePreviewIndex(index);
    const url = EhUrl.getGalleryDetailUrl(
      this.spiderInfo.gid, this.spiderInfo.token, previewIndex,
    );

    const { previewSet, previewPages } = await this.previewFetcher.getPreviewSet(url);
    this.spiderInfo.previewPages = previewPages;
    this.readPreviews(previewSet, previewIndex);
    this.spiderDen.writeSpiderInfo(this.spiderInfo);

    const pToken = this.spiderInfo.pTokenMap.get(index);
    if (pToken !== undefined && pToken !== TOKEN_FAILED) {
      return pToken;
    }

    // Retry: previewPerPage may have changed after readPreviews
    const retryPreviewIndex = this.computePreviewIndex(index);
    if (retryPreviewIndex !== previewIndex) {
      const retryUrl = EhUrl.getGalleryDetailUrl(
        this.spiderInfo.gid, this.spiderInfo.token, retryPreviewIndex,
      );
      const retry = await this.previewFetcher.getPreviewSet(retryUrl);
      this.spiderInfo.previewPages = retry.previewPages;
      this.readPreviews(retry.previewSet, retryPreviewIndex);
      this.spiderDen.writeSpiderInfo(this.spiderInfo);

      const retryPToken = this.spiderInfo.pTokenMap.get(index);
      if (retryPToken !== undefined && retryPToken !== TOKEN_FAILED) {
        return retryPToken;
      }
    }

    throw new Error(`Failed to get pToken for page ${index}`);
  }

  /**
   * Calculate which preview page contains pTokens for the given page index.
   */
  private computePreviewIndex(index: number): number {
    let previewIndex = 0;
    if (this.spiderInfo.previewPerPage > 0) {
      previewIndex = Math.floor(index / this.spiderInfo.previewPerPage);
    }
    if (this.spiderInfo.previewPages > 0) {
      previewIndex = Math.min(previewIndex, this.spiderInfo.previewPages - 1);
    }
    return previewIndex;
  }

  /**
   * Extract pTokens from a preview set and store them in SpiderInfo.
   * Also updates previewPerPage based on the preview set size.
   *
   * Mirrors the Android SpiderQueen.readPreviews() method.
   */
  private readPreviews(previewSet: PreviewSet, previewIndex: number): void {
    if (previewSet.size() > 0) {
      if (previewIndex === 0) {
        this.spiderInfo.previewPerPage = previewSet.size();
      } else {
        this.spiderInfo.previewPerPage = Math.floor(
          previewSet.getPosition(0) / previewIndex,
        );
      }
    }

    for (let i = 0; i < previewSet.size(); i++) {
      const pageUrl = previewSet.getPageUrlAt(i);
      const result = GalleryPageUrlParser.parse(pageUrl);
      if (result !== null) {
        this.spiderInfo.pTokenMap.set(result.page, result.pToken);
      }
    }
  }
}
