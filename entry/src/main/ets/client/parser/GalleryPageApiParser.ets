/*
 * Copyright 2019 Hippo Seven
 * Ported to HarmonyOS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { ParseException } from '../exception/ParseException.ets';
import { ParserUtils } from './ParserUtils';

export interface GalleryPageApiResult {
  imageUrl: string;
  skipHathKey: string;
  originImageUrl: string;
}

const PATTERN_IMAGE_URL = /<img[^>]*src="([^"]+)" style/;
const PATTERN_SKIP_HATH_KEY = /onclick="return nl\('([^)]+)'\)/;
const PATTERN_ORIGIN_IMAGE_URL = /<a href="([^"]+)fullimg\.php([^"]+)">/;

export class GalleryPageApiParser {

  static parse(body: string): GalleryPageApiResult {
    let jo: Record<string, string>;
    try {
      jo = JSON.parse(body);
    } catch (_) {
      throw new ParseException("Can't parse json", body);
    }

    if (jo['error']) {
      throw new ParseException(jo['error'], body);
    }

    let imageUrl = '';
    let skipHathKey = '';
    let originImageUrl = '';

    const i3 = jo['i3'] || '';
    let m = PATTERN_IMAGE_URL.exec(i3);
    if (m) {
      imageUrl = ParserUtils.unescapeXml(ParserUtils.trim(m[1]));
    }

    const i6 = jo['i6'] || '';
    m = PATTERN_SKIP_HATH_KEY.exec(i6);
    if (m) {
      skipHathKey = ParserUtils.unescapeXml(ParserUtils.trim(m[1]));
    }

    const i7 = jo['i7'] || '';
    m = PATTERN_ORIGIN_IMAGE_URL.exec(i7);
    if (m) {
      originImageUrl = ParserUtils.unescapeXml(m[1]) + 'fullimg.php' + ParserUtils.unescapeXml(m[2]);
    }

    if (imageUrl) {
      return { imageUrl, skipHathKey, originImageUrl };
    }
    throw new ParseException('Parse image url and skip hath key error', body);
  }
}
