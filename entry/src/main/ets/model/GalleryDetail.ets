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
import { GalleryTagGroup } from './GalleryTagGroup';
import { GalleryCommentList } from './GalleryComment';
import { PreviewSet } from './PreviewSet';
import { LargePreviewSet } from './LargePreviewSet';
import { NormalPreviewSet } from './NormalPreviewSet';

export class GalleryDetail extends GalleryInfo {
  apiUid: number = -1;
  apiKey: string = '';
  torrentCount: number = 0;
  torrentUrl: string = '';
  archiveUrl: string = '';
  parent: string = '';
  visible: string = '';
  language: string = '';
  size: string = '';
  favoriteCount: number = 0;
  isFavorited: boolean = false;
  ratingCount: number = 0;
  tags: GalleryTagGroup[] = [];
  comments: GalleryCommentList = new GalleryCommentList();
  previewPages: number = 0;
  previewSet: PreviewSet | null = null;

  /** Copy all fields from another GalleryDetail (or GalleryInfo). */
  override copyFrom(info: GalleryInfo): void {
    super.copyFrom(info);
    if (info instanceof GalleryDetail) {
      this.apiUid = info.apiUid;
      this.apiKey = info.apiKey;
      this.torrentCount = info.torrentCount;
      this.torrentUrl = info.torrentUrl;
      this.archiveUrl = info.archiveUrl;
      this.parent = info.parent;
      this.visible = info.visible;
      this.language = info.language;
      this.size = info.size;
      this.favoriteCount = info.favoriteCount;
      this.isFavorited = info.isFavorited;
      this.ratingCount = info.ratingCount;
      this.tags = info.tags.map(t => {
        const copy = new GalleryTagGroup();
        copy.groupName = t.groupName;
        for (const tag of t.getTags()) {
          copy.addTag(tag);
        }
        return copy;
      });
      this.comments = GalleryCommentList.of([...info.comments.comments], info.comments.hasMore);
      this.previewPages = info.previewPages;
      this.previewSet = info.previewSet;
    }
  }

  /** Serialize to a plain JSON-compatible object (replaces Android Parcelable). */
  override toJSON(): Record<string, Object | null> {
    const base = super.toJSON();
    let previewSetJson: Record<string, Object> | null = null;
    if (this.previewSet instanceof LargePreviewSet) {
      previewSetJson = (this.previewSet as LargePreviewSet).toJSON();
    } else if (this.previewSet instanceof NormalPreviewSet) {
      previewSetJson = (this.previewSet as NormalPreviewSet).toJSON();
    }
    return {
      ...base,
      apiUid: this.apiUid,
      apiKey: this.apiKey,
      torrentCount: this.torrentCount,
      torrentUrl: this.torrentUrl,
      archiveUrl: this.archiveUrl,
      parent: this.parent,
      visible: this.visible,
      language: this.language,
      size: this.size,
      favoriteCount: this.favoriteCount,
      isFavorited: this.isFavorited,
      ratingCount: this.ratingCount,
      tags: this.tags.map(t => t.toJSON()),
      comments: this.comments.toJSON(),
      previewPages: this.previewPages,
      previewSet: previewSetJson,
    };
  }

  /** Deserialize from a plain object (replaces Android Parcelable.Creator). */
  static override fromJSON(json: Record<string, Object | null>): GalleryDetail {
    const detail = new GalleryDetail();
    const base = GalleryInfo.fromJSON(json);
    detail.copyFrom(base);
    detail.apiUid = json['apiUid'] as number ?? -1;
    detail.apiKey = json['apiKey'] as string ?? '';
    detail.torrentCount = json['torrentCount'] as number ?? 0;
    detail.torrentUrl = json['torrentUrl'] as string ?? '';
    detail.archiveUrl = json['archiveUrl'] as string ?? '';
    detail.parent = json['parent'] as string ?? '';
    detail.visible = json['visible'] as string ?? '';
    detail.language = json['language'] as string ?? '';
    detail.size = json['size'] as string ?? '';
    detail.favoriteCount = json['favoriteCount'] as number ?? 0;
    detail.isFavorited = json['isFavorited'] as boolean ?? false;
    detail.ratingCount = json['ratingCount'] as number ?? 0;
    const tagsArr = json['tags'] as Record<string, Object | null>[] | null;
    detail.tags = tagsArr ? tagsArr.map(t => GalleryTagGroup.fromJSON(t)) : [];
    const commentsObj = json['comments'] as Record<string, Object | null> | null;
    detail.comments = commentsObj ? GalleryCommentList.fromJSON(commentsObj) : new GalleryCommentList();
    detail.previewPages = json['previewPages'] as number ?? 0;
    const previewSetObj = json['previewSet'] as Record<string, Object | null> | null;
    if (previewSetObj) {
      const psType = previewSetObj['type'] as string | null;
      if (psType === 'large') {
        detail.previewSet = LargePreviewSet.fromJSON(previewSetObj);
      } else if (psType === 'normal') {
        detail.previewSet = NormalPreviewSet.fromJSON(previewSetObj);
      }
    }
    return detail;
  }
}
