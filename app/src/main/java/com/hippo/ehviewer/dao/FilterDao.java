package com.hippo.ehviewer.dao;

import android.content.ContentValues;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;

import com.hippo.dao.AbstractDao;
import com.hippo.dao.Property;

public class FilterDao extends AbstractDao<Filter, Long> {

    public static final String TABLENAME = "FILTER";

    public static class Properties {
        public static final Property Id = new Property("_id", "id", Long.class, true);
        public static final Property Mode = new Property("MODE", "mode", int.class, false);
        public static final Property Text = new Property("TEXT", "text", String.class, false);
        public static final Property Enable = new Property("ENABLE", "enable", Boolean.class, false);
    }

    private static final String[] ALL_COLUMNS = {
            "\"_id\"", "\"MODE\"", "\"TEXT\"", "\"ENABLE\""
    };

    public FilterDao(SQLiteDatabase db) {
        super(db);
    }

    public static void createTable(SQLiteDatabase db, boolean ifNotExists) {
        String constraint = ifNotExists ? "IF NOT EXISTS " : "";
        db.execSQL("CREATE TABLE " + constraint + "\"FILTER\" (" +
                "\"_id\" INTEGER PRIMARY KEY AUTOINCREMENT ," +
                "\"MODE\" INTEGER NOT NULL ," +
                "\"TEXT\" TEXT," +
                "\"ENABLE\" INTEGER);");
    }

    @Override
    public String getTablename() {
        return TABLENAME;
    }

    @Override
    protected String[] getAllColumns() {
        return ALL_COLUMNS;
    }

    @Override
    protected String getPkColumn() {
        return "_id";
    }

    @Override
    protected boolean isAutoIncrement() {
        return true;
    }

    @Override
    protected Filter readEntity(Cursor cursor, int offset) {
        Filter entity = new Filter();
        entity.setId(cursor.isNull(offset + 0) ? null : cursor.getLong(offset + 0));
        entity.mode = cursor.getInt(offset + 1);
        entity.text = cursor.isNull(offset + 2) ? null : cursor.getString(offset + 2);
        entity.enable = cursor.isNull(offset + 3) ? null : cursor.getInt(offset + 3) != 0;
        return entity;
    }

    @Override
    protected void bindValues(ContentValues values, Filter entity) {
        if (entity.getId() != null) {
            values.put("_id", entity.getId());
        }
        values.put("MODE", entity.mode);
        values.put("TEXT", entity.text);
        if (entity.enable != null) {
            values.put("ENABLE", entity.enable ? 1 : 0);
        } else {
            values.putNull("ENABLE");
        }
    }

    @Override
    protected Long getKey(Filter entity) {
        return entity.getId();
    }

    @Override
    protected boolean hasKey(Filter entity) {
        return entity.getId() != null;
    }

    @Override
    protected void setKey(Filter entity, Long key) {
        entity.setId(key);
    }
}
