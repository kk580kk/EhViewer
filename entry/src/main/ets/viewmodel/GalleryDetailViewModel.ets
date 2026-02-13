/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { GalleryDetail } from '../model/GalleryDetail';
import { GalleryInfo } from '../model/GalleryInfo';
import { GalleryComment } from '../model/GalleryComment';
import { GalleryTagGroup } from '../model/GalleryTagGroup';
import { GalleryPreview } from '../model/GalleryPreview';
import { PreviewSet } from '../model/PreviewSet';
import { EhUtils } from '../client/EhUtils';
import { EhUrl } from '../client/EhUrl';

/** Loading states for the detail page. */
export const DetailState = {
  LOADING: 0,
  SUCCESS: 1,
  FAILED: 2,
} as const;

export type DetailState = (typeof DetailState)[keyof typeof DetailState];

/**
 * Abstraction for fetching gallery detail data.
 * Injected to allow testing without real network calls.
 */
export interface GalleryDetailFetcher {
  fetchDetail(gid: number, token: string): Promise<GalleryDetail>;
}

/**
 * ViewModel for GalleryDetailPage.
 *
 * Manages:
 *  - loading state
 *  - gallery detail data
 *  - derived display properties (title, category color, previews, etc.)
 */
export class GalleryDetailViewModel {
  private _state: DetailState = DetailState.LOADING;
  private _error: string = '';
  private _detail: GalleryDetail | null = null;
  private _gid: number = 0;
  private _token: string = '';
  private readonly fetcher: GalleryDetailFetcher;
  private _onStateChange: (() => void) | null = null;

  constructor(fetcher: GalleryDetailFetcher) {
    this.fetcher = fetcher;
  }

  /** Set callback to notify when state/detail changes (e.g. after load/retry). */
  setOnStateChange(cb: (() => void) | null): void {
    this._onStateChange = cb;
  }

  // ---- Getters ----

  get state(): DetailState {
    return this._state;
  }

  get error(): string {
    return this._error;
  }

  get detail(): GalleryDetail | null {
    return this._detail;
  }

  get gid(): number {
    return this._gid;
  }

  get token(): string {
    return this._token;
  }

  // ---- Derived display properties ----

  get displayTitle(): string {
    if (!this._detail) return '';
    return EhUtils.getSuitableTitle(this._detail);
  }

  get categoryText(): string {
    if (!this._detail) return '';
    return EhUtils.getCategoryString(this._detail.category);
  }

  get categoryColor(): string {
    if (!this._detail) return '#000000';
    return EhUtils.getCategoryColor(this._detail.category);
  }

  get uploaderText(): string {
    return this._detail?.uploader ?? '';
  }

  get ratingValue(): number {
    return this._detail?.rating ?? 0;
  }

  get pagesText(): string {
    if (!this._detail) return '';
    return `${this._detail.pages} pages`;
  }

  get languageText(): string {
    return this._detail?.language ?? '';
  }

  get sizeText(): string {
    return this._detail?.size ?? '';
  }

  get favoriteCountText(): string {
    if (!this._detail) return '';
    return `${this._detail.favoriteCount}`;
  }

  get postedText(): string {
    return this._detail?.posted ?? '';
  }

  get ratingCountText(): string {
    if (!this._detail) return '';
    return `${this._detail.ratingCount} votes`;
  }

  get isFavorited(): boolean {
    return this._detail?.isFavorited ?? false;
  }

  get tags(): GalleryTagGroup[] {
    return this._detail?.tags ?? [];
  }

  get comments(): GalleryComment[] {
    return this._detail?.comments?.comments ?? [];
  }

  get hasMoreComments(): boolean {
    return this._detail?.comments?.hasMore ?? false;
  }

  get previewCount(): number {
    if (!this._detail?.previewSet) return 0;
    return this._detail.previewSet.size();
  }

  get previewPages(): number {
    return this._detail?.previewPages ?? 0;
  }

  get thumbUrl(): string {
    return this._detail?.thumb ?? '';
  }

  get detailUrl(): string {
    if (!this._gid || !this._token) return '';
    return EhUrl.getGalleryDetailUrl(this._gid, this._token);
  }

  /**
   * Get preview items from the current preview set.
   */
  getPreviews(): GalleryPreview[] {
    if (!this._detail?.previewSet) return [];
    const set = this._detail.previewSet;
    const result: GalleryPreview[] = [];
    for (let i = 0; i < set.size(); i++) {
      result.push(set.getGalleryPreview(this._gid, i));
    }
    return result;
  }

  // ---- Actions ----

  /**
   * Load gallery detail data.
   */
  async load(gid: number, token: string): Promise<void> {
    this._gid = gid;
    this._token = token;
    this._state = DetailState.LOADING;
    this._error = '';
    this._detail = null;

    try {
      const detail = await this.fetcher.fetchDetail(gid, token);
      this._detail = detail;
      this._state = DetailState.SUCCESS;
    } catch (e) {
      this._error = e instanceof Error ? e.message : String(e);
      this._state = DetailState.FAILED;
    }
    this._onStateChange?.();
  }

  /**
   * Retry loading after a failure.
   */
  async retry(): Promise<void> {
    if (this._gid && this._token) {
      await this.load(this._gid, this._token);
    }
  }
}
