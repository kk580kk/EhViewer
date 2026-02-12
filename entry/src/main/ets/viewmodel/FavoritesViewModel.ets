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
import type { EhDB } from '../database/EhDB.ets';
import { FavListUrlBuilder } from '../model/FavListUrlBuilder.ets';
import { EhUtils } from '../client/EhUtils.ets';

/** Loading states for the favorites tab. */
export const FavState = {
  IDLE: 0,
  LOADING: 1,
  EMPTY: 2,
  SUCCESS: 3,
  FAILED: 4,
} as const;

export type FavState = (typeof FavState)[keyof typeof FavState];

/**
 * ViewModel for FavoritesTab.
 *
 * Manages:
 *  - current favorite category (local only for now; cloud requires login)
 *  - gallery list from EhDB local favorites
 *  - search / filter within local favorites
 *  - remove / clear operations
 */
export class FavoritesViewModel {
  private _state: FavState = FavState.IDLE;
  private _items: GalleryInfo[] = [];
  private _keyword: string = '';
  private _favCat: number = FavListUrlBuilder.FAV_CAT_LOCAL;
  private readonly db: EhDB;

  constructor(db: EhDB) {
    this.db = db;
  }

  // ---- Getters ----

  get state(): FavState {
    return this._state;
  }

  get items(): GalleryInfo[] {
    return this._items;
  }

  get keyword(): string {
    return this._keyword;
  }

  get favCat(): number {
    return this._favCat;
  }

  get isEmpty(): boolean {
    return this._items.length === 0;
  }

  get count(): number {
    return this._items.length;
  }

  get title(): string {
    if (this._favCat === FavListUrlBuilder.FAV_CAT_LOCAL) {
      return 'Local Favorites';
    }
    return 'Cloud Favorites';
  }

  // ---- Actions ----

  /** Load local favorites, optionally filtered by keyword. */
  load(keyword?: string): void {
    this._state = FavState.LOADING;
    this._keyword = keyword ?? '';

    try {
      if (this._keyword.length > 0) {
        this._items = this.db.searchLocalFavorites(this._keyword);
      } else {
        this._items = this.db.getAllLocalFavorites();
      }
      this._state = this._items.length > 0 ? FavState.SUCCESS : FavState.EMPTY;
    } catch (_e) {
      this._state = FavState.FAILED;
      this._items = [];
    }
  }

  /** Refresh the current list (re-applies current keyword). */
  refresh(): void {
    this.load(this._keyword);
  }

  /** Set favorite category. For now only local is fully supported. */
  setFavCat(cat: number): void {
    this._favCat = cat;
    this._keyword = '';
    this.load();
  }

  /** Search within favorites. */
  search(keyword: string): void {
    this.load(keyword);
  }

  /** Clear search and reload all. */
  clearSearch(): void {
    this.load('');
  }

  /** Remove a single favorite by gid. */
  removeFavorite(gid: number): void {
    this.db.removeLocalFavorites(gid);
    this.refresh();
  }

  /** Remove multiple favorites by gid array. */
  removeFavorites(gids: number[]): void {
    this.db.removeLocalFavoritesBatch(gids);
    this.refresh();
  }

  /** Check if a gallery is in local favorites. */
  isFavorited(gid: number): boolean {
    return this.db.containLocalFavorites(gid);
  }

  /** Add a gallery to local favorites. */
  addFavorite(galleryInfo: GalleryInfo): void {
    this.db.putLocalFavorites(galleryInfo);
    this.refresh();
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
