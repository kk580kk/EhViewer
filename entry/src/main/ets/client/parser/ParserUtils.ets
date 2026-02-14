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

const XML_ENTITIES: [string, string][] = [
  ['&amp;', '&'],
  ['&lt;', '<'],
  ['&gt;', '>'],
  ['&quot;', '"'],
  ['&apos;', "'"],
  ['&#039;', "'"],
];

export class ParserUtils {

  static unescapeXml(str: string): string {
    let result = str;
    for (const [entity, char] of XML_ENTITIES) {
      result = result.split(entity).join(char);
    }
    return result;
  }

  static trim(str: string | null | undefined): string {
    if (str == null) return '';
    return ParserUtils.unescapeXml(str).trim();
  }

  static parseInt(str: string | null | undefined, defValue: number): number {
    const cleaned = ParserUtils.trim(str).replace(/,/g, '');
    const n = Number.parseInt(cleaned, 10);
    return Number.isNaN(n) ? defValue : n;
  }

  static parseLong(str: string | null | undefined, defValue: number): number {
    return ParserUtils.parseInt(str, defValue);
  }

  static parseFloat(str: string | null | undefined, defValue: number): number {
    const cleaned = ParserUtils.trim(str).replace(/,/g, '');
    const n = Number.parseFloat(cleaned);
    return Number.isNaN(n) ? defValue : n;
  }

  static formatDate(time: number): string {
    const d = new Date(time);
    const yyyy = d.getUTCFullYear();
    const MM = String(d.getUTCMonth() + 1).padStart(2, '0');
    const dd = String(d.getUTCDate()).padStart(2, '0');
    const HH = String(d.getUTCHours()).padStart(2, '0');
    const mm = String(d.getUTCMinutes()).padStart(2, '0');
    return `${yyyy}-${MM}-${dd} ${HH}:${mm}`;
  }
}
