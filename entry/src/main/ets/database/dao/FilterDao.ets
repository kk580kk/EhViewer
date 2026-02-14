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
import { Filter } from '../../model/Filter.ets';

export class FilterDao extends AbstractDao<Filter> {
  static readonly TABLE = 'FILTER';

  constructor(store: DatabaseStore) { super(store); }

  get tableName(): string { return FilterDao.TABLE; }
  get pkColumn(): string { return '_id'; }
  override get autoIncrement(): boolean { return true; }

  getKey(entity: Filter): number | null { return entity.id; }

  override setKey(entity: Filter, key: number): void {
    entity.id = key;
  }

  toValues(e: Filter): ValuesBucket {
    return {
      _id: e.id,
      MODE: e.mode,
      TEXT: e.text,
      ENABLE: e.enable ? 1 : 0,
    };
  }

  fromRow(r: ResultRow): Filter {
    const e = new Filter();
    e.id = r.getLong('_id');
    e.mode = r.getLong('MODE');
    e.text = r.getString('TEXT');
    e.enable = r.getBoolean('ENABLE');
    return e;
  }

  static createTable(store: DatabaseStore): void {
    store.executeSql(
      `CREATE TABLE IF NOT EXISTS ${FilterDao.TABLE} (` +
      '_id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
      'MODE INTEGER NOT NULL DEFAULT 0, ' +
      'TEXT TEXT, ' +
      'ENABLE INTEGER DEFAULT 1)'
    );
  }
}
