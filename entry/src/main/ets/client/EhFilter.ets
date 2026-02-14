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

import { Filter } from '../model/Filter.ets';
import { GalleryInfo } from '../model/GalleryInfo.ets';
import type { EhDB } from '../database/EhDB.ets';

/**
 * Content filter that hides galleries by title, uploader, tag, or tag namespace.
 *
 * Mirrors the Android EhFilter class.
 */
export class EhFilter {
  private titleFilters: Filter[] = [];
  private uploaderFilters: Filter[] = [];
  private tagFilters: Filter[] = [];
  private tagNamespaceFilters: Filter[] = [];
  private db: EhDB;

  private static instance: EhFilter | null = null;

  static getInstance(db?: EhDB): EhFilter {
    if (EhFilter.instance === null) {
      if (!db) {
        throw new Error('EhFilter must be initialized with a database instance');
      }
      EhFilter.instance = new EhFilter(db);
    }
    return EhFilter.instance;
  }

  /** Reset the singleton (for testing). */
  static resetInstance(): void {
    EhFilter.instance = null;
  }

  constructor(db: EhDB) {
    this.db = db;
    this.loadFilters();
  }

  private loadFilters(): void {
    this.titleFilters = [];
    this.uploaderFilters = [];
    this.tagFilters = [];
    this.tagNamespaceFilters = [];

    const list = this.db.getAllFilter();
    for (const filter of list) {
      this.addToList(filter);
    }
  }

  private addToList(filter: Filter): void {
    switch (filter.mode) {
      case Filter.MODE_TITLE:
        if (filter.text) filter.text = filter.text.toLowerCase();
        this.titleFilters.push(filter);
        break;
      case Filter.MODE_UPLOADER:
        this.uploaderFilters.push(filter);
        break;
      case Filter.MODE_TAG:
        if (filter.text) filter.text = filter.text.toLowerCase();
        this.tagFilters.push(filter);
        break;
      case Filter.MODE_TAG_NAMESPACE:
        if (filter.text) filter.text = filter.text.toLowerCase();
        this.tagNamespaceFilters.push(filter);
        break;
    }
  }

  getTitleFilterList(): Filter[] {
    return this.titleFilters;
  }

  getUploaderFilterList(): Filter[] {
    return this.uploaderFilters;
  }

  getTagFilterList(): Filter[] {
    return this.tagFilters;
  }

  getTagNamespaceFilterList(): Filter[] {
    return this.tagNamespaceFilters;
  }

  addFilter(filter: Filter): void {
    filter.enable = true;
    this.db.addFilter(filter);
    this.addToList(filter);
  }

  triggerFilter(filter: Filter): void {
    this.db.triggerFilter(filter);
  }

  deleteFilter(filter: Filter): void {
    this.db.deleteFilter(filter);
    switch (filter.mode) {
      case Filter.MODE_TITLE:
        this.removeFromList(this.titleFilters, filter);
        break;
      case Filter.MODE_UPLOADER:
        this.removeFromList(this.uploaderFilters, filter);
        break;
      case Filter.MODE_TAG:
        this.removeFromList(this.tagFilters, filter);
        break;
      case Filter.MODE_TAG_NAMESPACE:
        this.removeFromList(this.tagNamespaceFilters, filter);
        break;
    }
  }

  private removeFromList(list: Filter[], filter: Filter): void {
    const idx = list.findIndex(f => f.equals(filter));
    if (idx >= 0) {
      list.splice(idx, 1);
    }
  }

  /** Whether any tag or tag-namespace filters exist. */
  needTags(): boolean {
    return this.tagFilters.length > 0 || this.tagNamespaceFilters.length > 0;
  }

  /** Returns true if the gallery passes the title filter (not blocked). */
  filterTitle(info: GalleryInfo | null): boolean {
    if (info === null) return false;

    const title = info.title;
    if (title && this.titleFilters.length > 0) {
      const lowerTitle = title.toLowerCase();
      for (const f of this.titleFilters) {
        if (f.enable && f.text && lowerTitle.includes(f.text)) {
          return false;
        }
      }
    }
    return true;
  }

  /** Returns true if the gallery passes the uploader filter (not blocked). */
  filterUploader(info: GalleryInfo | null): boolean {
    if (info === null) return false;

    const uploader = info.uploader;
    if (uploader && this.uploaderFilters.length > 0) {
      for (const f of this.uploaderFilters) {
        if (f.enable && uploader === f.text) {
          return false;
        }
      }
    }
    return true;
  }

  /** Returns true if the gallery passes the tag filter (not blocked). */
  filterTag(info: GalleryInfo | null): boolean {
    if (info === null) return false;

    const tags = info.simpleTags;
    if (tags !== null && this.tagFilters.length > 0) {
      for (const tag of tags) {
        for (const f of this.tagFilters) {
          if (f.enable && f.text && EhFilter.matchTag(tag, f.text)) {
            return false;
          }
        }
      }
    }
    return true;
  }

  /** Returns true if the gallery passes the tag namespace filter (not blocked). */
  filterTagNamespace(info: GalleryInfo | null): boolean {
    if (info === null) return false;

    const tags = info.simpleTags;
    if (tags !== null && this.tagNamespaceFilters.length > 0) {
      for (const tag of tags) {
        for (const f of this.tagNamespaceFilters) {
          if (f.enable && f.text && EhFilter.matchTagNamespace(tag, f.text)) {
            return false;
          }
        }
      }
    }
    return true;
  }

  private static matchTag(tag: string, filter: string): boolean {
    let tagNamespace: string | null;
    let tagName: string;
    let filterNamespace: string | null;
    let filterName: string;

    let idx = tag.indexOf(':');
    if (idx < 0) {
      tagNamespace = null;
      tagName = tag;
    } else {
      tagNamespace = tag.substring(0, idx);
      tagName = tag.substring(idx + 1);
    }

    idx = filter.indexOf(':');
    if (idx < 0) {
      filterNamespace = null;
      filterName = filter;
    } else {
      filterNamespace = filter.substring(0, idx);
      filterName = filter.substring(idx + 1);
    }

    if (tagNamespace !== null && filterNamespace !== null && tagNamespace !== filterNamespace) {
      return false;
    }

    return tagName === filterName;
  }

  private static matchTagNamespace(tag: string, filter: string): boolean {
    const idx = tag.indexOf(':');
    if (idx >= 0) {
      return tag.substring(0, idx) === filter;
    }
    return false;
  }
}
