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

import { GalleryInfo } from '../model/GalleryInfo.ets';

/**
 * Download task state constants and runtime data.
 *
 * Extends GalleryInfo with download-specific fields (state, progress, label, etc.).
 * Mirrors the Android DownloadInfo DAO entity.
 */
export class DownloadInfo extends GalleryInfo {
  // --- State constants ---
  static readonly STATE_INVALID: number = -1;
  static readonly STATE_NONE: number = 0;
  static readonly STATE_WAIT: number = 1;
  static readonly STATE_DOWNLOAD: number = 2;
  static readonly STATE_FINISH: number = 3;
  static readonly STATE_FAILED: number = 4;

  // --- Persisted fields ---
  state: number = DownloadInfo.STATE_NONE;
  legacy: number = -1;
  time: number = 0;
  label: string | null = null;

  // --- Runtime-only fields (not persisted) ---
  speed: number = -1;
  remaining: number = -1;
  finished: number = 0;
  downloaded: number = 0;
  total: number = -1;

  constructor(galleryInfo?: GalleryInfo) {
    super();
    if (galleryInfo) {
      this.copyFrom(galleryInfo);
    }
  }

  /**
   * Returns progress as a percentage (0–100), or -1 if indeterminate.
   */
  getProgressPercent(): number {
    if (this.state !== DownloadInfo.STATE_DOWNLOAD) {
      return this.state === DownloadInfo.STATE_FINISH ? 100 : -1;
    }
    if (this.total <= 0 || this.finished < 0) {
      return -1;
    }
    return Math.round((this.finished / this.total) * 100);
  }

  /**
   * Returns true if this download is currently active (waiting or downloading).
   */
  isActive(): boolean {
    return this.state === DownloadInfo.STATE_WAIT || this.state === DownloadInfo.STATE_DOWNLOAD;
  }
}
