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

export interface TorrentItem {
  url: string;
  name: string;
}

const PATTERN_TORRENT = /<td colspan="5"> &nbsp; <a href="([^"]+)"[^<]+>([^<]+)<\/a><\/td>/g;

export class TorrentParser {

  static parse(body: string): TorrentItem[] {
    const list: TorrentItem[] = [];
    let m: RegExpExecArray | null;
    while ((m = PATTERN_TORRENT.exec(body)) !== null) {
      let url = ParserUtils.trim(m[1]);
      const qIndex = url.indexOf('?p=');
      if (qIndex !== -1) {
        url = url.substring(0, qIndex);
      }
      const name = ParserUtils.trim(m[2]);
      list.push({ url, name });
    }
    return list;
  }
}
