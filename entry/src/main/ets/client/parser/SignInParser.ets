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

import { EhException } from '../exception/EhException.ets';
import { ParseException } from '../exception/ParseException.ets';

const NAME_PATTERN = /<p>You are now logged in as: (.+?)</;
const ERROR_PATTERN = /(?:<h4>The error returned was:<\/h4>\s*<p>(.+?)<\/p>)|(?:<span class="postcolor">(.+?)<\/span>)/;

export class SignInParser {

  static parse(body: string): string {
    let m = NAME_PATTERN.exec(body);
    if (m) {
      return m[1];
    }
    m = ERROR_PATTERN.exec(body);
    if (m) {
      throw new EhException(m[1] ?? m[2]);
    }
    throw new ParseException("Can't parse sign in", body);
  }
}
