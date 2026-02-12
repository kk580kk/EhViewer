/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { GalleryItemData } from '../../viewmodel/GalleryItemData.ets';

/**
 * GalleryCard — reusable gallery list item component.
 *
 * Displays thumbnail, title, category badge, uploader, and rating
 * in a horizontal card layout. Used by Favorites, History, Downloads,
 * and Gallery List tabs to avoid duplicated gallery row code.
 *
 * Usage:
 *   GalleryCard({
 *     item: galleryItemData,
 *     onItemClick: () => { ... },
 *   })
 */
@Component
export struct GalleryCard {
  @Prop item: GalleryItemData = new GalleryItemData();
  onItemClick: () => void = () => {};
  /** Optional builder for right-side actions (e.g. delete, start/stop). */
  @BuilderParam rightActions: () => void;

  build() {
    Row() {
      // Thumbnail
      Column() {
        if (this.item.thumb.length > 0) {
          Image(this.item.thumb)
            .width(72)
            .height(96)
            .borderRadius(6)
            .objectFit(ImageFit.Cover)
        } else {
          Text('\u{1F5BC}')
            .fontSize(28)
            .fontColor('#CCCCCC')
        }
      }
      .width(72)
      .height(96)
      .backgroundColor('#EEEEEE')
      .borderRadius(6)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      // Info column
      Column() {
        // Title
        Text(this.item.title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1a1a1a')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        // Category badge
        if (this.item.categoryText.length > 0) {
          Text(this.item.categoryText)
            .fontSize(10)
            .fontColor('#FFFFFF')
            .backgroundColor(this.item.categoryColor)
            .borderRadius(3)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .margin({ top: 4 })
        }

        // Uploader & rating
        Row() {
          Text(this.item.uploader)
            .fontSize(12)
            .fontColor('#666666')
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(`\u2605 ${this.item.rating.toFixed(1)}`)
            .fontSize(12)
            .fontColor('#FF9800')
        }
        .width('100%')
        .margin({ top: 4 })
      }
      .layoutWeight(1)
      .padding({ left: 12 })
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Start)

      // Optional right actions slot
      if (this.rightActions) {
        this.rightActions()
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .onClick(() => this.onItemClick())
  }
}
