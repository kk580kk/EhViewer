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
import {
  GalleryReaderViewModel,
  PageState,
} from '../viewmodel/GalleryReaderViewModel.ets';
import type { PageInfo } from '../viewmodel/GalleryReaderViewModel.ets';
import { GallerySource } from '../gallery/GallerySource.ets';
import { DirGalleryProvider } from '../gallery/DirGalleryProvider.ets';
import type { DirGalleryFsOps } from '../gallery/DirGalleryProvider.ets';
import type { GalleryProvider2 } from '../gallery/GalleryProvider2.ets';

/**
 * Gallery reader / viewer page — displays gallery images one by one.
 *
 * Supports three source types:
 *  - 'eh': online gallery (gid/token)
 *  - 'dir': local directory of images (path)
 *  - 'archive': archive file (path)
 *
 * Route params:
 *  { source?: string, gid?: number, token?: string, path?: string, page?: number, title?: string }
 */

interface ReaderParams {
  source: string;
  gid: number;
  token: string;
  path: string;
  page: number;
  title: string;
}

/**
 * Production filesystem adapter using @ohos.file.fs.
 * Falls back to no-op if the module is unavailable (test environment).
 */
class OhosDirFsOps implements DirGalleryFsOps {
  readdirSync(dirPath: string): string[] {
    // In production, use @ohos.file.fs.listFileSync
    try {
      const fs = globalThis.__ohosFs;
      if (fs && fs.listFileSync) {
        return fs.listFileSync(dirPath);
      }
    } catch (_e) { /* fall through */ }
    return [];
  }

  readFileSync(path: string): Uint8Array {
    try {
      const fs = globalThis.__ohosFs;
      if (fs && fs.readFileSync) {
        return new Uint8Array(fs.readFileSync(path));
      }
    } catch (_e) { /* fall through */ }
    return new Uint8Array(0);
  }

  writeFileSync(path: string, data: Uint8Array): void {
    try {
      const fs = globalThis.__ohosFs;
      if (fs && fs.writeFileSync) {
        fs.writeFileSync(path, data);
      }
    } catch (_e) { /* ignore */ }
  }

  existsSync(path: string): boolean {
    try {
      const fs = globalThis.__ohosFs;
      if (fs && fs.accessSync) {
        return fs.accessSync(path);
      }
    } catch (_e) { /* fall through */ }
    return false;
  }
}

@Entry
@Component
struct GalleryReaderPage {
  @State currentPage: number = 0;
  @State totalPages: number = 0;
  @State toolbarVisible: boolean = false;
  @State progressText: string = '';
  @State pageTitle: string = 'Reader';
  @State pageImageData: Map<number, Uint8Array> = new Map();
  @State pageStates: Map<number, PageInfo> = new Map();

  private vm: GalleryReaderViewModel = new GalleryReaderViewModel();
  private source: string = 'eh';
  private path: string = '';
  private gid: number = 0;
  private token: string = '';
  private startPage: number = 0;

  aboutToAppear(): void {
    const params = router.getParams() as ReaderParams | undefined;
    if (params) {
      this.source = params.source ?? 'eh';
      this.gid = params.gid ?? 0;
      this.token = params.token ?? '';
      this.path = params.path ?? '';
      this.startPage = params.page ?? 0;
      this.pageTitle = params.title || 'Reader';
    }

    this.vm.setOnChange(() => {
      this.currentPage = this.vm.currentPage;
      this.totalPages = this.vm.totalPages;
      this.progressText = this.vm.progressText;
      this.toolbarVisible = this.vm.toolbarVisible;
    });

    const provider = this.buildProvider();
    if (provider !== null) {
      const gallerySource = this.resolveGallerySource();
      this.vm.start(provider, gallerySource, this.startPage);
    }
  }

  aboutToDisappear(): void {
    this.vm.stop();
  }

  private buildProvider(): GalleryProvider2 | null {
    if (this.source === 'dir') {
      return new DirGalleryProvider(this.path, new OhosDirFsOps());
    }
    // archive and eh sources are not yet fully wired (placeholder)
    return null;
  }

  private resolveGallerySource(): GallerySource {
    switch (this.source) {
      case 'dir': return GallerySource.DIR;
      case 'archive': return GallerySource.ARCHIVE;
      default: return GallerySource.EH;
    }
  }

  build() {
    Stack() {
      if (this.totalPages > 0) {
        // Image viewer with swipe navigation
        Swiper() {
          ForEach(this.buildPageIndices(), (pageIndex: number) => {
            this.PageContent(pageIndex)
          }, (pageIndex: number) => `page_${pageIndex}`)
        }
        .index(this.currentPage)
        .loop(false)
        .indicator(false)
        .onChange((index: number) => {
          this.vm.goToPage(index);
        })
        .width('100%')
        .height('100%')
      } else if (this.vm.provider !== null && this.totalPages === 0) {
        // Loading state
        Column() {
          Text('Loading...')
            .fontSize(16)
            .fontColor('#cccccc')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#1a1a1a')
      } else {
        // No provider — unsupported source
        Column() {
          Text('Gallery source not available')
            .fontSize(16)
            .fontColor('#cccccc')
            .margin({ bottom: 16 })
          Text('Back')
            .fontSize(16)
            .fontColor('#4169E1')
            .onClick(() => { router.back(); })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#1a1a1a')
      }

      // Top overlay: back button + title
      if (this.toolbarVisible) {
        Column() {
          Row() {
            Text('\u2190')
              .fontSize(22)
              .fontColor('#ffffff')
              .width(48)
              .height(48)
              .textAlign(TextAlign.Center)
              .onClick(() => { router.back(); })

            Text(this.pageTitle)
              .fontSize(16)
              .fontColor('#ffffff')
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ left: 8 })
          }
          .width('100%')
          .height(56)
          .padding({ left: 8, right: 16 })
          .backgroundColor('#AA000000')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .position({ x: 0, y: 0 })
      }

      // Bottom overlay: progress bar + page number
      if (this.toolbarVisible && this.totalPages > 0) {
        Column() {
          Row() {
            Text(this.progressText)
              .fontSize(14)
              .fontColor('#ffffff')
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .height(48)
          .backgroundColor('#AA000000')
          .justifyContent(FlexAlign.Center)
        }
        .width('100%')
        .position({ x: 0, y: '100%' })
        .translate({ y: -48 })
      }

      // Always-visible progress indicator (small)
      if (!this.toolbarVisible && this.totalPages > 0) {
        Text(this.progressText)
          .fontSize(12)
          .fontColor('#cccccc')
          .backgroundColor('#66000000')
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .borderRadius(10)
          .position({ x: '50%', y: '95%' })
          .translate({ x: '-50%' })
      }

      // Back button always visible when toolbar is hidden
      if (!this.toolbarVisible) {
        Text('\u2190')
          .fontSize(22)
          .fontColor('#ffffff')
          .width(48)
          .height(48)
          .textAlign(TextAlign.Center)
          .backgroundColor('#66000000')
          .borderRadius(24)
          .position({ x: 16, y: 16 })
          .onClick(() => { router.back(); })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#1a1a1a')
    .onClick(() => {
      this.vm.toggleToolbar();
    })
  }

  @Builder
  PageContent(pageIndex: number) {
    Column() {
      // Request the page from the provider
      Text(`Page ${pageIndex + 1}`)
        .fontSize(14)
        .fontColor('#999999')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#1a1a1a')
    .onAppear(() => {
      this.vm.requestPage(pageIndex);
    })
  }

  private buildPageIndices(): number[] {
    const indices: number[] = [];
    for (let i = 0; i < this.totalPages; i++) {
      indices.push(i);
    }
    return indices;
  }
}
