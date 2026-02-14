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
 * Gallery browsing history entry.
 *
 * Extends GalleryInfo with browsing mode and timestamp.
 * Mirrors the Android HistoryInfo DAO entity.
 */
export class HistoryInfo extends GalleryInfo {
  mode: number = 0;
  time: number = 0;

  constructor(galleryInfo?: GalleryInfo) {
    super();
    if (galleryInfo) {
      this.copyFrom(galleryInfo);
    }
  }

  /** Copy all fields from another GalleryInfo (or HistoryInfo). */
  override copyFrom(info: GalleryInfo): void {
    super.copyFrom(info);
    if (info instanceof HistoryInfo) {
      this.mode = info.mode;
      this.time = info.time;
    }
  }

  /** Serialize to a plain JSON-compatible object. */
  override toJSON(): Record<string, Object | null> {
    return {
      ...super.toJSON(),
      mode: this.mode,
      time: this.time,
    };
  }

  /** Deserialize from a plain object. */
  static override fromJSON(json: Record<string, Object | null>): HistoryInfo {
    const base = GalleryInfo.fromJSON(json);
    const info = new HistoryInfo(base);
    info.mode = json['mode'] as number ?? 0;
    info.time = json['time'] as number ?? 0;
    return info;
  }
}
