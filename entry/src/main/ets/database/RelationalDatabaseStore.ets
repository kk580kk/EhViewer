/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import type { DatabaseStore, ValuesBucket, ResultRow, QueryOptions } from './DatabaseStore.ets';

/**
 * Minimal proxy for @ohos.data.relationalStore.RdbStore.
 *
 * In production, the real RdbStore structurally satisfies this interface.
 * In tests, supply a mock implementation.
 */
export interface RdbStoreProxy {
  executeSql(sql: string, bindArgs?: Array<string | number | null>): void;
  querySql(sql: string, bindArgs?: Array<string | number | null>): RdbResultSetProxy;
  beginTransaction(): void;
  commit(): void;
  rollBack(): void;
}

/** Proxy for relationalStore ResultSet. */
export interface RdbResultSetProxy {
  readonly columnNames: string[];
  goToNextRow(): boolean;
  getLong(columnIndex: number): number;
  getDouble(columnIndex: number): number;
  getString(columnIndex: number): string;
  getColumnIndex(columnName: string): number;
  isColumnNull(columnIndex: number): boolean;
  close(): void;
}

/**
 * DatabaseStore implementation backed by @ohos.data.relationalStore.
 *
 * Translates the DatabaseStore interface into SQL executed via RdbStoreProxy.
 * Uses SQLite built-in functions (last_insert_rowid(), changes()) for
 * insert/update/delete return values.
 */
export class RelationalDatabaseStore implements DatabaseStore {
  private rdb: RdbStoreProxy;
  private closed = false;

  constructor(rdb: RdbStoreProxy) {
    this.rdb = rdb;
  }

  executeSql(sql: string, args?: (string | number | null)[]): void {
    this.ensureOpen();
    this.rdb.executeSql(sql, args);
  }

  insert(table: string, values: ValuesBucket): number {
    this.ensureOpen();
    const keys = Object.keys(values);
    if (keys.length === 0) {
      this.rdb.executeSql(`INSERT INTO ${table} DEFAULT VALUES`);
    } else {
      const cols = keys.join(', ');
      const placeholders = keys.map(() => '?').join(', ');
      const sql = `INSERT INTO ${table} (${cols}) VALUES (${placeholders})`;
      this.rdb.executeSql(sql, keys.map(k => values[k]));
    }
    return this.queryScalar('SELECT last_insert_rowid()', -1);
  }

  update(table: string, values: ValuesBucket, where: string, whereArgs: (string | number)[]): number {
    this.ensureOpen();
    const keys = Object.keys(values);
    const setClauses = keys.map(k => `${k} = ?`).join(', ');
    const sql = `UPDATE ${table} SET ${setClauses} WHERE ${where}`;
    const bindArgs: (string | number | null)[] = [...keys.map(k => values[k]), ...whereArgs];
    this.rdb.executeSql(sql, bindArgs);
    return this.queryScalar('SELECT changes()', 0);
  }

  delete(table: string, where?: string, whereArgs?: (string | number)[]): number {
    this.ensureOpen();
    if (where) {
      this.rdb.executeSql(`DELETE FROM ${table} WHERE ${where}`, whereArgs);
    } else {
      this.rdb.executeSql(`DELETE FROM ${table}`);
    }
    return this.queryScalar('SELECT changes()', 0);
  }

  query(table: string, options?: QueryOptions): ResultRow[] {
    this.ensureOpen();
    const cols = options?.columns?.join(', ') || '*';
    let sql = `SELECT ${cols} FROM ${table}`;
    const args: (string | number | null)[] = [];

    if (options?.where) {
      sql += ` WHERE ${options.where}`;
      if (options.whereArgs) {
        args.push(...options.whereArgs);
      }
    }

    if (options?.orderBy) {
      sql += ` ORDER BY ${options.orderBy}`;
    }

    const hasLimit = options?.limit !== undefined;
    const hasOffset = options?.offset !== undefined && options.offset > 0;
    if (hasLimit || hasOffset) {
      sql += ` LIMIT ${hasLimit ? options!.limit : -1}`;
      if (hasOffset) {
        sql += ` OFFSET ${options!.offset}`;
      }
    }

    const rs = this.rdb.querySql(sql, args);
    try {
      return resultSetToRows(rs);
    } finally {
      rs.close();
    }
  }

  beginTransaction(): void {
    this.ensureOpen();
    this.rdb.beginTransaction();
  }

  commit(): void {
    this.ensureOpen();
    this.rdb.commit();
  }

  rollback(): void {
    this.ensureOpen();
    this.rdb.rollBack();
  }

  close(): void {
    this.closed = true;
  }

  /** Execute a scalar query and return the first column of the first row as number. */
  private queryScalar(sql: string, fallback: number): number {
    const rs = this.rdb.querySql(sql);
    try {
      return rs.goToNextRow() ? rs.getLong(0) : fallback;
    } finally {
      rs.close();
    }
  }

  private ensureOpen(): void {
    if (this.closed) {
      throw new Error('Database is closed');
    }
  }
}

/**
 * Convert a ResultSet into an array of ResultRow snapshots.
 *
 * Each row is captured as a column-name -> value map so that the
 * ResultSet can be closed immediately after iteration.
 */
function resultSetToRows(rs: RdbResultSetProxy): ResultRow[] {
  const names = rs.columnNames;
  const rows: ResultRow[] = [];

  while (rs.goToNextRow()) {
    const data: Record<string, string | number | null> = {};
    for (let i = 0; i < names.length; i++) {
      if (rs.isColumnNull(i)) {
        data[names[i]] = null;
      } else {
        data[names[i]] = rs.getString(i);
      }
    }
    rows.push(toResultRow(data));
  }

  return rows;
}

function toResultRow(data: Record<string, string | number | null>): ResultRow {
  return {
    getLong(column: string): number {
      const v = data[column];
      if (v === null || v === undefined) return 0;
      return typeof v === 'number' ? Math.floor(v) : parseInt(String(v), 10) || 0;
    },
    getDouble(column: string): number {
      const v = data[column];
      if (v === null || v === undefined) return 0;
      return typeof v === 'number' ? v : parseFloat(String(v)) || 0;
    },
    getString(column: string): string | null {
      const v = data[column];
      if (v === null || v === undefined) return null;
      return String(v);
    },
    getBoolean(column: string): boolean {
      const v = data[column];
      if (v === null || v === undefined) return false;
      if (typeof v === 'number') return v !== 0;
      return v === 'true' || v === '1';
    },
  };
}

/**
 * Convenience wrapper to adapt a real @ohos.data.relationalStore.RdbStore
 * into an RdbStoreProxy.
 *
 * Usage in production:
 *   import relationalStore from '@ohos.data.relationalStore';
 *   const config: relationalStore.StoreConfig = { name: 'EhViewer.db', securityLevel: ... };
 *   const rdb = relationalStore.getRdbStoreSync(context, config);
 *   const store = new RelationalDatabaseStore(wrapRdbStore(rdb));
 */
export function wrapRdbStore(rdbStore: RdbStoreProxy): RdbStoreProxy {
  return rdbStore;
}
