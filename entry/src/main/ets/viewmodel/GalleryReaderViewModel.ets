/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import type { GalleryProvider2 } from '../gallery/GalleryProvider2';
import type { GalleryProviderListener } from '../gallery/GalleryProvider';
import { GallerySource } from '../gallery/GallerySource';
import type { ReaderState } from '../gallery/ReaderState';
import { MutableReaderState } from '../gallery/ReaderState';

/** Reading direction / layout mode. */
export type ReadingMode = typeof ReadingMode[keyof typeof ReadingMode];
export const ReadingMode = {
  LEFT_TO_RIGHT: 0,
  RIGHT_TO_LEFT: 1,
  TOP_TO_BOTTOM: 2,
} as const;

/** State of a single page in the reader. */
export type PageState = typeof PageState[keyof typeof PageState];
export const PageState = {
  WAITING: 0,
  LOADING: 1,
  READY: 2,
  FAILED: 3,
} as const;

/** Information about a single page's state. */
export interface PageInfo {
  index: number;
  state: PageState;
  progress: number; // 0.0 – 1.0
  error: string;
}

/**
 * ViewModel for GalleryReaderPage.
 *
 * Manages:
 *  - current page index and total pages
 *  - reading mode (LTR / RTL / vertical scroll)
 *  - page states (waiting / loading / ready / failed)
 *  - reading progress persistence via GalleryProvider
 *  - toolbar visibility
 */
export class GalleryReaderViewModel implements GalleryProviderListener {
  private _provider: GalleryProvider2 | null = null;
  private _currentPage: number = 0;
  private _totalPages: number = 0;
  private _readingMode: ReadingMode = ReadingMode.LEFT_TO_RIGHT;
  private _toolbarVisible: boolean = false;
  private _pageStates: Map<number, PageInfo> = new Map();
  private _started: boolean = false;
  private _onChange: (() => void) | null = null;
  private _readerState: MutableReaderState = new MutableReaderState(GallerySource.EH);

  // ---- Getters ----

  get currentPage(): number {
    return this._currentPage;
  }

  get totalPages(): number {
    return this._totalPages;
  }

  get readingMode(): ReadingMode {
    return this._readingMode;
  }

  get toolbarVisible(): boolean {
    return this._toolbarVisible;
  }

  get isStarted(): boolean {
    return this._started;
  }

  get provider(): GalleryProvider2 | null {
    return this._provider;
  }

  /**
   * Read-only view of the current gallery source and page index.
   * Suitable for use by the reading page and navigation bar.
   */
  get readerState(): ReaderState {
    return this._readerState;
  }

  /** Progress text like "5 / 100". */
  get progressText(): string {
    if (this._totalPages <= 0) return '';
    return `${this._currentPage + 1} / ${this._totalPages}`;
  }

  /** Progress ratio 0.0 – 1.0 for a slider. */
  get progressRatio(): number {
    if (this._totalPages <= 1) return 0;
    return this._currentPage / (this._totalPages - 1);
  }

  // ---- Setup ----

  /**
   * Set a callback for state changes (used by UI to trigger re-render).
   */
  setOnChange(callback: (() => void) | null): void {
    this._onChange = callback;
  }

  /**
   * Attach a gallery provider and start reading.
   *
   * @param provider  the gallery data source
   * @param source    which kind of gallery (EH, DIR, ARCHIVE)
   * @param startPage 0-based page to begin reading from
   */
  start(provider: GalleryProvider2, source: GallerySource, startPage: number = 0): void {
    this._provider = provider;
    this._provider.addListener(this);
    this._provider.start();
    this._started = true;
    this._currentPage = startPage;
    this._readerState = new MutableReaderState(source, startPage);

    const size = this._provider.size();
    if (size > 0) {
      this._totalPages = size;
    }

    // Pre-request the first visible page
    this.requestPage(this._currentPage);
  }

  /**
   * Stop the reader and release the provider.
   */
  stop(): void {
    if (this._provider) {
      // Persist reading position
      this._provider.putStartPage(this._currentPage);
      this._provider.removeListener(this);
      this._provider.stop();
      this._provider = null;
    }
    this._started = false;
  }

  // ---- Actions ----

  /**
   * Set reading mode.
   */
  setReadingMode(mode: ReadingMode): void {
    this._readingMode = mode;
    this.notifyChange();
  }

  /**
   * Toggle the toolbar overlay.
   */
  toggleToolbar(): void {
    this._toolbarVisible = !this._toolbarVisible;
    this.notifyChange();
  }

  /**
   * Navigate to a specific page.
   */
  goToPage(page: number): void {
    if (page < 0 || (this._totalPages > 0 && page >= this._totalPages)) return;
    this._currentPage = page;
    this._readerState.setCurrentIndex(page);
    this.requestPage(page);
    this._provider?.putStartPage(page);
    this.notifyChange();
  }

  /**
   * Go to the next page.
   */
  nextPage(): boolean {
    if (this._totalPages > 0 && this._currentPage >= this._totalPages - 1) return false;
    this.goToPage(this._currentPage + 1);
    return true;
  }

  /**
   * Go to the previous page.
   */
  prevPage(): boolean {
    if (this._currentPage <= 0) return false;
    this.goToPage(this._currentPage - 1);
    return true;
  }

  /**
   * Get page info for a specific page.
   */
  getPageInfo(index: number): PageInfo {
    return this._pageStates.get(index) ?? {
      index,
      state: PageState.WAITING,
      progress: 0,
      error: '',
    };
  }

  /**
   * Request loading of a page.
   */
  requestPage(index: number): void {
    this._provider?.request(index);
  }

  /**
   * Force reload a page.
   */
  retryPage(index: number): void {
    this._pageStates.set(index, {
      index,
      state: PageState.WAITING,
      progress: 0,
      error: '',
    });
    this._provider?.forceRequest(index);
    this.notifyChange();
  }

  // ---- GalleryProviderListener ----

  onDataChanged(): void {
    if (this._provider) {
      const size = this._provider.size();
      if (size > 0) {
        this._totalPages = size;
      }
    }
    this.notifyChange();
  }

  onPageWait(index: number): void {
    this._pageStates.set(index, {
      index,
      state: PageState.WAITING,
      progress: 0,
      error: '',
    });
    this.notifyChange();
  }

  onPagePercent(index: number, percent: number): void {
    this._pageStates.set(index, {
      index,
      state: PageState.LOADING,
      progress: percent,
      error: '',
    });
    this.notifyChange();
  }

  onPageSucceed(index: number, _data: Uint8Array): void {
    this._pageStates.set(index, {
      index,
      state: PageState.READY,
      progress: 1.0,
      error: '',
    });
    this.notifyChange();
  }

  onPageFailed(index: number, error: string): void {
    this._pageStates.set(index, {
      index,
      state: PageState.FAILED,
      progress: 0,
      error,
    });
    this.notifyChange();
  }

  // ---- Private ----

  private notifyChange(): void {
    this._onChange?.();
  }
}
