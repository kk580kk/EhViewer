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

/**
 * A saved quick-search entry.
 *
 * Mirrors the Android QuickSearch DAO entity.
 */
export class QuickSearch {
  id: number | null = null;
  name: string = '';
  mode: number = 0;
  category: number = 0;
  keyword: string | null = null;
  advanceSearch: number = 0;
  minRating: number = 0;
  pageFrom: number = -1;
  pageTo: number = -1;
  time: number = 0;

  /** Copy all fields from another QuickSearch instance. */
  copyFrom(other: QuickSearch): void {
    this.id = other.id;
    this.name = other.name;
    this.mode = other.mode;
    this.category = other.category;
    this.keyword = other.keyword;
    this.advanceSearch = other.advanceSearch;
    this.minRating = other.minRating;
    this.pageFrom = other.pageFrom;
    this.pageTo = other.pageTo;
    this.time = other.time;
  }

  /** Check equality by search parameters (excluding id, name, time). */
  equals(other: QuickSearch | null): boolean {
    if (other === null) return false;
    return this.mode === other.mode
      && this.category === other.category
      && this.keyword === other.keyword
      && this.advanceSearch === other.advanceSearch
      && this.minRating === other.minRating
      && this.pageFrom === other.pageFrom
      && this.pageTo === other.pageTo;
  }

  toString(): string {
    return this.name;
  }

  /** Serialize to a plain JSON-compatible object. */
  toJSON(): Record<string, Object | null> {
    return {
      id: this.id,
      name: this.name,
      mode: this.mode,
      category: this.category,
      keyword: this.keyword,
      advanceSearch: this.advanceSearch,
      minRating: this.minRating,
      pageFrom: this.pageFrom,
      pageTo: this.pageTo,
      time: this.time,
    };
  }

  /** Deserialize from a plain object. */
  static fromJSON(json: Record<string, Object | null>): QuickSearch {
    const q = new QuickSearch();
    q.id = json['id'] as number | null ?? null;
    q.name = json['name'] as string ?? '';
    q.mode = json['mode'] as number ?? 0;
    q.category = json['category'] as number ?? 0;
    q.keyword = json['keyword'] as string | null ?? null;
    q.advanceSearch = json['advanceSearch'] as number ?? 0;
    q.minRating = json['minRating'] as number ?? 0;
    q.pageFrom = json['pageFrom'] as number ?? -1;
    q.pageTo = json['pageTo'] as number ?? -1;
    q.time = json['time'] as number ?? 0;
    return q;
  }
}
