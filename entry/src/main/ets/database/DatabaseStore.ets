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

/** Key-value map for row data, analogous to Android ContentValues. */
export type ValuesBucket = Record<string, string | number | null>;

/** Read-only accessor for a single result row. */
export interface ResultRow {
  getLong(column: string): number;
  getDouble(column: string): number;
  getString(column: string): string | null;
  getBoolean(column: string): boolean;
}

/** Query configuration. */
export interface QueryOptions {
  columns?: string[];
  where?: string;
  whereArgs?: (string | number | null)[];
  orderBy?: string;
  limit?: number;
  offset?: number;
}

/**
 * Abstraction over a relational database store.
 *
 * Production: backed by @ohos.data.relationalStore.
 * Tests: backed by MemoryDatabaseStore.
 */
export interface DatabaseStore {
  /** Execute a DDL or DML statement (CREATE TABLE, ALTER TABLE, DROP TABLE). */
  executeSql(sql: string, args?: (string | number | null)[]): void;

  /** Insert a row. Returns the row ID of the new row, or -1 on error. */
  insert(table: string, values: ValuesBucket): number;

  /** Update rows matching the where clause. Returns the number of affected rows. */
  update(table: string, values: ValuesBucket, where: string, whereArgs: (string | number)[]): number;

  /** Delete rows. If where is omitted, deletes all rows. Returns affected count. */
  delete(table: string, where?: string, whereArgs?: (string | number)[]): number;

  /** Query rows from a table. */
  query(table: string, options?: QueryOptions): ResultRow[];

  /** Begin a transaction. */
  beginTransaction(): void;

  /** Commit the current transaction. */
  commit(): void;

  /** Roll back the current transaction. */
  rollback(): void;

  /** Close the database. */
  close(): void;
}
