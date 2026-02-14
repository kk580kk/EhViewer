package com.hippo.ehviewer.dao;

import android.database.sqlite.SQLiteDatabase;

/**
 * Holds DAO instances for a single database connection.
 * Replaces greenDAO's DaoSession.
 */
public class DaoSession {

    private final DownloadsDao downloadsDao;
    private final DownloadLabelDao downloadLabelDao;
    private final DownloadDirnameDao downloadDirnameDao;
    private final HistoryDao historyDao;
    private final QuickSearchDao quickSearchDao;
    private final LocalFavoritesDao localFavoritesDao;
    private final BookmarksBao bookmarksBao;
    private final FilterDao filterDao;

    public DaoSession(SQLiteDatabase db) {
        downloadsDao = new DownloadsDao(db);
        downloadLabelDao = new DownloadLabelDao(db);
        downloadDirnameDao = new DownloadDirnameDao(db);
        historyDao = new HistoryDao(db);
        quickSearchDao = new QuickSearchDao(db);
        localFavoritesDao = new LocalFavoritesDao(db);
        bookmarksBao = new BookmarksBao(db);
        filterDao = new FilterDao(db);
    }

    public DownloadsDao getDownloadsDao() {
        return downloadsDao;
    }

    public DownloadLabelDao getDownloadLabelDao() {
        return downloadLabelDao;
    }

    public DownloadDirnameDao getDownloadDirnameDao() {
        return downloadDirnameDao;
    }

    public HistoryDao getHistoryDao() {
        return historyDao;
    }

    public QuickSearchDao getQuickSearchDao() {
        return quickSearchDao;
    }

    public LocalFavoritesDao getLocalFavoritesDao() {
        return localFavoritesDao;
    }

    public BookmarksBao getBookmarksBao() {
        return bookmarksBao;
    }

    public FilterDao getFilterDao() {
        return filterDao;
    }
}
