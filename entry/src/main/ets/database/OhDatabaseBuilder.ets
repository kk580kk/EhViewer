/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

/**
 * SQLite column type strings used in CREATE TABLE / ALTER TABLE statements.
 */
export type ColumnType = 'INTEGER' | 'REAL' | 'TEXT';

/** Default primary key column name. */
const COLUMN_ID = '_id';

/**
 * Version-aware schema builder for RelationalStore databases.
 *
 * Port of Android MSQLiteBuilder — collects DDL statements grouped by
 * version number. When the database is opened, the helper executes only
 * the statements needed to migrate from the old version to the new one.
 *
 * Usage:
 *   const builder = new OhDatabaseBuilder()
 *     .version(1)
 *       .createTable('DOWNLOADS')
 *       .insertColumn('DOWNLOADS', 'GID', 'INTEGER')
 *       .insertColumn('DOWNLOADS', 'TITLE', 'TEXT')
 *     .version(2)
 *       .insertColumn('DOWNLOADS', 'LABEL', 'TEXT');
 */
export class OhDatabaseBuilder {
  private currentVersion = 0;
  private currentStatements: string[] | null = null;
  private statementsMap: Map<number, string[]> = new Map();

  /**
   * Bump the schema version. All subsequent DDL calls are recorded
   * under this version until the next version() call.
   */
  version(version: number): OhDatabaseBuilder {
    if (version <= this.currentVersion) {
      throw new Error(
        `New version must be larger than current version. current: ${this.currentVersion}, new: ${version}`
      );
    }
    this.currentVersion = version;
    this.currentStatements = [];
    this.statementsMap.set(version, this.currentStatements);
    return this;
  }

  /**
   * Create a table with the default integer primary key (_id).
   */
  createTable(table: string): OhDatabaseBuilder {
    return this.createTableWithPK(table, COLUMN_ID, 'INTEGER');
  }

  /**
   * Create a table with a custom primary key column.
   */
  createTableWithPK(table: string, column: string, type: ColumnType): OhDatabaseBuilder {
    return this.statement(`CREATE TABLE ${table} (${column} ${type} PRIMARY KEY);`);
  }

  /**
   * Drop a table.
   */
  dropTable(table: string): OhDatabaseBuilder {
    return this.statement(`DROP TABLE IF EXISTS ${table};`);
  }

  /**
   * Add a column to an existing table.
   */
  insertColumn(table: string, column: string, type: ColumnType, defaultValue?: string | number): OhDatabaseBuilder {
    let sql = `ALTER TABLE ${table} ADD COLUMN ${column} ${type}`;
    if (defaultValue !== undefined) {
      sql += ` NOT NULL DEFAULT ${typeof defaultValue === 'string' ? `'${defaultValue}'` : defaultValue}`;
    }
    sql += ';';
    return this.statement(sql);
  }

  /**
   * Add an arbitrary DDL statement to the current version.
   */
  statement(sql: string): OhDatabaseBuilder {
    if (this.currentVersion === 0 || this.currentStatements === null) {
      throw new Error('Call version() first');
    }
    this.currentStatements.push(sql);
    return this;
  }

  /**
   * Return the latest version number recorded.
   */
  getVersion(): number {
    return this.currentVersion;
  }

  /**
   * Collect all DDL statements needed to migrate from oldVersion to newVersion.
   * Statements from version (oldVersion + 1) through newVersion are returned
   * in order.
   */
  getStatements(oldVersion: number, newVersion: number): string[] {
    const result: string[] = [];
    for (let v = oldVersion + 1; v <= newVersion; v++) {
      const list = this.statementsMap.get(v);
      if (list) {
        result.push(...list);
      }
    }
    return result;
  }
}
