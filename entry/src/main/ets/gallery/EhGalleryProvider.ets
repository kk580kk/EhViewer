/*
 * Copyright 2016 Hippo Seven
 * Ported to HarmonyOS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { GalleryProvider, STATE_ERROR } from './GalleryProvider.ets';
import { GalleryInfo } from '../model/GalleryInfo.ets';

// ---- Spider interface (dependency injection) ----

/**
 * Events from the spider to the gallery provider.
 * Mirrors Android's SpiderQueen.OnSpiderListener.
 */
export interface OnSpiderListener {
  onGetPages(pages: number): void;
  onGet509(index: number): void;
  onPageDownload(index: number, contentLength: number, receivedSize: number, bytesRead: number): void;
  onPageSuccess(index: number, finished: number, downloaded: number, total: number): void;
  onPageFailure(index: number, error: string, finished: number, downloaded: number, total: number): void;
  onFinish(finished: number, downloaded: number, total: number): void;
  onGetImageSuccess(index: number, data: Uint8Array): void;
  onGetImageFailure(index: number, error: string): void;
}

/**
 * Abstraction over SpiderQueen, so EhGalleryProvider can be tested
 * without the real spider implementation.
 */
export interface SpiderQueenLike {
  addOnSpiderListener(listener: OnSpiderListener): void;
  removeOnSpiderListener(listener: OnSpiderListener): void;
  size(): number;
  getError(): string | null;
  getStartPage(): number;
  putStartPage(page: number): void;
  /** Returns progress (number 0–1), error string, or null (waiting). */
  request(index: number): number | string | null;
  forceRequest(index: number): number | string | null;
  cancelRequest(index: number): void;
  save(index: number, destPath: string): boolean;
  saveToDir(index: number, dir: string, filename: string): string | null;
}

/**
 * Factory for obtaining / releasing SpiderQueen instances.
 */
export interface SpiderQueenFactory {
  obtain(galleryInfo: GalleryInfo, mode: number): SpiderQueenLike;
  release(spider: SpiderQueenLike, mode: number): void;
}

export const MODE_READ = 0;
export const MODE_DOWNLOAD = 1;

/**
 * Online gallery provider that delegates to a SpiderQueen for
 * fetching and caching gallery pages from E-Hentai/ExHentai.
 *
 * Mirrors the Android EhGalleryProvider.
 */
export class EhGalleryProvider extends GalleryProvider implements OnSpiderListener {

  private readonly galleryInfo: GalleryInfo;
  private readonly factory: SpiderQueenFactory;
  private spider: SpiderQueenLike | null = null;

  constructor(galleryInfo: GalleryInfo, factory: SpiderQueenFactory) {
    super();
    this.galleryInfo = galleryInfo;
    this.factory = factory;
  }

  override start(): void {
    super.start();
    this.spider = this.factory.obtain(this.galleryInfo, MODE_READ);
    this.spider.addOnSpiderListener(this);
  }

  override stop(): void {
    super.stop();
    if (this.spider !== null) {
      this.spider.removeOnSpiderListener(this);
      this.factory.release(this.spider, MODE_READ);
      this.spider = null;
    }
  }

  override size(): number {
    return this.spider !== null ? this.spider.size() : STATE_ERROR;
  }

  override getError(): string | null {
    return this.spider !== null ? this.spider.getError() : 'Not started';
  }

  override getStartPage(): number {
    return this.spider !== null ? this.spider.getStartPage() : 0;
  }

  override putStartPage(page: number): void {
    this.spider?.putStartPage(page);
  }

  override getImageFilename(index: number): string {
    const gid = this.galleryInfo.gid;
    const token = this.galleryInfo.token;
    return `${gid}-${token}-${(index + 1).toString().padStart(8, '0')}`;
  }

  override save(index: number, destPath: string): boolean {
    return this.spider !== null ? this.spider.save(index, destPath) : false;
  }

  override saveToDir(index: number, dir: string, filename: string): string | null {
    return this.spider !== null ? this.spider.saveToDir(index, dir, filename) : null;
  }

  // ---- Request handlers ----

  protected override onRequest(index: number): void {
    if (this.spider === null) return;
    const result = this.spider.request(index);
    if (typeof result === 'number') {
      this.notifyPagePercent(index, result);
    } else if (typeof result === 'string') {
      this.notifyPageFailed(index, result);
    } else {
      this.notifyPageWait(index);
    }
  }

  protected override onForceRequest(index: number): void {
    if (this.spider === null) return;
    const result = this.spider.forceRequest(index);
    if (typeof result === 'number') {
      this.notifyPagePercent(index, result);
    } else if (typeof result === 'string') {
      this.notifyPageFailed(index, result);
    } else {
      this.notifyPageWait(index);
    }
  }

  protected override onCancelRequest(index: number): void {
    this.spider?.cancelRequest(index);
  }

  // ---- OnSpiderListener ----

  onGetPages(_pages: number): void {
    this.notifyDataChanged();
  }

  onGet509(_index: number): void {
    // TODO: show 509 warning
  }

  onPageDownload(index: number, contentLength: number, receivedSize: number, _bytesRead: number): void {
    if (contentLength > 0) {
      this.notifyPagePercent(index, receivedSize / contentLength);
    }
  }

  onPageSuccess(index: number, _finished: number, _downloaded: number, _total: number): void {
    this.notifyPageDataChanged(index);
  }

  onPageFailure(index: number, error: string, _finished: number, _downloaded: number, _total: number): void {
    this.notifyPageFailed(index, error);
  }

  onFinish(_finished: number, _downloaded: number, _total: number): void {
    // no-op
  }

  onGetImageSuccess(index: number, data: Uint8Array): void {
    this.notifyPageSucceed(index, data);
  }

  onGetImageFailure(index: number, error: string): void {
    this.notifyPageFailed(index, error);
  }
}
