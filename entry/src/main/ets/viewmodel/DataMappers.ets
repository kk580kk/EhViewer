/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { GalleryInfo } from '../model/GalleryInfo.ets';
import { HistoryInfo } from '../model/HistoryInfo.ets';
import { DownloadInfo } from '../download/DownloadInfo.ets';
import { GalleryItemData, HistoryItemData, DownloadItemData } from './GalleryItemData.ets';
import { EhUtils } from '../client/EhUtils.ets';
import { ReadableTime } from '../util/ReadableTime.ets';
import { DownloadsViewModel } from './DownloadsViewModel.ets';

/**
 * Pure functions that map domain models to UI display data classes.
 * Keeps ViewModel and UI layers decoupled.
 */
export class DataMappers {

  /** Map a GalleryInfo to a GalleryItemData for list display. */
  static toGalleryItem(gi: GalleryInfo): GalleryItemData {
    const item = new GalleryItemData();
    item.gid = gi.gid;
    item.token = gi.token;
    item.title = EhUtils.getSuitableTitle(gi);
    item.thumb = gi.thumb;
    item.uploader = gi.uploader;
    item.rating = gi.rating;
    item.category = gi.category;
    item.categoryText = EhUtils.getCategoryString(gi.category);
    item.categoryColor = EhUtils.getCategoryColor(gi.category);
    item.posted = gi.posted;
    item.simpleLanguage = gi.simpleLanguage ?? '';
    return item;
  }

  /** Map a HistoryInfo to a HistoryItemData for list display. */
  static toHistoryItem(hi: HistoryInfo): HistoryItemData {
    const item = new HistoryItemData();
    item.gid = hi.gid;
    item.token = hi.token;
    item.title = EhUtils.getSuitableTitle(hi);
    item.thumb = hi.thumb;
    item.uploader = hi.uploader;
    item.rating = hi.rating;
    item.category = hi.category;
    item.categoryText = EhUtils.getCategoryString(hi.category);
    item.categoryColor = EhUtils.getCategoryColor(hi.category);
    item.posted = hi.posted;
    item.simpleLanguage = hi.simpleLanguage ?? '';
    item.time = hi.time;
    item.timeText = hi.time > 0 ? ReadableTime.getPlainTime(hi.time) : '';
    return item;
  }

  /** Map a DownloadInfo to a DownloadItemData for list display. */
  static toDownloadItem(di: DownloadInfo): DownloadItemData {
    const item = new DownloadItemData();
    item.gid = di.gid;
    item.token = di.token;
    item.title = EhUtils.getSuitableTitle(di);
    item.thumb = di.thumb;
    item.uploader = di.uploader;
    item.rating = di.rating;
    item.category = di.category;
    item.categoryText = EhUtils.getCategoryString(di.category);
    item.categoryColor = EhUtils.getCategoryColor(di.category);
    item.posted = di.posted;
    item.simpleLanguage = di.simpleLanguage ?? '';
    item.stateValue = di.state;
    item.stateText = DownloadsViewModel.getStateText(di);
    item.progressPercent = DownloadsViewModel.getProgressPercent(di);
    item.progressText = DownloadsViewModel.getProgressText(di);
    item.speed = di.speed;
    item.label = di.label;
    item.canStart = DownloadsViewModel.canStart(di);
    item.canStop = DownloadsViewModel.canStop(di);
    return item;
  }

  /** Batch-map GalleryInfo array. */
  static toGalleryItems(list: GalleryInfo[]): GalleryItemData[] {
    return list.map((gi: GalleryInfo) => DataMappers.toGalleryItem(gi));
  }

  /** Batch-map HistoryInfo array. */
  static toHistoryItems(list: HistoryInfo[]): HistoryItemData[] {
    return list.map((hi: HistoryInfo) => DataMappers.toHistoryItem(hi));
  }

  /** Batch-map DownloadInfo array. */
  static toDownloadItems(list: DownloadInfo[]): DownloadItemData[] {
    return list.map((di: DownloadInfo) => DataMappers.toDownloadItem(di));
  }
}
