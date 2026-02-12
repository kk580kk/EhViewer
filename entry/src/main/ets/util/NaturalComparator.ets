/*
 * Copyright 2018 Hippo Seven
 * Ported to HarmonyOS ArkTS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

/**
 * Implements natural sort order for strings.
 * Numbers within strings are compared numerically rather than lexicographically.
 */
export class NaturalComparator {

  compare(o1: string | null, o2: string | null): number {
    if (o1 === null && o2 === null) return 0;
    if (o1 === null) return -1;
    if (o2 === null) return 1;

    let index1 = 0;
    let index2 = 0;

    while (true) {
      const data1 = NaturalComparator.nextSlice(o1, index1);
      const data2 = NaturalComparator.nextSlice(o2, index2);

      if (data1 === null && data2 === null) return 0;
      if (data1 === null) return -1;
      if (data2 === null) return 1;

      index1 += data1.length;
      index2 += data2.length;

      let result: number;
      if (NaturalComparator.isDigit(data1) && NaturalComparator.isDigit(data2)) {
        result = NaturalComparator.compareNumberString(data1, data2);
      } else {
        result = data1.toLowerCase().localeCompare(data2.toLowerCase());
      }

      if (result !== 0) return result;
    }
  }

  private static isDigit(str: string): boolean {
    const ch = str.charCodeAt(0);
    return ch >= 0x30 && ch <= 0x39; // '0'..'9'
  }

  private static nextSlice(str: string, index: number): string | null {
    const length = str.length;
    if (index === length) return null;

    const ch = str.charCodeAt(index);
    if (ch === 0x2E || ch === 0x20) { // '.' or ' '
      return str.substring(index, index + 1);
    } else if (ch >= 0x30 && ch <= 0x39) { // '0'..'9'
      return str.substring(index, NaturalComparator.nextNumberBound(str, index + 1));
    } else {
      return str.substring(index, NaturalComparator.nextOtherBound(str, index + 1));
    }
  }

  private static nextNumberBound(str: string, index: number): number {
    const length = str.length;
    let i = index;
    while (i < length) {
      const ch = str.charCodeAt(i);
      if (ch < 0x30 || ch > 0x39) break;
      i++;
    }
    return i;
  }

  private static nextOtherBound(str: string, index: number): number {
    const length = str.length;
    let i = index;
    while (i < length) {
      const ch = str.charCodeAt(i);
      if (ch === 0x2E || ch === 0x20 || (ch >= 0x30 && ch <= 0x39)) break;
      i++;
    }
    return i;
  }

  private static removeLeadingZero(s: string): string {
    if (s.length < 1) return s;
    for (let i = 0, n = s.length - 1; i < n; i++) {
      if (s.charAt(i) !== '0') return s.substring(i);
    }
    return s.substring(s.length - 1);
  }

  private static compareNumberString(s1: string, s2: string): number {
    const p1 = NaturalComparator.removeLeadingZero(s1);
    const p2 = NaturalComparator.removeLeadingZero(s2);

    const l1 = p1.length;
    const l2 = p2.length;

    if (l1 > l2) return 1;
    if (l1 < l2) return -1;

    for (let i = 0; i < l1; i++) {
      const c1 = p1.charCodeAt(i);
      const c2 = p2.charCodeAt(i);
      if (c1 > c2) return 1;
      if (c1 < c2) return -1;
    }

    // More leading zeros → smaller (consistent with Java: -Integer.compare)
    if (s1.length > s2.length) return -1;
    if (s1.length < s2.length) return 1;
    return 0;
  }
}
