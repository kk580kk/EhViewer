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

/**
 * Describes a single spider crawl task: gallery metadata and per-page token map.
 *
 * Mirrors the Android SpiderInfo class with text-based serialization.
 * The file format (VERSION2) is:
 *   VERSION2
 *   <startPage hex 8 chars>
 *   <gid>
 *   <token>
 *   1              (deprecated mode field, always "1")
 *   <previewPages>
 *   <previewPerPage>
 *   <pages>
 *   <index> <pToken>   (repeated)
 */

const VERSION_STR = 'VERSION';
const VERSION = 2;

export const TOKEN_FAILED = 'failed';

export class SpiderInfo {
  startPage: number = 0;
  gid: number = -1;
  token: string = '';
  pages: number = -1;
  previewPages: number = -1;
  previewPerPage: number = -1;
  pTokenMap: Map<number, string> = new Map();

  /**
   * Deserialize from the text format.
   * Returns null if the data is invalid.
   */
  static read(text: string | null): SpiderInfo | null {
    if (text === null || text.length === 0) {
      return null;
    }

    try {
      const lines = text.split('\n');
      let cursor = 0;

      const readLine = (): string => {
        if (cursor >= lines.length) throw new Error('EOF');
        return lines[cursor++].trim();
      };

      const info = new SpiderInfo();

      // Version
      let line = readLine();
      const version = SpiderInfo.getVersion(line);
      if (version === VERSION) {
        line = readLine();
      } else if (version === 1) {
        // line is already the startPage line
      } else {
        return null;
      }

      // Start page (hex)
      info.startPage = SpiderInfo.parseStartPage(line);

      // Gid
      info.gid = Number.parseInt(readLine(), 10);
      if (Number.isNaN(info.gid)) return null;

      // Token
      info.token = readLine();

      // Deprecated mode field - skip
      readLine();

      // Preview pages
      info.previewPages = Number.parseInt(readLine(), 10);

      // Preview per page
      line = readLine();
      if (version === 1) {
        // In v1, this field didn't exist — skip the line
      } else {
        info.previewPerPage = Number.parseInt(line, 10);
      }

      // Pages
      info.pages = Number.parseInt(readLine(), 10);
      if (info.pages <= 0) return null;

      // pToken entries
      info.pTokenMap = new Map();
      while (cursor < lines.length) {
        const entry = lines[cursor++].trim();
        if (entry.length === 0) continue;
        const spaceIdx = entry.indexOf(' ');
        if (spaceIdx > 0) {
          const index = Number.parseInt(entry.substring(0, spaceIdx), 10);
          const pToken = entry.substring(spaceIdx + 1);
          if (!Number.isNaN(index) && pToken.length > 0) {
            info.pTokenMap.set(index, pToken);
          }
        }
      }

      // Validate
      if (info.gid === -1 || info.token.length === 0 || info.pages === -1) {
        return null;
      }
      return info;
    } catch (_) {
      return null;
    }
  }

  /**
   * Serialize to the text format.
   */
  write(): string {
    const lines: string[] = [];
    lines.push(VERSION_STR + VERSION.toString());
    lines.push(SpiderInfo.formatStartPage(this.startPage));
    lines.push(this.gid.toString());
    lines.push(this.token);
    lines.push('1'); // deprecated mode
    lines.push(this.previewPages.toString());
    lines.push(this.previewPerPage.toString());
    lines.push(this.pages.toString());

    // Sort pToken entries by index for deterministic output
    const sortedKeys = Array.from(this.pTokenMap.keys()).sort((a, b) => a - b);
    for (const key of sortedKeys) {
      const value = this.pTokenMap.get(key)!;
      if (value === TOKEN_FAILED || value.length === 0) {
        continue;
      }
      lines.push(`${key} ${value}`);
    }

    return lines.join('\n') + '\n';
  }

  private static getVersion(line: string): number {
    if (line.startsWith(VERSION_STR)) {
      const num = Number.parseInt(line.substring(VERSION_STR.length), 10);
      return Number.isNaN(num) ? -1 : num;
    }
    return 1;
  }

  private static parseStartPage(str: string): number {
    const val = Number.parseInt(str, 16);
    return (Number.isNaN(val) || val < 0) ? 0 : val;
  }

  private static formatStartPage(page: number): string {
    const val = page >= 0 ? page : 0;
    return val.toString(16).padStart(8, '0');
  }
}
