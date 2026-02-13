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
import { ListState } from '../../viewmodel/GalleryListViewModel';

export { GalleryItemData } from '../../viewmodel/GalleryItemData.ets';

/**
 * Gallery list tab content — displays gallery items with search, refresh,
 * pagination and mode switching.
 *
 * Data and actions are injected from the parent (Index) via props / callbacks,
 * keeping this component a pure presentation layer.
 */

@Component
export struct GalleryListTab {
  /** Gallery items to display. */
  @Prop items: GalleryItemData[] = [];
  /** Current loading state. */
  @Prop listState: number = ListState.IDLE;
  /** Whether there are more pages to load. */
  @Prop hasMore: boolean = false;
  /** Error message (when state is FAILED). */
  @Prop errorMessage: string = '';
  /** Current mode title (Homepage / Subscription / What's Hot / Search). */
  @Prop modeTitle: string = 'Homepage';

  /** Search text managed locally. */
  @State searchText: string = '';

  /** Callback when user taps a gallery item. */
  onItemClick: (gid: number, token: string) => void = () => {};
  /** Callback when user triggers refresh (pull-to-refresh). */
  onRefresh: () => void = () => {};
  /** Callback when user scrolls to bottom (load more). */
  onLoadMore: () => void = () => {};
  /** Callback when user submits a search query. */
  onSearch: (keyword: string) => void = () => {};
  /** Callback when user clears the search. */
  onClearSearch: () => void = () => {};
  /** Callback when user switches mode. */
  onModeChange: (mode: number) => void = () => {};

  build() {
    Column() {
      // Header with mode title
      Row() {
        Text(this.modeTitle)
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
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 4 })

      // Search bar
      Row() {
        TextInput({ placeholder: 'Search galleries...', text: this.searchText })
          .width('100%')
          .height(40)
          .backgroundColor('#FFFFFF')
          .borderRadius(20)
          .padding({ left: 16, right: 16 })
          .onSubmit(() => {
            if (this.searchText.length > 0) {
              this.onSearch(this.searchText);
            } else {
              this.onClearSearch();
            }
          })
          .onChange((value: string) => {
            this.searchText = value;
            if (value.length === 0) {
              this.onClearSearch();
            }
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 4, bottom: 8 })

      // Mode switcher chips
      Row() {
        this.ModeChip('Homepage', 0)
        this.ModeChip('Subscription', 1)
        this.ModeChip("What's Hot", 2)
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })

      // Content area
      if (this.listState === ListState.LOADING || this.listState === ListState.REFRESHING) {
        Column() {
          Text('Loading...')
            .fontSize(16)
            .fontColor('#666666')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.listState === ListState.FAILED) {
        Column() {
          Text(this.errorMessage || 'Failed to load')
            .fontSize(14)
            .fontColor('#B00020')
            .textAlign(TextAlign.Center)
            .margin({ bottom: 16 })
          Text('Tap to retry')
            .fontSize(16)
            .fontColor('#4169E1')
            .onClick(() => { this.onRefresh(); })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.listState === ListState.EMPTY) {
        Column() {
          Text('\u{1F4F0}')
            .fontSize(64)
            .fontColor('#CCCCCC')
            .margin({ bottom: 16 })
          Text('No galleries found')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ bottom: 4 })
          Text('Try a different search or mode')
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

          // Load more indicator
          if (this.hasMore) {
            ListItem() {
              Row() {
                Text(this.listState === ListState.LOAD_MORE ? 'Loading more...' : 'Pull up to load more')
                  .fontSize(13)
                  .fontColor('#999999')
              }
              .width('100%')
              .height(48)
              .justifyContent(FlexAlign.Center)
            }
          }
        }
        .width('100%')
        .layoutWeight(1)
        .divider({ strokeWidth: 0.5, color: '#F0F0F0', startMargin: 88, endMargin: 16 })
        .onReachEnd(() => {
          if (this.hasMore && this.listState !== ListState.LOAD_MORE) {
            this.onLoadMore();
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  ModeChip(label: string, mode: number) {
    Text(label)
      .fontSize(12)
      .fontColor(this.isModeActive(mode) ? '#FFFFFF' : '#4169E1')
      .backgroundColor(this.isModeActive(mode) ? '#4169E1' : '#E8EEFF')
      .borderRadius(16)
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .margin({ right: 8 })
      .onClick(() => {
        this.onModeChange(mode);
      })
  }

  private isModeActive(mode: number): boolean {
    const modeTitles: string[] = ['Homepage', 'Subscription', "What's Hot"];
    if (mode < modeTitles.length) {
      return this.modeTitle === modeTitles[mode];
    }
    return false;
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

        // Posted date & language
        Row() {
          Text(item.posted)
            .fontSize(11)
            .fontColor('#999999')
            .layoutWeight(1)
          if (item.simpleLanguage.length > 0) {
            Text(item.simpleLanguage)
              .fontSize(10)
              .fontColor('#666666')
              .backgroundColor('#F0F0F0')
              .borderRadius(3)
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
          }
        }
        .width('100%')
        .margin({ top: 2 })
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
