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
import { DownloadDirname } from '../../model/DownloadDirname.ets';

export class DownloadDirnameDao extends AbstractDao<DownloadDirname> {
  static readonly TABLE = 'DOWNLOAD_DIRNAME';

  constructor(store: DatabaseStore) { super(store); }

  get tableName(): string { return DownloadDirnameDao.TABLE; }
  get pkColumn(): string { return 'GID'; }

  getKey(entity: DownloadDirname): number | null { return entity.gid; }

  toValues(e: DownloadDirname): ValuesBucket {
    return {
      GID: e.gid,
      DIRNAME: e.dirname || null,
    };
  }

  fromRow(r: ResultRow): DownloadDirname {
    const e = new DownloadDirname();
    e.gid = r.getLong('GID');
    e.dirname = r.getString('DIRNAME') ?? '';
    return e;
  }

  static createTable(store: DatabaseStore): void {
    store.executeSql(
      `CREATE TABLE IF NOT EXISTS ${DownloadDirnameDao.TABLE} (` +
      'GID INTEGER PRIMARY KEY NOT NULL, ' +
      'DIRNAME TEXT)'
    );
  }
}
