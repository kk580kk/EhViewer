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
  ReadingMode,
} from '../viewmodel/GalleryReaderViewModel.ets';
import type { PageInfo } from '../viewmodel/GalleryReaderViewModel.ets';
import { GallerySource } from '../gallery/GallerySource.ets';
import { DirGalleryProvider } from '../gallery/DirGalleryProvider.ets';
import type { DirGalleryFsOps } from '../gallery/DirGalleryProvider.ets';
import { ArchiveGalleryProvider } from '../gallery/ArchiveGalleryProvider.ets';
import type { ArchiveReader, ArchiveFsOps } from '../gallery/ArchiveGalleryProvider.ets';
import { ArchiveOpener } from '../gallery/ArchiveOpener.ets';
import type { ArchiveFileOpener, ArchiveFileHandle, InflaterFactory, Inflater } from '../gallery/StreamingZipReader.ets';
import { EhGalleryProvider } from '../gallery/EhGalleryProvider.ets';
import type { SpiderQueenFactory, SpiderQueenLike } from '../gallery/EhGalleryProvider.ets';
import { GalleryInfo } from '../model/GalleryInfo.ets';
import type { GalleryProvider2 } from '../gallery/GalleryProvider2.ets';
import { SettingsService } from '../service/SettingsService.ets';

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

// ---- Production filesystem adapters ----

/**
 * Production filesystem adapter for DirGalleryProvider using @ohos.file.fs.
 */
class OhosDirFsOps implements DirGalleryFsOps {
  readdirSync(dirPath: string): string[] {
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

/**
 * Production filesystem adapter for ArchiveGalleryProvider.
 */
class OhosArchiveFsOps implements ArchiveFsOps {
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

/**
 * Production file opener for StreamingZipReader.
 */
class OhosArchiveFileOpener implements ArchiveFileOpener {
  async open(filePath: string): Promise<ArchiveFileHandle> {
    const fs = globalThis.__ohosFs;
    if (!fs) throw new Error('File system not available');
    const fd = fs.openSync(filePath, 0o0); // O_RDONLY
    const stat = fs.statSync(filePath);
    const fileSize = stat.size;
    return {
      size: fileSize,
      async read(offset: number, length: number): Promise<Uint8Array> {
        const buf = new ArrayBuffer(length);
        fs.readSync(fd.fd, buf, { offset: 0, length, position: offset });
        return new Uint8Array(buf);
      },
      close(): void {
        fs.closeSync(fd);
      },
    };
  }
}

/**
 * Production inflater factory using pako or @ohos.zlib.
 */
class OhosInflaterFactory implements InflaterFactory {
  create(): Inflater {
    // Attempt to use globalThis.__pakoInflate or similar
    const pako = globalThis.__pako;
    if (pako) {
      const inf = new pako.Inflate({ raw: true });
      return {
        inflate(data: Uint8Array): Uint8Array {
          inf.push(data, false);
          if (inf.result && inf.result.length > 0) {
            const out = new Uint8Array(inf.result);
            inf.result = null;
            return out;
          }
          return new Uint8Array(0);
        },
        finish(): Uint8Array {
          inf.push(new Uint8Array(0), true);
          return inf.result ? new Uint8Array(inf.result) : new Uint8Array(0);
        },
      };
    }
    throw new Error('No decompression library available');
  }
}

/**
 * Production SpiderQueenFactory — delegates to the global SpiderQueen singleton.
 */
class OhosSpiderQueenFactory implements SpiderQueenFactory {
  obtain(galleryInfo: GalleryInfo, mode: number): SpiderQueenLike {
    const sq = globalThis.__SpiderQueen;
    if (sq && sq.obtain) {
      return sq.obtain(galleryInfo, mode);
    }
    throw new Error('SpiderQueen not available');
  }

  release(spider: SpiderQueenLike, mode: number): void {
    const sq = globalThis.__SpiderQueen;
    if (sq && sq.release) {
      sq.release(spider, mode);
    }
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
  @State sliderValue: number = 0;
  @State stateVersion: number = 0; // Bumped on every change to trigger re-render
  @State readingMode: number = ReadingMode.LEFT_TO_RIGHT;
  @State showPageMenu: boolean = false;
  @State longPressPageIndex: number = -1;

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
      this.sliderValue = this.vm.progressRatio * 100;
      this.readingMode = this.vm.readingMode;
      this.stateVersion++;
    });

    const provider = this.buildProvider();
    if (provider !== null) {
      const gallerySource = this.resolveGallerySource();
      this.vm.start(provider, gallerySource, this.startPage);
      this.readingMode = this.vm.readingMode;
    }
  }

  aboutToDisappear(): void {
    this.vm.stop();
  }

  private buildProvider(): GalleryProvider2 | null {
    switch (this.source) {
      case 'dir':
        return new DirGalleryProvider(this.path, new OhosDirFsOps());
      case 'archive':
        return new ArchiveGalleryProvider(
          this.path,
          new ArchiveOpener(new OhosArchiveFileOpener(), new OhosInflaterFactory()),
          new OhosArchiveFsOps(),
        );
      case 'eh':
      default: {
        const gi = new GalleryInfo();
        gi.gid = this.gid;
        gi.token = this.token;
        return new EhGalleryProvider(gi, new OhosSpiderQueenFactory());
      }
    }
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
        // Reading direction: vertical uses Swiper vertical mode; RTL reverses slider
        Swiper() {
          ForEach(this.buildPageIndices(), (pageIndex: number) => {
            this.PageContent(pageIndex)
          }, (pageIndex: number) => `page_${pageIndex}`)
        }
        .index(this.currentPage)
        .loop(false)
        .indicator(false)
        .vertical(this.readingMode === ReadingMode.TOP_TO_BOTTOM)
        .onChange((index: number) => {
          this.vm.goToPage(index);
        })
        .width('100%')
        .height('100%')
      } else if (this.vm.provider !== null && this.totalPages === 0) {
        // Loading state
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color('#cccccc')
          Text('Loading...')
            .fontSize(16)
            .fontColor('#cccccc')
            .margin({ top: 16 })
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

      // Bottom overlay: slider + page number
      // RTL mode reverses the slider labels (end on left, start on right)
      if (this.toolbarVisible && this.totalPages > 0) {
        Column() {
          // Page slider for quick navigation
          Row() {
            Text(this.readingMode === ReadingMode.RIGHT_TO_LEFT
              ? `${this.totalPages}` : `${this.currentPage + 1}`)
              .fontSize(13)
              .fontColor('#ffffff')
              .width(40)
              .textAlign(TextAlign.Center)
            Slider({
              value: this.readingMode === ReadingMode.RIGHT_TO_LEFT
                ? 100 - this.sliderValue : this.sliderValue,
              min: 0,
              max: 100,
              step: this.totalPages > 1 ? 100 / (this.totalPages - 1) : 1,
            })
              .layoutWeight(1)
              .blockColor('#ffffff')
              .trackColor('#66ffffff')
              .selectedColor('#4169E1')
              .onChange((value: number) => {
                const ratio = this.readingMode === ReadingMode.RIGHT_TO_LEFT
                  ? (100 - value) / 100 : value / 100;
                this.vm.goToPageByRatio(ratio);
              })
            Text(this.readingMode === ReadingMode.RIGHT_TO_LEFT
              ? `${this.currentPage + 1}` : `${this.totalPages}`)
              .fontSize(13)
              .fontColor('#ffffff')
              .width(40)
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .padding({ left: 8, right: 8 })
          .alignItems(VerticalAlign.Center)

          Text(this.progressText)
            .fontSize(13)
            .fontColor('#cccccc')
            .textAlign(TextAlign.Center)
            .margin({ bottom: 4 })
        }
        .width('100%')
        .backgroundColor('#AA000000')
        .padding({ top: 4, bottom: 8 })
        .position({ x: 0, y: '100%' })
        .translate({ y: -96 })
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

      // Long-press page menu (refresh / save)
      if (this.showPageMenu && this.longPressPageIndex >= 0) {
        Column() {
          Column() {
            Text(`Page ${this.longPressPageIndex + 1}`)
              .fontSize(16)
              .fontColor('#ffffff')
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 16 })

            // Refresh
            Text('Refresh')
              .fontSize(15)
              .fontColor('#ffffff')
              .width('100%')
              .height(44)
              .textAlign(TextAlign.Center)
              .borderRadius(8)
              .backgroundColor('#334169E1')
              .margin({ bottom: 8 })
              .onClick(() => {
                this.vm.retryPage(this.longPressPageIndex);
                this.showPageMenu = false;
              })

            // Save
            Text('Save Image')
              .fontSize(15)
              .fontColor('#ffffff')
              .width('100%')
              .height(44)
              .textAlign(TextAlign.Center)
              .borderRadius(8)
              .backgroundColor('#334169E1')
              .margin({ bottom: 8 })
              .onClick(() => {
                this.onSaveImage(this.longPressPageIndex);
                this.showPageMenu = false;
              })

            // Cancel
            Text('Cancel')
              .fontSize(15)
              .fontColor('#999999')
              .width('100%')
              .height(44)
              .textAlign(TextAlign.Center)
              .borderRadius(8)
              .backgroundColor('#33ffffff')
              .onClick(() => { this.showPageMenu = false; })
          }
          .width('80%')
          .padding(20)
          .backgroundColor('#DD2a2a2a')
          .borderRadius(16)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#88000000')
        .onClick(() => { this.showPageMenu = false; })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#1a1a1a')
    .onClick(() => {
      if (!this.showPageMenu) {
        this.vm.toggleToolbar();
      }
    })
  }

  private onSaveImage(index: number): void {
    try {
      const fs = globalThis.__ohosFs;
      if (!fs) return;
      // Use a default save directory (external image dir or downloads)
      const ctx = globalThis.__appContext;
      const dir = ctx?.filesDir ?? '/data/storage/el2/base/files';
      const result = this.vm.saveImage(index, dir);
      // In production, show a toast with result
    } catch (_e) {
      // Ignore — production would show error toast
    }
  }

  @Builder
  PageContent(pageIndex: number) {
    // Use stateVersion to force re-evaluation when page states change
    Column() {
      if (this.stateVersion >= 0) {
        // Check page state from the ViewModel
        if (this.vm.getPageInfo(pageIndex).state === PageState.READY) {
          // Image is ready — display it
          if (this.vm.getPageImageData(pageIndex) !== null) {
            Image(this.vm.getPageImageData(pageIndex)!)
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Contain)
          } else {
            Text(`Page ${pageIndex + 1}`)
              .fontSize(14)
              .fontColor('#999999')
          }
        } else if (this.vm.getPageInfo(pageIndex).state === PageState.LOADING) {
          // Loading with progress
          Column() {
            LoadingProgress()
              .width(40)
              .height(40)
              .color('#cccccc')
            Text(`${Math.round(this.vm.getPageInfo(pageIndex).progress * 100)}%`)
              .fontSize(13)
              .fontColor('#999999')
              .margin({ top: 8 })
          }
        } else if (this.vm.getPageInfo(pageIndex).state === PageState.FAILED) {
          // Error state with retry
          Column() {
            Text('\u26A0')
              .fontSize(36)
              .fontColor('#F44336')
              .margin({ bottom: 8 })
            Text(this.vm.getPageInfo(pageIndex).error || 'Failed to load')
              .fontSize(13)
              .fontColor('#999999')
              .textAlign(TextAlign.Center)
              .margin({ bottom: 16 })
            Text('Retry')
              .fontSize(15)
              .fontColor('#4169E1')
              .padding({ left: 16, right: 16, top: 8, bottom: 8 })
              .borderRadius(20)
              .backgroundColor('#1A4169E1')
              .onClick(() => { this.vm.retryPage(pageIndex); })
          }
        } else {
          // Waiting state
          Column() {
            LoadingProgress()
              .width(40)
              .height(40)
              .color('#666666')
            Text(`Page ${pageIndex + 1}`)
              .fontSize(13)
              .fontColor('#666666')
              .margin({ top: 8 })
          }
        }
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#1a1a1a')
    .onAppear(() => {
      this.vm.requestPage(pageIndex);
    })
    .gesture(
      LongPressGesture({ repeat: false })
        .onAction(() => {
          this.longPressPageIndex = pageIndex;
          this.showPageMenu = true;
        })
    )
  }

  private buildPageIndices(): number[] {
    const indices: number[] = [];
    for (let i = 0; i < this.totalPages; i++) {
      indices.push(i);
    }
    return indices;
  }
}
