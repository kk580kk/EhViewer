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
import { ParseException } from '../exception/ParseException.ets';

export interface ProfileResult {
  displayName: string;
  avatar: string | null;
}

const PATTERN_DISPLAY_NAME = /<div id="profilename"[^>]*>\s*<a[^>]*>([^<]+)<\/a>/;
const PATTERN_AVATAR = /<div id="profilename"[^>]*>[\s\S]*?<img[^>]*\bsrc="([^"]+)"/;

export class ProfileParser {

  static parse(body: string): ProfileResult {
    const nameMatch = PATTERN_DISPLAY_NAME.exec(body);
    if (!nameMatch) {
      throw new ParseException('Parse profile error', body);
    }
    const displayName = nameMatch[1].trim();

    let avatar: string | null = null;
    const avatarMatch = PATTERN_AVATAR.exec(body);
    if (avatarMatch) {
      let src = avatarMatch[1].trim();
      if (src.length > 0) {
        if (!src.startsWith('http')) {
          src = EhUrl.URL_FORUMS + src;
        }
        avatar = src;
      }
    }

    return { displayName, avatar };
  }
}
