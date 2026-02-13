/*
 * Copyright 2016 Hippo Seven
 * Ported to HarmonyOS ArkTS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import type { HttpClient, KV } from '../network/HttpClient.ets';
import { buildEhHeaders } from '../network/HttpClient.ets';
import { EhUrl } from './EhUrl.ets';
import { EhException } from './exception/EhException.ets';
import { EhSignIn } from './EhSignIn.ets';
import { GalleryListParser } from './parser/GalleryListParser.ets';
import type { GalleryListResult } from './parser/GalleryListParser.ets';
import { GalleryDetailParser } from './parser/GalleryDetailParser.ets';
import { GalleryApiParser } from './parser/GalleryApiParser.ets';
import { GalleryTokenApiParser } from './parser/GalleryTokenApiParser.ets';
import { GalleryPageParser } from './parser/GalleryPageParser.ets';
import { GalleryPageApiParser } from './parser/GalleryPageApiParser.ets';
import { RateGalleryParser } from './parser/RateGalleryParser.ets';
import { VoteCommentParser } from './parser/VoteCommentParser.ets';
import { FavoritesParser } from './parser/FavoritesParser.ets';
import type { FavoritesResult } from './parser/FavoritesParser.ets';
import type { ProfileResult } from './parser/ProfileParser.ets';
import type { GalleryPageResult } from './parser/GalleryPageParser.ets';
import type { GalleryPageApiResult } from './parser/GalleryPageApiParser.ets';
import type { RateGalleryResult } from './parser/RateGalleryParser.ets';
import type { VoteCommentResult } from './parser/VoteCommentParser.ets';
import { GalleryInfo } from '../model/GalleryInfo';
import { GalleryDetail } from '../model/GalleryDetail';
import { GalleryCommentList } from '../model/GalleryComment';

const SAD_PANDA_DISPOSITION = 'inline; filename="sadpanda.jpg"';
const KOKOMADE_URL = 'https://exhentai.org/img/kokomade.jpg';
const MAX_API_BATCH = 25;

function checkBodyAndThrow(body: string, _headers?: Record<string, string>): void {
  if (body.includes(KOKOMADE_URL)) {
    throw new EhException('Kokomade');
  }
}

/**
 * ArkTS implementation of EhEngine.
 * Provides: list, detail, gallery page, comments, sign-in, favorites, rating, vote.
 */
export class EhEngine {
  private readonly httpClient: HttpClient;
  private readonly signInService: EhSignIn;

  constructor(httpClient: HttpClient, signInService: EhSignIn) {
    this.httpClient = httpClient;
    this.signInService = signInService;
  }

  /** Sign in with username and password. Returns display name. */
  async signIn(username: string, password: string): Promise<string> {
    const result = await this.signInService.signIn(username, password);
    return result.displayName;
  }

  /** Get current user profile (display name, avatar). */
  async getProfile(): Promise<ProfileResult> {
    return this.signInService.getProfile();
  }

  /** Whether the user has valid sign-in cookies. */
  hasSignedIn(): boolean {
    return this.signInService.hasSignedIn();
  }

  /** Clear cookies (sign out). */
  signOut(): void {
    this.signInService.signOut();
  }

  /**
   * Fetch a page of gallery list from the given URL.
   * Optionally fills missing fields (tags, pages, rating) via API in batches of 25.
   */
  async getGalleryList(url: string, fillByApi: boolean = true): Promise<GalleryListResult> {
    const referer = EhUrl.getReferer();
    const response = await this.httpClient.get(url, buildEhHeaders(referer));
    checkBodyAndThrow(response.body, response.headers);
    const result = GalleryListParser.parse(response.body);

    if (fillByApi && result.galleryInfoList.length > 0) {
      await this.fillGalleryListByApi(result.galleryInfoList, referer);
    }

    for (const info of result.galleryInfoList) {
      info.thumb = EhUrl.getFixedPreviewThumbUrl(info.thumb);
    }
    return result;
  }

  /** Fill gallery list items with extra data from gdata API (batch of 25). */
  async fillGalleryListByApi(
    galleryInfoList: GalleryInfo[],
    referer: string
  ): Promise<void> {
    for (let i = 0; i < galleryInfoList.length; i += MAX_API_BATCH) {
      const batch = galleryInfoList.slice(i, i + MAX_API_BATCH);
      const gidlist = batch.map(gi => [gi.gid, gi.token]);
      const json = JSON.stringify({ method: 'gdata', gidlist, namespace: 1 });
      const url = EhUrl.getApiUrl();
      const origin = EhUrl.getOrigin();
      const response = await this.httpClient.postJson(url, json, buildEhHeaders(referer, origin));
      checkBodyAndThrow(response.body);
      GalleryApiParser.parse(response.body, batch);
      for (const gi of batch) {
        gi.generateSLang();
      }
    }
  }

  /** Get gallery detail from detail page URL. */
  async getGalleryDetail(url: string): Promise<GalleryDetail> {
    const referer = EhUrl.getReferer();
    const response = await this.httpClient.get(url, buildEhHeaders(referer));
    checkBodyAndThrow(response.body, response.headers);
    return GalleryDetailParser.parse(response.body);
  }

  /** Get gallery page (image URL etc.) from page HTML URL. */
  async getGalleryPage(
    pageUrl: string,
    _gid: number,
    _token: string
  ): Promise<GalleryPageResult> {
    const referer = EhUrl.getGalleryDetailUrl(_gid, _token);
    const response = await this.httpClient.get(pageUrl, buildEhHeaders(referer));
    checkBodyAndThrow(response.body);
    return GalleryPageParser.parse(response.body);
  }

  /** Get gallery page image via showpage API. */
  async getGalleryPageApi(
    gid: number,
    index: number,
    pToken: string,
    showKey: string,
    previousPToken: string | null
  ): Promise<GalleryPageApiResult> {
    const json = JSON.stringify({
      method: 'showpage',
      gid,
      page: index + 1,
      imgkey: pToken,
      showkey: showKey,
    });
    const url = EhUrl.getApiUrl();
    const referer = index > 0 && previousPToken
      ? EhUrl.getPageUrl(gid, index - 1, previousPToken)
      : undefined;
    const origin = EhUrl.getOrigin();
    const response = await this.httpClient.postJson(url, json, buildEhHeaders(referer, origin));
    checkBodyAndThrow(response.body);
    return GalleryPageApiParser.parse(response.body);
  }

  /** Get page token for a gallery page (for loading image via API). */
  async getGalleryToken(gid: number, gtoken: string, page: number): Promise<string> {
    const json = JSON.stringify({
      method: 'gtoken',
      pagelist: [[gid, gtoken, page + 1]],
    });
    const url = EhUrl.getApiUrl();
    const origin = EhUrl.getOrigin();
    const response = await this.httpClient.postJson(url, json, buildEhHeaders(EhUrl.getReferer(), origin));
    checkBodyAndThrow(response.body);
    return GalleryTokenApiParser.parse(response.body);
  }

  /** Post a comment (new or edit). Returns updated comment list. */
  async commentGallery(
    url: string,
    comment: string,
    editCommentId: string | null
  ): Promise<GalleryCommentList> {
    const fields: KV[] = editCommentId
      ? [
          { key: 'commenttext_edit', value: comment },
          { key: 'edit_comment', value: editCommentId },
        ]
      : [{ key: 'commenttext_new', value: comment }];
    const origin = EhUrl.getOrigin();
    const response = await this.httpClient.postForm(url, fields, buildEhHeaders(url, origin));
    checkBodyAndThrow(response.body);
    const errorMatch = response.body.match(/#chd \+ p[\s\S]*?<p>([^<]+)</);
    if (errorMatch) {
      throw new EhException(errorMatch[1]);
    }
    return GalleryDetailParser.parseCommentsFromBody(response.body);
  }

  /** Rate a gallery. */
  async rateGallery(
    apiUid: number,
    apiKey: string,
    gid: number,
    token: string,
    rating: number
  ): Promise<RateGalleryResult> {
    const json = JSON.stringify({
      method: 'rategallery',
      apiuid: apiUid,
      apikey: apiKey,
      gid,
      token,
      rating: Math.ceil(rating * 2),
    });
    const url = EhUrl.getApiUrl();
    const referer = EhUrl.getGalleryDetailUrl(gid, token);
    const origin = EhUrl.getOrigin();
    const response = await this.httpClient.postJson(url, json, buildEhHeaders(referer, origin));
    checkBodyAndThrow(response.body);
    return RateGalleryParser.parse(response.body);
  }

  /** Vote on a comment (e.g. 1 for up, -1 for down). */
  async voteComment(
    apiUid: number,
    apiKey: string,
    gid: number,
    token: string,
    commentId: number,
    commentVote: number
  ): Promise<VoteCommentResult> {
    const json = JSON.stringify({
      method: 'votecomment',
      apiuid: apiUid,
      apikey: apiKey,
      gid,
      token,
      comment_id: commentId,
      comment_vote: commentVote,
    });
    const url = EhUrl.getApiUrl();
    const origin = EhUrl.getOrigin();
    const response = await this.httpClient.postJson(url, json, buildEhHeaders(EhUrl.getReferer(), origin));
    checkBodyAndThrow(response.body);
    return VoteCommentParser.parse(response.body, commentVote);
  }

  /** Get favorites page. */
  async getFavorites(url: string, fillByApi: boolean = false): Promise<FavoritesResult> {
    const referer = EhUrl.getReferer();
    const response = await this.httpClient.get(url, buildEhHeaders(referer));
    checkBodyAndThrow(response.body);
    const result = FavoritesParser.parse(response.body);
    if (fillByApi && result.galleryInfoList.length > 0) {
      await this.fillGalleryListByApi(result.galleryInfoList, url);
    }
    for (const info of result.galleryInfoList) {
      info.thumb = EhUrl.getFixedPreviewThumbUrl(info.thumb);
    }
    return result;
  }

  /**
   * Add a gallery to favorites.
   * @param dstCat -1 = remove, 0–9 = favorite category
   * @param note optional note (max 250 chars)
   */
  async addFavorites(
    gid: number,
    token: string,
    dstCat: number,
    note: string | null = null
  ): Promise<void> {
    const catStr = dstCat === -1 ? 'favdel' : (dstCat >= 0 && dstCat <= 9 ? String(dstCat) : '');
    if (dstCat < -1 || dstCat > 9) {
      throw new EhException('Invalid dstCat: ' + dstCat);
    }
    const url = EhUrl.getAddFavorites(gid, token);
    const origin = EhUrl.getOrigin();
    const fields: KV[] = [
      { key: 'favcat', value: catStr },
      { key: 'favnote', value: note ?? '' },
      { key: 'submit', value: 'Apply Changes' },
      { key: 'update', value: '1' },
    ];
    await this.httpClient.postForm(url, fields, buildEhHeaders(url, origin));
  }

  /** Add multiple galleries to a favorite category. */
  async addFavoritesRange(
    gidArray: number[],
    tokenArray: string[],
    dstCat: number
  ): Promise<void> {
    if (gidArray.length !== tokenArray.length) {
      throw new EhException('gid and token array length mismatch');
    }
    for (let i = 0; i < gidArray.length; i++) {
      await this.addFavorites(gidArray[i], tokenArray[i], dstCat, null);
    }
  }

  /** Move or remove galleries in favorites (from a favorites page URL). */
  async modifyFavorites(
    url: string,
    gidArray: number[],
    dstCat: number
  ): Promise<FavoritesResult> {
    const catStr = dstCat === -1 ? 'delete' : (dstCat >= 0 && dstCat <= 9 ? 'fav' + dstCat : '');
    if (dstCat < -1 || dstCat > 9) {
      throw new EhException('Invalid dstCat: ' + dstCat);
    }
    const origin = EhUrl.getOrigin();
    const fields: KV[] = [
      { key: 'ddact', value: catStr },
      ...gidArray.map(gid => ({ key: 'modifygids[]', value: String(gid) })),
      { key: 'apply', value: 'Apply' },
    ];
    const response = await this.httpClient.postForm(url, fields, buildEhHeaders(url, origin));
    checkBodyAndThrow(response.body);
    const result = FavoritesParser.parse(response.body);
    for (const info of result.galleryInfoList) {
      info.thumb = EhUrl.getFixedPreviewThumbUrl(info.thumb);
    }
    return result;
  }
}
