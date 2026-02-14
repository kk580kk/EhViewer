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
 * Factory for generating cache keys for gallery images and previews.
 *
 * Mirrors the Android EhCacheKeyFactory class.
 */
export class EhCacheKeyFactory {

  static getThumbKey(gid: number): string {
    return `preview:large:${gid}:0`;
  }

  static getNormalPreviewKey(gid: number, index: number): string {
    return `preview:normal:${gid}:${index}`;
  }

  static getLargePreviewKey(gid: number, index: number): string {
    return `preview:large:${gid}:${index}`;
  }

  static getLargePreviewSetKey(gid: number, index: number): string {
    return `large_preview_set:${gid}:${index}`;
  }

  static getImageKey(gid: number, index: number): string {
    return `image:${gid}:${index}`;
  }
}
