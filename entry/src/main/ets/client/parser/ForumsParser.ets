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

const PATTERN_PROFILE_URL = /<div id="userlinks"[^>]*>.*?<a href="([^"]+)"/s;

export class ForumsParser {

  static parse(body: string): string {
    const m = PATTERN_PROFILE_URL.exec(body);
    if (m) {
      return m[1];
    }
    throw new ParseException('Parse forums error', body);
  }
}
