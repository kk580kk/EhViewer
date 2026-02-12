/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

/**
 * Data class for gallery item display in list.
 * Decoupled from GalleryInfo to work with ArkTS @Prop.
 */
export class GalleryItemData {
  gid: number = 0;
  token: string = '';
  title: string = '';
  thumb: string = '';
  uploader: string = '';
  rating: number = 0;
  category: number = 0;
  categoryText: string = '';
  categoryColor: string = '#000000';
  posted: string = '';
  simpleLanguage: string = '';
}

/**
 * Data class for history item display.
 * Extends GalleryItemData with time display.
 */
export class HistoryItemData extends GalleryItemData {
  time: number = 0;
  timeText: string = '';
}

/**
 * Data class for download item display.
 * Extends GalleryItemData with download-specific fields.
 */
export class DownloadItemData extends GalleryItemData {
  stateValue: number = 0;
  stateText: string = '';
  progressPercent: number = -1;
  progressText: string = '';
  speed: number = 0;
  label: string | null = null;
  canStart: boolean = true;
  canStop: boolean = false;
}
