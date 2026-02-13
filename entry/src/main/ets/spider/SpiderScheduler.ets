/*
 * Copyright 2024 EhViewer Contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import type { DownloadManager } from '../download/DownloadManager.ets';
import type { DownloadInfo } from '../download/DownloadInfo.ets';
import type { ImageDownloader, ImageDownloadListener } from './ImageDownloader.ets';

/**
 * Bundle of spider components for a single active download task.
 */
export interface SpiderContext {
  downloader: ImageDownloader;
}

/**
 * Factory that creates spider components for a download task.
 *
 * Production: builds real SpiderQueen + SpiderDen + ImageDownloader.
 * Tests: returns lightweight stubs.
 */
export interface SpiderFactory {
  createSpider(info: DownloadInfo): SpiderContext;
}

/**
 * SpiderScheduler — bridges DownloadManager with the Spider download engine.
 *
 * Mirrors the Android DownloadManager's SpiderQueen integration:
 *  - When DownloadManager starts a task, creates spider components and begins downloading
 *  - Forwards ImageDownloader progress/finish events back to DownloadManager
 *  - Handles pause/resume/cancel lifecycle
 *
 * All spider lifecycle is managed through DownloadManager hooks
 * (onStartDownload, onPauseDownload, onResumeDownload, onCancelDownload).
 */
export class SpiderScheduler {
  private readonly dm: DownloadManager;
  private readonly factory: SpiderFactory;
  private readonly activeSpiders: Map<number, SpiderContext> = new Map();

  constructor(dm: DownloadManager, factory: SpiderFactory) {
    this.dm = dm;
    this.factory = factory;
    this.wireHooks();
  }

  /**
   * Number of active spider instances (for testing/monitoring).
   */
  getActiveCount(): number {
    return this.activeSpiders.size;
  }

  /**
   * Whether a spider is active for the given gid.
   */
  hasActive(gid: number): boolean {
    return this.activeSpiders.has(gid);
  }

  /**
   * Detach all hooks and cancel all active spiders.
   * Call when tearing down the scheduler (e.g. on app shutdown).
   */
  dispose(): void {
    // Cancel all active spiders
    for (const [_gid, ctx] of this.activeSpiders) {
      ctx.downloader.cancel();
    }
    this.activeSpiders.clear();

    // Detach hooks
    this.dm.onStartDownload = null;
    this.dm.onPauseDownload = null;
    this.dm.onResumeDownload = null;
    this.dm.onCancelDownload = null;
  }

  // ---- Internal ----

  private wireHooks(): void {
    this.dm.onStartDownload = (info) => this.handleStart(info);
    this.dm.onPauseDownload = (info) => this.handlePause(info);
    this.dm.onResumeDownload = (info) => this.handleResume(info);
    this.dm.onCancelDownload = (info) => this.handleCancel(info);
  }

  private handleStart(info: DownloadInfo): void {
    const gid = info.gid;

    // Guard: don't create duplicate spiders
    if (this.activeSpiders.has(gid)) {
      return;
    }

    const ctx = this.factory.createSpider(info);
    this.activeSpiders.set(gid, ctx);

    const listener: ImageDownloadListener = {
      onPageStart: (_index: number, _total: number): void => {
        // No-op: DownloadManager doesn't need per-page-start events
      },

      onPageSuccess: (_index: number, finished: number, downloaded: number, total: number): void => {
        this.dm.onDownloadProgress(finished, downloaded, total, -1, -1, gid);
      },

      onPageFailure: (_index: number, _error: string, finished: number, downloaded: number, total: number): void => {
        this.dm.onDownloadProgress(finished, downloaded, total, -1, -1, gid);
      },

      onFinish: (finished: number, downloaded: number, total: number): void => {
        this.activeSpiders.delete(gid);
        this.dm.onDownloadFinished(finished, downloaded, total, gid);
      },
    };

    ctx.downloader.addListener(listener);

    // Start the download asynchronously (fire-and-forget)
    ctx.downloader.downloadAll();
  }

  private handlePause(info: DownloadInfo): void {
    const ctx = this.activeSpiders.get(info.gid);
    if (ctx !== undefined) {
      ctx.downloader.pause();
    }
  }

  private handleResume(info: DownloadInfo): void {
    const ctx = this.activeSpiders.get(info.gid);
    if (ctx !== undefined) {
      ctx.downloader.resume();
    }
  }

  private handleCancel(info: DownloadInfo): void {
    const ctx = this.activeSpiders.get(info.gid);
    if (ctx !== undefined) {
      ctx.downloader.cancel();
      this.activeSpiders.delete(info.gid);
    }
  }
}
