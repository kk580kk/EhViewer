/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { DownloadInfo } from './DownloadInfo.ets';

/**
 * Immutable value object encapsulating download progress and status
 * for UI consumption (progress bars and status text).
 *
 * Created by {@link DownloadProgressEvent.from} from a {@link DownloadInfo}.
 */
export class DownloadProgressEvent {
  /** Gallery identifier. */
  readonly gid: number;
  /** Current download state (one of DownloadInfo.STATE_* constants). */
  readonly state: number;
  /** Number of pages finished. */
  readonly finished: number;
  /** Total number of pages. */
  readonly total: number;
  /** Progress percentage (0–100), or -1 if indeterminate. */
  readonly progressPercent: number;
  /** Download speed in bytes/s, or -1 if unavailable. */
  readonly speed: number;
  /** Estimated remaining time in ms, or -1 if unavailable. */
  readonly remaining: number;
  /** Human-readable status text suitable for display. */
  readonly statusText: string;
  /** Human-readable speed text (e.g. "1.2 MB/s"), or null when not downloading. */
  readonly speedText: string | null;

  constructor(
    gid: number, state: number, finished: number, total: number,
    progressPercent: number, speed: number, remaining: number,
    statusText: string, speedText: string | null,
  ) {
    this.gid = gid;
    this.state = state;
    this.finished = finished;
    this.total = total;
    this.progressPercent = progressPercent;
    this.speed = speed;
    this.remaining = remaining;
    this.statusText = statusText;
    this.speedText = speedText;
  }

  /** True if the progress bar can show a determinate value. */
  isDeterminate(): boolean {
    return this.progressPercent >= 0;
  }

  /** True if the download is actively running or queued. */
  isActive(): boolean {
    return this.state === DownloadInfo.STATE_WAIT ||
      this.state === DownloadInfo.STATE_DOWNLOAD;
  }

  /**
   * Factory: build a DownloadProgressEvent from a DownloadInfo instance.
   */
  static from(info: DownloadInfo): DownloadProgressEvent {
    return new DownloadProgressEvent(
      info.gid,
      info.state,
      info.finished,
      info.total,
      info.getProgressPercent(),
      info.speed,
      info.remaining,
      DownloadProgressEvent.formatStatusText(info),
      DownloadProgressEvent.formatSpeedText(info),
    );
  }

  // -- Internal formatters -------------------------------------------------

  private static formatStatusText(info: DownloadInfo): string {
    switch (info.state) {
      case DownloadInfo.STATE_NONE:
        return 'Not started';
      case DownloadInfo.STATE_WAIT:
        return 'Waiting';
      case DownloadInfo.STATE_DOWNLOAD:
        if (info.total <= 0 || info.finished < 0) {
          return 'Downloading...';
        }
        return `${info.finished}/${info.total}`;
      case DownloadInfo.STATE_FINISH:
        return 'Completed';
      case DownloadInfo.STATE_FAILED:
        return info.legacy > 0 ? `Failed (${info.legacy})` : 'Failed';
      default:
        return 'Unknown';
    }
  }

  private static formatSpeedText(info: DownloadInfo): string | null {
    if (info.state !== DownloadInfo.STATE_DOWNLOAD) {
      return null;
    }
    const speed = Math.max(info.speed, 0);
    const speedStr = DownloadProgressEvent.humanReadableByteCount(speed) + '/s';
    if (info.remaining >= 0) {
      return `${speedStr}, ${DownloadProgressEvent.shortTimeInterval(info.remaining)} left`;
    }
    return speedStr;
  }

  /** Format bytes as human-readable string (e.g. "1.2 KB", "3.4 MB"). */
  private static humanReadableByteCount(bytes: number): string {
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

  /** Format millis as short time interval (e.g. "3 min", "1 hr"). */
  private static shortTimeInterval(millis: number): string {
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
