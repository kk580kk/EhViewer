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

export class GalleryPreview {
  imageKey: string = '';
  imageUrl: string = '';
  pageUrl: string = '';
  position: number = 0;
  offsetX: number = Number.MIN_SAFE_INTEGER;
  offsetY: number = Number.MIN_SAFE_INTEGER;
  clipWidth: number = Number.MIN_SAFE_INTEGER;
  clipHeight: number = Number.MIN_SAFE_INTEGER;

  getPosition(): number {
    return this.position;
  }

  /** Whether this preview has clip/offset data (i.e. is a normal/thumbnail preview). */
  isClipped(): boolean {
    return this.offsetX !== Number.MIN_SAFE_INTEGER
      && this.offsetY !== Number.MIN_SAFE_INTEGER
      && this.clipWidth !== Number.MIN_SAFE_INTEGER
      && this.clipHeight !== Number.MIN_SAFE_INTEGER;
  }

  /** Serialize to a plain JSON-compatible object. */
  toJSON(): Record<string, Object> {
    return {
      imageKey: this.imageKey,
      imageUrl: this.imageUrl,
      pageUrl: this.pageUrl,
      position: this.position,
      offsetX: this.offsetX,
      offsetY: this.offsetY,
      clipWidth: this.clipWidth,
      clipHeight: this.clipHeight,
    };
  }

  /** Deserialize from a plain object. */
  static fromJSON(json: Record<string, Object>): GalleryPreview {
    const p = new GalleryPreview();
    p.imageKey = json['imageKey'] as string ?? '';
    p.imageUrl = json['imageUrl'] as string ?? '';
    p.pageUrl = json['pageUrl'] as string ?? '';
    p.position = json['position'] as number ?? 0;
    p.offsetX = json['offsetX'] as number ?? Number.MIN_SAFE_INTEGER;
    p.offsetY = json['offsetY'] as number ?? Number.MIN_SAFE_INTEGER;
    p.clipWidth = json['clipWidth'] as number ?? Number.MIN_SAFE_INTEGER;
    p.clipHeight = json['clipHeight'] as number ?? Number.MIN_SAFE_INTEGER;
    return p;
  }
}
