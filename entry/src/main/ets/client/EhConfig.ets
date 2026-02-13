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

import { SettingsService } from '../service/SettingsService.ets';
import { EhUrl } from './EhUrl.ets';
import { isValidInet4Address, isValidInetPort } from '../network/InetValidator.ets';

/** Default User-Agent sent with HTTP requests (Chrome on Windows). */
export const DEFAULT_USER_AGENT: string =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) ' +
  'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36';

export class EhConfig {
  // ---- Site (domain) ----
  /** Current gallery domain (e-hentai.org or exhentai.org) from settings. */
  static getGalleryDomain(): string {
    return SettingsService.getGallerySite() === EhUrl.SITE_EX ? EhUrl.DOMAIN_EX : EhUrl.DOMAIN_E;
  }

  // ---- Category bitmask values ----
  static readonly MISC: number = 0x1;
  static readonly DOUJINSHI: number = 0x2;
  static readonly MANGA: number = 0x4;
  static readonly ARTIST_CG: number = 0x8;
  static readonly GAME_CG: number = 0x10;
  static readonly IMAGE_SET: number = 0x20;
  static readonly COSPLAY: number = 0x40;
  static readonly ASIAN_PORN: number = 0x80;
  static readonly NON_H: number = 0x100;
  static readonly WESTERN: number = 0x200;
  static readonly ALL_CATEGORY: number = 0x3ff;

  // ---- Tag namespace bitmask values ----
  static readonly NAMESPACES_RECLASS: number = 0x1;
  static readonly NAMESPACES_LANGUAGE: number = 0x2;
  static readonly NAMESPACES_PARODY: number = 0x4;
  static readonly NAMESPACES_CHARACTER: number = 0x8;
  static readonly NAMESPACES_GROUP: number = 0x10;
  static readonly NAMESPACES_ARTIST: number = 0x20;
  static readonly NAMESPACES_MALE: number = 0x40;
  static readonly NAMESPACES_FEMALE: number = 0x80;

  // ---- Cookie keys ----
  static readonly KEY_UCONFIG: string = 'uconfig';
  static readonly KEY_LOAD_FROM_HAH: string = 'uh';
  static readonly KEY_IMAGE_SIZE: string = 'xr';
  static readonly KEY_SCALE_WIDTH: string = 'rx';
  static readonly KEY_SCALE_HEIGHT: string = 'ry';
  static readonly KEY_GALLERY_TITLE: string = 'tl';
  static readonly KEY_ARCHIVER_DOWNLOAD: string = 'ar';
  static readonly KEY_LAYOUT_MODE: string = 'dm';
  static readonly KEY_POPULAR: string = 'prn';
  static readonly KEY_DEFAULT_CATEGORIES: string = 'cats';
  static readonly KEY_FAVORITES_SORT: string = 'fs';
  static readonly KEY_EXCLUDED_NAMESPACES: string = 'xns';
  static readonly KEY_EXCLUDED_LANGUAGES: string = 'xl';
  static readonly KEY_RESULT_COUNT: string = 'rc';
  static readonly KEY_MOUSE_OVER: string = 'lt';
  static readonly KEY_PREVIEW_SIZE: string = 'ts';
  static readonly KEY_PREVIEW_ROW: string = 'tr';
  static readonly KEY_COMMENTS_SORT: string = 'cs';
  static readonly KEY_COMMENTS_VOTES: string = 'sc';
  static readonly KEY_TAGS_SORT: string = 'to';
  static readonly KEY_SHOW_GALLERY_INDEX: string = 'pn';
  static readonly KEY_HAH_CLIENT_IP_PORT: string = 'hp';
  static readonly KEY_HAH_CLIENT_PASSKEY: string = 'hk';
  static readonly KEY_ENABLE_TAG_FLAGGING: string = 'tf';
  static readonly KEY_ALWAYS_ORIGINAL: string = 'oi';
  static readonly KEY_MULTI_PAGE: string = 'qb';
  static readonly KEY_MULTI_PAGE_STYLE: string = 'ms';
  static readonly KEY_MULTI_PAGE_THUMB: string = 'mt';
  static readonly KEY_CONTENT_WARNING: string = 'nw';

  static readonly LOAD_FROM_HAH_YES: string = 'y';
  static readonly LOAD_FROM_HAH_NO: string = 'n';
  static readonly IMAGE_SIZE_AUTO: string = 'a';
  static readonly IMAGE_SIZE_780X: string = '780';
  static readonly IMAGE_SIZE_980X: string = '980';
  static readonly IMAGE_SIZE_1280X: string = '1280';
  static readonly IMAGE_SIZE_1600X: string = '1600';
  static readonly IMAGE_SIZE_2400X: string = '2400';
  static readonly GALLERY_TITLE_DEFAULT: string = 'r';
  static readonly GALLERY_TITLE_JAPANESE: string = 'j';
  static readonly ARCHIVER_DOWNLOAD_MAMS: string = '0';
  static readonly ARCHIVER_DOWNLOAD_AAMS: string = '1';
  static readonly ARCHIVER_DOWNLOAD_MAAS: string = '2';
  static readonly ARCHIVER_DOWNLOAD_AAAS: string = '3';
  static readonly LAYOUT_MODE_LIST: string = 'l';
  static readonly LAYOUT_MODE_THUMB: string = 't';
  static readonly POPULAR_YES: string = 'y';
  static readonly POPULAR_NO: string = 'n';
  static readonly FAVORITES_SORT_GALLERY_UPDATE_TIME: string = 'p';
  static readonly FAVORITES_SORT_FAVORITED_TIME: string = 'f';
  static readonly RESULT_COUNT_25: string = '0';
  static readonly RESULT_COUNT_50: string = '1';
  static readonly RESULT_COUNT_100: string = '2';
  static readonly RESULT_COUNT_200: string = '3';
  static readonly MOUSE_OVER_YES: string = 'm';
  static readonly MOUSE_OVER_NO: string = 'p';
  static readonly PREVIEW_SIZE_NORMAL: string = 'm';
  static readonly PREVIEW_SIZE_LARGE: string = 'l';
  static readonly PREVIEW_ROW_4: string = '2';
  static readonly PREVIEW_ROW_10: string = '5';
  static readonly PREVIEW_ROW_20: string = '10';
  static readonly PREVIEW_ROW_40: string = '20';
  static readonly COMMENTS_SORT_OLDEST_FIRST: string = 'a';
  static readonly COMMENTS_SORT_RECENT_FIRST: string = 'd';
  static readonly COMMENTS_SORT_HIGHEST_SCORE_FIRST: string = 's';
  static readonly COMMENTS_VOTES_POP: string = '0';
  static readonly COMMENTS_VOTES_ALWAYS: string = '1';
  static readonly TAGS_SORT_ALPHABETICAL: string = 'a';
  static readonly TAGS_SORT_POWER: string = 'p';
  static readonly SHOW_GALLERY_INDEX_YES: string = '1';
  static readonly SHOW_GALLERY_INDEX_NO: string = '0';
  static readonly ENABLE_TAG_FLAGGING_YES: string = 'y';
  static readonly ENABLE_TAG_FLAGGING_NO: string = 'n';
  static readonly ALWAYS_ORIGINAL_YES: string = 'y';
  static readonly ALWAYS_ORIGINAL_NO: string = 'n';
  static readonly MULTI_PAGE_YES: string = 'y';
  static readonly MULTI_PAGE_NO: string = 'n';
  static readonly MULTI_PAGE_STYLE_N: string = 'n';
  static readonly MULTI_PAGE_STYLE_C: string = 'c';
  static readonly MULTI_PAGE_STYLE_Y: string = 'y';
  static readonly MULTI_PAGE_THUMB_SHOW: string = 'n';
  static readonly MULTI_PAGE_THUMB_HIDE: string = 'y';
  static readonly CONTENT_WARNING_SHOW: string = '0';
  static readonly CONTENT_WARNING_NOT_SHOW: string = '1';

  // ---- Instance: User-Agent & uconfig-related ----
  /** User-Agent sent with HTTP requests. */
  userAgent: string = DEFAULT_USER_AGENT;

  loadFromHAH: string = EhConfig.LOAD_FROM_HAH_YES;
  imageSize: string = EhConfig.IMAGE_SIZE_AUTO;
  scaleWidth: number = 0;
  scaleHeight: number = 0;
  galleryTitle: string = EhConfig.GALLERY_TITLE_DEFAULT;
  archiverDownload: string = EhConfig.ARCHIVER_DOWNLOAD_MAMS;
  layoutMode: string = EhConfig.LAYOUT_MODE_LIST;
  popular: string = EhConfig.POPULAR_YES;
  defaultCategories: number = 0;
  favoritesSort: string = EhConfig.FAVORITES_SORT_FAVORITED_TIME;
  excludedNamespaces: number = 0;
  excludedLanguages: string = '';
  resultCount: string = EhConfig.RESULT_COUNT_25;
  mouseOver: string = EhConfig.MOUSE_OVER_YES;
  previewSize: string = EhConfig.PREVIEW_SIZE_LARGE;
  previewRow: string = EhConfig.PREVIEW_ROW_4;
  commentSort: string = EhConfig.COMMENTS_SORT_OLDEST_FIRST;
  commentVotes: string = EhConfig.COMMENTS_VOTES_POP;
  tagSort: string = EhConfig.TAGS_SORT_ALPHABETICAL;
  showGalleryIndex: string = EhConfig.SHOW_GALLERY_INDEX_YES;
  hahClientIp: string = '';
  hahClientPort: number = -1;
  hahClientPasskey: string = '';
  enableTagFlagging: string = EhConfig.ENABLE_TAG_FLAGGING_NO;
  alwaysOriginal: string = EhConfig.ALWAYS_ORIGINAL_NO;
  multiPage: string = EhConfig.MULTI_PAGE_NO;
  multiPageStyle: string = EhConfig.MULTI_PAGE_STYLE_N;
  multiPageThumb: string = EhConfig.MULTI_PAGE_THUMB_SHOW;

  private dirty: boolean = true;
  private cachedUconfig: string = '';

  setDirty(): void {
    this.dirty = true;
  }

  uconfig(): string {
    if (this.dirty) {
      this.dirty = false;
      this.updateUconfig();
    }
    return this.cachedUconfig;
  }

  private updateUconfig(): void {
    const hahClientIpPort =
      (isValidInet4Address(this.hahClientIp) && isValidInetPort(this.hahClientPort))
        ? this.hahClientIp + '%3A' + this.hahClientPort
        : '';
    const hahClientPasskey = this.hahClientPasskey ?? '';
    this.cachedUconfig =
      EhConfig.KEY_LOAD_FROM_HAH + '_' + this.loadFromHAH + '-' +
      EhConfig.KEY_IMAGE_SIZE + '_' + this.imageSize + '-' +
      EhConfig.KEY_SCALE_WIDTH + '_' + this.scaleWidth + '-' +
      EhConfig.KEY_SCALE_HEIGHT + '_' + this.scaleHeight + '-' +
      EhConfig.KEY_GALLERY_TITLE + '_' + this.galleryTitle + '-' +
      EhConfig.KEY_ARCHIVER_DOWNLOAD + '_' + this.archiverDownload + '-' +
      EhConfig.KEY_LAYOUT_MODE + '_' + this.layoutMode + '-' +
      EhConfig.KEY_POPULAR + '_' + this.popular + '-' +
      EhConfig.KEY_DEFAULT_CATEGORIES + '_' + this.defaultCategories + '-' +
      EhConfig.KEY_FAVORITES_SORT + '_' + this.favoritesSort + '-' +
      EhConfig.KEY_EXCLUDED_NAMESPACES + '_' + this.excludedNamespaces + '-' +
      EhConfig.KEY_EXCLUDED_LANGUAGES + '_' + this.excludedLanguages + '-' +
      EhConfig.KEY_RESULT_COUNT + '_' + this.resultCount + '-' +
      EhConfig.KEY_MOUSE_OVER + '_' + this.mouseOver + '-' +
      EhConfig.KEY_PREVIEW_SIZE + '_' + this.previewSize + '-' +
      EhConfig.KEY_PREVIEW_ROW + '_' + this.previewRow + '-' +
      EhConfig.KEY_COMMENTS_SORT + '_' + this.commentSort + '-' +
      EhConfig.KEY_COMMENTS_VOTES + '_' + this.commentVotes + '-' +
      EhConfig.KEY_TAGS_SORT + '_' + this.tagSort + '-' +
      EhConfig.KEY_SHOW_GALLERY_INDEX + '_' + this.showGalleryIndex + '-' +
      EhConfig.KEY_HAH_CLIENT_IP_PORT + '_' + hahClientIpPort + '-' +
      EhConfig.KEY_HAH_CLIENT_PASSKEY + '_' + hahClientPasskey + '-' +
      EhConfig.KEY_ENABLE_TAG_FLAGGING + '_' + this.enableTagFlagging + '-' +
      EhConfig.KEY_ALWAYS_ORIGINAL + '_' + this.alwaysOriginal + '-' +
      EhConfig.KEY_MULTI_PAGE + '_' + this.multiPage + '-' +
      EhConfig.KEY_MULTI_PAGE_STYLE + '_' + this.multiPageStyle + '-' +
      EhConfig.KEY_MULTI_PAGE_THUMB + '_' + this.multiPageThumb;
  }

  clone(): EhConfig {
    const c = new EhConfig();
    c.userAgent = this.userAgent;
    c.loadFromHAH = this.loadFromHAH;
    c.imageSize = this.imageSize;
    c.scaleWidth = this.scaleWidth;
    c.scaleHeight = this.scaleHeight;
    c.galleryTitle = this.galleryTitle;
    c.archiverDownload = this.archiverDownload;
    c.layoutMode = this.layoutMode;
    c.popular = this.popular;
    c.defaultCategories = this.defaultCategories;
    c.favoritesSort = this.favoritesSort;
    c.excludedNamespaces = this.excludedNamespaces;
    c.excludedLanguages = this.excludedLanguages;
    c.resultCount = this.resultCount;
    c.mouseOver = this.mouseOver;
    c.previewSize = this.previewSize;
    c.previewRow = this.previewRow;
    c.commentSort = this.commentSort;
    c.commentVotes = this.commentVotes;
    c.tagSort = this.tagSort;
    c.showGalleryIndex = this.showGalleryIndex;
    c.hahClientIp = this.hahClientIp;
    c.hahClientPort = this.hahClientPort;
    c.hahClientPasskey = this.hahClientPasskey;
    c.enableTagFlagging = this.enableTagFlagging;
    c.alwaysOriginal = this.alwaysOriginal;
    c.multiPage = this.multiPage;
    c.multiPageStyle = this.multiPageStyle;
    c.multiPageThumb = this.multiPageThumb;
    c.dirty = true;
    return c;
  }
}
