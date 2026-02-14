/*
 * Copyright 2019 Hippo Seven
 * Ported to HarmonyOS ArkTS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

/**
 * Helper for parsing and building excluded languages strings.
 * Format: language codes joined by "x", e.g. "0x1024x2048".
 */
export class ExcludedLanguagesHelper {
  static readonly ROW_COUNT: number = 17;
  static readonly COLUMN_COUNT: number = 3;

  /**
   * All language codes in order: [row * 3 + column]
   * column 0 = original, 1 = translated, 2 = rewrite.
   */
  static readonly LANGUAGES: string[] = [
    '0', '1024', '2048',       // Japanese
    '1', '1025', '2049',       // English
    '10', '1034', '2058',      // Chinese
    '20', '1044', '2068',      // Dutch
    '30', '1054', '2078',      // French
    '40', '1064', '2088',      // German
    '50', '1074', '2098',      // Hungarian
    '60', '1084', '2108',      // Italian
    '70', '1094', '2118',      // Korean
    '80', '1104', '2128',      // Polish
    '90', '1114', '2138',      // Portuguese
    '100', '1124', '2148',     // Russian
    '110', '1134', '2158',     // Spanish
    '120', '1144', '2168',     // Thai
    '130', '1154', '2178',     // Vietnamese
    '254', '1278', '2302',     // N/A
    '255', '1279', '2303',     // Other
  ];

  /**
   * Parse an excluded languages string into a 2D boolean array.
   * @param excludedLanguages e.g. "0x1024x2048", or null/empty
   * @returns boolean[ROW_COUNT][COLUMN_COUNT]
   */
  static parseExcludedLanguages(excludedLanguages: string | null): boolean[][] {
    const selections: boolean[][] = [];
    for (let i = 0; i < ExcludedLanguagesHelper.ROW_COUNT; i++) {
      selections.push([false, false, false]);
    }
    if (!excludedLanguages) {
      return selections;
    }

    const parts = excludedLanguages.split('x');
    const langs = ExcludedLanguagesHelper.LANGUAGES;
    let j = 0;
    for (let i = 0; i < parts.length; i++) {
      const part = parts[i];
      if (!ExcludedLanguagesHelper.isDecimal(part)) {
        continue;
      }
      for (; j < langs.length; j++) {
        if (langs[j] === part) {
          const row = Math.floor(j / ExcludedLanguagesHelper.COLUMN_COUNT);
          const col = j % ExcludedLanguagesHelper.COLUMN_COUNT;
          selections[row][col] = true;
          break;
        }
      }
    }
    return selections;
  }

  /**
   * Build an excluded languages string from a 2D boolean array.
   * @param selections boolean[ROW_COUNT][COLUMN_COUNT]
   * @returns e.g. "0x1024x2048"
   */
  static buildExcludedLanguages(selections: boolean[][]): string {
    const langs = ExcludedLanguagesHelper.LANGUAGES;
    const parts: string[] = [];
    let idx = 0;
    for (const row of selections) {
      for (const selected of row) {
        if (selected) {
          parts.push(langs[idx]);
        }
        idx++;
      }
    }
    return parts.join('x');
  }

  private static isDecimal(str: string): boolean {
    if (str.length === 0) return false;
    for (let i = 0; i < str.length; i++) {
      const ch = str.charCodeAt(i);
      if (ch < 0x30 || ch > 0x39) return false; // '0'..'9'
    }
    return true;
  }
}
