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

import { EhUtils } from '../EhUtils';
import { GalleryInfo } from '../../model/GalleryInfo';
import { ParserUtils } from './ParserUtils';

export class GalleryApiParser {

  static parse(body: string, galleryInfoList: GalleryInfo[]): void {
    const jo = JSON.parse(body);
    const ja: Record<string, unknown>[] = jo['gmetadata'];

    for (const g of ja) {
      const gid = Number(g['gid']);
      const gi = GalleryApiParser.getGalleryInfoByGid(galleryInfoList, gid);
      if (gi === null) continue;

      gi.title = ParserUtils.trim(g['title'] as string);
      gi.titleJpn = ParserUtils.trim(g['title_jpn'] as string);
      gi.category = EhUtils.getCategoryByString(g['category'] as string);
      gi.thumb = EhUtils.handleThumbUrlResolution(g['thumb'] as string) ?? '';
      gi.uploader = g['uploader'] as string;
      gi.posted = ParserUtils.formatDate(ParserUtils.parseLong(g['posted'] as string, 0) * 1000);
      gi.rating = ParserUtils.parseFloat(g['rating'] as string, 0);

      const tagJa = g['tags'] as string[];
      if (tagJa) {
        gi.simpleTags = tagJa.slice();
      }
      gi.pages = ParserUtils.parseInt(g['filecount'] as string, 0);
      gi.generateSLang();
    }
  }

  private static getGalleryInfoByGid(list: GalleryInfo[], gid: number): GalleryInfo | null {
    for (const gi of list) {
      if (gi.gid === gid) return gi;
    }
    return null;
  }
}
