package com.hippo.ehviewer.dao;

import android.content.ContentValues;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;

import com.hippo.dao.AbstractDao;
import com.hippo.dao.Property;

public class DownloadsDao extends AbstractDao<DownloadInfo, Long> {

    public static final String TABLENAME = "DOWNLOADS";

    public static class Properties {
        public static final Property Gid = new Property("GID", "gid", long.class, true);
        public static final Property Token = new Property("TOKEN", "token", String.class, false);
        public static final Property Title = new Property("TITLE", "title", String.class, false);
        public static final Property TitleJpn = new Property("TITLE_JPN", "titleJpn", String.class, false);
        public static final Property Thumb = new Property("THUMB", "thumb", String.class, false);
        public static final Property Category = new Property("CATEGORY", "category", int.class, false);
        public static final Property Posted = new Property("POSTED", "posted", String.class, false);
        public static final Property Uploader = new Property("UPLOADER", "uploader", String.class, false);
        public static final Property Rating = new Property("RATING", "rating", float.class, false);
        public static final Property SimpleLanguage = new Property("SIMPLE_LANGUAGE", "simpleLanguage", String.class, false);
        public static final Property State = new Property("STATE", "state", int.class, false);
        public static final Property Legacy = new Property("LEGACY", "legacy", int.class, false);
        public static final Property Time = new Property("TIME", "time", long.class, false);
        public static final Property Label = new Property("LABEL", "label", String.class, false);
    }

    private static final String[] ALL_COLUMNS = {
            "\"GID\"", "\"TOKEN\"", "\"TITLE\"", "\"TITLE_JPN\"", "\"THUMB\"",
            "\"CATEGORY\"", "\"POSTED\"", "\"UPLOADER\"", "\"RATING\"", "\"SIMPLE_LANGUAGE\"",
            "\"STATE\"", "\"LEGACY\"", "\"TIME\"", "\"LABEL\""
    };

    public DownloadsDao(SQLiteDatabase db) {
        super(db);
    }

    public static void createTable(SQLiteDatabase db, boolean ifNotExists) {
        String constraint = ifNotExists ? "IF NOT EXISTS " : "";
        db.execSQL("CREATE TABLE " + constraint + "\"DOWNLOADS\" (" +
                "\"GID\" INTEGER PRIMARY KEY NOT NULL ," +
                "\"TOKEN\" TEXT," +
                "\"TITLE\" TEXT," +
                "\"TITLE_JPN\" TEXT," +
                "\"THUMB\" TEXT," +
                "\"CATEGORY\" INTEGER NOT NULL ," +
                "\"POSTED\" TEXT," +
                "\"UPLOADER\" TEXT," +
                "\"RATING\" REAL NOT NULL ," +
                "\"SIMPLE_LANGUAGE\" TEXT," +
                "\"STATE\" INTEGER NOT NULL ," +
                "\"LEGACY\" INTEGER NOT NULL ," +
                "\"TIME\" INTEGER NOT NULL ," +
                "\"LABEL\" TEXT);");
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
    protected DownloadInfo readEntity(Cursor cursor, int offset) {
        DownloadInfo entity = new DownloadInfo();
        entity.gid = cursor.getLong(offset + 0);
        entity.token = cursor.isNull(offset + 1) ? null : cursor.getString(offset + 1);
        entity.title = cursor.isNull(offset + 2) ? null : cursor.getString(offset + 2);
        entity.titleJpn = cursor.isNull(offset + 3) ? null : cursor.getString(offset + 3);
        entity.thumb = cursor.isNull(offset + 4) ? null : cursor.getString(offset + 4);
        entity.category = cursor.getInt(offset + 5);
        entity.posted = cursor.isNull(offset + 6) ? null : cursor.getString(offset + 6);
        entity.uploader = cursor.isNull(offset + 7) ? null : cursor.getString(offset + 7);
        entity.rating = cursor.getFloat(offset + 8);
        entity.simpleLanguage = cursor.isNull(offset + 9) ? null : cursor.getString(offset + 9);
        entity.state = cursor.getInt(offset + 10);
        entity.legacy = cursor.getInt(offset + 11);
        entity.time = cursor.getLong(offset + 12);
        entity.label = cursor.isNull(offset + 13) ? null : cursor.getString(offset + 13);
        return entity;
    }

    @Override
    protected void bindValues(ContentValues values, DownloadInfo entity) {
        values.put("GID", entity.gid);
        values.put("TOKEN", entity.token);
        values.put("TITLE", entity.title);
        values.put("TITLE_JPN", entity.titleJpn);
        values.put("THUMB", entity.thumb);
        values.put("CATEGORY", entity.category);
        values.put("POSTED", entity.posted);
        values.put("UPLOADER", entity.uploader);
        values.put("RATING", entity.rating);
        values.put("SIMPLE_LANGUAGE", entity.simpleLanguage);
        values.put("STATE", entity.state);
        values.put("LEGACY", entity.legacy);
        values.put("TIME", entity.time);
        values.put("LABEL", entity.label);
    }

    @Override
    protected Long getKey(DownloadInfo entity) {
        return entity.gid;
    }

    @Override
    protected boolean hasKey(DownloadInfo entity) {
        return true; // gid is always set (non-null primitive)
    }
}
