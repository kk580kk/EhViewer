package com.hippo.dao;

import android.database.Cursor;

import java.util.ArrayList;
import java.util.List;

/**
 * Builds SQL queries with conditions, ordering, limit and offset.
 * Semantics mirror greenDAO's QueryBuilder.
 */
public class QueryBuilder<T> {

    private final AbstractDao<T, ?> dao;
    private final List<Condition> conditions = new ArrayList<>();
    private String orderBy;
    private int limit = Integer.MIN_VALUE;
    private int offset = Integer.MIN_VALUE;

    QueryBuilder(AbstractDao<T, ?> dao) {
        this.dao = dao;
    }

    public QueryBuilder<T> where(Condition... conditions) {
        for (Condition c : conditions) {
            this.conditions.add(c);
        }
        return this;
    }

    public QueryBuilder<T> orderAsc(Property... properties) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < properties.length; i++) {
            if (i > 0) sb.append(", ");
            sb.append('"').append(properties[i].columnName).append('"').append(" ASC");
        }
        this.orderBy = sb.toString();
        return this;
    }

    public QueryBuilder<T> orderDesc(Property... properties) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < properties.length; i++) {
            if (i > 0) sb.append(", ");
            sb.append('"').append(properties[i].columnName).append('"').append(" DESC");
        }
        this.orderBy = sb.toString();
        return this;
    }

    public QueryBuilder<T> limit(int limit) {
        this.limit = limit;
        return this;
    }

    public QueryBuilder<T> offset(int offset) {
        this.offset = offset;
        return this;
    }

    private String buildSelection() {
        if (conditions.isEmpty()) return null;
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < conditions.size(); i++) {
            if (i > 0) sb.append(" AND ");
            sb.append(conditions.get(i).clause);
        }
        return sb.toString();
    }

    private String[] buildSelectionArgs() {
        if (conditions.isEmpty()) return null;
        List<String> args = new ArrayList<>();
        for (Condition c : conditions) {
            if (c.args != null) {
                for (String arg : c.args) {
                    args.add(arg);
                }
            }
        }
        return args.isEmpty() ? null : args.toArray(new String[0]);
    }

    /**
     * Build the LIMIT clause for SQLiteDatabase.query().
     * SQLite supports: LIMIT count, or LIMIT offset, count
     * A count of -1 means unlimited.
     */
    private String buildLimit() {
        boolean hasLimit = limit != Integer.MIN_VALUE;
        boolean hasOffset = offset != Integer.MIN_VALUE;
        if (!hasLimit && !hasOffset) return null;
        if (hasOffset) {
            int effectiveLimit = hasLimit ? limit : -1;
            return offset + ", " + effectiveLimit;
        }
        return String.valueOf(limit);
    }

    Cursor buildCursor() {
        return dao.getDatabase().query(
                dao.getTablename(),
                dao.getAllColumns(),
                buildSelection(),
                buildSelectionArgs(),
                null, null,
                orderBy,
                buildLimit()
        );
    }

    /** Execute the query and return all results as a list. */
    public List<T> list() {
        return dao.loadAll(buildCursor());
    }

    /** Execute the query and return a lazy list backed by a cursor. */
    public LazyList<T> listLazy() {
        return new LazyList<>(dao, buildCursor());
    }

    /** Execute the query and return a closeable list iterator. */
    public CloseableListIterator<T> listIterator() {
        return new LazyList<>(dao, buildCursor()).listIterator();
    }
}
