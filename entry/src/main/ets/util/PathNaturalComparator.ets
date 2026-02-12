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

import { NaturalComparator } from './NaturalComparator.ets';

/**
 * Compares each path segment in natural sort order.
 * `\` and `/` are treated as the same separator.
 * Duplicate and leading separators are ignored, so relative and absolute paths are equivalent.
 * `./` and `../` are treated as normal path segments.
 */
export class PathNaturalComparator {

  private naturalComparator = new NaturalComparator();

  compare(o1: string | null, o2: string | null): number {
    if (o1 === null && o2 === null) return 0;
    if (o1 === null) return -1;
    if (o2 === null) return 1;

    let index1 = 0;
    let index2 = 0;

    while (true) {
      let data1: string | null = null;
      let data2: string | null = null;

      // Advance index1 past separators, find next normal segment
      while (true) {
        const newIndex1 = PathNaturalComparator.nextSegmentEnd(o1, index1);
        if (newIndex1 === index1) {
          data1 = null;
          break;
        }
        if (PathNaturalComparator.isNormal(o1.charCodeAt(newIndex1 - 1))) {
          data1 = o1.substring(index1, newIndex1);
          index1 = newIndex1;
          break;
        }
        index1 = newIndex1;
      }

      // Advance index2 past separators, find next normal segment
      while (true) {
        const newIndex2 = PathNaturalComparator.nextSegmentEnd(o2, index2);
        if (newIndex2 === index2) {
          data2 = null;
          break;
        }
        if (PathNaturalComparator.isNormal(o2.charCodeAt(newIndex2 - 1))) {
          data2 = o2.substring(index2, newIndex2);
          index2 = newIndex2;
          break;
        }
        index2 = newIndex2;
      }

      if (data1 === null && data2 === null) return 0;
      if (data1 === null) return -1;
      if (data2 === null) return 1;

      const result = this.naturalComparator.compare(data1, data2);
      if (result !== 0) return result;
    }
  }

  private static nextSegmentEnd(str: string, index: number): number {
    if (index >= str.length) return index;

    const startIsNormal = PathNaturalComparator.isNormal(str.charCodeAt(index));
    let i = index + 1;
    while (i < str.length && startIsNormal === PathNaturalComparator.isNormal(str.charCodeAt(i))) {
      i++;
    }
    return i;
  }

  private static isNormal(charCode: number): boolean {
    return charCode !== 0x2F && charCode !== 0x5C; // not '/' and not '\'
  }
}
