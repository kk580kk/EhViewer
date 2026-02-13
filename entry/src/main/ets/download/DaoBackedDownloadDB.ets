/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import type { DatabaseStore } from '../database/DatabaseStore.ets';
import type { DownloadDB } from './DownloadDB.ets';
import { DownloadInfo } from './DownloadInfo.ets';
import { DownloadLabel } from './DownloadLabel.ets';
import { DownloadsDao } from '../database/dao/DownloadsDao.ets';
import { DownloadLabelDao } from '../database/dao/DownloadLabelDao.ets';

/**
 * Production DownloadDB implementation backed by DownloadsDao and DownloadLabelDao.
 *
 * Bridges the DownloadDB interface to the DAO layer, persisting download tasks
 * (with their bound GalleryInfo data) and labels to a real DatabaseStore.
 */
export class DaoBackedDownloadDB implements DownloadDB {
  private readonly downloadsDao: DownloadsDao;
  private readonly labelDao: DownloadLabelDao;

  constructor(store: DatabaseStore) {
    this.downloadsDao = new DownloadsDao(store);
    this.labelDao = new DownloadLabelDao(store);
  }

  getAllDownloadInfo(): DownloadInfo[] {
    return this.downloadsDao.queryAll({ orderBy: 'TIME DESC' });
  }

  putDownloadInfo(info: DownloadInfo): void {
    const existing = this.downloadsDao.load(info.gid);
    if (existing !== null) {
      this.downloadsDao.update(info);
    } else {
      this.downloadsDao.insert(info);
    }
  }

  removeDownloadInfo(gid: number): void {
    this.downloadsDao.deleteByKey(gid);
  }

  getAllDownloadLabelList(): DownloadLabel[] {
    return this.labelDao.queryAll({ orderBy: 'TIME ASC' });
  }

  addDownloadLabel(label: string): DownloadLabel {
    const dl = new DownloadLabel(label);
    this.labelDao.insert(dl);
    return dl;
  }

  addDownloadLabelObject(label: DownloadLabel): DownloadLabel {
    const dl = new DownloadLabel(label.label);
    dl.time = label.time;
    this.labelDao.insert(dl);
    return dl;
  }

  updateDownloadLabel(label: DownloadLabel): void {
    this.labelDao.update(label);
  }

  moveDownloadLabel(fromPosition: number, toPosition: number): void {
    if (fromPosition === toPosition) return;

    const sorted = this.getAllDownloadLabelList();
    if (fromPosition < 0 || fromPosition >= sorted.length) return;
    if (toPosition < 0 || toPosition >= sorted.length) return;

    const reverse = fromPosition > toPosition;
    const offset = reverse ? toPosition : fromPosition;
    const limit = reverse ? fromPosition - toPosition + 1 : toPosition - fromPosition + 1;
    const slice = sorted.slice(offset, offset + limit);

    const step = reverse ? 1 : -1;
    const start = reverse ? limit - 1 : 0;
    const end = reverse ? 0 : limit - 1;
    const toTime = slice[end].time;
    for (let i = end; reverse ? i < start : i > start; i += step) {
      slice[i].time = slice[i + step].time;
    }
    slice[start].time = toTime;

    for (const item of slice) {
      this.labelDao.update(item);
    }
  }

  removeDownloadLabel(label: DownloadLabel): void {
    this.labelDao.delete(label);
  }
}
