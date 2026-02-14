package com.hippo.dao;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Marks a field as a database column.
 * If {@link #value()} is empty, the column name is derived from the field name
 * by converting camelCase to UPPER_SNAKE_CASE.
 */
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.FIELD)
public @interface DbColumn {
    /** Column name. Empty means auto-derive from field name. */
    String value() default "";
    boolean primaryKey() default false;
    boolean notNull() default false;
    boolean autoIncrement() default false;
}
