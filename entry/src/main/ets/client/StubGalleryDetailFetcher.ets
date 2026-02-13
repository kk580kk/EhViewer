/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { GalleryDetail } from '../model/GalleryDetail';
import { GalleryTagGroup } from '../model/GalleryTagGroup';
import { GalleryComment, GalleryCommentList } from '../model/GalleryComment';
import { LargePreviewSet } from '../model/LargePreviewSet';
import { EhConfig } from './EhConfig';
import { EhUrl } from './EhUrl';
import type { GalleryDetailFetcher } from '../viewmodel/GalleryDetailViewModel';

/**
 * Stub fetcher that generates mock gallery detail for development.
 * Replace with a real EhEngine-backed fetcher when network layer is integrated.
 */
export class StubGalleryDetailFetcher implements GalleryDetailFetcher {
  async fetchDetail(gid: number, token: string): Promise<GalleryDetail> {
    // Simulate network delay
    await new Promise<void>((resolve) => {
      const id = setTimeout(() => { resolve(); clearTimeout(id); }, 500);
    });

    const detail = new GalleryDetail();
    detail.gid = gid;
    detail.token = token;
    detail.title = `[Artist] Gallery Collection Vol.${gid}`;
    detail.titleJpn = `[作者] ギャラリーコレクション Vol.${gid}`;
    detail.thumb = `https://via.placeholder.com/250x350/1a237e/ffffff?text=G${gid}`;
    detail.category = EhConfig.DOUJINSHI;
    detail.uploader = 'gallery_master';
    detail.rating = 4.2;
    detail.ratingCount = 156;
    detail.posted = '2024-01-15 12:30';
    detail.pages = 42;
    detail.language = 'Japanese';
    detail.size = '125.6 MB';
    detail.favoriteCount = 328;
    detail.isFavorited = false;
    detail.torrentCount = 2;
    detail.parent = '';
    detail.visible = 'Yes';

    // Tags
    const langGroup = new GalleryTagGroup();
    langGroup.groupName = 'language';
    langGroup.addTag('japanese');
    langGroup.addTag('translated');

    const artistGroup = new GalleryTagGroup();
    artistGroup.groupName = 'artist';
    artistGroup.addTag('sample artist');

    const femaleGroup = new GalleryTagGroup();
    femaleGroup.groupName = 'female';
    femaleGroup.addTag('tag one');
    femaleGroup.addTag('tag two');
    femaleGroup.addTag('tag three');

    const maleGroup = new GalleryTagGroup();
    maleGroup.groupName = 'male';
    maleGroup.addTag('tag alpha');

    detail.tags = [langGroup, artistGroup, femaleGroup, maleGroup];

    // Comments
    const commentList = new GalleryCommentList();
    const c1 = new GalleryComment();
    c1.id = 1;
    c1.user = 'user_one';
    c1.comment = 'Great gallery, thanks for sharing!';
    c1.score = 5;
    c1.time = Date.now() - 86400000;
    c1.voteUpAble = true;
    c1.voteDownAble = true;

    const c2 = new GalleryComment();
    c2.id = 2;
    c2.user = 'user_two';
    c2.comment = 'Nice quality scans.';
    c2.score = 3;
    c2.time = Date.now() - 172800000;
    c2.voteUpAble = true;
    c2.voteDownAble = true;

    commentList.comments = [c1, c2];
    commentList.hasMore = true;
    detail.comments = commentList;

    detail.previewPages = 3;
    const previewSet = new LargePreviewSet();
    const baseUrl = EhUrl.getGalleryDetailUrl(gid, token);
    previewSet.addItem(0, `https://via.placeholder.com/200x280/283593/ffffff?text=P1`, `${baseUrl}#p=0`);
    previewSet.addItem(1, `https://via.placeholder.com/200x280/3949ab/ffffff?text=P2`, `${baseUrl}#p=1`);
    previewSet.addItem(2, `https://via.placeholder.com/200x280/5c6bc0/ffffff?text=P3`, `${baseUrl}#p=2`);
    detail.previewSet = previewSet;

    return detail;
  }
}
