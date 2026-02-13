/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { DownloadInfo } from '../download/DownloadInfo.ets';
import { DownloadLabel } from '../download/DownloadLabel.ets';
import type { EhDB } from '../database/EhDB.ets';
import type { DownloadManager } from '../download/DownloadManager.ets';
import { GalleryInfo } from '../model/GalleryInfo.ets';
import { EhUtils } from '../client/EhUtils.ets';

/** Loading states for the downloads tab. */
export const DownloadsState = {
  IDLE: 0,
  LOADING: 1,
  EMPTY: 2,
  SUCCESS: 3,
  FAILED: 4,
} as const;

export type DownloadsState = (typeof DownloadsState)[keyof typeof DownloadsState];

/**
 * ViewModel for DownloadsTab.
 *
 * Manages:
 *  - download task list from EhDB
 *  - label filtering
 *  - download CRUD operations
 *  - state display helpers (progress text, state text)
 */
export class DownloadsViewModel {
  private _state: DownloadsState = DownloadsState.IDLE;
  private _items: DownloadInfo[] = [];
  private _allItems: DownloadInfo[] = [];
  private _labels: DownloadLabel[] = [];
  private _currentLabel: string | null = null;
  private readonly db: EhDB;
  private readonly downloadManager: DownloadManager | null;

  constructor(db: EhDB, downloadManager: DownloadManager | null = null) {
    this.db = db;
    this.downloadManager = downloadManager;
  }

  // ---- Getters ----

  get state(): DownloadsState {
    return this._state;
  }

  get items(): DownloadInfo[] {
    return this._items;
  }

  get labels(): DownloadLabel[] {
    return this._labels;
  }

  get currentLabel(): string | null {
    return this._currentLabel;
  }

  get isEmpty(): boolean {
    return this._items.length === 0;
  }

  get count(): number {
    return this._items.length;
  }

  get title(): string {
    return this._currentLabel ?? 'All Downloads';
  }

  /** Label names including a leading "All" entry. */
  get labelNames(): string[] {
    const names: string[] = ['All Downloads'];
    for (const label of this._labels) {
      names.push(label.label);
    }
    return names;
  }

  // ---- Actions ----

  /** Load all downloads and labels. */
  load(): void {
    this._state = DownloadsState.LOADING;

    try {
      this._allItems = this.db.getAllDownloadInfo();
      this._labels = this.db.getAllDownloadLabelList();
      this.applyLabelFilter();
      this._state = this._items.length > 0 ? DownloadsState.SUCCESS : DownloadsState.EMPTY;
    } catch (_e) {
      this._state = DownloadsState.FAILED;
      this._items = [];
      this._allItems = [];
    }
  }

  /** Refresh the download list. */
  refresh(): void {
    this.load();
  }

  /** Filter downloads by label. null = show all. */
  setLabel(label: string | null): void {
    this._currentLabel = label;
    this.applyLabelFilter();
    this._state = this._items.length > 0 ? DownloadsState.SUCCESS : DownloadsState.EMPTY;
  }

  /** Remove a download record by gid. */
  removeDownload(gid: number): void {
    if (this.downloadManager !== null) {
      this.downloadManager.deleteDownload(gid);
    } else {
      this.db.removeDownloadInfo(gid);
    }
    this.refresh();
  }

  /** Remove multiple downloads by gid. */
  removeDownloads(gids: number[]): void {
    if (this.downloadManager !== null) {
      this.downloadManager.deleteRangeDownload(gids);
    } else {
      for (const gid of gids) {
        this.db.removeDownloadInfo(gid);
      }
    }
    this.refresh();
  }

  /**
   * Add a new download task from gallery info.
   * Delegates to DownloadManager to properly queue the task.
   * Returns true if the download was added, false if DownloadManager is not set
   * or the gallery is already in the queue.
   */
  addDownload(galleryInfo: GalleryInfo, label: string | null = null): boolean {
    if (this.downloadManager === null) return false;
    this.downloadManager.startDownload(galleryInfo, label);
    this.refresh();
    return true;
  }

  /**
   * Cancel (stop) a download task by gid.
   * Returns true if the download was cancelled.
   */
  cancelDownload(gid: number): boolean {
    if (this.downloadManager === null) return false;
    this.downloadManager.stopDownload(gid);
    this.refresh();
    return true;
  }

  /**
   * Retry a failed download task by gid.
   * Returns true if the download was re-queued.
   */
  retryDownload(gid: number): boolean {
    if (this.downloadManager === null) return false;
    const result = this.downloadManager.retryDownload(gid);
    if (result) {
      this.refresh();
    }
    return result;
  }

  /** Add a download label. Returns the created label. */
  addLabel(name: string): DownloadLabel {
    const label = this.db.addDownloadLabel(name);
    this._labels = this.db.getAllDownloadLabelList();
    return label;
  }

  /** Remove a download label. */
  removeLabel(label: DownloadLabel): void {
    this.db.removeDownloadLabel(label);
    this._labels = this.db.getAllDownloadLabelList();
    // Reset filter if current label was removed
    if (this._currentLabel === label.label) {
      this._currentLabel = null;
      this.applyLabelFilter();
    }
  }

  // ---- Display helpers ----

  /** Get human-readable state text for a download item. */
  static getStateText(info: DownloadInfo): string {
    switch (info.state) {
      case DownloadInfo.STATE_NONE:
        return 'Not started';
      case DownloadInfo.STATE_WAIT:
        return 'Waiting';
      case DownloadInfo.STATE_DOWNLOAD:
        return DownloadsViewModel.getProgressText(info);
      case DownloadInfo.STATE_FINISH:
        return 'Completed';
      case DownloadInfo.STATE_FAILED:
        return info.legacy > 0 ? `Failed (${info.legacy})` : 'Failed';
      default:
        return 'Unknown';
    }
  }

  /** Get progress text like "12/36". */
  static getProgressText(info: DownloadInfo): string {
    if (info.total <= 0 || info.finished < 0) {
      return 'Downloading...';
    }
    return `${info.finished}/${info.total}`;
  }

  /** Get progress percentage (0-100). Returns -1 if indeterminate. */
  static getProgressPercent(info: DownloadInfo): number {
    if (info.total <= 0) {
      return -1;
    }
    return Math.round((info.finished / info.total) * 100);
  }

  /** Whether the download can be started/resumed. */
  static canStart(info: DownloadInfo): boolean {
    return info.state === DownloadInfo.STATE_NONE ||
      info.state === DownloadInfo.STATE_FAILED;
  }

  /** Whether the download can be stopped/paused. */
  static canStop(info: DownloadInfo): boolean {
    return info.state === DownloadInfo.STATE_WAIT ||
      info.state === DownloadInfo.STATE_DOWNLOAD;
  }

  /** Get display title for a gallery info. */
  getDisplayTitle(gi: DownloadInfo): string {
    return EhUtils.getSuitableTitle(gi);
  }

  /** Get category color for a gallery info. */
  getCategoryColor(gi: DownloadInfo): string {
    return EhUtils.getCategoryColor(gi.category);
  }

  /** Get category text for a gallery info. */
  getCategoryText(gi: DownloadInfo): string {
    return EhUtils.getCategoryString(gi.category);
  }

  // ---- Private helpers ----

  private applyLabelFilter(): void {
    if (this._currentLabel === null) {
      this._items = [...this._allItems];
    } else {
      this._items = this._allItems.filter(
        (item: DownloadInfo) => item.label === this._currentLabel
      );
    }
  }
}
