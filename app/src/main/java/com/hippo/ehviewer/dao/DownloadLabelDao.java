package com.hippo.ehviewer.dao;

import android.content.ContentValues;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;

import com.hippo.dao.AbstractDao;
import com.hippo.dao.Property;

public class DownloadLabelDao extends AbstractDao<DownloadLabel, Long> {

    public static final String TABLENAME = "DOWNLOAD_LABELS";

    public static class Properties {
        public static final Property Id = new Property("_id", "id", Long.class, true);
        public static final Property Label = new Property("LABEL", "label", String.class, false);
        public static final Property Time = new Property("TIME", "time", long.class, false);
    }

    private static final String[] ALL_COLUMNS = {
            "\"_id\"", "\"LABEL\"", "\"TIME\""
    };

    public DownloadLabelDao(SQLiteDatabase db) {
        super(db);
    }

    public static void createTable(SQLiteDatabase db, boolean ifNotExists) {
        String constraint = ifNotExists ? "IF NOT EXISTS " : "";
        db.execSQL("CREATE TABLE " + constraint + "\"DOWNLOAD_LABELS\" (" +
                "\"_id\" INTEGER PRIMARY KEY AUTOINCREMENT ," +
                "\"LABEL\" TEXT," +
                "\"TIME\" INTEGER NOT NULL );");
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
    protected DownloadLabel readEntity(Cursor cursor, int offset) {
        DownloadLabel entity = new DownloadLabel();
        entity.setId(cursor.isNull(offset + 0) ? null : cursor.getLong(offset + 0));
        entity.setLabel(cursor.isNull(offset + 1) ? null : cursor.getString(offset + 1));
        entity.setTime(cursor.getLong(offset + 2));
        return entity;
    }

    @Override
    protected void bindValues(ContentValues values, DownloadLabel entity) {
        if (entity.getId() != null) {
            values.put("_id", entity.getId());
        }
        values.put("LABEL", entity.getLabel());
        values.put("TIME", entity.getTime());
    }

    @Override
    protected Long getKey(DownloadLabel entity) {
        return entity.getId();
    }

    @Override
    protected boolean hasKey(DownloadLabel entity) {
        return entity.getId() != null;
    }

    @Override
    protected void setKey(DownloadLabel entity, Long key) {
        entity.setId(key);
    }
}
