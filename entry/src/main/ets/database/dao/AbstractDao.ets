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

/**
 * Base DAO providing CRUD operations for a single entity → table mapping.
 *
 * Subclasses implement the abstract methods to define the entity-specific
 * column layout, serialization, and deserialization.
 *
 * Semantics mirror greenDAO's AbstractDao:
 *   - insert / update / delete / deleteByKey / deleteAll
 *   - load (by primary key)
 *   - queryAll with ordering, filtering, limit/offset
 *   - batch operations in a transaction
 */
export abstract class AbstractDao<T> {
  protected store: DatabaseStore;

  constructor(store: DatabaseStore) {
    this.store = store;
  }

  /** Table name for this entity. */
  abstract get tableName(): string;

  /** Primary key column name. */
  abstract get pkColumn(): string;

  /** Whether the primary key is auto-increment (uses _id INTEGER PK AUTOINCREMENT). */
  get autoIncrement(): boolean { return false; }

  /** Convert an entity to a ValuesBucket for insert/update. */
  abstract toValues(entity: T): ValuesBucket;

  /** Read an entity from a ResultRow. */
  abstract fromRow(row: ResultRow): T;

  /** Extract the primary key value from an entity. */
  abstract getKey(entity: T): number | null;

  /** Set the auto-generated key back on the entity after insert. */
  setKey(entity: T, key: number): void {
    // Override in auto-increment DAOs
  }

  // ---- CRUD ----

  /** Load an entity by primary key. Returns null if not found. */
  load(key: number): T | null {
    const rows = this.store.query(this.tableName, {
      where: `${this.pkColumn} = ?`,
      whereArgs: [key],
      limit: 1,
    });
    if (rows.length === 0) return null;
    return this.fromRow(rows[0]);
  }

  /**
   * Insert an entity. Returns the row ID.
   * For auto-increment DAOs, the generated key is set on the entity.
   */
  insert(entity: T): number {
    const values = this.toValues(entity);
    if (this.autoIncrement) {
      const key = this.getKey(entity);
      if (key === null || key === undefined) {
        delete values[this.pkColumn];
      }
    }
    const rowId = this.store.insert(this.tableName, values);
    if (this.autoIncrement && rowId > 0) {
      this.setKey(entity, rowId);
    }
    return rowId;
  }

  /** Update an entity by its primary key. */
  update(entity: T): void {
    const key = this.getKey(entity);
    if (key === null) return;
    const values = this.toValues(entity);
    this.store.update(this.tableName, values,
      `${this.pkColumn} = ?`, [key]);
  }

  /** Delete an entity. */
  delete(entity: T): void {
    const key = this.getKey(entity);
    if (key !== null) {
      this.deleteByKey(key);
    }
  }

  /** Delete by primary key. */
  deleteByKey(key: number): void {
    this.store.delete(this.tableName,
      `${this.pkColumn} = ?`, [key]);
  }

  /** Delete all rows. */
  deleteAll(): void {
    this.store.delete(this.tableName);
  }

  /** Delete a list of entities in a transaction. */
  deleteInTx(entities: T[]): void {
    this.store.beginTransaction();
    try {
      for (const entity of entities) {
        this.delete(entity);
      }
      this.store.commit();
    } catch (e) {
      this.store.rollback();
      throw e;
    }
  }

  /** Update a list of entities in a transaction. */
  updateInTx(entities: T[]): void {
    this.store.beginTransaction();
    try {
      for (const entity of entities) {
        this.update(entity);
      }
      this.store.commit();
    } catch (e) {
      this.store.rollback();
      throw e;
    }
  }

  // ---- Query helpers ----

  /** Query all rows with optional ordering, where clause, limit, offset. */
  queryAll(options?: {
    orderBy?: string;
    where?: string;
    whereArgs?: (string | number | null)[];
    limit?: number;
    offset?: number;
  }): T[] {
    const rows = this.store.query(this.tableName, options);
    return rows.map(row => this.fromRow(row));
  }
}
