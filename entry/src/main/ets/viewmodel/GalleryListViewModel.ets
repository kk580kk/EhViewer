/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { GalleryInfo } from '../model/GalleryInfo';
import { ListUrlBuilder } from '../model/ListUrlBuilder';
import { EhUtils } from '../client/EhUtils';

/** Loading states for the gallery list. */
export const ListState = {
  IDLE: 0,
  LOADING: 1,
  REFRESHING: 2,
  LOAD_MORE: 3,
  SUCCESS: 4,
  EMPTY: 5,
  FAILED: 6,
} as const;

export type ListState = (typeof ListState)[keyof typeof ListState];

/** Sub-modes for the gallery list scene. */
export const ListMode = {
  HOMEPAGE: 0,
  SUBSCRIPTION: 1,
  WHATS_HOT: 2,
  SEARCH: 3,
} as const;

export type ListMode = (typeof ListMode)[keyof typeof ListMode];

/**
 * Abstraction for fetching gallery list data.
 * Injected to allow testing without real network calls.
 */
export interface GalleryListFetcher {
  /**
   * Fetch a page of gallery list results.
   * Returns the list of items and whether there's a next page.
   */
  fetchList(url: string): Promise<GalleryListResult>;
}

export interface GalleryListResult {
  items: GalleryInfo[];
  hasNextPage: boolean;
}

/**
 * ViewModel for GalleryListTab.
 *
 * Manages:
 *  - list mode (homepage / subscription / whats-hot / search)
 *  - search keyword and category filter
 *  - pagination (page index, hasMore)
 *  - loading state
 *  - gallery items
 */
export class GalleryListViewModel {
  private _state: ListState = ListState.IDLE;
  private _error: string = '';
  private _items: GalleryInfo[] = [];
  private _listMode: ListMode = ListMode.HOMEPAGE;
  private _keyword: string = '';
  private _category: number = EhUtils.NONE;
  private _pageIndex: number = 0;
  private _hasMore: boolean = false;
  private readonly fetcher: GalleryListFetcher;
  private readonly urlBuilder: ListUrlBuilder = new ListUrlBuilder();

  constructor(fetcher: GalleryListFetcher) {
    this.fetcher = fetcher;
  }

  // ---- Getters ----

  get state(): ListState { return this._state; }
  get error(): string { return this._error; }
  get items(): GalleryInfo[] { return this._items; }
  get listMode(): ListMode { return this._listMode; }
  get keyword(): string { return this._keyword; }
  get category(): number { return this._category; }
  get pageIndex(): number { return this._pageIndex; }
  get hasMore(): boolean { return this._hasMore; }
  get isEmpty(): boolean { return this._items.length === 0; }
  get count(): number { return this._items.length; }

  get modeTitle(): string {
    switch (this._listMode) {
      case ListMode.HOMEPAGE: return 'Homepage';
      case ListMode.SUBSCRIPTION: return 'Subscription';
      case ListMode.WHATS_HOT: return "What's Hot";
      case ListMode.SEARCH: return 'Search';
      default: return 'Gallery';
    }
  }

  // ---- Actions ----

  /** Set the list mode and reset state. */
  setListMode(mode: ListMode): void {
    this._listMode = mode;
    this._keyword = '';
    this._category = EhUtils.NONE;
    this._pageIndex = 0;
    this._items = [];
    this._hasMore = false;
  }

  /** Set search keyword. */
  setKeyword(keyword: string): void {
    this._keyword = keyword;
  }

  /** Set category filter. */
  setCategory(category: number): void {
    this._category = category;
  }

  /** Build URL from current state. */
  buildUrl(): string {
    this.urlBuilder.setPageIndex(this._pageIndex);

    switch (this._listMode) {
      case ListMode.SUBSCRIPTION:
        this.urlBuilder.setMode(ListUrlBuilder.MODE_SUBSCRIPTION);
        break;
      case ListMode.WHATS_HOT:
        this.urlBuilder.setMode(ListUrlBuilder.MODE_WHATS_HOT);
        break;
      case ListMode.SEARCH:
        this.urlBuilder.setMode(ListUrlBuilder.MODE_NORMAL);
        this.urlBuilder.setKeyword(this._keyword);
        this.urlBuilder.setCategory(this._category);
        break;
      case ListMode.HOMEPAGE:
      default:
        this.urlBuilder.setMode(ListUrlBuilder.MODE_NORMAL);
        this.urlBuilder.setKeyword(this._keyword.length > 0 ? this._keyword : null);
        this.urlBuilder.setCategory(this._category);
        break;
    }

    return this.urlBuilder.build();
  }

  /** Load first page (refresh). */
  async load(): Promise<void> {
    this._pageIndex = 0;
    this._items = [];
    this._hasMore = false;
    this._error = '';
    this._state = ListState.LOADING;

    try {
      const url = this.buildUrl();
      const result = await this.fetcher.fetchList(url);
      this._items = result.items;
      this._hasMore = result.hasNextPage;
      this._state = this._items.length > 0 ? ListState.SUCCESS : ListState.EMPTY;
    } catch (e) {
      this._error = e instanceof Error ? e.message : String(e);
      this._state = ListState.FAILED;
    }
  }

  /** Refresh (pull-to-refresh). */
  async refresh(): Promise<void> {
    this._pageIndex = 0;
    this._hasMore = false;
    this._error = '';
    this._state = ListState.REFRESHING;

    try {
      const url = this.buildUrl();
      const result = await this.fetcher.fetchList(url);
      this._items = result.items;
      this._hasMore = result.hasNextPage;
      this._state = this._items.length > 0 ? ListState.SUCCESS : ListState.EMPTY;
    } catch (e) {
      this._error = e instanceof Error ? e.message : String(e);
      this._state = ListState.FAILED;
    }
  }

  /** Load next page (append). */
  async loadMore(): Promise<void> {
    if (!this._hasMore) return;
    if (this._state === ListState.LOAD_MORE) return;

    this._pageIndex += 1;
    this._error = '';
    this._state = ListState.LOAD_MORE;

    try {
      const url = this.buildUrl();
      const result = await this.fetcher.fetchList(url);
      this._items = this._items.concat(result.items);
      this._hasMore = result.hasNextPage;
      this._state = ListState.SUCCESS;
    } catch (e) {
      this._pageIndex -= 1;
      this._error = e instanceof Error ? e.message : String(e);
      this._state = ListState.FAILED;
    }
  }

  /** Perform a keyword search (resets page). */
  async search(keyword: string): Promise<void> {
    this._keyword = keyword;
    this._listMode = ListMode.SEARCH;
    await this.load();
  }

  /** Clear search and return to homepage. */
  async clearSearch(): Promise<void> {
    this._keyword = '';
    this._listMode = ListMode.HOMEPAGE;
    await this.load();
  }
}
