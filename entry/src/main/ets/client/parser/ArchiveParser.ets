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

import { ParserUtils } from './ParserUtils';

export interface ArchiveItem {
  res: string;
  name: string;
}

export interface ArchiveResult {
  paramOr: string;
  items: ArchiveItem[];
}

const PATTERN_FORM = /<form id="hathdl_form" action="[^"]*?or=([^="]*?)" method="post">/;
const PATTERN_ARCHIVE = /<a href="[^"]*" onclick="return do_hathdl\('([^']+)'\)">([^<]+)<\/a>/g;

export class ArchiveParser {

  static parse(body: string): ArchiveResult {
    const formMatch = PATTERN_FORM.exec(body);
    if (!formMatch) {
      return { paramOr: '', items: [] };
    }
    const paramOr = formMatch[1];
    const items: ArchiveItem[] = [];
    let m: RegExpExecArray | null;
    while ((m = PATTERN_ARCHIVE.exec(body)) !== null) {
      items.push({
        res: ParserUtils.trim(m[1]),
        name: ParserUtils.trim(m[2]),
      });
    }
    return { paramOr, items };
  }
}
