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

import { GalleryInfo } from '../model/GalleryInfo.ets';
import { SettingsService } from '../service/SettingsService.ets';
import type { DownloadDB } from './DownloadDB.ets';
import { DownloadInfo } from './DownloadInfo.ets';
import { DownloadLabel } from './DownloadLabel.ets';
import type { DownloadProgressCallback } from './DownloadProgressCallback.ets';
import { DownloadProgressEvent } from './DownloadProgressEvent.ets';

/**
 * Listener for download list changes (UI updates).
 */
export interface DownloadInfoListener {
  onAdd(info: DownloadInfo, list: DownloadInfo[], position: number): void;
  onUpdate(info: DownloadInfo, list: DownloadInfo[]): void;
  onUpdateAll(): void;
  onReload(): void;
  onChange(): void;
  onRenameLabel(from: string, to: string): void;
  onRemove(info: DownloadInfo, list: DownloadInfo[], position: number): void;
  onUpdateLabels(): void;
}

/**
 * Listener for download lifecycle events.
 */
export interface DownloadListener {
  onStart(info: DownloadInfo): void;
  onPause(info: DownloadInfo): void;
  onResume(info: DownloadInfo): void;
  onFinish(info: DownloadInfo): void;
  onCancel(info: DownloadInfo): void;
}

/** Sort descending by time. */
function dateDescCompare(a: DownloadInfo, b: DownloadInfo): number {
  return a.time > b.time ? -1 : 1;
}

/**
 * Manages the download queue and task lifecycle.
 *
 * Maintains four logical lanes:
 *   - WAIT    – queued, waiting to start
 *   - DOWNLOAD – currently being downloaded (at most one)
 *   - FINISH  – completed successfully
 *   - FAILED  – completed with errors
 *
 * Mirrors the Android DownloadManager. Actual file I/O (SpiderQueen) is
 * replaced by a pluggable onStartDownload callback so the queue logic
 * can be tested independently.
 */
export class DownloadManager {
  private readonly db: DownloadDB;

  /** All download info, ordered by time descending. */
  private readonly allInfoList: DownloadInfo[] = [];
  /** Fast lookup by gid. */
  private readonly allInfoMap: Map<number, DownloadInfo> = new Map();

  /** Label string -> list of DownloadInfo with that label. */
  private readonly labelMap: Map<string, DownloadInfo[]> = new Map();
  /** All labels (without default). */
  private readonly labelList: DownloadLabel[] = [];
  /** Downloads with null label. */
  private readonly defaultInfoList: DownloadInfo[] = [];

  /** Items waiting to be downloaded, FIFO order. */
  private readonly waitList: DownloadInfo[] = [];

  /** Active download tasks (supports concurrent downloads). */
  private readonly currentTasks: DownloadInfo[] = [];

  private downloadListener: DownloadListener | null = null;
  private readonly downloadInfoListeners: DownloadInfoListener[] = [];
  private readonly progressCallbacks: DownloadProgressCallback[] = [];

  /**
   * Optional hook called when a new task transitions to STATE_DOWNLOAD.
   * Production code will wire this to SpiderQueen; tests leave it null.
   */
  onStartDownload: ((info: DownloadInfo) => void) | null = null;

  /**
   * Optional hook called when a task is paused.
   * Production code will wire this to ImageDownloader.pause().
   */
  onPauseDownload: ((info: DownloadInfo) => void) | null = null;

  /**
   * Optional hook called when a paused task is resumed.
   * Production code will wire this to ImageDownloader.resume().
   */
  onResumeDownload: ((info: DownloadInfo) => void) | null = null;

  /**
   * Optional hook called when an active task is cancelled/stopped.
   * Production code will wire this to ImageDownloader.cancel().
   */
  onCancelDownload: ((info: DownloadInfo) => void) | null = null;

  constructor(db: DownloadDB) {
    this.db = db;

    // Load labels
    const labels = db.getAllDownloadLabelList();
    this.labelList.push(...labels);
    for (const label of labels) {
      this.labelMap.set(label.label, []);
    }

    // Load all download info
    const allInfoList = db.getAllDownloadInfo();
    this.allInfoList.push(...allInfoList);

    for (const info of allInfoList) {
      this.allInfoMap.set(info.gid, info);

      const list = this.getInfoListForLabel(info.label);
      if (list !== null) {
        list.push(info);
      } else {
        // Label not in labelList – create it
        const newList: DownloadInfo[] = [info];
        this.labelMap.set(info.label!, newList);
        if (!this.containLabel(info.label)) {
          this.labelList.push(db.addDownloadLabel(info.label!));
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  private getInfoListForLabel(label: string | null): DownloadInfo[] | null {
    if (label === null) {
      return this.defaultInfoList;
    }
    return this.labelMap.get(label) ?? null;
  }

  // ---------------------------------------------------------------------------
  // Query API
  // ---------------------------------------------------------------------------

  containLabel(label: string | null): boolean {
    if (label === null) return false;
    return this.labelList.some(l => l.label === label);
  }

  containDownloadInfo(gid: number): boolean {
    return this.allInfoMap.has(gid);
  }

  getLabelList(): DownloadLabel[] {
    return this.labelList;
  }

  getDefaultDownloadInfoList(): DownloadInfo[] {
    return this.defaultInfoList;
  }

  getLabelDownloadInfoList(label: string): DownloadInfo[] | null {
    return this.labelMap.get(label) ?? null;
  }

  getAllDownloadInfoList(): DownloadInfo[] {
    return this.allInfoList;
  }

  getDownloadInfo(gid: number): DownloadInfo | null {
    return this.allInfoMap.get(gid) ?? null;
  }

  getDownloadState(gid: number): number {
    const info = this.allInfoMap.get(gid);
    return info !== undefined ? info.state : DownloadInfo.STATE_INVALID;
  }

  isIdle(): boolean {
    return this.currentTasks.length === 0 && this.waitList.length === 0;
  }

  /**
   * Check if there are downloads that were interrupted by app restart
   * (persisted in STATE_WAIT, STATE_DOWNLOAD, or STATE_PAUSED).
   */
  hasRestorable(): boolean {
    for (const info of this.allInfoList) {
      if (info.state === DownloadInfo.STATE_WAIT ||
          info.state === DownloadInfo.STATE_DOWNLOAD ||
          info.state === DownloadInfo.STATE_PAUSED) {
        return true;
      }
    }
    return false;
  }

  /**
   * Restore downloads that were interrupted by app restart.
   * Re-queues items persisted in STATE_WAIT, STATE_DOWNLOAD, or STATE_PAUSED.
   */
  restoreDownloads(): void {
    let updated = false;
    for (const info of this.allInfoList) {
      if (info.state === DownloadInfo.STATE_WAIT ||
          info.state === DownloadInfo.STATE_DOWNLOAD ||
          info.state === DownloadInfo.STATE_PAUSED) {
        updated = true;
        info.state = DownloadInfo.STATE_WAIT;
        this.waitList.push(info);
        this.db.putDownloadInfo(info);
      }
    }

    if (updated) {
      for (const l of this.downloadInfoListeners) {
        l.onUpdateAll();
      }
      this.ensureDownload();
    }
  }

  getCurrentTask(): DownloadInfo | null {
    return this.currentTasks.length > 0 ? this.currentTasks[0] : null;
  }

  getCurrentTasks(): DownloadInfo[] {
    return this.currentTasks;
  }

  getWaitList(): DownloadInfo[] {
    return this.waitList;
  }

  // ---------------------------------------------------------------------------
  // Listener management
  // ---------------------------------------------------------------------------

  addDownloadInfoListener(listener: DownloadInfoListener): void {
    this.downloadInfoListeners.push(listener);
  }

  removeDownloadInfoListener(listener: DownloadInfoListener): void {
    const idx = this.downloadInfoListeners.indexOf(listener);
    if (idx >= 0) {
      this.downloadInfoListeners.splice(idx, 1);
    }
  }

  setDownloadListener(listener: DownloadListener | null): void {
    this.downloadListener = listener;
  }

  addProgressCallback(callback: DownloadProgressCallback): void {
    this.progressCallbacks.push(callback);
  }

  removeProgressCallback(callback: DownloadProgressCallback): void {
    const idx = this.progressCallbacks.indexOf(callback);
    if (idx >= 0) {
      this.progressCallbacks.splice(idx, 1);
    }
  }

  private notifyProgressCallbacks(info: DownloadInfo, stateChanged: boolean): void {
    if (this.progressCallbacks.length === 0) return;
    const event = DownloadProgressEvent.from(info);
    for (const cb of this.progressCallbacks) {
      if (stateChanged) {
        cb.onDownloadStateChanged(event);
      }
      cb.onDownloadProgress(event);
    }
  }

  // ---------------------------------------------------------------------------
  // Queue management – ensure / start / stop
  // ---------------------------------------------------------------------------

  /**
   * Pick tasks from the wait list and transition them to STATE_DOWNLOAD.
   * Supports concurrent downloads up to the configured limit.
   */
  private ensureDownload(): void {
    const limit = SettingsService.getConcurrentDownloadLimit();

    while (this.currentTasks.length < limit && this.waitList.length > 0) {
      const info = this.waitList.shift()!;
      this.currentTasks.push(info);

      info.state = DownloadInfo.STATE_DOWNLOAD;
      info.speed = -1;
      info.remaining = -1;
      info.total = -1;
      info.finished = 0;
      info.downloaded = 0;
      info.legacy = -1;

      this.db.putDownloadInfo(info);

      if (this.downloadListener !== null) {
        this.downloadListener.onStart(info);
      }

      const list = this.getInfoListForLabel(info.label);
      if (list !== null) {
        for (const l of this.downloadInfoListeners) {
          l.onUpdate(info, list);
        }
      }

      this.notifyProgressCallbacks(info, true);

      if (this.onStartDownload !== null) {
        this.onStartDownload(info);
      }
    }
  }

  /**
   * Add a gallery to the queue and start downloading.
   * If the gallery is already tracked and not in WAIT state, re-queue it.
   */
  startDownload(galleryInfo: GalleryInfo, label: string | null = null): void {
    // Already an active task
    if (this.currentTasks.some(t => t.gid === galleryInfo.gid)) {
      return;
    }

    const existing = this.allInfoMap.get(galleryInfo.gid);
    if (existing !== undefined) {
      if (existing.state !== DownloadInfo.STATE_WAIT) {
        existing.state = DownloadInfo.STATE_WAIT;
        this.waitList.push(existing);
        this.db.putDownloadInfo(existing);

        const list = this.getInfoListForLabel(existing.label);
        if (list !== null) {
          for (const l of this.downloadInfoListeners) {
            l.onUpdate(existing, list);
          }
        }
        this.ensureDownload();
      }
      return;
    }

    // New download
    const info = new DownloadInfo(galleryInfo);
    info.label = label;
    info.state = DownloadInfo.STATE_WAIT;
    info.time = Date.now();

    const list = this.getInfoListForLabel(info.label);
    if (list === null) {
      return; // label doesn't exist
    }
    list.unshift(info);

    this.allInfoList.unshift(info);
    this.allInfoMap.set(galleryInfo.gid, info);
    this.waitList.push(info);

    this.db.putDownloadInfo(info);

    for (const l of this.downloadInfoListeners) {
      l.onAdd(info, list, list.length - 1);
    }

    this.ensureDownload();
  }

  /**
   * Start downloads for a batch of gids that are already in the list
   * (only NONE / FAILED / FINISH will be re-queued).
   */
  startRangeDownload(gidList: number[]): void {
    let updated = false;
    for (const gid of gidList) {
      const info = this.allInfoMap.get(gid);
      if (info === undefined) continue;
      if (info.state === DownloadInfo.STATE_NONE ||
          info.state === DownloadInfo.STATE_FAILED ||
          info.state === DownloadInfo.STATE_FINISH) {
        updated = true;
        info.state = DownloadInfo.STATE_WAIT;
        this.waitList.push(info);
        this.db.putDownloadInfo(info);
      }
    }
    if (updated) {
      for (const l of this.downloadInfoListeners) {
        l.onUpdateAll();
      }
      this.ensureDownload();
    }
  }

  /**
   * Retry a single failed or idle download by gid.
   * Returns true if the download was found and re-queued.
   */
  retryDownload(gid: number): boolean {
    const info = this.allInfoMap.get(gid);
    if (info === undefined) return false;

    // Already active
    if (this.currentTasks.some(t => t.gid === gid)) return false;
    if (info.state === DownloadInfo.STATE_WAIT) return false;

    // Only retry NONE, FAILED, or FINISH
    if (info.state !== DownloadInfo.STATE_NONE &&
        info.state !== DownloadInfo.STATE_FAILED &&
        info.state !== DownloadInfo.STATE_FINISH) {
      return false;
    }

    info.state = DownloadInfo.STATE_WAIT;
    this.waitList.push(info);
    this.db.putDownloadInfo(info);

    const list = this.getInfoListForLabel(info.label);
    if (list !== null) {
      for (const l of this.downloadInfoListeners) {
        l.onUpdate(info, list);
      }
    }
    this.ensureDownload();
    return true;
  }

  /** Re-queue all NONE / FAILED downloads. */
  startAllDownload(): void {
    let updated = false;
    for (const info of this.allInfoList) {
      if (info.state === DownloadInfo.STATE_NONE || info.state === DownloadInfo.STATE_FAILED) {
        updated = true;
        info.state = DownloadInfo.STATE_WAIT;
        this.waitList.push(info);
        this.db.putDownloadInfo(info);
      }
    }
    if (updated) {
      for (const l of this.downloadInfoListeners) {
        l.onUpdateAll();
      }
      this.ensureDownload();
    }
  }

  /** Stop a single download by gid (returns the stopped info, or null). */
  stopDownload(gid: number): void {
    const info = this.stopDownloadInternal(gid);
    if (info !== null) {
      const list = this.getInfoListForLabel(info.label);
      if (list !== null) {
        for (const l of this.downloadInfoListeners) {
          l.onUpdate(info, list);
        }
      }
      this.ensureDownload();
    }
  }

  stopCurrentDownload(): void {
    const info = this.stopCurrentDownloadInternal();
    if (info !== null) {
      const list = this.getInfoListForLabel(info.label);
      if (list !== null) {
        for (const l of this.downloadInfoListeners) {
          l.onUpdate(info, list);
        }
      }
      this.ensureDownload();
    }
  }

  stopRangeDownload(gidList: number[]): void {
    this.stopRangeDownloadInternal(gidList);
    for (const l of this.downloadInfoListeners) {
      l.onUpdateAll();
    }
    this.ensureDownload();
  }

  stopAllDownload(): void {
    for (const info of this.waitList) {
      info.state = DownloadInfo.STATE_NONE;
      this.db.putDownloadInfo(info);
    }
    this.waitList.length = 0;

    // Stop all active tasks (including paused)
    const activeCopy = [...this.currentTasks];
    for (const info of activeCopy) {
      this.stopActiveDownloadInternal(info.gid);
    }

    for (const l of this.downloadInfoListeners) {
      l.onUpdateAll();
    }
  }

  /**
   * Pause an active download. The task remains in currentTasks but its state
   * changes to STATE_PAUSED. The actual ImageDownloader is paused via the
   * onPauseDownload hook.
   */
  pauseDownload(gid: number): void {
    const info = this.currentTasks.find(t => t.gid === gid);
    if (info === undefined || info.state !== DownloadInfo.STATE_DOWNLOAD) return;

    info.state = DownloadInfo.STATE_PAUSED;
    this.db.putDownloadInfo(info);

    if (this.onPauseDownload !== null) {
      this.onPauseDownload(info);
    }

    if (this.downloadListener !== null) {
      this.downloadListener.onPause(info);
    }

    const list = this.getInfoListForLabel(info.label);
    if (list !== null) {
      for (const l of this.downloadInfoListeners) {
        l.onUpdate(info, list);
      }
    }

    this.notifyProgressCallbacks(info, true);
  }

  /**
   * Resume a paused download. The task transitions from STATE_PAUSED back
   * to STATE_DOWNLOAD.
   */
  resumeDownload(gid: number): void {
    const info = this.currentTasks.find(t => t.gid === gid);
    if (info === undefined || info.state !== DownloadInfo.STATE_PAUSED) return;

    info.state = DownloadInfo.STATE_DOWNLOAD;
    this.db.putDownloadInfo(info);

    if (this.onResumeDownload !== null) {
      this.onResumeDownload(info);
    }

    if (this.downloadListener !== null) {
      this.downloadListener.onResume(info);
    }

    const list = this.getInfoListForLabel(info.label);
    if (list !== null) {
      for (const l of this.downloadInfoListeners) {
        l.onUpdate(info, list);
      }
    }

    this.notifyProgressCallbacks(info, true);
  }

  private stopDownloadInternal(gid: number): DownloadInfo | null {
    const activeIdx = this.currentTasks.findIndex(t => t.gid === gid);
    if (activeIdx >= 0) {
      return this.stopActiveDownloadInternal(gid);
    }
    const idx = this.waitList.findIndex(info => info.gid === gid);
    if (idx >= 0) {
      const info = this.waitList[idx];
      this.waitList.splice(idx, 1);
      info.state = DownloadInfo.STATE_NONE;
      this.db.putDownloadInfo(info);
      return info;
    }
    return null;
  }

  private stopActiveDownloadInternal(gid: number): DownloadInfo | null {
    const idx = this.currentTasks.findIndex(t => t.gid === gid);
    if (idx < 0) return null;

    const info = this.currentTasks[idx];
    this.currentTasks.splice(idx, 1);

    if (this.onCancelDownload !== null) {
      this.onCancelDownload(info);
    }

    info.state = DownloadInfo.STATE_NONE;
    this.db.putDownloadInfo(info);
    if (this.downloadListener !== null) {
      this.downloadListener.onCancel(info);
    }
    this.notifyProgressCallbacks(info, true);
    return info;
  }

  private stopCurrentDownloadInternal(): DownloadInfo | null {
    if (this.currentTasks.length === 0) return null;
    return this.stopActiveDownloadInternal(this.currentTasks[0].gid);
  }

  private stopRangeDownloadInternal(gidList: number[]): void {
    const gidSet = new Set(gidList);
    // Stop active tasks
    for (let i = this.currentTasks.length - 1; i >= 0; i--) {
      if (gidSet.has(this.currentTasks[i].gid)) {
        this.stopActiveDownloadInternal(this.currentTasks[i].gid);
      }
    }
    // Stop waiting tasks
    for (let i = this.waitList.length - 1; i >= 0; i--) {
      const info = this.waitList[i];
      if (gidSet.has(info.gid)) {
        this.waitList.splice(i, 1);
        info.state = DownloadInfo.STATE_NONE;
        this.db.putDownloadInfo(info);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Delete
  // ---------------------------------------------------------------------------

  deleteDownload(gid: number): void {
    this.stopDownloadInternal(gid);
    const info = this.allInfoMap.get(gid);
    if (info === undefined) return;

    this.db.removeDownloadInfo(info.gid);
    const allIdx = this.allInfoList.indexOf(info);
    if (allIdx >= 0) {
      this.allInfoList.splice(allIdx, 1);
    }
    this.allInfoMap.delete(info.gid);

    const list = this.getInfoListForLabel(info.label);
    if (list !== null) {
      const index = list.indexOf(info);
      if (index >= 0) {
        list.splice(index, 1);
        for (const l of this.downloadInfoListeners) {
          l.onRemove(info, list, index);
        }
      }
    }

    this.ensureDownload();
  }

  deleteRangeDownload(gidList: number[]): void {
    this.stopRangeDownloadInternal(gidList);
    for (const gid of gidList) {
      const info = this.allInfoMap.get(gid);
      if (info === undefined) continue;

      this.db.removeDownloadInfo(info.gid);
      const allIdx = this.allInfoList.indexOf(info);
      if (allIdx >= 0) {
        this.allInfoList.splice(allIdx, 1);
      }
      this.allInfoMap.delete(info.gid);

      const list = this.getInfoListForLabel(info.label);
      if (list !== null) {
        const idx = list.indexOf(info);
        if (idx >= 0) {
          list.splice(idx, 1);
        }
      }
    }

    for (const l of this.downloadInfoListeners) {
      l.onReload();
    }
    this.ensureDownload();
  }

  // ---------------------------------------------------------------------------
  // Add without starting
  // ---------------------------------------------------------------------------

  addDownload(galleryInfo: GalleryInfo, label: string | null = null): void {
    if (this.containDownloadInfo(galleryInfo.gid)) return;

    const info = new DownloadInfo(galleryInfo);
    info.label = label;
    info.state = DownloadInfo.STATE_NONE;
    info.time = Date.now();

    const list = this.getInfoListForLabel(info.label);
    if (list === null) return;
    list.unshift(info);

    this.allInfoList.unshift(info);
    this.allInfoMap.set(galleryInfo.gid, info);

    this.db.putDownloadInfo(info);

    for (const l of this.downloadInfoListeners) {
      l.onAdd(info, list, list.length - 1);
    }
  }

  addDownloadBatch(downloadInfoList: DownloadInfo[]): void {
    for (const info of downloadInfoList) {
      if (this.containDownloadInfo(info.gid)) continue;

      // Reset active states
      if (info.state === DownloadInfo.STATE_WAIT ||
          info.state === DownloadInfo.STATE_DOWNLOAD ||
          info.state === DownloadInfo.STATE_PAUSED) {
        info.state = DownloadInfo.STATE_NONE;
      }

      let list = this.getInfoListForLabel(info.label);
      if (list === null) {
        list = [];
        this.labelMap.set(info.label!, list);
        if (!this.containLabel(info.label)) {
          this.labelList.push(this.db.addDownloadLabel(info.label!));
        }
      }
      list.push(info);
      list.sort(dateDescCompare);

      this.allInfoList.push(info);
      this.allInfoMap.set(info.gid, info);
      this.db.putDownloadInfo(info);
    }

    this.allInfoList.sort(dateDescCompare);

    for (const l of this.downloadInfoListeners) {
      l.onReload();
    }
  }

  // ---------------------------------------------------------------------------
  // Finish callback – called by the download engine when a task completes.
  // ---------------------------------------------------------------------------

  /**
   * Signal that a download has finished.
   * When called without gid (legacy), finishes the first active task.
   * @param finished pages finished successfully
   * @param downloaded pages attempted
   * @param total total pages
   * @param gid optional gallery id to identify which task finished
   */
  onDownloadFinished(finished: number, downloaded: number, total: number, gid?: number): void {
    let info: DownloadInfo | null = null;
    if (gid !== undefined) {
      const idx = this.currentTasks.findIndex(t => t.gid === gid);
      if (idx >= 0) {
        info = this.currentTasks[idx];
        this.currentTasks.splice(idx, 1);
      }
    } else {
      // Legacy: finish first active task
      info = this.currentTasks.length > 0 ? this.currentTasks.shift()! : null;
    }

    if (info === null) return;

    info.finished = finished;
    info.downloaded = downloaded;
    info.total = total;
    info.legacy = total - finished;

    if (info.legacy === 0) {
      info.state = DownloadInfo.STATE_FINISH;
    } else {
      info.state = DownloadInfo.STATE_FAILED;
    }

    this.db.putDownloadInfo(info);

    if (this.downloadListener !== null) {
      this.downloadListener.onFinish(info);
    }

    const list = this.getInfoListForLabel(info.label);
    if (list !== null) {
      for (const l of this.downloadInfoListeners) {
        l.onUpdate(info, list);
      }
    }

    this.notifyProgressCallbacks(info, true);

    this.ensureDownload();
  }

  /**
   * Signal a progress update for a download (speed, page count, etc.).
   * Called periodically by the download engine.
   * @param gid optional gallery id; if omitted, updates first active task
   */
  onDownloadProgress(finished: number, downloaded: number, total: number, speed: number, remaining: number, gid?: number): void {
    let info: DownloadInfo | null = null;
    if (gid !== undefined) {
      info = this.currentTasks.find(t => t.gid === gid) ?? null;
    } else {
      info = this.currentTasks.length > 0 ? this.currentTasks[0] : null;
    }
    if (info === null) return;

    info.finished = finished;
    info.downloaded = downloaded;
    info.total = total;
    info.speed = speed;
    info.remaining = remaining;

    const list = this.getInfoListForLabel(info.label);
    if (list !== null) {
      for (const l of this.downloadInfoListeners) {
        l.onUpdate(info, list);
      }
    }

    this.notifyProgressCallbacks(info, false);
  }

  // ---------------------------------------------------------------------------
  // Label management
  // ---------------------------------------------------------------------------

  addLabel(label: string): void {
    if (this.containLabel(label)) return;

    this.labelList.push(this.db.addDownloadLabel(label));
    this.labelMap.set(label, []);

    for (const l of this.downloadInfoListeners) {
      l.onUpdateLabels();
    }
  }

  renameLabel(from: string, to: string): void {
    const labelObj = this.labelList.find(l => l.label === from);
    if (labelObj === undefined) return;

    labelObj.label = to;
    this.db.updateDownloadLabel(labelObj);

    const list = this.labelMap.get(from);
    if (list === undefined) return;
    this.labelMap.delete(from);

    for (const info of list) {
      info.label = to;
      this.db.putDownloadInfo(info);
    }
    this.labelMap.set(to, list);

    for (const l of this.downloadInfoListeners) {
      l.onRenameLabel(from, to);
    }
  }

  moveLabel(fromPosition: number, toPosition: number): void {
    if (fromPosition < 0 || fromPosition >= this.labelList.length) return;
    if (toPosition < 0 || toPosition >= this.labelList.length) return;

    const item = this.labelList.splice(fromPosition, 1)[0];
    this.labelList.splice(toPosition, 0, item);
    this.db.moveDownloadLabel(fromPosition, toPosition);

    for (const l of this.downloadInfoListeners) {
      l.onUpdateLabels();
    }
  }

  deleteLabel(label: string): void {
    const idx = this.labelList.findIndex(l => l.label === label);
    if (idx < 0) return;

    const labelObj = this.labelList[idx];
    this.labelList.splice(idx, 1);
    this.db.removeDownloadLabel(labelObj);

    const list = this.labelMap.get(label);
    this.labelMap.delete(label);

    if (list !== undefined) {
      for (const info of list) {
        info.label = null;
        this.db.putDownloadInfo(info);
        this.defaultInfoList.push(info);
      }
      this.defaultInfoList.sort(dateDescCompare);
    }

    for (const l of this.downloadInfoListeners) {
      l.onChange();
    }
  }

  changeLabel(infos: DownloadInfo[], label: string | null): void {
    if (label !== null && !this.containLabel(label)) return;

    const dstList = this.getInfoListForLabel(label);
    if (dstList === null) return;

    for (const info of infos) {
      if (info.label === label) continue;

      const srcList = this.getInfoListForLabel(info.label);
      if (srcList === null) continue;

      const srcIdx = srcList.indexOf(info);
      if (srcIdx >= 0) {
        srcList.splice(srcIdx, 1);
      }

      dstList.push(info);
      info.label = label;
      dstList.sort(dateDescCompare);
      this.db.putDownloadInfo(info);
    }

    for (const l of this.downloadInfoListeners) {
      l.onReload();
    }
  }

  addDownloadLabelBatch(downloadLabelList: DownloadLabel[]): void {
    for (const label of downloadLabelList) {
      if (!this.containLabel(label.label)) {
        this.labelMap.set(label.label, []);
        this.labelList.push(this.db.addDownloadLabelObject(label));
      }
    }
  }
}
