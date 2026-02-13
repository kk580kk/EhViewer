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

import { GalleryDetail } from '../../model/GalleryDetail';
import { GalleryTagGroup } from '../../model/GalleryTagGroup';
import { GalleryComment, GalleryCommentList } from '../../model/GalleryComment';
import { LargePreviewSet } from '../../model/LargePreviewSet';
import { NormalPreviewSet } from '../../model/NormalPreviewSet';
import { EhUtils } from '../EhUtils';
import { ParserUtils } from './ParserUtils';
import { EhException } from '../exception/EhException.ets';
import { ParseException } from '../exception/ParseException.ets';
import { OffensiveException } from '../exception/OffensiveException.ets';

const PATTERN_ERROR = /<div class="d">\s*<p>([^<]+)<\/p>/;
const PATTERN_DETAIL = /var gid = (\d+);[\s\S]*?var token = "([a-f0-9]+)";[\s\S]*?var apiuid = ([-\d]+);[\s\S]*?var apikey = "([a-f0-9]+)"/;
const PATTERN_TORRENT = /<a[^<>]*onclick="return popUp\('([^']+)'[^)]+\)">Torrent Download \\( (\\d+) \\)<\/a>/;
const PATTERN_ARCHIVE = /<a[^<>]*onclick="return popUp\('([^']+)'[^)]+\)">Archive Download<\/a>/;
const PATTERN_COVER = /width:(\d+)px; height:(\d+)px[^;]*url\((.+?)\)/;
const PATTERN_TAG_GROUP = /<tr><td[^<>]+>([\w\s]+):<\/td><td>(?:<div[^<>]+><a[^<>]+>[\w\s]+<\/a><\/div>)+<\/td><\/tr>/g;
const PATTERN_TAG = /<div[^<>]+><a[^<>]+>([\w\s]+)<\/a><\/div>/g;
const PATTERN_COMMENT = /<div class="c3">Posted on ([^<>]+) by: &nbsp; <a[^<>]+>([^<>]+)<\/a>[\s\S]*?<div class="c6"[^>]*>([\s\S]*?)<\/div><div class="c[78]"/g;
const PATTERN_PAGES = /<tr><td[^<>]*>Length:<\/td><td[^<>]*>([\d,]+) pages<\/td><\/tr>/;
const PATTERN_PREVIEW_PAGES = /<td[^>]+><a[^>]+>([\d,]+)<\/a><\/td><td[^>]+>(?:<a[^>]+>)?&gt;(?:<\/a>)?<\/td>/;
const PATTERN_NORMAL_PREVIEW = /<div class="gdtm"[^<>]*><div[^<>]*width:(\d+)[^<>]*height:(\d+)[^<>]*\((.+?)\)[^<>]*-(\d+)px[^<>]*><a[^<>]*href="(.+?)"[^<>]*><img alt="([\d,]+)"/g;
const PATTERN_LARGE_PREVIEW = /<div class="gdtl"[\s\S]*?<a href="(.+?)"><img alt="([\d,]+)"[\s\S]*?src="(.+?)"/g;

const OFFENSIVE_STRING = '<p>(And if you choose to ignore this warning, you lose all rights to complain about it in the future.)</p>';

const WEB_COMMENT_DATE_FORMAT = /(\d{1,2})\s+(\w+)\s+(\d{4}),\s+(\d{1,2}):(\d{2})\s+(\w+)/;

function parseCommentTime(webDateString: string): number {
  const m = WEB_COMMENT_DATE_FORMAT.exec(webDateString.trim());
  if (!m) return 0;
  const months: Record<string, number> = {
    January: 0, February: 1, March: 2, April: 3, May: 4, June: 5,
    July: 6, August: 7, September: 8, October: 9, November: 10, December: 11,
  };
  const month = months[m[2]] ?? 0;
  const day = parseInt(m[1], 10);
  const year = parseInt(m[3], 10);
  const hour = parseInt(m[4], 10);
  const min = parseInt(m[5], 10);
  const d = new Date(Date.UTC(year, month, day, hour, min, 0));
  return d.getTime();
}

function parseTagGroups(body: string): GalleryTagGroup[] {
  const list: GalleryTagGroup[] = [];
  const groupRegex = new RegExp(PATTERN_TAG_GROUP.source, 'g');
  let gm: RegExpExecArray | null;
  while ((gm = groupRegex.exec(body)) !== null) {
    const tagGroup = new GalleryTagGroup();
    tagGroup.groupName = ParserUtils.trim(gm[1]).replace(/:$/, '');
    const tagRegex = new RegExp(PATTERN_TAG.source, 'g');
    let tm: RegExpExecArray | null;
    const block = gm[0];
    while ((tm = tagRegex.exec(block)) !== null) {
      let tag = ParserUtils.trim(tm[1]);
      const idx = tag.indexOf('|');
      if (idx >= 0) tag = tag.substring(0, idx).trim();
      if (tag) tagGroup.addTag(tag);
    }
    if (tagGroup.size() > 0) list.push(tagGroup);
  }
  return list;
}

function parseComments(body: string): GalleryComment[] {
  const list: GalleryComment[] = [];
  const commentRegex = new RegExp(PATTERN_COMMENT.source, 'g');
  let m: RegExpExecArray | null;
  let id = 1;
  while ((m = commentRegex.exec(body)) !== null) {
    const comment = new GalleryComment();
    comment.id = id++;
    comment.time = parseCommentTime(m[1]);
    comment.user = ParserUtils.trim(m[2]);
    comment.comment = m[3];
    list.push(comment);
  }
  return list;
}

function parsePreviewSet(body: string): LargePreviewSet | NormalPreviewSet {
  const largeRegex = new RegExp(PATTERN_LARGE_PREVIEW.source, 'g');
  const largeSet = new LargePreviewSet();
  let m: RegExpExecArray | null;
  let index = 0;
  while ((m = largeRegex.exec(body)) !== null) {
    const pageUrl = ParserUtils.unescapeXml(ParserUtils.trim(m[1]));
    const imageUrl = ParserUtils.unescapeXml(ParserUtils.trim(m[3]));
    largeSet.addItem(index, imageUrl, pageUrl);
    index++;
  }
  if (largeSet.size() > 0) return largeSet;

  const normalRegex = new RegExp(PATTERN_NORMAL_PREVIEW.source, 'g');
  const normalSet = new NormalPreviewSet();
  let pos = 0;
  let nm: RegExpExecArray | null;
  while ((nm = normalRegex.exec(body)) !== null) {
    const width = parseInt(nm[1], 10);
    const height = parseInt(nm[2], 10);
    const imageUrl = ParserUtils.unescapeXml(ParserUtils.trim(nm[3]));
    const pageUrl = ParserUtils.unescapeXml(ParserUtils.trim(nm[5]));
    normalSet.addItem(pos, imageUrl, 0, 0, width, height, pageUrl);
    pos++;
  }
  return normalSet;
}

export class GalleryDetailParser {

  static parse(body: string): GalleryDetail {
    if (body.includes(OFFENSIVE_STRING)) {
      throw new OffensiveException('Offensive content');
    }

    const errorM = PATTERN_ERROR.exec(body);
    if (errorM) {
      throw new EhException(ParserUtils.trim(errorM[1]));
    }

    const detailM = PATTERN_DETAIL.exec(body);
    if (!detailM) {
      throw new ParseException("Can't parse gallery detail", body);
    }

    const gd = new GalleryDetail();
    gd.gid = parseInt(detailM[1], 10);
    gd.token = detailM[2];
    gd.apiUid = parseInt(detailM[3], 10);
    gd.apiKey = detailM[4];

    const torrentM = PATTERN_TORRENT.exec(body);
    if (torrentM) {
      gd.torrentUrl = ParserUtils.unescapeXml(ParserUtils.trim(torrentM[1]));
      gd.torrentCount = ParserUtils.parseInt(torrentM[2], 0);
    }

    const archiveM = PATTERN_ARCHIVE.exec(body);
    if (archiveM) {
      gd.archiveUrl = ParserUtils.unescapeXml(ParserUtils.trim(archiveM[1]));
    }

    const coverM = PATTERN_COVER.exec(body);
    if (coverM) {
      gd.thumb = EhUtils.handleThumbUrlResolution(ParserUtils.unescapeXml(ParserUtils.trim(coverM[3]))) ?? '';
    }

    const gnM = /id="gn"[^>]*>([^<]*)</.exec(body);
    gd.title = gnM ? ParserUtils.trim(gnM[1]) : '';

    const gjM = /id="gj"[^>]*>([^<]*)</.exec(body);
    gd.titleJpn = gjM ? ParserUtils.trim(gjM[1]) : '';

    const gdcM = /id="gdc"[\s\S]*?class="(?:cn|cs)"[^>]*>([^<]+)</.exec(body);
    if (gdcM) {
      gd.category = EhUtils.getCategoryByString(ParserUtils.trim(gdcM[1]));
    } else {
      gd.category = EhUtils.UNKNOWN;
    }

    const gdnM = /id="gdn"[^>]*>([^<]*)</.exec(body);
    gd.uploader = gdnM ? ParserUtils.trim(gdnM[1]) : '';

    const postedM = /Posted[\s\S]*?<td[^>]*>([^<]*)</.exec(body);
    if (postedM) gd.posted = ParserUtils.trim(postedM[1]);

    const lengthM = PATTERN_PAGES.exec(body);
    if (lengthM) {
      gd.pages = ParserUtils.parseInt(lengthM[1], 0);
    }

    const favM = /Favorited[\s\S]*?<td[^>]*>([^<]*)</.exec(body);
    if (favM) {
      const v = ParserUtils.trim(favM[1]);
      if (v === 'Never') gd.favoriteCount = 0;
      else if (v === 'Once') gd.favoriteCount = 1;
      else gd.favoriteCount = ParserUtils.parseInt(v, 0);
    }

    const langM = /Language[\s\S]*?<td[^>]*>([^<]*)</.exec(body);
    if (langM) gd.language = ParserUtils.trim(langM[1]);

    const sizeM = /File Size[\s\S]*?<td[^>]*>([^<]*)</.exec(body);
    if (sizeM) gd.size = ParserUtils.trim(sizeM[1]);

    const ratingCountM = /id="rating_count"[^>]*>([^<]*)</.exec(body);
    if (ratingCountM) gd.ratingCount = ParserUtils.parseInt(ratingCountM[1], 0);

    const ratingLabelM = /id="rating_label"[^>]*>([^<]*)</.exec(body);
    if (ratingLabelM) {
      const s = ParserUtils.trim(ratingLabelM[1]);
      if (s === 'Not Yet Rated') gd.rating = -1;
      else {
        const spaceIdx = s.indexOf(' ');
        gd.rating = spaceIdx >= 0 ? ParserUtils.parseFloat(s.substring(spaceIdx + 1), 0) : 0;
      }
    } else {
      gd.rating = -1;
    }

    const gdfM = /id="gdf"[^>]*>([^<]*)</.exec(body);
    if (gdfM) {
      const favText = ParserUtils.trim(gdfM[1]);
      gd.isFavorited = favText !== 'Add to Favorites';
      if (gd.isFavorited) gd.favoriteName = favText;
    }

    gd.tags = parseTagGroups(body);
    gd.comments = GalleryCommentList.of(parseComments(body), body.includes('click to show all'));
    gd.previewPages = 0;
    const previewPagesM = PATTERN_PREVIEW_PAGES.exec(body);
    if (previewPagesM) {
      gd.previewPages = ParserUtils.parseInt(previewPagesM[1], 0);
    }
    try {
      gd.previewSet = parsePreviewSet(body);
    } catch (_) {
      gd.previewSet = null;
    }

    return gd;
  }

  /** Parse only comments from document HTML (e.g. after posting a comment). */
  static parseCommentsFromBody(body: string): GalleryCommentList {
    const comments = parseComments(body);
    const hasMore = body.includes('click to show all');
    return GalleryCommentList.of(comments, hasMore);
  }
}
