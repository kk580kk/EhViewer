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

import { EhUrl } from '../client/EhUrl';

export class FavListUrlBuilder {
  static readonly FAV_CAT_ALL: number = -1;
  static readonly FAV_CAT_LOCAL: number = -2;

  private index: number = 0;
  private keyword: string | null = null;
  private favCat: number = FavListUrlBuilder.FAV_CAT_ALL;

  setIndex(index: number): void {
    this.index = index;
  }

  setKeyword(keyword: string | null): void {
    this.keyword = keyword;
  }

  setFavCat(favCat: number): void {
    this.favCat = favCat;
  }

  getKeyword(): string | null {
    return this.keyword;
  }

  getFavCat(): number {
    return this.favCat;
  }

  static isValidFavCat(favCat: number): boolean {
    return favCat >= 0 && favCat <= 9;
  }

  isLocalFavCat(): boolean {
    return this.favCat === FavListUrlBuilder.FAV_CAT_LOCAL;
  }

  build(): string {
    let url = EhUrl.getFavoritesUrl();
    const params: string[] = [];

    if (FavListUrlBuilder.isValidFavCat(this.favCat)) {
      params.push(`favcat=${this.favCat}`);
    } else if (this.favCat === FavListUrlBuilder.FAV_CAT_ALL) {
      params.push('favcat=all');
    }

    if (this.keyword !== null && this.keyword.length > 0) {
      params.push(`f_search=${encodeURIComponent(this.keyword)}`);
      params.push('sn=on');
      params.push('st=on');
      params.push('sf=on');
    }

    if (this.index > 0) {
      params.push(`page=${this.index}`);
    }

    if (params.length > 0) {
      url += '?' + params.join('&');
    }
    return url;
  }
}
