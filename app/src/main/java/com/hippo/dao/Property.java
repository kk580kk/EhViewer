package com.hippo.dao;

/**
 * Represents a column in a table, used for building queries.
 */
public class Property {

    public final String columnName;
    public final String fieldName;
    public final Class<?> type;
    public final boolean primaryKey;

    public Property(String columnName, String fieldName, Class<?> type, boolean primaryKey) {
        this.columnName = columnName;
        this.fieldName = fieldName;
        this.type = type;
        this.primaryKey = primaryKey;
    }

    public Condition eq(Object value) {
        return new Condition(columnName + "=?", String.valueOf(value));
    }

    public Condition notEq(Object value) {
        return new Condition(columnName + "!=?", String.valueOf(value));
    }

    public Condition like(String value) {
        return new Condition(columnName + " LIKE ?", value);
    }

    public Condition gt(Object value) {
        return new Condition(columnName + ">?", String.valueOf(value));
    }

    public Condition lt(Object value) {
        return new Condition(columnName + "<?", String.valueOf(value));
    }

    public Condition ge(Object value) {
        return new Condition(columnName + ">=?", String.valueOf(value));
    }

    public Condition le(Object value) {
        return new Condition(columnName + "<=?", String.valueOf(value));
    }

    public Condition isNull() {
        return new Condition(columnName + " IS NULL");
    }

    public Condition isNotNull() {
        return new Condition(columnName + " IS NOT NULL");
    }
}
