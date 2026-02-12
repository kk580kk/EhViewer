/*
 * Copyright 2017 Hippo Seven
 * Ported to HarmonyOS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import type { Cookie } from './Cookie.ets';
import { cookieKey } from './Cookie.ets';
import type { CookiePersistence } from './CookieRepository.ets';
import type { DatabaseStore, ValuesBucket } from '../database/DatabaseStore.ets';

const TABLE_COOKIE = 'OK_HTTP_3_COOKIE';
const COLUMN_ROWID = '_rowid';
const COLUMN_NAME = 'NAME';
const COLUMN_VALUE = 'VALUE';
const COLUMN_EXPIRES_AT = 'EXPIRES_AT';
const COLUMN_DOMAIN = 'DOMAIN';
const COLUMN_PATH = 'PATH';
const COLUMN_SECURE = 'SECURE';
const COLUMN_HTTP_ONLY = 'HTTP_ONLY';
const COLUMN_PERSISTENT = 'PERSISTENT';
const COLUMN_HOST_ONLY = 'HOST_ONLY';

const CREATE_TABLE_SQL =
  `CREATE TABLE IF NOT EXISTS ${TABLE_COOKIE} (` +
  `${COLUMN_NAME} TEXT, ` +
  `${COLUMN_VALUE} TEXT, ` +
  `${COLUMN_EXPIRES_AT} INTEGER, ` +
  `${COLUMN_DOMAIN} TEXT, ` +
  `${COLUMN_PATH} TEXT, ` +
  `${COLUMN_SECURE} INTEGER, ` +
  `${COLUMN_HTTP_ONLY} INTEGER, ` +
  `${COLUMN_PERSISTENT} INTEGER, ` +
  `${COLUMN_HOST_ONLY} INTEGER)`;

/**
 * CookiePersistence backed by DatabaseStore.
 *
 * Mirrors Android CookieDatabase.java: stores persistent cookies in a
 * relational table keyed by an auto-increment id. A cookie-to-id map
 * is maintained in memory for efficient update/remove.
 */
export class CookieDatabase implements CookiePersistence {
  private db: DatabaseStore;
  /** Maps cookieKey(cookie) -> row id in the database. */
  private idMap: Map<string, number> = new Map();

  constructor(db: DatabaseStore) {
    this.db = db;
    this.db.executeSql(CREATE_TABLE_SQL);
  }

  loadAll(): Cookie[] {
    const now = Date.now();
    const cookies: Cookie[] = [];
    const idsToRemove: number[] = [];

    const rows = this.db.query(TABLE_COOKIE);
    for (const row of rows) {
      const id = row.getLong(COLUMN_ROWID);
      const name = row.getString(COLUMN_NAME);
      const value = row.getString(COLUMN_VALUE);
      const expiresAt = row.getLong(COLUMN_EXPIRES_AT);
      const domain = row.getString(COLUMN_DOMAIN);
      const path = row.getString(COLUMN_PATH);
      const secure = row.getBoolean(COLUMN_SECURE);
      const httpOnly = row.getBoolean(COLUMN_HTTP_ONLY);
      const persistent = row.getBoolean(COLUMN_PERSISTENT);
      const hostOnly = row.getBoolean(COLUMN_HOST_ONLY);

      // Skip invalid or non-persistent or expired cookies
      if (!name || !domain || !path || !persistent || expiresAt <= now) {
        idsToRemove.push(id);
        continue;
      }

      const cookie: Cookie = {
        name, value: value ?? '', expiresAt, domain, path,
        secure, httpOnly, persistent, hostOnly,
      };
      this.idMap.set(cookieKey(cookie), id);
      cookies.push(cookie);
    }

    // Clean up invalid/expired rows
    if (idsToRemove.length > 0) {
      this.db.beginTransaction();
      try {
        for (const id of idsToRemove) {
          this.db.delete(TABLE_COOKIE, `${COLUMN_ROWID} = ?`, [id]);
        }
        this.db.commit();
      } catch {
        this.db.rollback();
      }
    }

    return cookies;
  }

  add(cookie: Cookie): void {
    const values = toValues(cookie);
    const id = this.db.insert(TABLE_COOKIE, values);
    if (id !== -1) {
      this.idMap.set(cookieKey(cookie), id);
    }
  }

  update(from: Cookie, to: Cookie): void {
    const key = cookieKey(from);
    const id = this.idMap.get(key);
    if (id === undefined) return;

    const values = toValues(to);
    this.db.update(TABLE_COOKIE, values, `${COLUMN_ROWID} = ?`, [id]);

    // Update id map
    this.idMap.delete(key);
    this.idMap.set(cookieKey(to), id);
  }

  remove(cookie: Cookie): void {
    const key = cookieKey(cookie);
    const id = this.idMap.get(key);
    if (id === undefined) return;

    this.db.delete(TABLE_COOKIE, `${COLUMN_ROWID} = ?`, [id]);
    this.idMap.delete(key);
  }

  clear(): void {
    this.db.delete(TABLE_COOKIE);
    this.idMap.clear();
  }
}

function toValues(cookie: Cookie): ValuesBucket {
  return {
    [COLUMN_NAME]: cookie.name,
    [COLUMN_VALUE]: cookie.value,
    [COLUMN_EXPIRES_AT]: cookie.expiresAt,
    [COLUMN_DOMAIN]: cookie.domain,
    [COLUMN_PATH]: cookie.path,
    [COLUMN_SECURE]: cookie.secure ? 1 : 0,
    [COLUMN_HTTP_ONLY]: cookie.httpOnly ? 1 : 0,
    [COLUMN_PERSISTENT]: cookie.persistent ? 1 : 0,
    [COLUMN_HOST_ONLY]: cookie.hostOnly ? 1 : 0,
  };
}
