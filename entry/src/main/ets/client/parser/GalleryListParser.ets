/*
 * Copyright 2016 Hippo Seven
 * Ported to HarmonyOS ArkTS (regex-based)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { GalleryInfo } from '../../model/GalleryInfo';
import { EhUtils } from '../EhUtils';
import { ParserUtils } from './ParserUtils';
import { GalleryDetailUrlParser } from './GalleryDetailUrlParser';
import { ParseException } from '../exception/ParseException.ets';

export interface GalleryListResult {
  pages: number;
  nextPage: number;
  noWatchedTags: boolean;
  galleryInfoList: GalleryInfo[];
}

const PATTERN_NEXT_PAGE = /page=(\d+)/;
const PATTERN_PTT_PAGES = /class="ptt"[\s\S]*?<td[^>]*>(\d+)<\/td>/g;
const PATTERN_GALLERY_LINK = /href="([^"]*\/g\/\d+\/[0-9a-f]{10}[^"]*)"/gi;
const PATTERN_TITLE_IN_GLNAME = /class="glname"[\s\S]*?\/g\/(\d+)\/([0-9a-f]{10})\/[^"]*"[^>]*>([^<]+)</;
const PATTERN_PAGES = /(\d+)\s*page/;
const PATTERN_RATING = /(\d+)px[^}]*}(\s*[^}]*)?(\d+)px/;
const PATTERN_FAVORITE_SLOT = /background-color:rgba\((\d+),(\d+),(\d+),/;
const FAVORITE_SLOT_RGB: [string, string, string][] = [
  ['0', '0', '0'],
  ['240', '0', '0'],
  ['240', '160', '0'],
  ['208', '208', '0'],
  ['0', '128', '0'],
  ['144', '240', '64'],
  ['64', '176', '240'],
  ['0', '0', '240'],
  ['80', '0', '128'],
  ['224', '128', '224'],
];

function parseRating(ratingStyle: string): string | null {
  const m = PATTERN_RATING.exec(ratingStyle);
  if (!m) return null;
  const num1 = ParserUtils.parseInt(m[1], -1);
  const num2 = ParserUtils.parseInt(m[3], -1);
  if (num1 < 0 || num2 < 0) return null;
  let rate = 5 - Math.floor(num1 / 16);
  if (num2 === 21) rate -= 1;
  return rate === Math.floor(rate) ? String(rate) : `${rate}.5`;
}

function parseFavoriteSlot(style: string): number {
  const m = PATTERN_FAVORITE_SLOT.exec(style);
  if (!m) return -2;
  const r = m[1];
  const g = m[2];
  const b = m[3];
  for (let slot = 0; slot < FAVORITE_SLOT_RGB.length; slot++) {
    const [sr, sg, sb] = FAVORITE_SLOT_RGB[slot];
    if (r === sr && g === sg && b === sb) return slot;
  }
  return -2;
}

function parseGalleryFromBlock(block: string): GalleryInfo | null {
  const urlResult = GalleryDetailUrlParser.parse(block, false);
  if (!urlResult) return null;

  const gi = new GalleryInfo();
  gi.gid = urlResult.gid;
  gi.token = urlResult.token;

  const titleM = PATTERN_TITLE_IN_GLNAME.exec(block);
  if (titleM) {
    gi.title = ParserUtils.trim(titleM[3]);
  } else {
    const altM = /\/g\/\d+\/[0-9a-f]{10}\/[^"]*"[^>]*>([^<]{3,})</.exec(block);
    gi.title = altM ? ParserUtils.trim(altM[1]) : '';
  }
  if (!gi.title) return null;

  const cnM = /class="(?:cn|cs)"[^>]*>([^<]+)</.exec(block);
  if (cnM) {
    gi.category = EhUtils.getCategoryByString(ParserUtils.trim(cnM[1]));
  } else {
    gi.category = EhUtils.UNKNOWN;
  }

  const thumbM = /(?:data-src|src)="([^"]+)"/.exec(block);
  if (thumbM) {
    gi.thumb = EhUtils.handleThumbUrlResolution(ParserUtils.trim(thumbM[1])) ?? '';
  }

  const pagesM = PATTERN_PAGES.exec(block);
  if (pagesM) {
    gi.pages = ParserUtils.parseInt(pagesM[1], 0);
  }

  const irM = /class="ir[^"]*"[^>]*style="([^"]+)"/.exec(block);
  if (irM) {
    const ratingStr = parseRating(irM[1]);
    if (ratingStr) {
      gi.rating = ParserUtils.parseFloat(ratingStr, -1);
    }
    gi.rated = /class="ir[^"]*\s(?:irr|irg|irb)\s"/.test(block);
  }

  const postedM = new RegExp(`id="posted_${gi.gid}"[^>]*style="([^"]*)"[^>]*>([^<]*)`).exec(block);
  if (postedM) {
    gi.posted = ParserUtils.trim(postedM[2]);
    gi.favoriteSlot = parseFavoriteSlot(postedM[1]);
  }

  const uploaderM = /class="gl(?:hide|3e)"[\s\S]*?<a[^>]*>([^<]+)</.exec(block);
  if (uploaderM) {
    gi.uploader = ParserUtils.trim(uploaderM[1]);
  }

  gi.generateSLang();
  return gi;
}

export class GalleryListParser {

  static parse(body: string): GalleryListResult {
    const result: GalleryListResult = {
      pages: 1,
      nextPage: 0,
      noWatchedTags: body.includes('<p>You do not have any watched tags'),
      galleryInfoList: [],
    };

    if (body.includes('No hits found</p>')) {
      result.pages = 0;
      return result;
    }

    const pttPages: number[] = [];
    let pm: RegExpExecArray | null;
    const pttRegex = new RegExp(PATTERN_PTT_PAGES.source, 'g');
    while ((pm = pttRegex.exec(body)) !== null) {
      pttPages.push(ParserUtils.parseInt(pm[1], 0));
    }
    if (pttPages.length > 0) {
      result.pages = pttPages[pttPages.length - 1];
      const nextLink = body.match(/class="ptt"[\s\S]*?<a[^>]+href="[^"]*page=(\d+)[^"]*"[^>]*>.*?&gt;/);
      if (nextLink) {
        result.nextPage = ParserUtils.parseInt(nextLink[1], 0);
      }
    }

    const galleryInfoList: GalleryInfo[] = [];
    const itgMatch = body.match(/class="itg"[\s\S]*?<tbody>([\s\S]*?)<\/tbody>/);
    const tableBody = itgMatch ? itgMatch[1] : body;
    const rowRegex = /<tr[^>]*class="gtr[^"]*"[^>]*>([\s\S]*?)<\/tr>/gi;
    let rowM: RegExpExecArray | null;
    while ((rowM = rowRegex.exec(tableBody)) !== null) {
      const gi = parseGalleryFromBlock(rowM[1]);
      if (gi) galleryInfoList.push(gi);
    }

    if (galleryInfoList.length === 0) {
      const altRowRegex = /<tr[^>]*>[\s\S]*?\/g\/(\d+)\/([0-9a-f]{10})\/[\s\S]*?<\/tr>/gi;
      let altM: RegExpExecArray | null;
      while ((altM = altRowRegex.exec(tableBody)) !== null) {
        const gi = parseGalleryFromBlock(altM[0]);
        if (gi) galleryInfoList.push(gi);
      }
    }

    if (galleryInfoList.length === 0 && !body.includes('No hits found')) {
      throw new ParseException("Can't parse gallery list", body);
    }

    result.galleryInfoList = galleryInfoList;
    return result;
  }
}
