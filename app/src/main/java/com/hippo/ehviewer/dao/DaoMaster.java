package com.hippo.ehviewer.dao;

import android.content.Context;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;

/**
 * Master of DAO: manages the database schema and creates sessions.
 * Replaces greenDAO's DaoMaster.
 */
public class DaoMaster {

    public static final int SCHEMA_VERSION = 4;

    private final SQLiteDatabase db;

    public DaoMaster(SQLiteDatabase db) {
        this.db = db;
    }

    public DaoSession newSession() {
        return new DaoSession(db);
    }

    /** Create all tables. */
    public static void createAllTables(SQLiteDatabase db, boolean ifNotExists) {
        DownloadsDao.createTable(db, ifNotExists);
        DownloadLabelDao.createTable(db, ifNotExists);
        DownloadDirnameDao.createTable(db, ifNotExists);
        HistoryDao.createTable(db, ifNotExists);
        QuickSearchDao.createTable(db, ifNotExists);
        LocalFavoritesDao.createTable(db, ifNotExists);
        BookmarksBao.createTable(db, ifNotExists);
        FilterDao.createTable(db, ifNotExists);
    }

    /**
     * SQLiteOpenHelper that creates the schema on first use.
     */
    public static abstract class OpenHelper extends SQLiteOpenHelper {

        public OpenHelper(Context context, String name, SQLiteDatabase.CursorFactory factory) {
            super(context, name, factory, SCHEMA_VERSION);
        }

        @Override
        public void onCreate(SQLiteDatabase db) {
            createAllTables(db, false);
        }
    }
}
