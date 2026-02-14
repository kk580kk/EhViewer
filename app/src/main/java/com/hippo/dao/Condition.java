package com.hippo.dao;

/**
 * Represents a WHERE condition for query building.
 */
public class Condition {

    public final String clause;
    public final String[] args;

    public Condition(String clause, String... args) {
        this.clause = clause;
        this.args = args;
    }
}
