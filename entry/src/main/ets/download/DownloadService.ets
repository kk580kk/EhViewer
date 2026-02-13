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

import type { DownloadListener } from './DownloadManager.ets';
import type { DownloadManager } from './DownloadManager.ets';
import { DownloadInfo } from './DownloadInfo.ets';
import { GalleryInfo } from '../model/GalleryInfo.ets';

// ---------------------------------------------------------------------------
// Platform abstractions
// ---------------------------------------------------------------------------

/**
 * Handle for a platform background task (e.g. HarmonyOS long-running task).
 * Implementations request/cancel actual OS-level background execution.
 */
export interface BackgroundTaskHandle {
  /** Request background execution permission from the OS. */
  requestBackgroundRunning(): void;
  /** Cancel / release background execution permission. */
  cancelBackgroundRunning(): void;
}

/**
 * Adapter for platform notification display.
 * Abstracts HarmonyOS notification APIs so DownloadService logic is testable.
 */
export interface NotificationAdapter {
  /** Show or update the "downloading" notification. */
  showDownloading(title: string, text: string, progress: number, total: number): void;
  /** Show the "downloaded" summary notification. */
  showDownloaded(text: string, items: DownloadedItem[]): void;
  /** Show the 509 error notification. */
  show509Alert(): void;
  /** Cancel the "downloading" notification. */
  cancelDownloading(): void;
}

// ---------------------------------------------------------------------------
// Action constants (mirror Android DownloadService intent actions)
// ---------------------------------------------------------------------------

export const DownloadAction = {
  START: 'start',
  START_RANGE: 'start_range',
  START_ALL: 'start_all',
  STOP: 'stop',
  STOP_RANGE: 'stop_range',
  STOP_CURRENT: 'stop_current',
  STOP_ALL: 'stop_all',
  DELETE: 'delete',
  DELETE_RANGE: 'delete_range',
  CLEAR: 'clear',
} as const;

export type DownloadAction = (typeof DownloadAction)[keyof typeof DownloadAction];

// ---------------------------------------------------------------------------
// Supporting types
// ---------------------------------------------------------------------------

/** Info about a finished/failed download item for notification display. */
export interface DownloadedItem {
  gid: number;
  title: string;
  finished: boolean;
}

/** Statistics about completed downloads since last clear. */
export interface DownloadedStats {
  finishedCount: number;
  failedCount: number;
  downloadedCount: number;
  items: Map<number, DownloadedItem>;
}

// ---------------------------------------------------------------------------
// DownloadService
// ---------------------------------------------------------------------------

/**
 * DownloadService — background download execution manager for HarmonyOS.
 *
 * Equivalent to Android's DownloadService (foreground Service):
 *  - Receives action-based commands to start/stop/delete downloads
 *  - Listens to DownloadManager events for lifecycle notifications
 *  - Requests background execution when downloads are active
 *  - Provides notification data through NotificationAdapter
 *  - Auto-stops (releases background) when idle
 *
 * Platform dependencies (BackgroundTaskHandle, NotificationAdapter) are
 * injected, making the core logic fully testable without HarmonyOS APIs.
 */
export class DownloadService implements DownloadListener {
  private downloadManager: DownloadManager | null = null;
  private backgroundTask: BackgroundTaskHandle | null = null;
  private notification: NotificationAdapter | null = null;
  private running: boolean = false;

  // -- Downloaded item tracking (for summary notification) --
  private readonly itemStateMap: Map<number, boolean> = new Map();
  private readonly itemTitleMap: Map<number, string> = new Map();
  private finishedCount: number = 0;
  private failedCount: number = 0;
  private downloadedCount: number = 0;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /**
   * Start the service and bind to a DownloadManager.
   * Equivalent to Android Service.onCreate + startService.
   */
  start(
    downloadManager: DownloadManager,
    backgroundTask?: BackgroundTaskHandle,
    notification?: NotificationAdapter,
  ): void {
    if (this.running) return;

    this.downloadManager = downloadManager;
    this.backgroundTask = backgroundTask ?? null;
    this.notification = notification ?? null;
    this.running = true;

    this.downloadManager.setDownloadListener(this);
  }

  /**
   * Stop the service, detach from DownloadManager, release resources.
   * Equivalent to Android Service.onDestroy.
   */
  stop(): void {
    if (!this.running) return;

    if (this.downloadManager !== null) {
      this.downloadManager.setDownloadListener(null);
      this.downloadManager = null;
    }

    this.cancelBackgroundRunning();
    this.notification = null;
    this.backgroundTask = null;
    this.running = false;
  }

  /** Whether the service is currently running. */
  isRunning(): boolean {
    return this.running;
  }

  // ---------------------------------------------------------------------------
  // Action handling (replaces Android Intent dispatch)
  // ---------------------------------------------------------------------------

  /**
   * Handle a download action. Replaces Android's onStartCommand / handleIntent.
   */
  handleAction(action: DownloadAction, params?: ActionParams): void {
    if (this.downloadManager === null) return;

    switch (action) {
      case DownloadAction.START:
        if (params?.galleryInfo) {
          this.downloadManager.startDownload(params.galleryInfo, params.label ?? null);
        }
        break;
      case DownloadAction.START_RANGE:
        if (params?.gidList) {
          this.downloadManager.startRangeDownload(params.gidList);
        }
        break;
      case DownloadAction.START_ALL:
        this.downloadManager.startAllDownload();
        break;
      case DownloadAction.STOP:
        if (params?.gid !== undefined) {
          this.downloadManager.stopDownload(params.gid);
        }
        break;
      case DownloadAction.STOP_RANGE:
        if (params?.gidList) {
          this.downloadManager.stopRangeDownload(params.gidList);
        }
        break;
      case DownloadAction.STOP_CURRENT:
        this.downloadManager.stopCurrentDownload();
        break;
      case DownloadAction.STOP_ALL:
        this.downloadManager.stopAllDownload();
        break;
      case DownloadAction.DELETE:
        if (params?.gid !== undefined) {
          this.downloadManager.deleteDownload(params.gid);
        }
        break;
      case DownloadAction.DELETE_RANGE:
        if (params?.gidList) {
          this.downloadManager.deleteRangeDownload(params.gidList);
        }
        break;
      case DownloadAction.CLEAR:
        this.clearStats();
        break;
    }

    this.checkStopSelf();
  }

  // ---------------------------------------------------------------------------
  // DownloadListener implementation
  // ---------------------------------------------------------------------------

  onStart(info: DownloadInfo): void {
    this.requestBackgroundRunning();

    const title = this.getSuitableTitle(info);
    if (this.notification !== null) {
      this.notification.showDownloading(title, '', 0, 0);
    }
  }

  onFinish(info: DownloadInfo): void {
    if (this.notification !== null) {
      this.notification.cancelDownloading();
    }

    this.trackFinishedItem(info);
    this.showDownloadedNotification();
    this.checkStopSelf();
  }

  onCancel(info: DownloadInfo): void {
    if (this.notification !== null) {
      this.notification.cancelDownloading();
    }
    this.checkStopSelf();
  }

  // ---------------------------------------------------------------------------
  // 509 handling
  // ---------------------------------------------------------------------------

  /** Called when a 509 (bandwidth limit) error is received. */
  onGet509(): void {
    if (this.notification !== null) {
      this.notification.show509Alert();
    }
  }

  // ---------------------------------------------------------------------------
  // Progress update (called by DownloadManager on progress)
  // ---------------------------------------------------------------------------

  /**
   * Update the downloading notification with current progress.
   * Should be called periodically by the download engine.
   */
  onDownloadProgress(info: DownloadInfo): void {
    if (this.notification === null) return;

    const title = this.getSuitableTitle(info);
    const speed = Math.max(info.speed, 0);
    const speedText = this.humanReadableByteCount(speed) + '/s';
    let text: string;
    if (info.remaining >= 0) {
      text = `${speedText}, ${this.shortTimeInterval(info.remaining)} left`;
    } else {
      text = speedText;
    }

    this.notification.showDownloading(title, text, info.finished, info.total);
  }

  // ---------------------------------------------------------------------------
  // Stats / Clear
  // ---------------------------------------------------------------------------

  /** Get current download completion statistics. */
  getStats(): DownloadedStats {
    const items = new Map<number, DownloadedItem>();
    for (const [gid, finished] of this.itemStateMap) {
      items.set(gid, {
        gid,
        title: this.itemTitleMap.get(gid) ?? '',
        finished,
      });
    }
    return {
      finishedCount: this.finishedCount,
      failedCount: this.failedCount,
      downloadedCount: this.downloadedCount,
      items,
    };
  }

  /** Clear completed download statistics. */
  clearStats(): void {
    this.finishedCount = 0;
    this.failedCount = 0;
    this.downloadedCount = 0;
    this.itemStateMap.clear();
    this.itemTitleMap.clear();
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  private trackFinishedItem(info: DownloadInfo): void {
    const isFinish = info.state === DownloadInfo.STATE_FINISH;
    const gid = info.gid;
    const title = this.getSuitableTitle(info);

    if (!this.itemStateMap.has(gid)) {
      this.itemStateMap.set(gid, isFinish);
      this.itemTitleMap.set(gid, title);
      this.downloadedCount++;
      if (isFinish) {
        this.finishedCount++;
      } else {
        this.failedCount++;
      }
    } else {
      const wasFinish = this.itemStateMap.get(gid)!;
      this.itemStateMap.set(gid, isFinish);
      this.itemTitleMap.set(gid, title);
      if (wasFinish && !isFinish) {
        this.finishedCount--;
        this.failedCount++;
      } else if (!wasFinish && isFinish) {
        this.finishedCount++;
        this.failedCount--;
      }
    }
  }

  private showDownloadedNotification(): void {
    if (this.notification === null) return;

    const items: DownloadedItem[] = [];
    for (const [gid, finished] of this.itemStateMap) {
      items.push({
        gid,
        title: this.itemTitleMap.get(gid) ?? '',
        finished,
      });
    }

    let text: string;
    if (this.finishedCount > 0 && this.failedCount === 0) {
      if (this.finishedCount === 1 && items.length >= 1) {
        text = `${items[0].title} downloaded`;
      } else {
        text = `${this.finishedCount} downloaded`;
      }
    } else if (this.finishedCount === 0 && this.failedCount > 0) {
      if (this.failedCount === 1 && items.length >= 1) {
        text = `${items[0].title} failed`;
      } else {
        text = `${this.failedCount} failed`;
      }
    } else {
      text = `${this.finishedCount} downloaded, ${this.failedCount} failed`;
    }

    this.notification.showDownloaded(text, items);
  }

  private checkStopSelf(): void {
    if (this.downloadManager === null || this.downloadManager.isIdle()) {
      this.cancelBackgroundRunning();
    }
  }

  private requestBackgroundRunning(): void {
    if (this.backgroundTask !== null) {
      this.backgroundTask.requestBackgroundRunning();
    }
  }

  private cancelBackgroundRunning(): void {
    if (this.backgroundTask !== null) {
      this.backgroundTask.cancelBackgroundRunning();
    }
  }

  private getSuitableTitle(info: DownloadInfo): string {
    return info.titleJpn || info.title || `Gallery ${info.gid}`;
  }

  private humanReadableByteCount(bytes: number): string {
    if (bytes < 1024) return bytes + ' B';
    const units = ['KB', 'MB', 'GB', 'TB'];
    let value = bytes;
    let unitIndex = -1;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    return `${value.toFixed(1)} ${units[unitIndex]}`;
  }

  private shortTimeInterval(millis: number): string {
    const seconds = Math.floor(millis / 1000);
    if (seconds < 60) return `${seconds}s`;
    const minutes = Math.floor(seconds / 60);
    if (minutes < 60) return `${minutes}m`;
    const hours = Math.floor(minutes / 60);
    if (hours < 24) return `${hours}h`;
    const days = Math.floor(hours / 24);
    return `${days}d`;
  }
}

// ---------------------------------------------------------------------------
// Action parameters
// ---------------------------------------------------------------------------

/** Parameters for handleAction, replacing Android Intent extras. */
export interface ActionParams {
  galleryInfo?: GalleryInfo;
  label?: string;
  gid?: number;
  gidList?: number[];
}
