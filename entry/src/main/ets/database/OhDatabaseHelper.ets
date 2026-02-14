/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import type { DatabaseStore } from './DatabaseStore.ets';
import type { OhDatabaseBuilder } from './OhDatabaseBuilder.ets';

/** Key used to store the schema version inside the database. */
const VERSION_TABLE = '__db_version';
const VERSION_COLUMN = 'version';

/**
 * Database lifecycle helper — manages creation and migration.
 *
 * Port of Android MSQLiteOpenHelper. On first open, executes all DDL
 * from version 0 → target. On subsequent opens, migrates from the
 * stored version to the target version.
 *
 * The schema version is persisted in a small internal table (__db_version).
 *
 * Usage:
 *   const helper = new OhDatabaseHelper(builder, targetVersion);
 *   helper.onCreate(store);   // fresh database
 *   helper.onUpgrade(store, oldVersion, newVersion); // migration
 */
export class OhDatabaseHelper {
  private builder: OhDatabaseBuilder;
  private targetVersion: number;

  constructor(builder: OhDatabaseBuilder, targetVersion: number) {
    this.builder = builder;
    this.targetVersion = targetVersion;
  }

  /**
   * Initialise a DatabaseStore: detect the current schema version,
   * then run onCreate or onUpgrade as needed.
   *
   * Call this once after obtaining the DatabaseStore instance.
   */
  initialize(store: DatabaseStore): void {
    this.ensureVersionTable(store);
    const currentVersion = this.readVersion(store);

    if (currentVersion === 0) {
      this.onCreate(store);
    } else if (currentVersion < this.targetVersion) {
      this.onUpgrade(store, currentVersion, this.targetVersion);
    } else if (currentVersion > this.targetVersion) {
      this.onDowngrade(store);
    }
    // currentVersion === targetVersion → nothing to do
  }

  /**
   * Called when the database is created for the first time.
   * Runs all statements from version 0 to targetVersion.
   */
  onCreate(store: DatabaseStore): void {
    this.onUpgrade(store, 0, this.targetVersion);
  }

  /**
   * Called when the database needs to be upgraded.
   * Runs the DDL statements for versions (oldVersion, newVersion].
   */
  onUpgrade(store: DatabaseStore, oldVersion: number, newVersion: number): void {
    const statements = this.builder.getStatements(oldVersion, newVersion);
    store.beginTransaction();
    try {
      for (const sql of statements) {
        store.executeSql(sql);
      }
      this.writeVersion(store, newVersion);
      store.commit();
    } catch (e) {
      store.rollback();
      throw e;
    }
  }

  /**
   * Called when the database version is higher than the target.
   * Drops all user tables and recreates from scratch.
   */
  onDowngrade(store: DatabaseStore): void {
    this.dropAllTables(store);
    this.onCreate(store);
  }

  /** Return the target schema version. */
  getTargetVersion(): number {
    return this.targetVersion;
  }

  // ---- Internal helpers ----

  private ensureVersionTable(store: DatabaseStore): void {
    store.executeSql(
      `CREATE TABLE IF NOT EXISTS ${VERSION_TABLE} (${VERSION_COLUMN} INTEGER NOT NULL DEFAULT 0)`
    );
  }

  private readVersion(store: DatabaseStore): number {
    const rows = store.query(VERSION_TABLE, { limit: 1 });
    if (rows.length === 0) {
      return 0;
    }
    return rows[0].getLong(VERSION_COLUMN);
  }

  private writeVersion(store: DatabaseStore, version: number): void {
    // Delete any existing version row, then insert the new one
    store.delete(VERSION_TABLE);
    store.insert(VERSION_TABLE, { [VERSION_COLUMN]: version });
  }

  private dropAllTables(store: DatabaseStore): void {
    // Drop the version table; builder statements will recreate user tables
    store.executeSql(`DROP TABLE IF EXISTS ${VERSION_TABLE}`);
    this.ensureVersionTable(store);
  }
}
