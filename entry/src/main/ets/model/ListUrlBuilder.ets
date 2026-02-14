/*
 * Copyright 2015 Hippo Seven
 * Ported to HarmonyOS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { EhConfig } from '../client/EhConfig';
import { EhUrl } from '../client/EhUrl';
import { EhUtils } from '../client/EhUtils';
import { AdvanceSearchTable } from './AdvanceSearchTable';
import { QuickSearch } from './QuickSearch';

export class ListUrlBuilder {
  static readonly MODE_NORMAL: number = 0x0;
  static readonly MODE_UPLOADER: number = 0x1;
  static readonly MODE_TAG: number = 0x2;
  static readonly MODE_WHATS_HOT: number = 0x3;
  static readonly MODE_IMAGE_SEARCH: number = 0x4;
  static readonly MODE_SUBSCRIPTION: number = 0x5;

  static readonly DEFAULT_ADVANCE: number = AdvanceSearchTable.SNAME | AdvanceSearchTable.STAGS;
  static readonly DEFAULT_MIN_RATING: number = 2;

  private mode: number = ListUrlBuilder.MODE_NORMAL;
  private pageIndex: number = 0;
  private category: number = EhUtils.NONE;
  private keyword: string | null = null;
  private advanceSearch: number = -1;
  private minRating: number = -1;
  private pageFrom: number = -1;
  private pageTo: number = -1;
  private imagePath: string | null = null;
  private useSimilarityScan: boolean = false;
  private onlySearchCovers: boolean = false;
  private showExpunged: boolean = false;

  getMode(): number { return this.mode; }
  setMode(mode: number): void { this.mode = mode; }

  getPageIndex(): number { return this.pageIndex; }
  setPageIndex(index: number): void { this.pageIndex = index; }

  getCategory(): number { return this.category; }
  setCategory(category: number): void { this.category = category; }

  getKeyword(): string | null { return this.keyword; }
  setKeyword(keyword: string | null): void { this.keyword = keyword; }

  getAdvanceSearch(): number { return this.advanceSearch; }
  setAdvanceSearch(advanceSearch: number): void { this.advanceSearch = advanceSearch; }

  getMinRating(): number { return this.minRating; }
  setMinRating(minRating: number): void { this.minRating = minRating; }

  getPageFrom(): number { return this.pageFrom; }
  setPageFrom(pageFrom: number): void { this.pageFrom = pageFrom; }

  getPageTo(): number { return this.pageTo; }
  setPageTo(pageTo: number): void { this.pageTo = pageTo; }

  getImagePath(): string | null { return this.imagePath; }
  setImagePath(imagePath: string | null): void { this.imagePath = imagePath; }

  isUseSimilarityScan(): boolean { return this.useSimilarityScan; }
  setUseSimilarityScan(useSimilarityScan: boolean): void { this.useSimilarityScan = useSimilarityScan; }

  isOnlySearchCovers(): boolean { return this.onlySearchCovers; }
  setOnlySearchCovers(onlySearchCovers: boolean): void { this.onlySearchCovers = onlySearchCovers; }

  isShowExpunged(): boolean { return this.showExpunged; }
  setShowExpunged(showExpunged: boolean): void { this.showExpunged = showExpunged; }

  /** Copy all fields from another ListUrlBuilder. */
  set(lub: ListUrlBuilder): void {
    this.mode = lub.mode;
    this.pageIndex = lub.pageIndex;
    this.category = lub.category;
    this.keyword = lub.keyword;
    this.advanceSearch = lub.advanceSearch;
    this.minRating = lub.minRating;
    this.pageFrom = lub.pageFrom;
    this.pageTo = lub.pageTo;
    this.imagePath = lub.imagePath;
    this.useSimilarityScan = lub.useSimilarityScan;
    this.onlySearchCovers = lub.onlySearchCovers;
    this.showExpunged = lub.showExpunged;
  }

  /** Populate from a QuickSearch entry. */
  setFromQuickSearch(q: QuickSearch): void {
    this.mode = q.mode;
    this.pageIndex = 0;
    this.category = q.category;
    this.keyword = q.keyword;
    this.advanceSearch = q.advanceSearch;
    this.minRating = q.minRating;
    this.pageFrom = q.pageFrom;
    this.pageTo = q.pageTo;
    this.imagePath = null;
    this.useSimilarityScan = false;
    this.onlySearchCovers = false;
    this.showExpunged = false;
  }

  /** Check if this builder matches a QuickSearch entry. */
  equalsQuickSearch(q: QuickSearch | null): boolean {
    if (q === null) return false;
    return q.mode === this.mode
      && q.category === this.category
      && q.keyword === this.keyword
      && q.advanceSearch === this.advanceSearch
      && q.minRating === this.minRating
      && q.pageFrom === this.pageFrom
      && q.pageTo === this.pageTo;
  }

  /** Create a shallow clone of this builder. */
  clone(): ListUrlBuilder {
    const copy = new ListUrlBuilder();
    copy.set(this);
    return copy;
  }

  /** Convert current state to a QuickSearch entry. */
  toQuickSearch(): QuickSearch {
    const q = new QuickSearch();
    q.mode = this.mode;
    q.category = this.category;
    q.keyword = this.keyword;
    q.advanceSearch = this.advanceSearch;
    q.minRating = this.minRating;
    q.pageFrom = this.pageFrom;
    q.pageTo = this.pageTo;
    return q;
  }

  /** Build the request URL string from current state. */
  build(): string {
    switch (this.mode) {
      case ListUrlBuilder.MODE_UPLOADER: {
        let url = EhUrl.getHost() + 'uploader/';
        if (this.keyword) {
          url += encodeURIComponent(this.keyword);
        }
        if (this.pageIndex !== 0) {
          url += '/' + this.pageIndex;
        }
        return url;
      }
      case ListUrlBuilder.MODE_TAG: {
        let url = EhUrl.getHost() + 'tag/';
        if (this.keyword) {
          url += encodeURIComponent(this.keyword);
        }
        if (this.pageIndex !== 0) {
          url += '/' + this.pageIndex;
        }
        return url;
      }
      case ListUrlBuilder.MODE_WHATS_HOT:
        return EhUrl.getPopularUrl();
      case ListUrlBuilder.MODE_IMAGE_SEARCH:
        return EhUrl.getImageSearchUrl();
      case ListUrlBuilder.MODE_SUBSCRIPTION:
      case ListUrlBuilder.MODE_NORMAL:
      default: {
        const base = this.mode === ListUrlBuilder.MODE_SUBSCRIPTION
          ? EhUrl.getWatchedUrl()
          : EhUrl.getHost();
        const params: string[] = [];
        if (this.category !== EhUtils.NONE) {
          params.push('f_cats=' + ((~this.category) & EhConfig.ALL_CATEGORY));
        }
        if (this.keyword !== null) {
          const kw = this.keyword.trim();
          if (kw.length > 0) {
            params.push('f_search=' + encodeURIComponent(kw));
          }
        }
        if (this.pageIndex !== 0) {
          params.push('page=' + this.pageIndex);
        }
        if (this.advanceSearch !== -1) {
          params.push('advsearch=1');
          if ((this.advanceSearch & AdvanceSearchTable.SNAME) !== 0) params.push('f_sname=on');
          if ((this.advanceSearch & AdvanceSearchTable.STAGS) !== 0) params.push('f_stags=on');
          if ((this.advanceSearch & AdvanceSearchTable.SDESC) !== 0) params.push('f_sdesc=on');
          if ((this.advanceSearch & AdvanceSearchTable.STORR) !== 0) params.push('f_storr=on');
          if ((this.advanceSearch & AdvanceSearchTable.STO) !== 0) params.push('f_sto=on');
          if ((this.advanceSearch & AdvanceSearchTable.SDT1) !== 0) params.push('f_sdt1=on');
          if ((this.advanceSearch & AdvanceSearchTable.SDT2) !== 0) params.push('f_sdt2=on');
          if ((this.advanceSearch & AdvanceSearchTable.SH) !== 0) params.push('f_sh=on');
          if ((this.advanceSearch & AdvanceSearchTable.SFL) !== 0) params.push('f_sfl=on');
          if ((this.advanceSearch & AdvanceSearchTable.SFU) !== 0) params.push('f_sfu=on');
          if ((this.advanceSearch & AdvanceSearchTable.SFT) !== 0) params.push('f_sft=on');
          if (this.minRating !== -1) {
            params.push('f_sr=on');
            params.push('f_srdd=' + this.minRating);
          }
          if (this.pageFrom !== -1 || this.pageTo !== -1) {
            params.push('f_sp=on');
            params.push('f_spf=' + (this.pageFrom !== -1 ? this.pageFrom : ''));
            params.push('f_spt=' + (this.pageTo !== -1 ? this.pageTo : ''));
          }
        }
        return params.length > 0 ? base + '?' + params.join('&') : base;
      }
    }
  }

  setQuery(query: string | null): void {
    this.reset();
    if (query == null || query.length === 0) return;

    const parts = query.split('&');
    let category = 0;
    let keyword: string | null = null;
    let enableAdvanceSearch = false;
    let advanceSearch = 0;
    let enableMinRating = false;
    let minRating = -1;
    let enablePage = false;
    let pageFrom = -1;
    let pageTo = -1;

    for (const part of parts) {
      const idx = part.indexOf('=');
      if (idx < 0) continue;
      const key = part.substring(0, idx);
      const value = part.substring(idx + 1);
      switch (key) {
        case 'f_cats': {
          const cats = Number.parseInt(value, 10);
          if (!Number.isNaN(cats)) { category |= (~cats) & 0x3ff; }
          break;
        }
        case 'f_doujinshi': if (value === '1') category |= EhConfig.DOUJINSHI; break;
        case 'f_manga': if (value === '1') category |= EhConfig.MANGA; break;
        case 'f_artistcg': if (value === '1') category |= EhConfig.ARTIST_CG; break;
        case 'f_gamecg': if (value === '1') category |= EhConfig.GAME_CG; break;
        case 'f_western': if (value === '1') category |= EhConfig.WESTERN; break;
        case 'f_non-h': if (value === '1') category |= EhConfig.NON_H; break;
        case 'f_imageset': if (value === '1') category |= EhConfig.IMAGE_SET; break;
        case 'f_cosplay': if (value === '1') category |= EhConfig.COSPLAY; break;
        case 'f_asianporn': if (value === '1') category |= EhConfig.ASIAN_PORN; break;
        case 'f_misc': if (value === '1') category |= EhConfig.MISC; break;
        case 'f_search':
          try { keyword = decodeURIComponent(value); } catch (_) { /* ignore */ }
          break;
        case 'advsearch':
          if (value === '1') enableAdvanceSearch = true;
          break;
        case 'f_sname': if (value === 'on') advanceSearch |= 0x1; break;
        case 'f_stags': if (value === 'on') advanceSearch |= 0x2; break;
        case 'f_sdesc': if (value === 'on') advanceSearch |= 0x4; break;
        case 'f_storr': if (value === 'on') advanceSearch |= 0x8; break;
        case 'f_sto':   if (value === 'on') advanceSearch |= 0x10; break;
        case 'f_sdt1':  if (value === 'on') advanceSearch |= 0x20; break;
        case 'f_sdt2':  if (value === 'on') advanceSearch |= 0x40; break;
        case 'f_sh':    if (value === 'on') advanceSearch |= 0x80; break;
        case 'f_sr':    if (value === 'on') enableMinRating = true; break;
        case 'f_srdd': { const v = Number.parseInt(value, 10); if (!Number.isNaN(v)) minRating = v; break; }
        case 'f_sp':    if (value === 'on') enablePage = true; break;
        case 'f_spf': { const v = Number.parseInt(value, 10); if (!Number.isNaN(v)) pageFrom = v; break; }
        case 'f_spt': { const v = Number.parseInt(value, 10); if (!Number.isNaN(v)) pageTo = v; break; }
      }
    }

    this.category = category;
    this.keyword = keyword;
    if (enableAdvanceSearch) {
      this.advanceSearch = advanceSearch;
      this.minRating = enableMinRating ? minRating : -1;
      if (enablePage) { this.pageFrom = pageFrom; this.pageTo = pageTo; }
      else { this.pageFrom = -1; this.pageTo = -1; }
    } else {
      this.advanceSearch = -1;
    }
  }

  private reset(): void {
    this.mode = ListUrlBuilder.MODE_NORMAL;
    this.pageIndex = 0;
    this.category = EhUtils.NONE;
    this.keyword = null;
    this.advanceSearch = -1;
    this.minRating = -1;
    this.pageFrom = -1;
    this.pageTo = -1;
    this.imagePath = null;
    this.useSimilarityScan = false;
    this.onlySearchCovers = false;
    this.showExpunged = false;
  }
}
