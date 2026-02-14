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

import { EhConfig } from './EhConfig';
import { GalleryInfo } from '../model/GalleryInfo';
import { SettingsService } from '../service/SettingsService';

export class EhUtils {
  static readonly NONE: number = -1;
  static readonly UNKNOWN: number = 0x400;
  static readonly ALL_CATEGORY: number = EhUtils.UNKNOWN - 1;

  static readonly BG_COLOR_DOUJINSHI: string = '#FFF44336';
  static readonly BG_COLOR_MANGA: string = '#FFFF9800';
  static readonly BG_COLOR_ARTIST_CG: string = '#FFFBC02D';
  static readonly BG_COLOR_GAME_CG: string = '#FF4CAF50';
  static readonly BG_COLOR_WESTERN: string = '#FF8BC34A';
  static readonly BG_COLOR_NON_H: string = '#FF2196F3';
  static readonly BG_COLOR_IMAGE_SET: string = '#FF3F51B5';
  static readonly BG_COLOR_COSPLAY: string = '#FF9C27B0';
  static readonly BG_COLOR_ASIAN_PORN: string = '#FF9575CD';
  static readonly BG_COLOR_MISC: string = '#FFF06292';
  static readonly BG_COLOR_UNKNOWN: string = '#FF000000';

  private static readonly PATTERN_TITLE_PREFIX: RegExp =
    /^(?:(?:\([^)]*\))|(?:\[[^\]]*\])|(?:\{[^}]*\})|(?:~[^~]*~)|\s+)*/;
  private static readonly PATTERN_TITLE_SUFFIX: RegExp =
    /(?:\s+ch.[\s\d-]+)?(?:(?:\([^)]*\))|(?:\[[^\]]*\])|(?:\{[^}]*\})|(?:~[^~]*~)|\s+)*$/i;

  private static readonly CATEGORY_VALUES: number[] = [
    EhConfig.MISC, EhConfig.DOUJINSHI, EhConfig.MANGA, EhConfig.ARTIST_CG,
    EhConfig.GAME_CG, EhConfig.IMAGE_SET, EhConfig.COSPLAY, EhConfig.ASIAN_PORN,
    EhConfig.NON_H, EhConfig.WESTERN, EhUtils.UNKNOWN,
  ];

  private static readonly CATEGORY_STRINGS: string[][] = [
    ['misc'],
    ['doujinshi'],
    ['manga'],
    ['artistcg', 'Artist CG Sets', 'Artist CG'],
    ['gamecg', 'Game CG Sets', 'Game CG'],
    ['imageset', 'Image Sets', 'Image Set'],
    ['cosplay'],
    ['asianporn', 'Asian Porn'],
    ['non-h'],
    ['western'],
    ['unknown'],
  ];

  static getCategoryByString(type: string): number {
    for (let i = 0; i < EhUtils.CATEGORY_STRINGS.length - 1; i++) {
      for (const str of EhUtils.CATEGORY_STRINGS[i]) {
        if (str.toLowerCase() === type.toLowerCase()) {
          return EhUtils.CATEGORY_VALUES[i];
        }
      }
    }
    return EhUtils.CATEGORY_VALUES[EhUtils.CATEGORY_VALUES.length - 1];
  }

  static getCategoryString(type: number): string {
    for (let i = 0; i < EhUtils.CATEGORY_VALUES.length - 1; i++) {
      if (EhUtils.CATEGORY_VALUES[i] === type) {
        return EhUtils.CATEGORY_STRINGS[i][0];
      }
    }
    return EhUtils.CATEGORY_STRINGS[EhUtils.CATEGORY_STRINGS.length - 1][0];
  }

  static getCategoryColor(category: number): string {
    switch (category) {
      case EhConfig.DOUJINSHI: return EhUtils.BG_COLOR_DOUJINSHI;
      case EhConfig.MANGA: return EhUtils.BG_COLOR_MANGA;
      case EhConfig.ARTIST_CG: return EhUtils.BG_COLOR_ARTIST_CG;
      case EhConfig.GAME_CG: return EhUtils.BG_COLOR_GAME_CG;
      case EhConfig.WESTERN: return EhUtils.BG_COLOR_WESTERN;
      case EhConfig.NON_H: return EhUtils.BG_COLOR_NON_H;
      case EhConfig.IMAGE_SET: return EhUtils.BG_COLOR_IMAGE_SET;
      case EhConfig.COSPLAY: return EhUtils.BG_COLOR_COSPLAY;
      case EhConfig.ASIAN_PORN: return EhUtils.BG_COLOR_ASIAN_PORN;
      case EhConfig.MISC: return EhUtils.BG_COLOR_MISC;
      default: return EhUtils.BG_COLOR_UNKNOWN;
    }
  }

  static getSuitableTitle(gi: GalleryInfo): string {
    if (SettingsService.getShowJpnTitle()) {
      return gi.titleJpn || gi.title;
    } else {
      return gi.title || gi.titleJpn;
    }
  }

  static extractTitle(title: string | null): string | null {
    if (title === null) return null;
    let result = title.replace(EhUtils.PATTERN_TITLE_PREFIX, '');
    result = result.replace(EhUtils.PATTERN_TITLE_SUFFIX, '');
    const index = result.indexOf('|');
    if (index >= 0) {
      result = result.substring(0, index);
    }
    return result.length === 0 ? null : result;
  }

  static handleThumbUrlResolution(url: string | null): string | null {
    if (url === null) return null;

    let resolution: string;
    switch (SettingsService.getThumbResolution()) {
      case 1:
        resolution = '250';
        break;
      case 2:
        resolution = '300';
        break;
      default:
        return url;
    }

    const index1 = url.lastIndexOf('_');
    const index2 = url.lastIndexOf('.');
    if (index1 >= 0 && index2 >= 0 && index1 < index2) {
      return url.substring(0, index1 + 1) + resolution + url.substring(index2);
    }
    return url;
  }
}
