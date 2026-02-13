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

import { ParseException } from '../exception/ParseException.ets';
import { ParserUtils } from './ParserUtils';

export interface GalleryPageResult {
  imageUrl: string;
  skipHathKey: string;
  originImageUrl: string;
  showKey: string;
}

const PATTERN_IMAGE_URL = /<img[^>]*src="([^"]+)" style/;
const PATTERN_SKIP_HATH_KEY = /onclick="return nl\('([^)]+)'\)/;
const PATTERN_ORIGIN_IMAGE_URL = /<a href="([^"]+)fullimg\.php([^"]+)">/;
const PATTERN_SHOW_KEY = /var showkey="([0-9a-z]+)";/;

export class GalleryPageParser {

  static parse(body: string): GalleryPageResult {
    let imageUrl = '';
    let skipHathKey = '';
    let originImageUrl = '';
    let showKey = '';

    let m = PATTERN_IMAGE_URL.exec(body);
    if (m) {
      imageUrl = ParserUtils.unescapeXml(ParserUtils.trim(m[1]));
    }

    m = PATTERN_SKIP_HATH_KEY.exec(body);
    if (m) {
      skipHathKey = ParserUtils.unescapeXml(ParserUtils.trim(m[1]));
    }

    m = PATTERN_ORIGIN_IMAGE_URL.exec(body);
    if (m) {
      originImageUrl = ParserUtils.unescapeXml(m[1]) + 'fullimg.php' + ParserUtils.unescapeXml(m[2]);
    }

    m = PATTERN_SHOW_KEY.exec(body);
    if (m) {
      showKey = m[1];
    }

    if (imageUrl && showKey) {
      return { imageUrl, skipHathKey, originImageUrl, showKey };
    }
    throw new ParseException('Parse image url and show error', body);
  }
}
