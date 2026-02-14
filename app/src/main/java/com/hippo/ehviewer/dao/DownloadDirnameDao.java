package com.hippo.ehviewer.dao;

import android.content.ContentValues;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;

import com.hippo.dao.AbstractDao;
import com.hippo.dao.Property;

public class DownloadDirnameDao extends AbstractDao<DownloadDirname, Long> {

    public static final String TABLENAME = "DOWNLOAD_DIRNAME";

    public static class Properties {
        public static final Property Gid = new Property("GID", "gid", long.class, true);
        public static final Property Dirname = new Property("DIRNAME", "dirname", String.class, false);
    }

    private static final String[] ALL_COLUMNS = {
            "\"GID\"", "\"DIRNAME\""
    };

    public DownloadDirnameDao(SQLiteDatabase db) {
        super(db);
    }

    public static void createTable(SQLiteDatabase db, boolean ifNotExists) {
        String constraint = ifNotExists ? "IF NOT EXISTS " : "";
        db.execSQL("CREATE TABLE " + constraint + "\"DOWNLOAD_DIRNAME\" (" +
                "\"GID\" INTEGER PRIMARY KEY NOT NULL ," +
                "\"DIRNAME\" TEXT);");
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
        return "GID";
    }

    @Override
    protected DownloadDirname readEntity(Cursor cursor, int offset) {
        DownloadDirname entity = new DownloadDirname();
        entity.setGid(cursor.getLong(offset + 0));
        entity.setDirname(cursor.isNull(offset + 1) ? null : cursor.getString(offset + 1));
        return entity;
    }

    @Override
    protected void bindValues(ContentValues values, DownloadDirname entity) {
        values.put("GID", entity.getGid());
        values.put("DIRNAME", entity.getDirname());
    }

    @Override
    protected Long getKey(DownloadDirname entity) {
        return entity.getGid();
    }

    @Override
    protected boolean hasKey(DownloadDirname entity) {
        return true;
    }
}
