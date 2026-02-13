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
import { DownloadInfo } from '../download/DownloadInfo.ets';
import type { DownloadManager } from '../download/DownloadManager.ets';
import type { DownloadProgressCallback } from '../download/DownloadProgressCallback.ets';
import { DownloadProgressEvent } from '../download/DownloadProgressEvent.ets';

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
 *  - download state and progress for the current gallery
 */
export class GalleryDetailViewModel implements DownloadProgressCallback {
  private _state: DetailState = DetailState.LOADING;
  private _error: string = '';
  private _detail: GalleryDetail | null = null;
  private _gid: number = 0;
  private _token: string = '';
  private readonly fetcher: GalleryDetailFetcher;
  private readonly _downloadManager: DownloadManager | null;
  private _onStateChange: (() => void) | null = null;

  // ---- Download state ----
  private _downloadState: number = DownloadInfo.STATE_INVALID;
  private _downloadProgressPercent: number = -1;
  private _downloadStatusText: string = '';
  private _downloadSpeedText: string | null = null;

  constructor(fetcher: GalleryDetailFetcher, downloadManager?: DownloadManager) {
    this.fetcher = fetcher;
    this._downloadManager = downloadManager ?? null;
    if (this._downloadManager !== null) {
      this._downloadManager.addProgressCallback(this);
    }
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

  // ---- Download display properties ----

  /** Current download state for this gallery (STATE_INVALID if not in queue). */
  get downloadState(): number {
    return this._downloadState;
  }

  /** Download progress (0–100), or -1 if indeterminate. */
  get downloadProgressPercent(): number {
    return this._downloadProgressPercent;
  }

  /** Human-readable download status text (e.g. "Waiting", "5/10", "Completed"). */
  get downloadStatusText(): string {
    return this._downloadStatusText;
  }

  /** Human-readable speed text (e.g. "1.2 MB/s"), or null. */
  get downloadSpeedText(): string | null {
    return this._downloadSpeedText;
  }

  /** Whether this gallery is currently in the download queue (any active state). */
  get isDownloading(): boolean {
    return this._downloadState === DownloadInfo.STATE_WAIT ||
      this._downloadState === DownloadInfo.STATE_DOWNLOAD ||
      this._downloadState === DownloadInfo.STATE_PAUSED;
  }

  /** Whether this gallery has been downloaded successfully. */
  get isDownloaded(): boolean {
    return this._downloadState === DownloadInfo.STATE_FINISH;
  }

  /** Whether this gallery is in the download list at all. */
  get hasDownload(): boolean {
    return this._downloadManager !== null &&
      this._downloadManager.containDownloadInfo(this._gid);
  }

  /** Text for the download button (changes based on state). */
  get downloadButtonText(): string {
    switch (this._downloadState) {
      case DownloadInfo.STATE_WAIT:
        return 'Waiting';
      case DownloadInfo.STATE_DOWNLOAD:
        return this._downloadProgressPercent >= 0
          ? `${this._downloadProgressPercent}%`
          : 'Downloading';
      case DownloadInfo.STATE_PAUSED:
        return 'Paused';
      case DownloadInfo.STATE_FINISH:
        return 'Downloaded';
      case DownloadInfo.STATE_FAILED:
        return 'Retry';
      default:
        return 'Download';
    }
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
      this.syncDownloadState();
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

  /**
   * Initiate download for the current gallery.
   * Returns true if download was started, false if not possible.
   */
  startDownload(label: string | null = null): boolean {
    if (this._downloadManager === null || this._detail === null) return false;
    // If already finished, nothing to do
    if (this._downloadState === DownloadInfo.STATE_FINISH) return false;
    // If failed, retry
    if (this._downloadState === DownloadInfo.STATE_FAILED) {
      return this._downloadManager.retryDownload(this._gid);
    }
    // If already active, nothing to do
    if (this.isDownloading) return false;

    this._downloadManager.startDownload(this._detail, label);
    this.syncDownloadState();
    this._onStateChange?.();
    return true;
  }

  /**
   * Stop the current gallery's download.
   */
  stopDownload(): void {
    if (this._downloadManager === null) return;
    this._downloadManager.stopDownload(this._gid);
    this.syncDownloadState();
    this._onStateChange?.();
  }

  /**
   * Detach from DownloadManager progress callbacks. Call when the page is destroyed.
   */
  dispose(): void {
    if (this._downloadManager !== null) {
      this._downloadManager.removeProgressCallback(this);
    }
  }

  // ---- DownloadProgressCallback ----

  onDownloadProgress(event: DownloadProgressEvent): void {
    if (event.gid !== this._gid) return;
    this._downloadProgressPercent = event.progressPercent;
    this._downloadStatusText = event.statusText;
    this._downloadSpeedText = event.speedText;
    this._onStateChange?.();
  }

  onDownloadStateChanged(event: DownloadProgressEvent): void {
    if (event.gid !== this._gid) return;
    this._downloadState = event.state;
    this._downloadProgressPercent = event.progressPercent;
    this._downloadStatusText = event.statusText;
    this._downloadSpeedText = event.speedText;
    this._onStateChange?.();
  }

  // ---- Private ----

  /** Sync download state from DownloadManager (for initial load or after manual actions). */
  private syncDownloadState(): void {
    if (this._downloadManager === null || this._gid === 0) {
      this._downloadState = DownloadInfo.STATE_INVALID;
      this._downloadProgressPercent = -1;
      this._downloadStatusText = '';
      this._downloadSpeedText = null;
      return;
    }
    const info = this._downloadManager.getDownloadInfo(this._gid);
    if (info === null) {
      this._downloadState = DownloadInfo.STATE_INVALID;
      this._downloadProgressPercent = -1;
      this._downloadStatusText = '';
      this._downloadSpeedText = null;
      return;
    }
    const event = DownloadProgressEvent.from(info);
    this._downloadState = event.state;
    this._downloadProgressPercent = event.progressPercent;
    this._downloadStatusText = event.statusText;
    this._downloadSpeedText = event.speedText;
  }
}
