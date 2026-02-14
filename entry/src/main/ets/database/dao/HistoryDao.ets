/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import type { DatabaseStore, ValuesBucket, ResultRow } from '../DatabaseStore.ets';
import { AbstractDao } from './AbstractDao.ets';
import { HistoryInfo } from '../../model/HistoryInfo.ets';

export class HistoryDao extends AbstractDao<HistoryInfo> {
  static readonly TABLE = 'HISTORY';

  constructor(store: DatabaseStore) { super(store); }

  get tableName(): string { return HistoryDao.TABLE; }
  get pkColumn(): string { return 'GID'; }

  getKey(entity: HistoryInfo): number | null { return entity.gid; }

  toValues(e: HistoryInfo): ValuesBucket {
    return {
      GID: e.gid,
      TOKEN: e.token || null,
      TITLE: e.title || null,
      TITLE_JPN: e.titleJpn || null,
      THUMB: e.thumb || null,
      CATEGORY: e.category,
      POSTED: e.posted || null,
      UPLOADER: e.uploader || null,
      RATING: e.rating,
      SIMPLE_LANGUAGE: e.simpleLanguage,
      MODE: e.mode,
      TIME: e.time,
    };
  }

  fromRow(r: ResultRow): HistoryInfo {
    const e = new HistoryInfo();
    e.gid = r.getLong('GID');
    e.token = r.getString('TOKEN') ?? '';
    e.title = r.getString('TITLE') ?? '';
    e.titleJpn = r.getString('TITLE_JPN') ?? '';
    e.thumb = r.getString('THUMB') ?? '';
    e.category = r.getLong('CATEGORY');
    e.posted = r.getString('POSTED') ?? '';
    e.uploader = r.getString('UPLOADER') ?? '';
    e.rating = r.getDouble('RATING');
    e.simpleLanguage = r.getString('SIMPLE_LANGUAGE');
    e.mode = r.getLong('MODE');
    e.time = r.getLong('TIME');
    return e;
  }

  static createTable(store: DatabaseStore): void {
    store.executeSql(
      `CREATE TABLE IF NOT EXISTS ${HistoryDao.TABLE} (` +
      'GID INTEGER PRIMARY KEY NOT NULL, ' +
      'TOKEN TEXT, TITLE TEXT, TITLE_JPN TEXT, THUMB TEXT, ' +
      'CATEGORY INTEGER NOT NULL DEFAULT 0, ' +
      'POSTED TEXT, UPLOADER TEXT, ' +
      'RATING REAL NOT NULL DEFAULT 0, ' +
      'SIMPLE_LANGUAGE TEXT, ' +
      'MODE INTEGER NOT NULL DEFAULT 0, ' +
      'TIME INTEGER NOT NULL DEFAULT 0)'
    );
  }
}
