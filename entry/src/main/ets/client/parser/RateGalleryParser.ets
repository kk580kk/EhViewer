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

import { ParseException } from '../exception/ParseException.ets';

export interface RateGalleryResult {
  rating: number;
  ratingCount: number;
}

export class RateGalleryParser {

  static parse(body: string): RateGalleryResult {
    try {
      const jo = JSON.parse(body);
      return {
        rating: Number(jo['rating_avg']),
        ratingCount: Number(jo['rating_cnt']),
      };
    } catch (_) {
      throw new ParseException("Can't parse rate gallery", body);
    }
  }
}
