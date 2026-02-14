/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import type { DatabaseStore } from '../DatabaseStore.ets';
import { DownloadsDao } from './DownloadsDao.ets';
import { DownloadLabelDao } from './DownloadLabelDao.ets';
import { DownloadDirnameDao } from './DownloadDirnameDao.ets';
import { HistoryDao } from './HistoryDao.ets';
import { QuickSearchDao } from './QuickSearchDao.ets';
import { LocalFavoritesDao } from './LocalFavoritesDao.ets';
import { FilterDao } from './FilterDao.ets';

/** Current schema version, matching the Android greenDAO version. */
export const SCHEMA_VERSION = 4;

/** Create all tables needed by EhDB. */
export function createAllTables(store: DatabaseStore): void {
  DownloadsDao.createTable(store);
  DownloadLabelDao.createTable(store);
  DownloadDirnameDao.createTable(store);
  HistoryDao.createTable(store);
  QuickSearchDao.createTable(store);
  LocalFavoritesDao.createTable(store);
  FilterDao.createTable(store);
}
