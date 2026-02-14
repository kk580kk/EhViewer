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

import { DownloadInfo } from './DownloadInfo.ets';
import { DownloadLabel } from './DownloadLabel.ets';

/**
 * Persistence interface for download data.
 *
 * Abstracts all DB operations that DownloadManager needs.
 * Production implementation will use DatabaseStore / RelationalStore;
 * tests can use MemoryDownloadDB.
 */
export interface DownloadDB {
  /** Return all download info, ordered by time descending. */
  getAllDownloadInfo(): DownloadInfo[];

  /** Insert or update a download info record. */
  putDownloadInfo(info: DownloadInfo): void;

  /** Remove a download info record by gid. */
  removeDownloadInfo(gid: number): void;

  /** Return all download labels, ordered by time ascending. */
  getAllDownloadLabelList(): DownloadLabel[];

  /** Add a new download label. Returns the label with id set. */
  addDownloadLabel(label: string): DownloadLabel;

  /** Add an existing DownloadLabel object (from import). Returns with id set. */
  addDownloadLabelObject(label: DownloadLabel): DownloadLabel;

  /** Update an existing download label (e.g. rename). */
  updateDownloadLabel(label: DownloadLabel): void;

  /** Swap label ordering between two positions. */
  moveDownloadLabel(fromPosition: number, toPosition: number): void;

  /** Remove a download label. */
  removeDownloadLabel(label: DownloadLabel): void;
}
