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

import type { DatabaseStore, ValuesBucket, ResultRow, QueryOptions } from './DatabaseStore.ets';

type RowData = Record<string, string | number | null>;

/**
 * In-memory implementation of DatabaseStore for testing.
 *
 * Supports basic CREATE TABLE, INSERT, UPDATE, DELETE, and query with
 * simple WHERE clauses (column = ? / AND logic).
 * Does not parse full SQL — only handles the subset needed by EhDB.
 */
export class MemoryDatabaseStore implements DatabaseStore {
  private tables: Map<string, RowData[]> = new Map();
  private nextRowId: Map<string, number> = new Map();
  /** Maps table name → AUTOINCREMENT PK column name. */
  private autoIncrementPK: Map<string, string> = new Map();
  private inTransaction = false;
  private closed = false;

  executeSql(sql: string, _args?: (string | number | null)[]): void {
    this.ensureOpen();
    const trimmed = sql.trim();

    // Handle CREATE TABLE
    const createMatch = trimmed.match(/^CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(\w+)/i);
    if (createMatch) {
      const table = createMatch[1];
      if (!this.tables.has(table)) {
        this.tables.set(table, []);
        this.nextRowId.set(table, 1);
      }
      // Detect AUTOINCREMENT PK so insert() can auto-assign the column
      const autoIncMatch = trimmed.match(/(\w+)\s+INTEGER\s+PRIMARY\s+KEY\s+AUTOINCREMENT/i);
      if (autoIncMatch) {
        this.autoIncrementPK.set(table, autoIncMatch[1]);
      }
      return;
    }

    // Handle DROP TABLE
    const dropMatch = trimmed.match(/^DROP\s+TABLE\s+(?:IF\s+EXISTS\s+)?(\w+)/i);
    if (dropMatch) {
      const table = dropMatch[1];
      this.tables.delete(table);
      this.nextRowId.delete(table);
      this.autoIncrementPK.delete(table);
      return;
    }

    // Handle ALTER TABLE (no-op for in-memory, columns are dynamic)
    if (/^ALTER\s+TABLE/i.test(trimmed)) {
      return;
    }
  }

  insert(table: string, values: ValuesBucket): number {
    this.ensureOpen();
    const rows = this.getTable(table);
    const id = this.nextRowId.get(table) ?? 1;
    this.nextRowId.set(table, id + 1);

    const row: RowData = { _rowid: id, ...values };
    // Simulate SQLite AUTOINCREMENT: if the PK column is absent from
    // the VALUES, auto-assign it to the generated rowid.
    const autoCol = this.autoIncrementPK.get(table);
    if (autoCol && !(autoCol in values)) {
      row[autoCol] = id;
    }
    rows.push(row);
    return id;
  }

  update(table: string, values: ValuesBucket, where: string, whereArgs: (string | number)[]): number {
    this.ensureOpen();
    const rows = this.getTable(table);
    const predicate = buildPredicate(where, whereArgs);
    let count = 0;

    for (const row of rows) {
      if (predicate(row)) {
        for (const key of Object.keys(values)) {
          row[key] = values[key];
        }
        count++;
      }
    }
    return count;
  }

  delete(table: string, where?: string, whereArgs?: (string | number)[]): number {
    this.ensureOpen();
    const rows = this.getTable(table);

    if (!where) {
      const count = rows.length;
      rows.length = 0;
      return count;
    }

    const predicate = buildPredicate(where, whereArgs ?? []);
    let count = 0;
    for (let i = rows.length - 1; i >= 0; i--) {
      if (predicate(rows[i])) {
        rows.splice(i, 1);
        count++;
      }
    }
    return count;
  }

  query(table: string, options?: QueryOptions): ResultRow[] {
    this.ensureOpen();
    const rows = this.getTable(table);
    let result = [...rows];

    // WHERE filter
    if (options?.where) {
      const predicate = buildPredicate(options.where, options.whereArgs ?? []);
      result = result.filter(predicate);
    }

    // ORDER BY
    if (options?.orderBy) {
      const { column, desc } = parseOrderBy(options.orderBy);
      result.sort((a, b) => {
        const va = a[column] ?? 0;
        const vb = b[column] ?? 0;
        let cmp: number;
        if (typeof va === 'number' && typeof vb === 'number') {
          cmp = va - vb;
        } else {
          cmp = String(va).localeCompare(String(vb));
        }
        return desc ? -cmp : cmp;
      });
    }

    // OFFSET
    if (options?.offset && options.offset > 0) {
      result = result.slice(options.offset);
    }

    // LIMIT
    if (options?.limit !== undefined && options.limit >= 0) {
      result = result.slice(0, options.limit);
    }

    // Column projection
    const columns = options?.columns;
    return result.map(row => toResultRow(row, columns));
  }

  beginTransaction(): void {
    this.ensureOpen();
    this.inTransaction = true;
  }

  commit(): void {
    this.ensureOpen();
    this.inTransaction = false;
  }

  rollback(): void {
    this.ensureOpen();
    this.inTransaction = false;
  }

  close(): void {
    this.closed = true;
  }

  // ---- Test helpers ----

  /** Check if a table exists. */
  hasTable(table: string): boolean {
    return this.tables.has(table);
  }

  /** Get the number of rows in a table. */
  rowCount(table: string): number {
    return this.getTable(table).length;
  }

  private getTable(table: string): RowData[] {
    const rows = this.tables.get(table);
    if (!rows) {
      throw new Error(`Table '${table}' does not exist`);
    }
    return rows;
  }

  private ensureOpen(): void {
    if (this.closed) {
      throw new Error('Database is closed');
    }
  }
}

// ---- Internal helpers ----

type Predicate = (row: RowData) => boolean;

/**
 * Parse a simple WHERE clause into a predicate function.
 * Supports: "col = ?" and "col1 = ? AND col2 = ?" patterns.
 */
function buildPredicate(where: string, args: (string | number | null)[]): Predicate {
  const conditions = where.split(/\s+AND\s+/i);
  const checks: { column: string; argIndex: number }[] = [];

  let argIdx = 0;
  for (const cond of conditions) {
    const m = cond.trim().match(/^(\w+)\s*=\s*\?$/);
    if (m) {
      checks.push({ column: m[1], argIndex: argIdx });
      argIdx++;
    } else {
      // Unsupported clause — always true
      argIdx++;
    }
  }

  return (row: RowData): boolean => {
    for (const check of checks) {
      const expected = args[check.argIndex];
      const actual = row[check.column];
      if (expected === null) {
        if (actual !== null) return false;
      } else if (actual === null) {
        return false;
      } else if (typeof expected === 'number') {
        if (Number(actual) !== expected) return false;
      } else {
        if (String(actual) !== String(expected)) return false;
      }
    }
    return true;
  };
}

function parseOrderBy(orderBy: string): { column: string; desc: boolean } {
  const parts = orderBy.trim().split(/\s+/);
  const column = parts[0];
  const desc = parts.length > 1 && parts[1].toUpperCase() === 'DESC';
  return { column, desc };
}

function toResultRow(row: RowData, columns?: string[]): ResultRow {
  return {
    getLong(column: string): number {
      const v = row[column];
      if (v === null || v === undefined) return 0;
      return typeof v === 'number' ? Math.floor(v) : parseInt(String(v), 10) || 0;
    },
    getDouble(column: string): number {
      const v = row[column];
      if (v === null || v === undefined) return 0;
      return typeof v === 'number' ? v : parseFloat(String(v)) || 0;
    },
    getString(column: string): string | null {
      const v = row[column];
      if (v === null || v === undefined) return null;
      return String(v);
    },
    getBoolean(column: string): boolean {
      const v = row[column];
      if (v === null || v === undefined) return false;
      if (typeof v === 'number') return v !== 0;
      return v === 'true' || v === '1';
    },
  };
}
