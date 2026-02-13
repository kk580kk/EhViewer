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

import { GalleryInfo } from '../../model/GalleryInfo';
import { EhException } from '../exception/EhException.ets';
import { ParseException } from '../exception/ParseException.ets';
import { ParserUtils } from './ParserUtils';
import { GalleryListParser } from './GalleryListParser';

export interface FavoritesResult {
  catArray: string[];
  countArray: number[];
  pages: number;
  nextPage: number;
  galleryInfoList: GalleryInfo[];
}

const NEED_SIGN_IN = 'This page requires you to log on.</p>';

export class FavoritesParser {

  static parse(body: string): FavoritesResult {
    if (body.includes(NEED_SIGN_IN)) {
      throw new EhException('Need sign in');
    }

    const catArray: string[] = [];
    const countArray: number[] = [];

    try {
      const idoMatch = body.match(/class="ido"[\s\S]*?<div class="fp fps"/);
      const fpRegex = /class="fp"(?![^"]*fps)[^>]*>[\s\S]*?<div[^>]*>([^<]*)<\/div>[\s\S]*?<div[^>]*>([^<]*)<\/div>/g;
      if (idoMatch) {
        const idoBlock = body.substring(body.indexOf('class="ido"'), body.indexOf('<div class="fp fps"'));
        let m: RegExpExecArray | null;
        while ((m = fpRegex.exec(idoBlock)) !== null && catArray.length < 10) {
          countArray.push(ParserUtils.parseInt(m[1], 0));
          catArray.push(ParserUtils.trim(m[2]));
        }
      }
      while (catArray.length < 10) {
        catArray.push('');
        countArray.push(0);
      }
    } catch (e) {
      throw new ParseException('Parse favorites error', body);
    }

    const listResult = GalleryListParser.parse(body);
    return {
      catArray,
      countArray,
      pages: listResult.pages,
      nextPage: listResult.nextPage,
      galleryInfoList: listResult.galleryInfoList,
    };
  }
}
