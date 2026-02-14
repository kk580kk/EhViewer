package com.hippo.dao;

import android.content.ContentValues;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;

import java.util.ArrayList;
import java.util.List;

/**
 * Base DAO providing CRUD operations for a single entity-to-table mapping.
 * Semantics mirror greenDAO's AbstractDao.
 *
 * @param <T> Entity type
 * @param <K> Primary key type
 */
public abstract class AbstractDao<T, K> {

    protected final SQLiteDatabase db;

    public AbstractDao(SQLiteDatabase db) {
        this.db = db;
    }

    /** Table name for this entity. */
    public abstract String getTablename();

    /** All column names in declaration order. */
    protected abstract String[] getAllColumns();

    /** Primary key column name. */
    protected abstract String getPkColumn();

    /** Read an entity from a cursor at the given column offset. */
    protected abstract T readEntity(Cursor cursor, int offset);

    /** Populate ContentValues from an entity. */
    protected abstract void bindValues(ContentValues values, T entity);

    /** Extract the primary key from an entity (may return null for auto-increment before insert). */
    protected abstract K getKey(T entity);

    /** Whether the entity has a non-null primary key. */
    protected abstract boolean hasKey(T entity);

    /** Set the auto-generated key on the entity after insert. */
    protected void setKey(T entity, K key) {
        // Override in auto-increment DAOs
    }

    /** Whether the primary key is auto-increment. */
    protected boolean isAutoIncrement() {
        return false;
    }

    // ---- CRUD ----

    /** Load an entity by primary key. Returns null if not found. */
    public T load(K key) {
        if (key == null) return null;
        Cursor cursor = db.query(getTablename(), getAllColumns(),
                getPkColumn() + "=?", new String[]{String.valueOf(key)},
                null, null, null, "1");
        try {
            if (cursor.moveToFirst()) {
                return readEntity(cursor, 0);
            }
            return null;
        } finally {
            cursor.close();
        }
    }

    /** Insert an entity. Returns the row ID. */
    public long insert(T entity) {
        ContentValues values = new ContentValues();
        bindValues(values, entity);
        if (isAutoIncrement() && !hasKey(entity)) {
            values.remove(getPkColumn());
        }
        long rowId = db.insert(getTablename(), null, values);
        if (isAutoIncrement() && rowId > 0) {
            @SuppressWarnings("unchecked")
            K key = (K) Long.valueOf(rowId);
            setKey(entity, key);
        }
        return rowId;
    }

    /** Update an entity by its primary key. */
    public void update(T entity) {
        K key = getKey(entity);
        if (key == null) return;
        ContentValues values = new ContentValues();
        bindValues(values, entity);
        db.update(getTablename(), values,
                getPkColumn() + "=?", new String[]{String.valueOf(key)});
    }

    /** Delete an entity. */
    public void delete(T entity) {
        K key = getKey(entity);
        if (key != null) {
            deleteByKey(key);
        }
    }

    /** Delete by primary key. */
    public void deleteByKey(K key) {
        db.delete(getTablename(),
                getPkColumn() + "=?", new String[]{String.valueOf(key)});
    }

    /** Delete all rows. */
    public void deleteAll() {
        db.delete(getTablename(), null, null);
    }

    /** Delete a list of entities in a transaction. */
    public void deleteInTx(Iterable<T> entities) {
        db.beginTransaction();
        try {
            for (T entity : entities) {
                delete(entity);
            }
            db.setTransactionSuccessful();
        } finally {
            db.endTransaction();
        }
    }

    /** Update a list of entities in a transaction. */
    public void updateInTx(Iterable<T> entities) {
        db.beginTransaction();
        try {
            for (T entity : entities) {
                update(entity);
            }
            db.setTransactionSuccessful();
        } finally {
            db.endTransaction();
        }
    }

    /** Create a new QueryBuilder for this DAO. */
    public QueryBuilder<T> queryBuilder() {
        return new QueryBuilder<>(this);
    }

    // ---- Internal helpers ----

    List<T> loadAll(Cursor cursor) {
        List<T> list = new ArrayList<>();
        try {
            while (cursor.moveToNext()) {
                list.add(readEntity(cursor, 0));
            }
        } finally {
            cursor.close();
        }
        return list;
    }

    SQLiteDatabase getDatabase() {
        return db;
    }
}
