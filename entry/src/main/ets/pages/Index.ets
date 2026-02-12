/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { GalleryListTab } from '../ui/tabs/GalleryListTab.ets';
import { FavoritesTab } from '../ui/tabs/FavoritesTab.ets';
import { HistoryTab } from '../ui/tabs/HistoryTab.ets';
import { DownloadsTab } from '../ui/tabs/DownloadsTab.ets';
import { SettingsTab } from '../ui/tabs/SettingsTab.ets';
import {
  TAB_ITEMS,
  TAB_GALLERY,
  TAB_FAVORITES,
  TAB_HISTORY,
  TAB_DOWNLOADS,
  TAB_SETTINGS,
} from '../router/TabConfig.ets';

/**
 * Main entry page with bottom tab navigation.
 *
 * Equivalent to Android MainActivity + NavigationView:
 *  - Gallery list (homepage / subscription / whats-hot will be sub-modes)
 *  - Favourites
 *  - History
 *  - Downloads
 *  - Settings
 */
@Entry
@Component
struct Index {
  @State currentTab: number = TAB_GALLERY;

  @Builder
  tabBuilder(index: number) {
    Column() {
      Text(index === this.currentTab ? TAB_ITEMS[index].iconSelected : TAB_ITEMS[index].icon)
        .fontSize(22)
        .fontColor(index === this.currentTab ? '#4169E1' : '#999999')

      Text(TAB_ITEMS[index].title)
        .fontSize(11)
        .fontColor(index === this.currentTab ? '#4169E1' : '#999999')
        .margin({ top: 2 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Column() {
      Tabs({ barPosition: BarPosition.End, index: this.currentTab }) {
        TabContent() {
          GalleryListTab()
        }
        .tabBar(this.tabBuilder(TAB_GALLERY))

        TabContent() {
          FavoritesTab()
        }
        .tabBar(this.tabBuilder(TAB_FAVORITES))

        TabContent() {
          HistoryTab()
        }
        .tabBar(this.tabBuilder(TAB_HISTORY))

        TabContent() {
          DownloadsTab()
        }
        .tabBar(this.tabBuilder(TAB_DOWNLOADS))

        TabContent() {
          SettingsTab()
        }
        .tabBar(this.tabBuilder(TAB_SETTINGS))
      }
      .barHeight(56)
      .barMode(BarMode.Fixed)
      .onChange((index: number) => {
        this.currentTab = index;
      })
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
