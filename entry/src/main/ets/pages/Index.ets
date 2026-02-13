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
import { GalleryListViewModel, ListState, ListMode } from '../viewmodel/GalleryListViewModel.ets';
import { FavoritesViewModel } from '../viewmodel/FavoritesViewModel.ets';
import { HistoryViewModel } from '../viewmodel/HistoryViewModel.ets';
import { DownloadsViewModel } from '../viewmodel/DownloadsViewModel.ets';
import { MemoryEhDB } from '../database/MemoryEhDB.ets';
import { DataMappers } from '../viewmodel/DataMappers.ets';
import { PageRouter } from '../router/PageRouter.ets';
import { StubGalleryListFetcher } from '../client/StubGalleryListFetcher.ets';
import router from '@ohos.router';

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
  private galleryListVM = new GalleryListViewModel(new StubGalleryListFetcher());
  private favVM = new FavoritesViewModel(this.db);
  private historyVM = new HistoryViewModel(this.db);
  private downloadsVM = new DownloadsViewModel(this.db);

  // Gallery list UI state
  @State galleryItems: GalleryItemData[] = [];
  @State galleryListState: number = ListState.IDLE;
  @State galleryHasMore: boolean = false;
  @State galleryError: string = '';
  @State galleryModeTitle: string = 'Homepage';

  // Favorites UI data
  @State favItems: GalleryItemData[] = [];
  @State favEmpty: boolean = true;

  // History UI data
  @State historyItems: HistoryItemData[] = [];
  @State historyEmpty: boolean = true;

  // Downloads UI data
  @State downloadItems: DownloadItemData[] = [];
  @State downloadEmpty: boolean = true;
  @State downloadLabelNames: string[] = ['All Downloads'];

  aboutToAppear(): void {
    // Inject real router navigator
    PageRouter.setNavigator({
      pushUrl(url: string, params?: Record<string, Object>): void {
        router.pushUrl({ url, params }).catch(() => {});
      },
      replaceUrl(url: string, params?: Record<string, Object>): void {
        router.replaceUrl({ url, params }).catch(() => {});
      },
      back(): void {
        router.back();
      },
    });

    this.loadGalleryList();
    this.loadFavorites();
    this.loadHistory();
    this.loadDownloads();
  }

  // ---- Gallery List ----

  private async loadGalleryList(): Promise<void> {
    await this.galleryListVM.load();
    this.syncGalleryListState();
  }

  private async refreshGalleryList(): Promise<void> {
    await this.galleryListVM.refresh();
    this.syncGalleryListState();
  }

  private async loadMoreGalleries(): Promise<void> {
    await this.galleryListVM.loadMore();
    this.syncGalleryListState();
  }

  private async searchGalleries(keyword: string): Promise<void> {
    await this.galleryListVM.search(keyword);
    this.syncGalleryListState();
  }

  private async clearGallerySearch(): Promise<void> {
    await this.galleryListVM.clearSearch();
    this.syncGalleryListState();
  }

  private async switchGalleryMode(mode: number): Promise<void> {
    let listMode: ListMode;
    switch (mode) {
      case 1: listMode = ListMode.SUBSCRIPTION; break;
      case 2: listMode = ListMode.WHATS_HOT; break;
      default: listMode = ListMode.HOMEPAGE; break;
    }
    this.galleryListVM.setListMode(listMode);
    await this.galleryListVM.load();
    this.syncGalleryListState();
  }

  private syncGalleryListState(): void {
    this.galleryItems = DataMappers.toGalleryItems(this.galleryListVM.items);
    this.galleryListState = this.galleryListVM.state;
    this.galleryHasMore = this.galleryListVM.hasMore;
    this.galleryError = this.galleryListVM.error;
    this.galleryModeTitle = this.galleryListVM.modeTitle;
  }

  // ---- Favorites ----

  private loadFavorites(): void {
    this.favVM.load();
    this.favItems = DataMappers.toGalleryItems(this.favVM.items);
    this.favEmpty = this.favVM.isEmpty;
  }

  // ---- History ----

  private loadHistory(): void {
    this.historyVM.load();
    this.historyItems = DataMappers.toHistoryItems(this.historyVM.items);
    this.historyEmpty = this.historyVM.isEmpty;
  }

  // ---- Downloads ----

  private loadDownloads(): void {
    this.downloadsVM.load();
    this.downloadItems = DataMappers.toDownloadItems(
      this.downloadsVM.items,
      (gid: number) => this.downloadsVM.getDownloadDir(gid),
    );
    this.downloadEmpty = this.downloadsVM.isEmpty;
    this.downloadLabelNames = this.downloadsVM.labelNames;
  }

  // ---- Navigation ----

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
          GalleryListTab({
            items: this.galleryItems,
            listState: this.galleryListState,
            hasMore: this.galleryHasMore,
            errorMessage: this.galleryError,
            modeTitle: this.galleryModeTitle,
            onItemClick: (gid: number, token: string) => {
              this.navigateToDetail(gid, token);
            },
            onRefresh: () => {
              this.refreshGalleryList();
            },
            onLoadMore: () => {
              this.loadMoreGalleries();
            },
            onSearch: (keyword: string) => {
              this.searchGalleries(keyword);
            },
            onClearSearch: () => {
              this.clearGallerySearch();
            },
            onModeChange: (mode: number) => {
              this.switchGalleryMode(mode);
            },
          })
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
              // Find the download item to check if it's finished
              const item = this.downloadItems.find(
                (d: DownloadItemData) => d.gid === gid,
              );
              if (item !== undefined && item.isFinished && item.downloadDir !== null) {
                // Open as local gallery
                PageRouter.toLocalGalleryReader('dir', item.downloadDir, 0, item.title);
              } else {
                this.navigateToDetail(gid, token);
              }
            },
            onRemove: (gid: number) => {
              this.downloadsVM.removeDownload(gid);
              this.downloadItems = DataMappers.toDownloadItems(
                this.downloadsVM.items,
                (g: number) => this.downloadsVM.getDownloadDir(g),
              );
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
              this.downloadItems = DataMappers.toDownloadItems(
                this.downloadsVM.items,
                (g: number) => this.downloadsVM.getDownloadDir(g),
              );
              this.downloadEmpty = this.downloadsVM.isEmpty;
            },
            onRefresh: () => {
              this.loadDownloads();
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
        if (index === TAB_GALLERY) {
          this.syncGalleryListState();
        } else if (index === TAB_FAVORITES) {
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
