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

import type { EhDB } from './EhDB.ets';
import { GalleryInfo } from '../model/GalleryInfo.ets';
import { DownloadInfo } from '../download/DownloadInfo.ets';
import { DownloadLabel } from '../download/DownloadLabel.ets';
import { HistoryInfo } from '../model/HistoryInfo.ets';
import { LocalFavoriteInfo } from '../model/LocalFavoriteInfo.ets';
import { QuickSearch } from '../model/QuickSearch.ets';
import { Filter } from '../model/Filter.ets';

const MAX_HISTORY_COUNT = 100;

/**
 * In-memory implementation of EhDB for testing.
 *
 * Mirrors Android EhDB behavior without touching any real database.
 */
export class MemoryEhDB implements EhDB {

  // ---- Downloads ----

  private downloads: Map<number, DownloadInfo> = new Map();

  getAllDownloadInfo(): DownloadInfo[] {
    const list = Array.from(this.downloads.values());
    list.sort((a, b) => b.time - a.time);
    return list;
  }

  putDownloadInfo(info: DownloadInfo): void {
    this.downloads.set(info.gid, info);
  }

  removeDownloadInfo(gid: number): void {
    this.downloads.delete(gid);
  }

  // ---- Download Labels ----

  private labels: DownloadLabel[] = [];
  private nextLabelId: number = 1;

  getAllDownloadLabelList(): DownloadLabel[] {
    const sorted = [...this.labels];
    sorted.sort((a, b) => a.time - b.time);
    return sorted;
  }

  addDownloadLabel(label: string): DownloadLabel {
    const dl = new DownloadLabel(label);
    dl.id = this.nextLabelId++;
    this.labels.push(dl);
    return dl;
  }

  addDownloadLabelObject(label: DownloadLabel): DownloadLabel {
    const dl = new DownloadLabel(label.label);
    dl.id = this.nextLabelId++;
    dl.time = label.time;
    this.labels.push(dl);
    return dl;
  }

  updateDownloadLabel(label: DownloadLabel): void {
    const idx = this.labels.findIndex(l => l.id === label.id);
    if (idx >= 0) {
      this.labels[idx] = label;
    }
  }

  moveDownloadLabel(fromPosition: number, toPosition: number): void {
    if (fromPosition === toPosition) return;
    const sorted = this.getAllDownloadLabelList();
    if (fromPosition < 0 || fromPosition >= sorted.length) return;
    if (toPosition < 0 || toPosition >= sorted.length) return;

    const reverse = fromPosition > toPosition;
    const offset = reverse ? toPosition : fromPosition;
    const limit = reverse ? fromPosition - toPosition + 1 : toPosition - fromPosition + 1;
    const slice = sorted.slice(offset, offset + limit);

    const step = reverse ? 1 : -1;
    const start = reverse ? limit - 1 : 0;
    const end = reverse ? 0 : limit - 1;
    const toTime = slice[end].time;
    for (let i = end; reverse ? i < start : i > start; i += step) {
      slice[i].time = slice[i + step].time;
    }
    slice[start].time = toTime;

    // Persist the time changes back
    for (const item of slice) {
      this.updateDownloadLabel(item);
    }
  }

  removeDownloadLabel(label: DownloadLabel): void {
    const idx = this.labels.findIndex(l => l.id === label.id);
    if (idx >= 0) {
      this.labels.splice(idx, 1);
    }
  }

  // ---- Download Dirname ----

  private dirnames: Map<number, string> = new Map();

  getDownloadDirname(gid: number): string | null {
    return this.dirnames.get(gid) ?? null;
  }

  putDownloadDirname(gid: number, dirname: string): void {
    this.dirnames.set(gid, dirname);
  }

  removeDownloadDirname(gid: number): void {
    this.dirnames.delete(gid);
  }

  clearDownloadDirname(): void {
    this.dirnames.clear();
  }

  // ---- History ----

  private history: Map<number, HistoryInfo> = new Map();

  getHistoryList(): HistoryInfo[] {
    const list = Array.from(this.history.values());
    list.sort((a, b) => b.time - a.time);
    return list;
  }

  putHistoryInfo(galleryInfo: GalleryInfo): void {
    const existing = this.history.get(galleryInfo.gid);
    if (existing) {
      existing.time = Date.now();
    } else {
      const info = new HistoryInfo(galleryInfo);
      info.time = Date.now();
      this.history.set(info.gid, info);
      this.trimHistory();
    }
  }

  putHistoryInfoList(historyInfoList: HistoryInfo[]): void {
    for (const info of historyInfoList) {
      if (!this.history.has(info.gid)) {
        this.history.set(info.gid, info);
      }
    }
    this.trimHistory();
  }

  deleteHistoryInfo(info: HistoryInfo): void {
    this.history.delete(info.gid);
  }

  clearHistoryInfo(): void {
    this.history.clear();
  }

  private trimHistory(): void {
    if (this.history.size <= MAX_HISTORY_COUNT) return;
    const sorted = this.getHistoryList();
    for (let i = MAX_HISTORY_COUNT; i < sorted.length; i++) {
      this.history.delete(sorted[i].gid);
    }
  }

  // ---- Local Favorites ----

  private favorites: Map<number, LocalFavoriteInfo> = new Map();

  getAllLocalFavorites(): GalleryInfo[] {
    const list = Array.from(this.favorites.values());
    list.sort((a, b) => b.time - a.time);
    return list;
  }

  searchLocalFavorites(query: string): GalleryInfo[] {
    const lower = query.toLowerCase();
    const list = Array.from(this.favorites.values())
      .filter(f => f.title.toLowerCase().includes(lower));
    list.sort((a, b) => b.time - a.time);
    return list;
  }

  removeLocalFavorites(gid: number): void {
    this.favorites.delete(gid);
  }

  removeLocalFavoritesBatch(gidArray: number[]): void {
    for (const gid of gidArray) {
      this.favorites.delete(gid);
    }
  }

  containLocalFavorites(gid: number): boolean {
    return this.favorites.has(gid);
  }

  putLocalFavorites(galleryInfo: GalleryInfo): void {
    if (this.favorites.has(galleryInfo.gid)) return;
    let info: LocalFavoriteInfo;
    if (galleryInfo instanceof LocalFavoriteInfo) {
      info = galleryInfo;
    } else {
      info = new LocalFavoriteInfo(galleryInfo);
      info.time = Date.now();
    }
    this.favorites.set(info.gid, info);
  }

  putLocalFavoritesList(galleryInfoList: GalleryInfo[]): void {
    for (const gi of galleryInfoList) {
      this.putLocalFavorites(gi);
    }
  }

  // ---- Quick Search ----

  private quickSearches: QuickSearch[] = [];
  private nextQuickSearchId: number = 1;

  getAllQuickSearch(): QuickSearch[] {
    const sorted = [...this.quickSearches];
    sorted.sort((a, b) => a.time - b.time);
    return sorted;
  }

  insertQuickSearch(quickSearch: QuickSearch): void {
    quickSearch.id = this.nextQuickSearchId++;
    quickSearch.time = Date.now();
    this.quickSearches.push(quickSearch);
  }

  updateQuickSearch(quickSearch: QuickSearch): void {
    const idx = this.quickSearches.findIndex(q => q.id === quickSearch.id);
    if (idx >= 0) {
      this.quickSearches[idx] = quickSearch;
    }
  }

  deleteQuickSearch(quickSearch: QuickSearch): void {
    const idx = this.quickSearches.findIndex(q => q.id === quickSearch.id);
    if (idx >= 0) {
      this.quickSearches.splice(idx, 1);
    }
  }

  moveQuickSearch(fromPosition: number, toPosition: number): void {
    if (fromPosition === toPosition) return;
    const sorted = this.getAllQuickSearch();
    if (fromPosition < 0 || fromPosition >= sorted.length) return;
    if (toPosition < 0 || toPosition >= sorted.length) return;

    const reverse = fromPosition > toPosition;
    const offset = reverse ? toPosition : fromPosition;
    const limit = reverse ? fromPosition - toPosition + 1 : toPosition - fromPosition + 1;
    const slice = sorted.slice(offset, offset + limit);

    const step = reverse ? 1 : -1;
    const start = reverse ? limit - 1 : 0;
    const end = reverse ? 0 : limit - 1;
    const toTime = slice[end].time;
    for (let i = end; reverse ? i < start : i > start; i += step) {
      slice[i].time = slice[i + step].time;
    }
    slice[start].time = toTime;

    for (const item of slice) {
      this.updateQuickSearch(item);
    }
  }

  // ---- Filters ----

  private filters: Filter[] = [];
  private nextFilterId: number = 1;

  getAllFilter(): Filter[] {
    return [...this.filters];
  }

  addFilter(filter: Filter): void {
    filter.id = this.nextFilterId++;
    this.filters.push(filter);
  }

  deleteFilter(filter: Filter): void {
    const idx = this.filters.findIndex(f => f.id === filter.id);
    if (idx >= 0) {
      this.filters.splice(idx, 1);
    }
  }

  triggerFilter(filter: Filter): void {
    filter.enable = !filter.enable;
    const idx = this.filters.findIndex(f => f.id === filter.id);
    if (idx >= 0) {
      this.filters[idx] = filter;
    }
  }
}
