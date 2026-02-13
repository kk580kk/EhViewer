/*
 * Copyright 2024 EhViewer Contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import type { SpiderQueen, PageUrlResult } from './SpiderQueen.ets';
import type { SpiderDen } from './SpiderDen.ets';
import { MODE_DOWNLOAD } from './SpiderDen.ets';

/**
 * Result of fetching raw image data from a URL.
 */
export interface ImageFetchResult {
  /** Raw image bytes. */
  data: Uint8Array;
  /** MIME content type, e.g. 'image/jpeg'. */
  contentType: string;
}

/**
 * Fetches raw image data from a URL.
 * Abstraction over HTTP so the download logic is testable.
 */
export interface ImageFetcher {
  fetchImage(url: string, referer?: string): Promise<ImageFetchResult>;
}

/**
 * Listener for per-page progress during sequential downloading.
 */
export interface ImageDownloadListener {
  /** Called when a page begins downloading. */
  onPageStart(index: number, total: number): void;
  /** Called when a page is downloaded and saved successfully. */
  onPageSuccess(index: number, finished: number, downloaded: number, total: number): void;
  /** Called when a page fails. */
  onPageFailure(index: number, error: string, finished: number, downloaded: number, total: number): void;
  /** Called when the entire download completes (all pages attempted). */
  onFinish(finished: number, downloaded: number, total: number): void;
}

/** Map MIME content type to file extension (without dot). */
function extensionFromContentType(contentType: string): string {
  const lower = contentType.toLowerCase();
  if (lower.includes('jpeg') || lower.includes('jpg')) return 'jpg';
  if (lower.includes('png')) return 'png';
  if (lower.includes('gif')) return 'gif';
  if (lower.includes('webp')) return 'webp';
  return 'jpg'; // default
}

/**
 * State constants for individual page download status.
 */
export const PageState = {
  NONE: 0,
  DOWNLOADING: 1,
  FINISHED: 2,
  FAILED: 3,
} as const;

export type PageState = (typeof PageState)[keyof typeof PageState];

/**
 * Downloads all images of a gallery sequentially (page 0, 1, 2, ...)
 * and writes each to local storage via SpiderDen.
 *
 * Mirrors the Android SpiderWorker download loop, adapted for
 * async/await with a single-worker sequential model.
 *
 * Usage:
 *   const downloader = new ImageDownloader(queen, den, fetcher);
 *   downloader.addListener(myListener);
 *   await downloader.downloadAll();
 */
export class ImageDownloader {
  private readonly queen: SpiderQueen;
  private readonly den: SpiderDen;
  private readonly fetcher: ImageFetcher;
  private readonly listeners: ImageDownloadListener[] = [];
  private readonly maxRetries: number;

  private cancelled: boolean = false;

  /** Per-page state tracking. */
  private pageStates: PageState[] = [];
  private finished: number = 0;
  private downloaded: number = 0;

  constructor(
    queen: SpiderQueen,
    den: SpiderDen,
    fetcher: ImageFetcher,
    maxRetries: number = 2,
  ) {
    this.queen = queen;
    this.den = den;
    this.fetcher = fetcher;
    this.maxRetries = maxRetries;
  }

  addListener(listener: ImageDownloadListener): void {
    this.listeners.push(listener);
  }

  removeListener(listener: ImageDownloadListener): void {
    const idx = this.listeners.indexOf(listener);
    if (idx >= 0) this.listeners.splice(idx, 1);
  }

  /** Cancel the ongoing download. Pages already written are kept. */
  cancel(): void {
    this.cancelled = true;
  }

  isCancelled(): boolean {
    return this.cancelled;
  }

  getFinished(): number {
    return this.finished;
  }

  getDownloaded(): number {
    return this.downloaded;
  }

  getPageStates(): ReadonlyArray<PageState> {
    return this.pageStates;
  }

  /**
   * Download all pages sequentially from 0 to total-1.
   * Skips pages already present in SpiderDen.
   * Updates progress after each page.
   */
  async downloadAll(): Promise<void> {
    const total = this.queen.getSpiderInfo().pages;
    if (total <= 0) {
      this.notifyFinish(0, 0, 0);
      return;
    }

    // Ensure SpiderDen is in download mode
    this.den.setMode(MODE_DOWNLOAD);

    // Init state tracking
    this.pageStates = new Array<PageState>(total).fill(PageState.NONE);
    this.finished = 0;
    this.downloaded = 0;

    for (let index = 0; index < total; index++) {
      if (this.cancelled) break;

      // Skip if already downloaded
      if (this.den.containImage(index)) {
        this.pageStates[index] = PageState.FINISHED;
        this.finished++;
        this.downloaded++;
        this.notifyPageSuccess(index, this.finished, this.downloaded, total);
        continue;
      }

      this.pageStates[index] = PageState.DOWNLOADING;
      this.notifyPageStart(index, total);

      const success = await this.downloadPage(index, total);
      if (success) {
        this.pageStates[index] = PageState.FINISHED;
        this.finished++;
        this.downloaded++;
        this.notifyPageSuccess(index, this.finished, this.downloaded, total);
      } else {
        this.pageStates[index] = PageState.FAILED;
        this.downloaded++;
        // Error message already notified inside downloadPage
      }
    }

    this.notifyFinish(this.finished, this.downloaded, total);
  }

  /**
   * Download a single page with retries.
   * Returns true if the page was saved successfully.
   */
  private async downloadPage(index: number, total: number): Promise<boolean> {
    let lastError = '';

    for (let attempt = 0; attempt <= this.maxRetries; attempt++) {
      if (this.cancelled) {
        lastError = 'Cancelled';
        break;
      }

      try {
        // 1. Resolve image URL via SpiderQueen
        const pageResult: PageUrlResult = await this.queen.getPageUrl(index);
        const imageUrl = pageResult.originImageUrl || pageResult.imageUrl;

        if (!imageUrl) {
          lastError = 'Empty image URL';
          continue;
        }

        // 2. Fetch image bytes
        const fetchResult = await this.fetcher.fetchImage(imageUrl);

        if (fetchResult.data.length === 0) {
          lastError = 'Empty image data';
          continue;
        }

        // 3. Determine file extension from content type
        const extension = extensionFromContentType(fetchResult.contentType);

        // 4. Save to SpiderDen
        const saved = this.den.saveImage(index, fetchResult.data, extension);
        if (!saved) {
          lastError = 'Failed to write image to disk';
          continue;
        }

        return true;
      } catch (e: unknown) {
        lastError = e instanceof Error ? e.message : String(e);
      }
    }

    this.notifyPageFailure(index, lastError, this.finished, this.downloaded + 1, total);
    return false;
  }

  // ---- Listener notification helpers ----

  private notifyPageStart(index: number, total: number): void {
    for (const l of this.listeners) {
      l.onPageStart(index, total);
    }
  }

  private notifyPageSuccess(index: number, finished: number, downloaded: number, total: number): void {
    for (const l of this.listeners) {
      l.onPageSuccess(index, finished, downloaded, total);
    }
  }

  private notifyPageFailure(index: number, error: string, finished: number, downloaded: number, total: number): void {
    for (const l of this.listeners) {
      l.onPageFailure(index, error, finished, downloaded, total);
    }
  }

  private notifyFinish(finished: number, downloaded: number, total: number): void {
    for (const l of this.listeners) {
      l.onFinish(finished, downloaded, total);
    }
  }
}
