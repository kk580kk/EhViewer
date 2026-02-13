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

import { EhUrl } from '../EhUrl';
import { ListUrlBuilder } from '../../model/ListUrlBuilder';

const VALID_HOSTS: string[] = [EhUrl.DOMAIN_EX, EhUrl.DOMAIN_E, EhUrl.DOMAIN_LOFI];
const PATH_UPLOADER = '/uploader/';
const PATH_TAG = '/tag/';

export class GalleryListUrlParser {

  static parse(urlStr: string): ListUrlBuilder | null {
    let url: URL;
    try {
      url = new URL(urlStr);
    } catch (_) {
      return null;
    }

    if (!VALID_HOSTS.includes(url.hostname)) {
      return null;
    }

    const path = url.pathname;
    const query = url.search ? url.search.substring(1) : null;
    if (path === '/' || path.length === 0) {
      const builder = new ListUrlBuilder();
      builder.setQuery(query);
      GalleryListUrlParser.parsePageFromQuery(query, builder);
      return builder;
    } else if (path.startsWith(PATH_UPLOADER)) {
      return GalleryListUrlParser.parseUploader(path);
    } else if (path.startsWith(PATH_TAG)) {
      return GalleryListUrlParser.parseTag(path);
    } else if (path.startsWith('/')) {
      const catStr = path.substring(1).replace(/\//g, '');
      const category = Number.parseInt(catStr, 10);
      if (Number.isNaN(category)) return null;
      const builder = new ListUrlBuilder();
      builder.setQuery(query);
      GalleryListUrlParser.parsePageFromQuery(query, builder);
      builder.setCategory(category);
      return builder;
    }
    return null;
  }

  private static parseUploader(path: string): ListUrlBuilder | null {
    const prefixLen = PATH_UPLOADER.length;
    const idx = path.indexOf('/', prefixLen);
    let uploader: string;
    if (idx < 0) {
      uploader = path.substring(prefixLen);
    } else {
      uploader = path.substring(prefixLen, idx);
    }
    try {
      uploader = decodeURIComponent(uploader);
    } catch (_) {
      return null;
    }
    if (uploader.length === 0) return null;

    const builder = new ListUrlBuilder();
    builder.setMode(ListUrlBuilder.MODE_UPLOADER);
    builder.setKeyword(uploader);
    GalleryListUrlParser.parsePageFromPath(path, idx, builder);
    return builder;
  }

  private static parseTag(path: string): ListUrlBuilder | null {
    const prefixLen = PATH_TAG.length;
    const idx = path.indexOf('/', prefixLen);
    let tag: string;
    if (idx < 0) {
      tag = path.substring(prefixLen);
    } else {
      tag = path.substring(prefixLen, idx);
    }
    try {
      tag = decodeURIComponent(tag);
    } catch (_) {
      return null;
    }
    if (tag.length === 0) return null;

    const builder = new ListUrlBuilder();
    builder.setMode(ListUrlBuilder.MODE_TAG);
    builder.setKeyword(tag);
    GalleryListUrlParser.parsePageFromPath(path, idx, builder);
    return builder;
  }

  private static parsePageFromQuery(query: string | null, builder: ListUrlBuilder): void {
    if (query == null || query.length === 0) return;
    for (const pair of query.split('&')) {
      const eq = pair.indexOf('=');
      if (eq < 0) continue;
      if (pair.substring(0, eq) === 'page') {
        const page = Number.parseInt(pair.substring(eq + 1), 10);
        if (!Number.isNaN(page) && page >= 0) {
          builder.setPageIndex(page);
        }
        return;
      }
    }
  }

  private static parsePageFromPath(path: string, slashIndex: number, builder: ListUrlBuilder): void {
    if (slashIndex < 0) return;
    let rest = path.substring(slashIndex + 1).trim();
    if (rest.length === 0) return;
    const page = Number.parseInt(rest, 10);
    if (!Number.isNaN(page) && page >= 0) {
      builder.setPageIndex(page);
    }
  }
}
