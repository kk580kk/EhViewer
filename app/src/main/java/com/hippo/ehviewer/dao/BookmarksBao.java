package com.hippo.ehviewer.dao;

import android.content.ContentValues;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;

import com.hippo.dao.AbstractDao;
import com.hippo.dao.Property;

public class BookmarksBao extends AbstractDao<BookmarkInfo, Long> {

    public static final String TABLENAME = "BOOKMARKS";

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
        public static final Property Page = new Property("PAGE", "page", int.class, false);
        public static final Property Time = new Property("TIME", "time", long.class, false);
    }

    private static final String[] ALL_COLUMNS = {
            "\"GID\"", "\"TOKEN\"", "\"TITLE\"", "\"TITLE_JPN\"", "\"THUMB\"",
            "\"CATEGORY\"", "\"POSTED\"", "\"UPLOADER\"", "\"RATING\"", "\"SIMPLE_LANGUAGE\"",
            "\"PAGE\"", "\"TIME\""
    };

    public BookmarksBao(SQLiteDatabase db) {
        super(db);
    }

    public static void createTable(SQLiteDatabase db, boolean ifNotExists) {
        String constraint = ifNotExists ? "IF NOT EXISTS " : "";
        db.execSQL("CREATE TABLE " + constraint + "\"BOOKMARKS\" (" +
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
                "\"PAGE\" INTEGER NOT NULL ," +
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
        return "GID";
    }

    @Override
    protected BookmarkInfo readEntity(Cursor cursor, int offset) {
        BookmarkInfo entity = new BookmarkInfo();
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
        entity.page = cursor.getInt(offset + 10);
        entity.time = cursor.getLong(offset + 11);
        return entity;
    }

    @Override
    protected void bindValues(ContentValues values, BookmarkInfo entity) {
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
        values.put("PAGE", entity.page);
        values.put("TIME", entity.time);
    }

    @Override
    protected Long getKey(BookmarkInfo entity) {
        return entity.gid;
    }

    @Override
    protected boolean hasKey(BookmarkInfo entity) {
        return true;
    }
}
