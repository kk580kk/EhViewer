/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { GalleryItemData, HistoryItemData } from '../../viewmodel/GalleryItemData.ets';

export { HistoryItemData } from '../../viewmodel/GalleryItemData.ets';

/**
 * History tab — shows the user's browsing history.
 *
 * Features:
 *  - Gallery list with thumbnail, title, category badge, rating, time
 *  - Swipe to delete individual entries
 *  - "Clear all" action in header
 *  - Empty state placeholder
 */

@Component
export struct HistoryTab {
  /** History items to display. */
  @Prop items: HistoryItemData[] = [];
  /** Whether the list is empty. */
  @Prop isEmpty: boolean = true;

  /** Callback when user taps a history item. */
  onItemClick: (gid: number, token: string) => void = () => {};
  /** Callback when user deletes a history entry. */
  onDelete: (index: number) => void = () => {};
  /** Callback when user clears all history. */
  onClearAll: () => void = () => {};

  build() {
    Column() {
      // Header with clear all button
      Row() {
        Text('History')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1a1a1a')
          .layoutWeight(1)

        if (!this.isEmpty) {
          Text('Clear All')
            .fontSize(14)
            .fontColor('#F44336')
            .onClick(() => {
              this.onClearAll();
            })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      if (this.isEmpty) {
        // Empty state
        Column() {
          Text('\u{1F553}')
            .fontSize(64)
            .fontColor('#CCCCCC')
            .margin({ bottom: 16 })
          Text('No history yet')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ bottom: 4 })
          Text('Galleries you browse will appear here')
            .fontSize(13)
            .fontColor('#BBBBBB')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        // History list
        List() {
          ForEach(this.items, (item: HistoryItemData, index: number) => {
            ListItem() {
              this.HistoryRow(item, index)
            }
            .onClick(() => {
              this.onItemClick(item.gid, item.token);
            })
          }, (item: HistoryItemData) => item.gid.toString())
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
  HistoryRow(item: HistoryItemData, index: number) {
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

        // Time & Rating
        Row() {
          Text(item.timeText)
            .fontSize(12)
            .fontColor('#999999')
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

      // Delete button
      Text('\u2715')
        .fontSize(18)
        .fontColor('#CCCCCC')
        .padding(8)
        .onClick(() => {
          this.onDelete(index);
        })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
  }
}

