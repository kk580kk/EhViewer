import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { SqlUtils } from '../../../main/ets/util/SqlUtils.ets';
import { MemoryDatabaseStore } from '../../../main/ets/database/MemoryDatabaseStore.ets';
import type { ResultRow } from '../../../main/ets/database/DatabaseStore.ets';

describe('SqlUtils', () => {

  // ---- sqlEscapeString ----

  describe('sqlEscapeString', () => {
    it('should return the same string when no quotes present', () => {
      assert.strictEqual(SqlUtils.sqlEscapeString('hello'), 'hello');
    });

    it('should double single quotes', () => {
      assert.strictEqual(SqlUtils.sqlEscapeString("it's"), "it''s");
    });

    it('should double multiple single quotes', () => {
      assert.strictEqual(SqlUtils.sqlEscapeString("it's a 'test'"), "it''s a ''test''");
    });

    it('should handle empty string', () => {
      assert.strictEqual(SqlUtils.sqlEscapeString(''), '');
    });

    it('should handle string of only quotes', () => {
      assert.strictEqual(SqlUtils.sqlEscapeString("'''"), "''''''");
    });
  });

  // ---- exeSQLSafely ----

  describe('exeSQLSafely', () => {
    it('should execute valid SQL without throwing', () => {
      const db = new MemoryDatabaseStore();
      assert.doesNotThrow(() => {
        SqlUtils.exeSQLSafely(db, 'CREATE TABLE test_table (id INTEGER)');
      });
      assert.ok(db.hasTable('test_table'));
    });

    it('should silently ignore SQL errors', () => {
      const db = new MemoryDatabaseStore();
      // Querying a non-existent table would throw from MemoryDatabaseStore,
      // but exeSQLSafely should swallow it
      assert.doesNotThrow(() => {
        SqlUtils.exeSQLSafely(db, 'SOMETHING INVALID');
      });
    });
  });

  // ---- dropTable ----

  describe('dropTable', () => {
    it('should drop an existing table', () => {
      const db = new MemoryDatabaseStore();
      db.executeSql('CREATE TABLE my_table (id INTEGER)');
      assert.ok(db.hasTable('my_table'));

      SqlUtils.dropTable(db, 'my_table');
      assert.ok(!db.hasTable('my_table'));
    });

    it('should not throw when dropping a non-existent table', () => {
      const db = new MemoryDatabaseStore();
      assert.doesNotThrow(() => {
        SqlUtils.dropTable(db, 'nonexistent');
      });
    });
  });

  // ---- dropAllTables ----

  describe('dropAllTables', () => {
    it('should drop all user tables', () => {
      const db = new MemoryDatabaseStore();
      // We need sqlite_master to exist for querying; MemoryDatabaseStore
      // doesn't support sqlite_master queries, so we test the concept
      // by creating the expected table structure manually.
      db.executeSql('CREATE TABLE sqlite_master (name TEXT, type TEXT)');
      db.insert('sqlite_master', { name: 'users', type: 'table' });
      db.insert('sqlite_master', { name: 'posts', type: 'table' });

      // Create the actual tables too
      db.executeSql('CREATE TABLE users (id INTEGER)');
      db.executeSql('CREATE TABLE posts (id INTEGER)');

      SqlUtils.dropAllTables(db);

      assert.ok(!db.hasTable('users'));
      assert.ok(!db.hasTable('posts'));
    });
  });

  // ---- ResultRow value extraction ----

  describe('getBoolean', () => {
    it('should return the boolean value from a row', () => {
      const row = createRow({ flag: 1 });
      assert.strictEqual(SqlUtils.getBoolean(row, 'flag', false), true);
    });

    it('should return default when row throws', () => {
      const row = createThrowingRow();
      assert.strictEqual(SqlUtils.getBoolean(row, 'missing', true), true);
    });

    it('should return false for 0', () => {
      const row = createRow({ flag: 0 });
      assert.strictEqual(SqlUtils.getBoolean(row, 'flag', true), false);
    });
  });

  describe('getInt', () => {
    it('should return the integer value from a row', () => {
      const row = createRow({ count: 42 });
      assert.strictEqual(SqlUtils.getInt(row, 'count', 0), 42);
    });

    it('should return default when row throws', () => {
      const row = createThrowingRow();
      assert.strictEqual(SqlUtils.getInt(row, 'missing', -1), -1);
    });
  });

  describe('getLong', () => {
    it('should return the long value from a row', () => {
      const row = createRow({ id: 1234567890 });
      assert.strictEqual(SqlUtils.getLong(row, 'id', 0), 1234567890);
    });

    it('should return default when row throws', () => {
      const row = createThrowingRow();
      assert.strictEqual(SqlUtils.getLong(row, 'missing', -1), -1);
    });
  });

  describe('getFloat', () => {
    it('should return the float value from a row', () => {
      const row = createRow({ rating: 4.5 });
      assert.strictEqual(SqlUtils.getFloat(row, 'rating', 0), 4.5);
    });

    it('should return default when row throws', () => {
      const row = createThrowingRow();
      assert.strictEqual(SqlUtils.getFloat(row, 'missing', 1.0), 1.0);
    });
  });

  describe('getString', () => {
    it('should return the string value from a row', () => {
      const row = createRow({ name: 'Alice' });
      assert.strictEqual(SqlUtils.getString(row, 'name', ''), 'Alice');
    });

    it('should return default for null value', () => {
      const row = createRow({ name: null });
      assert.strictEqual(SqlUtils.getString(row, 'name', 'default'), 'default');
    });

    it('should return default when row throws', () => {
      const row = createThrowingRow();
      assert.strictEqual(SqlUtils.getString(row, 'missing', 'fallback'), 'fallback');
    });
  });
});

// ---- Helpers ----

/** Create a ResultRow from a plain object (returns type-defaults for missing keys). */
function createRow(data: Record<string, string | number | null>): ResultRow {
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

/** Create a ResultRow that throws on every access (simulates column-not-found errors). */
function createThrowingRow(): ResultRow {
  return {
    getLong(_column: string): number { throw new Error('column not found'); },
    getDouble(_column: string): number { throw new Error('column not found'); },
    getString(_column: string): string | null { throw new Error('column not found'); },
    getBoolean(_column: string): boolean { throw new Error('column not found'); },
  };
}
