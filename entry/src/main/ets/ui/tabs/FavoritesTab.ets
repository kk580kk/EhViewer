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

export { GalleryItemData } from '../../viewmodel/GalleryItemData.ets';

/**
 * Favorites tab — shows the user's local favourite galleries.
 *
 * Features:
 *  - Gallery list with thumbnail, title, category badge, rating, uploader
 *  - Search bar for filtering favorites
 *  - Swipe or long-press to remove a favorite
 *  - Empty state placeholder
 */

@Component
export struct FavoritesTab {
  /** Gallery items to display. Provided by the parent via ViewModel. */
  @Prop items: GalleryItemData[] = [];
  /** Whether the list is empty (show placeholder). */
  @Prop isEmpty: boolean = true;
  /** Current search keyword. */
  @State searchText: string = '';
  /** Whether search bar is active. */
  @State searchActive: boolean = false;

  /** Callback when user taps a gallery item. */
  onItemClick: (gid: number, token: string) => void = () => {};
  /** Callback when user requests to remove a favorite. */
  onRemove: (gid: number) => void = () => {};
  /** Callback when user performs a search. */
  onSearch: (keyword: string) => void = () => {};
  /** Callback when user clears the search. */
  onClearSearch: () => void = () => {};

  build() {
    Column() {
      // Search bar
      Row() {
        TextInput({ placeholder: 'Search favorites...', text: this.searchText })
          .width('100%')
          .height(40)
          .backgroundColor('#FFFFFF')
          .borderRadius(20)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.searchText = value;
            this.onSearch(value);
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor('#F5F5F5')

      if (this.isEmpty) {
        // Empty state
        Column() {
          Text('\u2606')
            .fontSize(64)
            .fontColor('#CCCCCC')
            .margin({ bottom: 16 })
          Text('No favorites yet')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ bottom: 4 })
          Text('Add galleries to your favorites to see them here')
            .fontSize(13)
            .fontColor('#BBBBBB')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        // Gallery list
        List() {
          ForEach(this.items, (item: GalleryItemData) => {
            ListItem() {
              this.GalleryRow(item)
            }
            .onClick(() => {
              this.onItemClick(item.gid, item.token);
            })
          }, (item: GalleryItemData) => item.gid.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .divider({ strokeWidth: 0.5, color: '#F0F0F0', startMargin: 88, endMargin: 16 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  GalleryRow(item: GalleryItemData) {
    Row() {
      // Thumbnail placeholder
      Column() {
        Text('\u{1F5BC}')
          .fontSize(28)
          .fontColor('#CCCCCC')
      }
      .width(72)
      .height(96)
      .backgroundColor('#EEEEEE')
      .borderRadius(6)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      // Info
      Column() {
        // Title
        Text(item.title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1a1a1a')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        // Category badge
        Text(item.categoryText)
          .fontSize(10)
          .fontColor('#FFFFFF')
          .backgroundColor(item.categoryColor)
          .borderRadius(3)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .margin({ top: 4 })

        // Uploader & Rating
        Row() {
          Text(item.uploader)
            .fontSize(12)
            .fontColor('#666666')
            .layoutWeight(1)
          Text(`\u2605 ${item.rating.toFixed(1)}`)
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
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
  }
}

