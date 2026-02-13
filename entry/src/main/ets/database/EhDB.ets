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

import { GalleryInfo } from '../model/GalleryInfo.ets';
import { DownloadInfo } from '../download/DownloadInfo.ets';
import { DownloadLabel } from '../download/DownloadLabel.ets';
import type { DownloadDB } from '../download/DownloadDB.ets';
import { DownloadDirname } from '../model/DownloadDirname.ets';
import { HistoryInfo } from '../model/HistoryInfo.ets';
import { LocalFavoriteInfo } from '../model/LocalFavoriteInfo.ets';
import { QuickSearch } from '../model/QuickSearch.ets';
import { Filter } from '../model/Filter.ets';

/**
 * Unified persistence interface for all EhViewer tables.
 *
 * Extends DownloadDB so any EhDB implementation can be used as a DownloadDB
 * (e.g. passed directly to DownloadManager).
 *
 * Mirrors the Android EhDB class, covering:
 * - Downloads (DOWNLOADS table) — inherited from DownloadDB
 * - Download labels (DOWNLOAD_LABELS table) — inherited from DownloadDB
 * - Download directory names (DOWNLOAD_DIRNAME table)
 * - Browsing history (HISTORY table)
 * - Local favorites (LOCAL_FAVORITES table)
 * - Quick search (QUICK_SEARCH table)
 * - Filters (FILTER table)
 *
 * Production: backed by DatabaseStore / RelationalStore.
 * Tests: backed by MemoryEhDB.
 */
export interface EhDB extends DownloadDB {

  // ---- Download Dirname ----

  /** Get the download directory name for a gid, or null if not found. */
  getDownloadDirname(gid: number): string | null;

  /** Insert or update the download directory name for a gid. */
  putDownloadDirname(gid: number, dirname: string): void;

  /** Remove the download directory name for a gid. */
  removeDownloadDirname(gid: number): void;

  /** Remove all download directory names. */
  clearDownloadDirname(): void;

  // ---- History ----

  /** Return all history entries, ordered by time descending. */
  getHistoryList(): HistoryInfo[];

  /** Insert or update a history entry from a gallery info. */
  putHistoryInfo(galleryInfo: GalleryInfo): void;

  /** Batch-insert history entries (for import). */
  putHistoryInfoList(historyInfoList: HistoryInfo[]): void;

  /** Delete a single history entry. */
  deleteHistoryInfo(info: HistoryInfo): void;

  /** Delete all history. */
  clearHistoryInfo(): void;

  // ---- Local Favorites ----

  /** Return all local favorites, ordered by time descending. */
  getAllLocalFavorites(): GalleryInfo[];

  /** Search local favorites by title substring. */
  searchLocalFavorites(query: string): GalleryInfo[];

  /** Remove a single local favorite by gid. */
  removeLocalFavorites(gid: number): void;

  /** Remove multiple local favorites by gid. */
  removeLocalFavoritesBatch(gidArray: number[]): void;

  /** Check if a gid exists in local favorites. */
  containLocalFavorites(gid: number): boolean;

  /** Add a gallery to local favorites (no-op if already present). */
  putLocalFavorites(galleryInfo: GalleryInfo): void;

  /** Add multiple galleries to local favorites. */
  putLocalFavoritesList(galleryInfoList: GalleryInfo[]): void;

  // ---- Quick Search ----

  /** Return all quick searches, ordered by time ascending. */
  getAllQuickSearch(): QuickSearch[];

  /** Insert a new quick search. Sets id and time on the object. */
  insertQuickSearch(quickSearch: QuickSearch): void;

  /** Update an existing quick search. */
  updateQuickSearch(quickSearch: QuickSearch): void;

  /** Delete a quick search. */
  deleteQuickSearch(quickSearch: QuickSearch): void;

  /** Swap quick search ordering between two positions. */
  moveQuickSearch(fromPosition: number, toPosition: number): void;

  // ---- Filters ----

  /** Return all filters. */
  getAllFilter(): Filter[];

  /** Add a new filter. Sets id on the object. */
  addFilter(filter: Filter): void;

  /** Delete a filter. */
  deleteFilter(filter: Filter): void;

  /** Toggle a filter's enable state. */
  triggerFilter(filter: Filter): void;
}
