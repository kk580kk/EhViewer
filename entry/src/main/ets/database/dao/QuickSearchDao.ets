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
import { QuickSearch } from '../../model/QuickSearch.ets';

export class QuickSearchDao extends AbstractDao<QuickSearch> {
  static readonly TABLE = 'QUICK_SEARCH';

  constructor(store: DatabaseStore) { super(store); }

  get tableName(): string { return QuickSearchDao.TABLE; }
  get pkColumn(): string { return '_id'; }
  override get autoIncrement(): boolean { return true; }

  getKey(entity: QuickSearch): number | null { return entity.id; }

  override setKey(entity: QuickSearch, key: number): void {
    entity.id = key;
  }

  toValues(e: QuickSearch): ValuesBucket {
    return {
      _id: e.id,
      NAME: e.name || null,
      MODE: e.mode,
      CATEGORY: e.category,
      KEYWORD: e.keyword,
      ADVANCE_SEARCH: e.advanceSearch,
      MIN_RATING: e.minRating,
      PAGE_FROM: e.pageFrom,
      PAGE_TO: e.pageTo,
      TIME: e.time,
    };
  }

  fromRow(r: ResultRow): QuickSearch {
    const e = new QuickSearch();
    e.id = r.getLong('_id');
    e.name = r.getString('NAME') ?? '';
    e.mode = r.getLong('MODE');
    e.category = r.getLong('CATEGORY');
    e.keyword = r.getString('KEYWORD');
    e.advanceSearch = r.getLong('ADVANCE_SEARCH');
    e.minRating = r.getLong('MIN_RATING');
    e.pageFrom = r.getLong('PAGE_FROM');
    e.pageTo = r.getLong('PAGE_TO');
    e.time = r.getLong('TIME');
    return e;
  }

  static createTable(store: DatabaseStore): void {
    store.executeSql(
      `CREATE TABLE IF NOT EXISTS ${QuickSearchDao.TABLE} (` +
      '_id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
      'NAME TEXT, ' +
      'MODE INTEGER NOT NULL DEFAULT 0, ' +
      'CATEGORY INTEGER NOT NULL DEFAULT 0, ' +
      'KEYWORD TEXT, ' +
      'ADVANCE_SEARCH INTEGER NOT NULL DEFAULT 0, ' +
      'MIN_RATING INTEGER NOT NULL DEFAULT 0, ' +
      'PAGE_FROM INTEGER NOT NULL DEFAULT -1, ' +
      'PAGE_TO INTEGER NOT NULL DEFAULT -1, ' +
      'TIME INTEGER NOT NULL DEFAULT 0)'
    );
  }
}
