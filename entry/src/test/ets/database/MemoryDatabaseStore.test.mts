import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { MemoryDatabaseStore } from '../../../main/ets/database/MemoryDatabaseStore.ets';

describe('MemoryDatabaseStore', () => {
  let db: MemoryDatabaseStore;

  beforeEach(() => {
    db = new MemoryDatabaseStore();
  });

  describe('executeSql', () => {
    it('should create a table', () => {
      db.executeSql('CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT)');
      assert.strictEqual(db.hasTable('test'), true);
    });

    it('should handle CREATE TABLE IF NOT EXISTS', () => {
      db.executeSql('CREATE TABLE IF NOT EXISTS test (id INTEGER)');
      db.executeSql('CREATE TABLE IF NOT EXISTS test (id INTEGER)');
      assert.strictEqual(db.hasTable('test'), true);
    });

    it('should drop a table', () => {
      db.executeSql('CREATE TABLE test (id INTEGER)');
      db.executeSql('DROP TABLE test');
      assert.strictEqual(db.hasTable('test'), false);
    });

    it('should handle DROP TABLE IF EXISTS', () => {
      db.executeSql('DROP TABLE IF EXISTS nonexistent');
      // should not throw
    });

    it('should handle ALTER TABLE (no-op)', () => {
      db.executeSql('CREATE TABLE test (id INTEGER)');
      db.executeSql('ALTER TABLE test ADD COLUMN name TEXT');
      // should not throw
    });
  });

  describe('insert', () => {
    it('should insert a row and return row ID', () => {
      db.executeSql('CREATE TABLE test (name TEXT, age INTEGER)');
      const id1 = db.insert('test', { name: 'Alice', age: 30 });
      const id2 = db.insert('test', { name: 'Bob', age: 25 });
      assert.strictEqual(id1, 1);
      assert.strictEqual(id2, 2);
      assert.strictEqual(db.rowCount('test'), 2);
    });

    it('should throw for non-existent table', () => {
      assert.throws(() => db.insert('nope', { x: 1 }), /does not exist/);
    });
  });

  describe('query', () => {
    beforeEach(() => {
      db.executeSql('CREATE TABLE users (name TEXT, age INTEGER)');
      db.insert('users', { name: 'Alice', age: 30 });
      db.insert('users', { name: 'Bob', age: 25 });
      db.insert('users', { name: 'Charlie', age: 35 });
    });

    it('should return all rows when no options', () => {
      const rows = db.query('users');
      assert.strictEqual(rows.length, 3);
    });

    it('should filter by where clause', () => {
      const rows = db.query('users', { where: 'name = ?', whereArgs: ['Bob'] });
      assert.strictEqual(rows.length, 1);
      assert.strictEqual(rows[0].getString('name'), 'Bob');
      assert.strictEqual(rows[0].getLong('age'), 25);
    });

    it('should sort by orderBy ASC', () => {
      const rows = db.query('users', { orderBy: 'age ASC' });
      assert.strictEqual(rows[0].getString('name'), 'Bob');
      assert.strictEqual(rows[2].getString('name'), 'Charlie');
    });

    it('should sort by orderBy DESC', () => {
      const rows = db.query('users', { orderBy: 'age DESC' });
      assert.strictEqual(rows[0].getString('name'), 'Charlie');
      assert.strictEqual(rows[2].getString('name'), 'Bob');
    });

    it('should apply limit', () => {
      const rows = db.query('users', { limit: 2 });
      assert.strictEqual(rows.length, 2);
    });

    it('should apply offset and limit', () => {
      const rows = db.query('users', { orderBy: 'age ASC', offset: 1, limit: 1 });
      assert.strictEqual(rows.length, 1);
      assert.strictEqual(rows[0].getString('name'), 'Alice');
    });
  });

  describe('update', () => {
    it('should update matching rows', () => {
      db.executeSql('CREATE TABLE t (name TEXT, val INTEGER)');
      db.insert('t', { name: 'a', val: 1 });
      db.insert('t', { name: 'b', val: 2 });

      const count = db.update('t', { val: 10 }, 'name = ?', ['a']);
      assert.strictEqual(count, 1);

      const rows = db.query('t', { where: 'name = ?', whereArgs: ['a'] });
      assert.strictEqual(rows[0].getLong('val'), 10);
    });

    it('should return 0 when no rows match', () => {
      db.executeSql('CREATE TABLE t (name TEXT)');
      db.insert('t', { name: 'a' });
      const count = db.update('t', { name: 'b' }, 'name = ?', ['x']);
      assert.strictEqual(count, 0);
    });
  });

  describe('delete', () => {
    it('should delete matching rows', () => {
      db.executeSql('CREATE TABLE t (name TEXT)');
      db.insert('t', { name: 'a' });
      db.insert('t', { name: 'b' });

      const count = db.delete('t', 'name = ?', ['a']);
      assert.strictEqual(count, 1);
      assert.strictEqual(db.rowCount('t'), 1);
    });

    it('should delete all rows when no where clause', () => {
      db.executeSql('CREATE TABLE t (name TEXT)');
      db.insert('t', { name: 'a' });
      db.insert('t', { name: 'b' });

      const count = db.delete('t');
      assert.strictEqual(count, 2);
      assert.strictEqual(db.rowCount('t'), 0);
    });
  });

  describe('ResultRow', () => {
    it('should handle getString for null values', () => {
      db.executeSql('CREATE TABLE t (name TEXT)');
      db.insert('t', { name: null });
      const rows = db.query('t');
      assert.strictEqual(rows[0].getString('name'), null);
    });

    it('should handle getLong for missing columns', () => {
      db.executeSql('CREATE TABLE t (name TEXT)');
      db.insert('t', { name: 'x' });
      const rows = db.query('t');
      assert.strictEqual(rows[0].getLong('missing'), 0);
    });

    it('should handle getBoolean', () => {
      db.executeSql('CREATE TABLE t (flag INTEGER)');
      db.insert('t', { flag: 1 });
      db.insert('t', { flag: 0 });
      const rows = db.query('t', { orderBy: '_rowid ASC' });
      assert.strictEqual(rows[0].getBoolean('flag'), true);
      assert.strictEqual(rows[1].getBoolean('flag'), false);
    });

    it('should handle getDouble', () => {
      db.executeSql('CREATE TABLE t (rating REAL)');
      db.insert('t', { rating: 4.5 });
      const rows = db.query('t');
      assert.ok(Math.abs(rows[0].getDouble('rating') - 4.5) < 0.001);
    });
  });

  describe('transactions', () => {
    it('should support begin/commit', () => {
      db.executeSql('CREATE TABLE t (x INTEGER)');
      db.beginTransaction();
      db.insert('t', { x: 1 });
      db.commit();
      assert.strictEqual(db.rowCount('t'), 1);
    });

    it('should support rollback without error', () => {
      db.executeSql('CREATE TABLE t (x INTEGER)');
      db.beginTransaction();
      db.insert('t', { x: 1 });
      db.rollback();
      // MemoryDatabaseStore doesn't actually undo, but should not throw
    });
  });

  describe('close', () => {
    it('should reject operations after close', () => {
      db.executeSql('CREATE TABLE t (x INTEGER)');
      db.close();
      assert.throws(() => db.insert('t', { x: 1 }), /closed/);
    });
  });

  describe('AND where clause', () => {
    it('should filter by multiple conditions', () => {
      db.executeSql('CREATE TABLE t (a TEXT, b INTEGER)');
      db.insert('t', { a: 'x', b: 1 });
      db.insert('t', { a: 'x', b: 2 });
      db.insert('t', { a: 'y', b: 1 });

      const rows = db.query('t', { where: 'a = ? AND b = ?', whereArgs: ['x', 1] });
      assert.strictEqual(rows.length, 1);
      assert.strictEqual(rows[0].getString('a'), 'x');
      assert.strictEqual(rows[0].getLong('b'), 1);
    });
  });
});
