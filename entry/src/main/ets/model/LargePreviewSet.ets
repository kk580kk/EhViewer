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

import { GalleryPreview } from './GalleryPreview';
import { PreviewSet } from './PreviewSet';

export class LargePreviewSet extends PreviewSet {
  private positionList: number[] = [];
  private imageUrlList: string[] = [];
  private pageUrlList: string[] = [];

  private static getLargePreviewKey(gid: number, index: number): string {
    return `preview:large:${gid}:${index}`;
  }

  addItem(index: number, imageUrl: string, pageUrl: string): void {
    this.positionList.push(index);
    this.imageUrlList.push(imageUrl);
    this.pageUrlList.push(pageUrl);
  }

  size(): number {
    return this.imageUrlList.length;
  }

  getPosition(index: number): number {
    return this.positionList[index];
  }

  getPageUrlAt(index: number): string {
    return this.pageUrlList[index];
  }

  getGalleryPreview(gid: number, index: number): GalleryPreview {
    const preview = new GalleryPreview();
    preview.position = this.positionList[index];
    preview.imageKey = LargePreviewSet.getLargePreviewKey(gid, preview.position);
    preview.imageUrl = this.imageUrlList[index];
    preview.pageUrl = this.pageUrlList[index];
    return preview;
  }

  /** Serialize to a plain JSON-compatible object. */
  toJSON(): Record<string, Object> {
    return {
      type: 'large',
      positionList: [...this.positionList],
      imageUrlList: [...this.imageUrlList],
      pageUrlList: [...this.pageUrlList],
    };
  }

  /** Deserialize from a plain object. */
  static fromJSON(json: Record<string, Object | null>): LargePreviewSet {
    const set = new LargePreviewSet();
    const positions = json['positionList'] as number[] | null;
    const imageUrls = json['imageUrlList'] as string[] | null;
    const pageUrls = json['pageUrlList'] as string[] | null;
    if (positions && imageUrls && pageUrls) {
      for (let i = 0; i < positions.length; i++) {
        set.addItem(positions[i], imageUrls[i], pageUrls[i]);
      }
    }
    return set;
  }
}
