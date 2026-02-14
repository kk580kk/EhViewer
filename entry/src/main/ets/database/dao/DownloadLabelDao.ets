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
import { DownloadLabel } from '../../download/DownloadLabel.ets';

export class DownloadLabelDao extends AbstractDao<DownloadLabel> {
  static readonly TABLE = 'DOWNLOAD_LABELS';

  constructor(store: DatabaseStore) { super(store); }

  get tableName(): string { return DownloadLabelDao.TABLE; }
  get pkColumn(): string { return '_id'; }
  override get autoIncrement(): boolean { return true; }

  getKey(entity: DownloadLabel): number | null { return entity.id; }

  override setKey(entity: DownloadLabel, key: number): void {
    entity.id = key;
  }

  toValues(e: DownloadLabel): ValuesBucket {
    return {
      _id: e.id,
      LABEL: e.label || null,
      TIME: e.time,
    };
  }

  fromRow(r: ResultRow): DownloadLabel {
    const e = new DownloadLabel();
    e.id = r.getLong('_id');
    e.label = r.getString('LABEL') ?? '';
    e.time = r.getLong('TIME');
    return e;
  }

  static createTable(store: DatabaseStore): void {
    store.executeSql(
      `CREATE TABLE IF NOT EXISTS ${DownloadLabelDao.TABLE} (` +
      '_id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
      'LABEL TEXT, ' +
      'TIME INTEGER NOT NULL DEFAULT 0)'
    );
  }
}
