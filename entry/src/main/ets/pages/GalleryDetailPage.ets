/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import router from '@ohos.router';
import { AppToolbar } from '../ui/components/AppToolbar.ets';
import { LoadImageView } from '../ui/components/LoadImageView.ets';
import {
  GalleryDetailViewModel,
  DetailState,
} from '../viewmodel/GalleryDetailViewModel.ets';
import { StubGalleryDetailFetcher } from '../client/StubGalleryDetailFetcher.ets';
import type { GalleryTagGroup } from '../model/GalleryTagGroup';
import type { GalleryComment } from '../model/GalleryComment';
import type { GalleryPreview } from '../model/GalleryPreview';
import { ReadableTime } from '../util/ReadableTime.ets';

/**
 * Gallery detail page — full gallery info, tags, comments, and previews.
 *
 * Receives route params: { gid: number, token: string }
 */

interface DetailParams {
  gid: number;
  token: string;
}

@Entry
@Component
struct GalleryDetailPage {
  @State gid: number = 0;
  @State token: string = '';
  @State detailState: DetailState = DetailState.LOADING;
  @State errorMessage: string = '';

  private vm: GalleryDetailViewModel = new GalleryDetailViewModel(new StubGalleryDetailFetcher());

  aboutToAppear(): void {
    const params = router.getParams() as DetailParams | undefined;
    if (params) {
      this.gid = params.gid ?? 0;
      this.token = params.token ?? '';
    }
    this.vm.setOnStateChange(() => {
      this.detailState = this.vm.state;
      this.errorMessage = this.vm.error;
    });
    this.vm.load(this.gid, this.token);
  }

  build() {
    Column() {
      AppToolbar({
        title: this.vm.displayTitle || 'Gallery Detail',
        showBack: true,
        onBack: () => { router.back(); },
      })

      if (this.detailState === DetailState.LOADING) {
        Column() {
          Text('Loading...')
            .fontSize(16)
            .fontColor('#666666')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.detailState === DetailState.FAILED) {
        Column() {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor('#B00020')
            .textAlign(TextAlign.Center)
            .margin({ bottom: 16 })
          Text('Retry')
            .fontSize(16)
            .fontColor('#1976D2')
            .onClick(() => { this.vm.retry(); })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column() {
            this.HeaderSection();
            this.InfoSection();
            this.RatingSection();
            this.ActionsSection();
            this.TagsSection();
            this.CommentsSection();
            this.PreviewsSection();
          }
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  HeaderSection() {
    Column() {
      Row() {
        LoadImageView({
          src: this.vm.thumbUrl,
          imageWidth: 120,
          imageHeight: 168,
          radius: 8,
        })
        Column() {
          Text(this.vm.displayTitle)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1a1a1a')
            .maxLines(5)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.vm.uploaderText)
            .fontSize(13)
            .fontColor('#666666')
            .margin({ top: 6 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.vm.categoryText)
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .backgroundColor(this.vm.categoryColor)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .margin({ top: 8 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
      .padding(16)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  InfoSection() {
    Column() {
      Row() {
        Text(this.vm.languageText || '—')
          .fontSize(14)
          .fontColor('#333333')
          .layoutWeight(1)
        Text(this.vm.pagesText)
          .fontSize(14)
          .fontColor('#333333')
        Text(this.vm.sizeText || '—')
          .fontSize(14)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      Row() {
        Text(`Fav: ${this.vm.favoriteCountText}`)
          .fontSize(14)
          .fontColor('#333333')
          .layoutWeight(1)
        Text(this.vm.postedText || '—')
          .fontSize(14)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .margin({ top: 8 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
  }

  @Builder
  RatingSection() {
    Row() {
      Text(`★ ${this.vm.ratingValue.toFixed(1)}`)
        .fontSize(14)
        .fontColor('#333333')
      Text(this.vm.ratingCountText)
        .fontSize(13)
        .fontColor('#666666')
        .margin({ left: 8 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 4, bottom: 8 })
  }

  @Builder
  ActionsSection() {
    Row() {
      Text('Download')
        .fontSize(15)
        .fontColor('#333333')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Divider()
        .vertical(true)
        .height(24)
        .color('#E0E0E0')
      Text('Read')
        .fontSize(15)
        .fontColor('#1976D2')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(48)
    .backgroundColor('#F5F5F5')
    .borderRadius(8)
    .margin({ left: 16, right: 16, top: 8, bottom: 8 })
  }

  @Builder
  TagsSection() {
    const tags: GalleryTagGroup[] = this.vm.tags;
    if (tags.length === 0) {
      return;
    }
    Column() {
      Text('Tags')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .margin({ bottom: 8 })
      ForEach(tags, (group: GalleryTagGroup, groupIndex: number) => {
        Column() {
          Text(group.groupName)
            .fontSize(12)
            .fontColor('#666666')
            .margin({ bottom: 4 })
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(group.getTags(), (tag: string, tagIndex: number) => {
              Text(tag)
                .fontSize(12)
                .fontColor('#1976D2')
                .backgroundColor('#E3F2FD')
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .margin({ right: 4, bottom: 4 })
                .borderRadius(4)
            }, (tag: string, tagIndex: number) => `tag_${groupIndex}_${tagIndex}_${tag}`)
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: 12 })
      }, (group: GalleryTagGroup, groupIndex: number) => `group_${groupIndex}_${group.groupName}`)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(16)
  }

  @Builder
  CommentsSection() {
    const comments: GalleryComment[] = this.vm.comments;
    if (comments.length === 0) {
      return;
    }
    Column() {
      Text('Comments')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .margin({ bottom: 8 })
      ForEach(comments, (c: GalleryComment, index: number) => {
        Column() {
          Row() {
            Text(c.user)
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
            Text(c.score > 0 ? ` +${c.score}` : '')
              .fontSize(12)
              .fontColor('#4CAF50')
            Text(ReadableTime.getPlainTime(c.time))
              .fontSize(12)
              .fontColor('#999999')
              .margin({ left: 8 })
          }
          .width('100%')
          Text(c.comment)
            .fontSize(13)
            .fontColor('#555555')
            .margin({ top: 4 })
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(12)
        .backgroundColor('#FAFAFA')
        .borderRadius(8)
        .margin({ bottom: 8 })
      }, (c: GalleryComment, index: number) => `comment_${index}_${c.id}`)
      if (this.vm.hasMoreComments) {
        Text('More comments...')
          .fontSize(13)
          .fontColor('#1976D2')
          .margin({ top: 4 })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(16)
  }

  @Builder
  PreviewsSection() {
    const previews: GalleryPreview[] = this.vm.getPreviews();
    if (previews.length === 0) {
      return;
    }
    Column() {
      Text(`Previews (${this.vm.previewCount})`)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .margin({ bottom: 8 })
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(previews, (p: GalleryPreview, index: number) => {
          Column() {
            if (p.imageUrl.length > 0) {
              Image(p.imageUrl)
                .width('100%')
                .aspectRatio(0.7)
                .objectFit(ImageFit.Cover)
                .borderRadius(6)
            } else {
              Column() {
                Text(`P${p.position + 1}`)
                  .fontSize(12)
                  .fontColor('#999999')
              }
              .width('100%')
              .aspectRatio(0.7)
              .backgroundColor('#EEEEEE')
              .borderRadius(6)
              .justifyContent(FlexAlign.Center)
            }
          }
          .width('31%')
          .margin({ right: '2%', bottom: 8 })
        }, (p: GalleryPreview, index: number) => `preview_${index}_${p.position}`)
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(16)
  }
}
