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

import { GalleryInfo } from './GalleryInfo';

/**
 * Locally-stored favorite gallery entry.
 *
 * Extends GalleryInfo with a timestamp for ordering.
 * Mirrors the Android LocalFavoriteInfo DAO entity.
 */
export class LocalFavoriteInfo extends GalleryInfo {
  time: number = 0;

  constructor(galleryInfo?: GalleryInfo) {
    super();
    if (galleryInfo) {
      this.copyFrom(galleryInfo);
    }
  }

  /** Copy all fields from another GalleryInfo (or LocalFavoriteInfo). */
  override copyFrom(info: GalleryInfo): void {
    super.copyFrom(info);
    if (info instanceof LocalFavoriteInfo) {
      this.time = info.time;
    }
  }

  /** Serialize to a plain JSON-compatible object. */
  override toJSON(): Record<string, Object | null> {
    return {
      ...super.toJSON(),
      time: this.time,
    };
  }

  /** Deserialize from a plain object. */
  static override fromJSON(json: Record<string, Object | null>): LocalFavoriteInfo {
    const base = GalleryInfo.fromJSON(json);
    const info = new LocalFavoriteInfo(base);
    info.time = json['time'] as number ?? 0;
    return info;
  }
}
