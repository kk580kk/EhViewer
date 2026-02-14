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

export class NormalPreviewSet extends PreviewSet {
  private positionList: number[] = [];
  private imageKeyList: string[] = [];
  private imageUrlList: string[] = [];
  private offsetXList: number[] = [];
  private offsetYList: number[] = [];
  private clipWidthList: number[] = [];
  private clipHeightList: number[] = [];
  private pageUrlList: string[] = [];

  private static getImageKey(imageUrl: string): string {
    const index = imageUrl.indexOf('/');
    return index >= 0 ? imageUrl.substring(index + 1) : imageUrl;
  }

  addItem(position: number, imageUrl: string, xOffset: number, yOffset: number,
    width: number, height: number, pageUrl: string): void {
    this.positionList.push(position);
    this.imageKeyList.push(NormalPreviewSet.getImageKey(imageUrl));
    this.imageUrlList.push(imageUrl);
    this.offsetXList.push(xOffset);
    this.offsetYList.push(yOffset);
    this.clipWidthList.push(width);
    this.clipHeightList.push(height);
    this.pageUrlList.push(pageUrl);
  }

  size(): number {
    return this.positionList.length;
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
    preview.imageKey = this.imageKeyList[index];
    preview.imageUrl = this.imageUrlList[index];
    preview.pageUrl = this.pageUrlList[index];
    preview.offsetX = this.offsetXList[index];
    preview.offsetY = this.offsetYList[index];
    preview.clipWidth = this.clipWidthList[index];
    preview.clipHeight = this.clipHeightList[index];
    return preview;
  }

  /** Serialize to a plain JSON-compatible object. */
  toJSON(): Record<string, Object> {
    return {
      type: 'normal',
      positionList: [...this.positionList],
      imageUrlList: [...this.imageUrlList],
      offsetXList: [...this.offsetXList],
      offsetYList: [...this.offsetYList],
      clipWidthList: [...this.clipWidthList],
      clipHeightList: [...this.clipHeightList],
      pageUrlList: [...this.pageUrlList],
    };
  }

  /** Deserialize from a plain object. */
  static fromJSON(json: Record<string, Object | null>): NormalPreviewSet {
    const set = new NormalPreviewSet();
    const positions = json['positionList'] as number[] | null;
    const imageUrls = json['imageUrlList'] as string[] | null;
    const offsetXs = json['offsetXList'] as number[] | null;
    const offsetYs = json['offsetYList'] as number[] | null;
    const clipWidths = json['clipWidthList'] as number[] | null;
    const clipHeights = json['clipHeightList'] as number[] | null;
    const pageUrls = json['pageUrlList'] as string[] | null;
    if (positions && imageUrls && offsetXs && offsetYs && clipWidths && clipHeights && pageUrls) {
      for (let i = 0; i < positions.length; i++) {
        set.addItem(positions[i], imageUrls[i], offsetXs[i], offsetYs[i],
          clipWidths[i], clipHeights[i], pageUrls[i]);
      }
    }
    return set;
  }
}
