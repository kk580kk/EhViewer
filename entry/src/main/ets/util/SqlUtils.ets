/*
 * Copyright 2016 Hippo Seven
 * Ported to HarmonyOS ArkTS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import type { DatabaseStore, ResultRow } from '../database/DatabaseStore.ets';

/**
 * SqlUtils — SQL utility methods for safe execution and value extraction.
 *
 * Port of Android com.hippo.util.SqlUtils.
 *
 * Platform differences:
 *   - Android uses SQLiteDatabase + Cursor.
 *   - HarmonyOS uses the DatabaseStore / ResultRow interfaces.
 *   - `getBoolean`, `getInt`, `getLong`, `getFloat`, `getString` accept
 *     a ResultRow (which provides column access by name) instead of a
 *     Cursor (which uses column index lookup). Behaviour is identical:
 *     returns the value or the default if the column is missing / throws.
 */
export class SqlUtils {
  private constructor() {}

  /**
   * Execute a SQL statement safely, ignoring any errors.
   */
  static exeSQLSafely(db: DatabaseStore, sql: string): void {
    try {
      db.executeSql(sql);
    } catch (_e) {
      // Ignore
    }
  }

  /**
   * Drop a table if it exists.
   */
  static dropTable(db: DatabaseStore, tableName: string): void {
    SqlUtils.exeSQLSafely(db, `DROP TABLE IF EXISTS ${tableName}`);
  }

  /**
   * Drop all user tables from the database.
   *
   * Queries sqlite_master to find all user tables (excluding internal
   * sqlite tables) and drops each one.
   */
  static dropAllTables(db: DatabaseStore): void {
    const rows = db.query('sqlite_master', {
      columns: ['name'],
      where: "type = 'table' AND name NOT LIKE 'sqlite_%' AND name != 'android_metadata'",
    });
    for (const row of rows) {
      const tableName = row.getString('name');
      if (tableName !== null) {
        SqlUtils.dropTable(db, tableName);
      }
    }
  }

  /**
   * Escape single quotes in a SQL string value by doubling them.
   * Equivalent to Android's DatabaseUtils.sqlEscapeString (inner logic).
   *
   * NOTE: This does NOT wrap the result in quotes. It only escapes
   * the content. Use with parameterised queries where possible.
   */
  static sqlEscapeString(value: string): string {
    let result = '';
    for (let i = 0; i < value.length; i++) {
      const c = value.charAt(i);
      if (c === "'") {
        result += "'";
      }
      result += c;
    }
    return result;
  }

  /**
   * Read a boolean value from a ResultRow.
   * Returns `defValue` if the column is missing or an error occurs.
   */
  static getBoolean(row: ResultRow, column: string, defValue: boolean): boolean {
    try {
      return row.getBoolean(column);
    } catch (_e) {
      return defValue;
    }
  }

  /**
   * Read an integer value from a ResultRow.
   * Returns `defValue` if the column is missing or an error occurs.
   */
  static getInt(row: ResultRow, column: string, defValue: number): number {
    try {
      return row.getLong(column);
    } catch (_e) {
      return defValue;
    }
  }

  /**
   * Read a long (number) value from a ResultRow.
   * Returns `defValue` if the column is missing or an error occurs.
   *
   * In ArkTS all numbers are IEEE-754 doubles. For integer columns
   * that fit within Number.MAX_SAFE_INTEGER this is lossless.
   */
  static getLong(row: ResultRow, column: string, defValue: number): number {
    try {
      return row.getLong(column);
    } catch (_e) {
      return defValue;
    }
  }

  /**
   * Read a float (double) value from a ResultRow.
   * Returns `defValue` if the column is missing or an error occurs.
   */
  static getFloat(row: ResultRow, column: string, defValue: number): number {
    try {
      return row.getDouble(column);
    } catch (_e) {
      return defValue;
    }
  }

  /**
   * Read a string value from a ResultRow.
   * Returns `defValue` if the column is missing, null, or an error occurs.
   */
  static getString(row: ResultRow, column: string, defValue: string): string {
    try {
      const v = row.getString(column);
      return v !== null ? v : defValue;
    } catch (_e) {
      return defValue;
    }
  }
}
