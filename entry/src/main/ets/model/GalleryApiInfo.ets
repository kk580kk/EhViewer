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

export class GalleryApiInfo {
  gid: number = 0;
  token: string = '';
  archiverKey: string = '';
  title: string = '';
  titleJpn: string = '';
  category: number = 0;
  thumb: string = '';
  uploader: string = '';
  posted: number = 0;
  filecount: number = 0;
  filesize: number = 0;
  expunged: boolean = false;
  rating: number = 0;
  torrentcount: number = 0;
  tags: string[] | null = null;

  /** Apply API response data onto an existing GalleryInfo instance. */
  applyTo(info: GalleryInfo): void {
    info.gid = this.gid;
    info.token = this.token;
    if (this.title) info.title = this.title;
    if (this.titleJpn) info.titleJpn = this.titleJpn;
    info.category = this.category;
    if (this.thumb) info.thumb = this.thumb;
    if (this.uploader) info.uploader = this.uploader;
    info.rating = this.rating;
    info.pages = this.filecount;
    info.simpleTags = this.tags ? [...this.tags] : null;
    info.generateSLang();
  }

  /** Serialize to a plain JSON-compatible object. */
  toJSON(): Record<string, Object | null> {
    return {
      gid: this.gid,
      token: this.token,
      archiverKey: this.archiverKey,
      title: this.title,
      titleJpn: this.titleJpn,
      category: this.category,
      thumb: this.thumb,
      uploader: this.uploader,
      posted: this.posted,
      filecount: this.filecount,
      filesize: this.filesize,
      expunged: this.expunged,
      rating: this.rating,
      torrentcount: this.torrentcount,
      tags: this.tags,
    };
  }

  /** Deserialize from a plain object. */
  static fromJSON(json: Record<string, Object | null>): GalleryApiInfo {
    const info = new GalleryApiInfo();
    info.gid = json['gid'] as number ?? 0;
    info.token = json['token'] as string ?? '';
    info.archiverKey = json['archiverKey'] as string ?? '';
    info.title = json['title'] as string ?? '';
    info.titleJpn = json['titleJpn'] as string ?? '';
    info.category = json['category'] as number ?? 0;
    info.thumb = json['thumb'] as string ?? '';
    info.uploader = json['uploader'] as string ?? '';
    info.posted = json['posted'] as number ?? 0;
    info.filecount = json['filecount'] as number ?? 0;
    info.filesize = json['filesize'] as number ?? 0;
    info.expunged = json['expunged'] as boolean ?? false;
    info.rating = json['rating'] as number ?? 0;
    info.torrentcount = json['torrentcount'] as number ?? 0;
    info.tags = json['tags'] as string[] | null ?? null;
    return info;
  }
}
