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

export interface GalleryPageUrlResult {
  gid: number;
  pToken: string;
  page: number;
}

const URL_STRICT_PATTERN = new RegExp(
  'https?://(?:' + EhUrl.DOMAIN_EX + '|' + EhUrl.DOMAIN_E + '|' + EhUrl.DOMAIN_LOFI +
  ')/s/([0-9a-f]{10})/(\\d+)-(\\d+)'
);

const URL_PATTERN = /([0-9a-f]{10})\/(\d+)-(\d+)/;

export class GalleryPageUrlParser {

  static parse(url: string | null, strict: boolean = true): GalleryPageUrlResult | null {
    if (url == null) return null;

    const pattern = strict ? URL_STRICT_PATTERN : URL_PATTERN;
    const m = pattern.exec(url);
    if (m) {
      const gid = Number.parseInt(m[2], 10);
      const page = Number.parseInt(m[3], 10) - 1;
      if (gid < 0 || Number.isNaN(gid) || page < 0 || Number.isNaN(page)) return null;
      return { gid, pToken: m[1], page };
    }
    return null;
  }
}
