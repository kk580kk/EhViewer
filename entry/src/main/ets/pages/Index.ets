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
import { GalleryItemData, HistoryItemData, DownloadItemData } from '../viewmodel/GalleryItemData.ets';
import {
  TAB_ITEMS,
  TAB_GALLERY,
  TAB_FAVORITES,
  TAB_HISTORY,
  TAB_DOWNLOADS,
  TAB_SETTINGS,
} from '../router/TabConfig.ets';
import { FavoritesViewModel } from '../viewmodel/FavoritesViewModel.ets';
import { HistoryViewModel } from '../viewmodel/HistoryViewModel.ets';
import { DownloadsViewModel } from '../viewmodel/DownloadsViewModel.ets';
import { MemoryEhDB } from '../database/MemoryEhDB.ets';
import { DataMappers } from '../viewmodel/DataMappers.ets';
import { PageRouter } from '../router/PageRouter.ets';

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

  // Shared database (will be replaced by production DB when available)
  private db = new MemoryEhDB();

  // ViewModels
  private favVM = new FavoritesViewModel(this.db);
  private historyVM = new HistoryViewModel(this.db);
  private downloadsVM = new DownloadsViewModel(this.db);

  // UI data arrays
  @State favItems: GalleryItemData[] = [];
  @State favEmpty: boolean = true;
  @State historyItems: HistoryItemData[] = [];
  @State historyEmpty: boolean = true;
  @State downloadItems: DownloadItemData[] = [];
  @State downloadEmpty: boolean = true;
  @State downloadLabelNames: string[] = ['All Downloads'];

  aboutToAppear(): void {
    this.loadFavorites();
    this.loadHistory();
    this.loadDownloads();
  }

  private loadFavorites(): void {
    this.favVM.load();
    this.favItems = DataMappers.toGalleryItems(this.favVM.items);
    this.favEmpty = this.favVM.isEmpty;
  }

  private loadHistory(): void {
    this.historyVM.load();
    this.historyItems = DataMappers.toHistoryItems(this.historyVM.items);
    this.historyEmpty = this.historyVM.isEmpty;
  }

  private loadDownloads(): void {
    this.downloadsVM.load();
    this.downloadItems = DataMappers.toDownloadItems(this.downloadsVM.items);
    this.downloadEmpty = this.downloadsVM.isEmpty;
    this.downloadLabelNames = this.downloadsVM.labelNames;
  }

  private navigateToDetail(gid: number, token: string): void {
    PageRouter.toGalleryDetail(gid, token);
  }

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
          FavoritesTab({
            items: this.favItems,
            isEmpty: this.favEmpty,
            onItemClick: (gid: number, token: string) => {
              this.navigateToDetail(gid, token);
            },
            onRemove: (gid: number) => {
              this.favVM.removeFavorite(gid);
              this.favItems = DataMappers.toGalleryItems(this.favVM.items);
              this.favEmpty = this.favVM.isEmpty;
            },
            onSearch: (keyword: string) => {
              this.favVM.search(keyword);
              this.favItems = DataMappers.toGalleryItems(this.favVM.items);
              this.favEmpty = this.favVM.isEmpty;
            },
            onClearSearch: () => {
              this.favVM.clearSearch();
              this.favItems = DataMappers.toGalleryItems(this.favVM.items);
              this.favEmpty = this.favVM.isEmpty;
            },
          })
        }
        .tabBar(this.tabBuilder(TAB_FAVORITES))

        TabContent() {
          HistoryTab({
            items: this.historyItems,
            isEmpty: this.historyEmpty,
            onItemClick: (gid: number, token: string) => {
              this.navigateToDetail(gid, token);
            },
            onDelete: (index: number) => {
              this.historyVM.deleteAt(index);
              this.historyItems = DataMappers.toHistoryItems(this.historyVM.items);
              this.historyEmpty = this.historyVM.isEmpty;
            },
            onClearAll: () => {
              this.historyVM.clearAll();
              this.historyItems = DataMappers.toHistoryItems(this.historyVM.items);
              this.historyEmpty = this.historyVM.isEmpty;
            },
          })
        }
        .tabBar(this.tabBuilder(TAB_HISTORY))

        TabContent() {
          DownloadsTab({
            items: this.downloadItems,
            isEmpty: this.downloadEmpty,
            labelNames: this.downloadLabelNames,
            onItemClick: (gid: number, token: string) => {
              this.navigateToDetail(gid, token);
            },
            onRemove: (gid: number) => {
              this.downloadsVM.removeDownload(gid);
              this.downloadItems = DataMappers.toDownloadItems(this.downloadsVM.items);
              this.downloadEmpty = this.downloadsVM.isEmpty;
            },
            onStart: (_gid: number) => {
              // TODO: integrate with actual DownloadManager when available
            },
            onStop: (_gid: number) => {
              // TODO: integrate with actual DownloadManager when available
            },
            onLabelChange: (label: string | null) => {
              this.downloadsVM.setLabel(label === 'All Downloads' ? null : label);
              this.downloadItems = DataMappers.toDownloadItems(this.downloadsVM.items);
              this.downloadEmpty = this.downloadsVM.isEmpty;
            },
          })
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
        // Reload data when switching to a tab
        if (index === TAB_FAVORITES) {
          this.loadFavorites();
        } else if (index === TAB_HISTORY) {
          this.loadHistory();
        } else if (index === TAB_DOWNLOADS) {
          this.loadDownloads();
        }
      })
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
