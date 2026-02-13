/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { GalleryItemData, DownloadItemData } from '../../viewmodel/GalleryItemData.ets';

export { DownloadItemData } from '../../viewmodel/GalleryItemData.ets';

/**
 * Downloads tab — shows the DownloadManager task list.
 *
 * Features:
 *  - Download list with thumbnail, title, state, progress
 *  - Label filter dropdown
 *  - Start/Stop/Delete controls per item
 *  - Empty state placeholder
 */

@Component
export struct DownloadsTab {
  /** Download items to display. */
  @Prop items: DownloadItemData[] = [];
  /** Whether the list is empty. */
  @Prop isEmpty: boolean = true;
  /** Available label names for filtering. */
  @Prop labelNames: string[] = ['All Downloads'];
  /** Currently selected label index. */
  @State selectedLabelIndex: number = 0;

  /** Callback when user taps a download item. */
  onItemClick: (gid: number, token: string) => void = () => {};
  /** Callback when user removes a download. */
  onRemove: (gid: number) => void = () => {};
  /** Callback when user requests start. */
  onStart: (gid: number) => void = () => {};
  /** Callback when user requests stop. */
  onStop: (gid: number) => void = () => {};
  /** Callback when user requests pause. */
  onPause: (gid: number) => void = () => {};
  /** Callback when user requests resume. */
  onResume: (gid: number) => void = () => {};
  /** Callback when user selects a label filter. */
  onLabelChange: (label: string | null) => void = () => {};
  /** Callback when user triggers refresh. */
  onRefresh: () => void = () => {};

  build() {
    Column() {
      // Header with label filter and refresh
      Row() {
        Text('Downloads')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1a1a1a')
          .layoutWeight(1)

        // Refresh button
        Text('\u{1F504}')
          .fontSize(20)
          .fontColor('#4169E1')
          .padding(8)
          .onClick(() => {
            this.onRefresh();
          })

        // Label selector (shown as text button)
        Text(this.labelNames[this.selectedLabelIndex] ?? 'All Downloads')
          .fontSize(14)
          .fontColor('#4169E1')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(12)
          .backgroundColor('#E8EEFF')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      if (this.isEmpty) {
        // Empty state
        Column() {
          Text('\u2B07')
            .fontSize(64)
            .fontColor('#CCCCCC')
            .margin({ bottom: 16 })
          Text('No downloads yet')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ bottom: 4 })
          Text('Download galleries to read them offline')
            .fontSize(13)
            .fontColor('#BBBBBB')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        // Downloads list
        List() {
          ForEach(this.items, (item: DownloadItemData) => {
            ListItem() {
              this.DownloadRow(item)
            }
            .onClick(() => {
              this.onItemClick(item.gid, item.token);
            })
          }, (item: DownloadItemData) => item.gid.toString())
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
  DownloadRow(item: DownloadItemData) {
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

      // Info and controls
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

        // State text and progress
        Row() {
          Text(item.stateText)
            .fontSize(12)
            .fontColor(this.getStateColor(item.stateValue))
            .layoutWeight(1)

          // Action buttons
          if (item.canStart) {
            Text('\u25B6')
              .fontSize(18)
              .fontColor('#4CAF50')
              .padding(4)
              .onClick(() => {
                this.onStart(item.gid);
              })
          }
          if (item.canPause) {
            Text('\u23F8')
              .fontSize(18)
              .fontColor('#FF9800')
              .padding(4)
              .onClick(() => {
                this.onPause(item.gid);
              })
          }
          if (item.canResume) {
            Text('\u25B6')
              .fontSize(18)
              .fontColor('#4CAF50')
              .padding(4)
              .onClick(() => {
                this.onResume(item.gid);
              })
          }
          if (item.canStop) {
            Text('\u23F9')
              .fontSize(18)
              .fontColor('#F44336')
              .padding(4)
              .onClick(() => {
                this.onStop(item.gid);
              })
          }
          Text('\u2715')
            .fontSize(16)
            .fontColor('#CCCCCC')
            .padding(4)
            .onClick(() => {
              this.onRemove(item.gid);
            })
        }
        .width('100%')
        .margin({ top: 4 })

        // Progress bar for downloading or paused state
        if ((item.stateValue === 2 || item.stateValue === 5) && item.progressPercent >= 0) {
          Progress({ value: item.progressPercent, total: 100, type: ProgressType.Linear })
            .width('100%')
            .height(4)
            .margin({ top: 4 })
            .color(item.stateValue === 5 ? '#FF9800' : '#4169E1')
            .backgroundColor('#E0E0E0')
        }
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

  private getStateColor(state: number): string {
    switch (state) {
      case 1: return '#FF9800'; // Wait
      case 2: return '#4169E1'; // Downloading
      case 3: return '#4CAF50'; // Finish
      case 4: return '#F44336'; // Failed
      case 5: return '#FF9800'; // Paused
      default: return '#999999'; // None
    }
  }
}

