/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { GalleryInfo } from '../model/GalleryInfo.ets';
import { HistoryInfo } from '../model/HistoryInfo.ets';
import type { EhDB } from '../database/EhDB.ets';
import { EhUtils } from '../client/EhUtils.ets';

/** Loading states for the history tab. */
export const HistoryState = {
  IDLE: 0,
  LOADING: 1,
  EMPTY: 2,
  SUCCESS: 3,
  FAILED: 4,
} as const;

export type HistoryState = (typeof HistoryState)[keyof typeof HistoryState];

/**
 * ViewModel for HistoryTab.
 *
 * Manages:
 *  - browsing history list from EhDB
 *  - delete individual entries
 *  - clear all history
 */
export class HistoryViewModel {
  private _state: HistoryState = HistoryState.IDLE;
  private _items: HistoryInfo[] = [];
  private readonly db: EhDB;

  constructor(db: EhDB) {
    this.db = db;
  }

  // ---- Getters ----

  get state(): HistoryState {
    return this._state;
  }

  get items(): HistoryInfo[] {
    return this._items;
  }

  get isEmpty(): boolean {
    return this._items.length === 0;
  }

  get count(): number {
    return this._items.length;
  }

  // ---- Actions ----

  /** Load all history entries. */
  load(): void {
    this._state = HistoryState.LOADING;

    try {
      this._items = this.db.getHistoryList();
      this._state = this._items.length > 0 ? HistoryState.SUCCESS : HistoryState.EMPTY;
    } catch (_e) {
      this._state = HistoryState.FAILED;
      this._items = [];
    }
  }

  /** Refresh the history list. */
  refresh(): void {
    this.load();
  }

  /** Delete a single history entry. */
  deleteHistory(info: HistoryInfo): void {
    this.db.deleteHistoryInfo(info);
    this.refresh();
  }

  /** Delete a history entry by index. Returns true if index was valid. */
  deleteAt(index: number): boolean {
    if (index < 0 || index >= this._items.length) {
      return false;
    }
    this.db.deleteHistoryInfo(this._items[index]);
    this.refresh();
    return true;
  }

  /** Clear all history. */
  clearAll(): void {
    this.db.clearHistoryInfo();
    this.refresh();
  }

  /** Record a gallery visit in history. */
  recordVisit(galleryInfo: GalleryInfo): void {
    this.db.putHistoryInfo(galleryInfo);
  }

  /** Get display title for a gallery info. */
  getDisplayTitle(gi: GalleryInfo): string {
    return EhUtils.getSuitableTitle(gi);
  }

  /** Get category color for a gallery info. */
  getCategoryColor(gi: GalleryInfo): string {
    return EhUtils.getCategoryColor(gi.category);
  }

  /** Get category text for a gallery info. */
  getCategoryText(gi: GalleryInfo): string {
    return EhUtils.getCategoryString(gi.category);
  }
}
