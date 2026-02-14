package com.hippo.ehviewer.dao;

import android.content.ContentValues;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;

import com.hippo.dao.AbstractDao;
import com.hippo.dao.Property;

public class QuickSearchDao extends AbstractDao<QuickSearch, Long> {

    public static final String TABLENAME = "QUICK_SEARCH";

    public static class Properties {
        public static final Property Id = new Property("_id", "id", Long.class, true);
        public static final Property Name = new Property("NAME", "name", String.class, false);
        public static final Property Mode = new Property("MODE", "mode", int.class, false);
        public static final Property Category = new Property("CATEGORY", "category", int.class, false);
        public static final Property Keyword = new Property("KEYWORD", "keyword", String.class, false);
        public static final Property AdvanceSearch = new Property("ADVANCE_SEARCH", "advanceSearch", int.class, false);
        public static final Property MinRating = new Property("MIN_RATING", "minRating", int.class, false);
        public static final Property PageFrom = new Property("PAGE_FROM", "pageFrom", int.class, false);
        public static final Property PageTo = new Property("PAGE_TO", "pageTo", int.class, false);
        public static final Property Time = new Property("TIME", "time", long.class, false);
    }

    private static final String[] ALL_COLUMNS = {
            "\"_id\"", "\"NAME\"", "\"MODE\"", "\"CATEGORY\"", "\"KEYWORD\"",
            "\"ADVANCE_SEARCH\"", "\"MIN_RATING\"", "\"PAGE_FROM\"", "\"PAGE_TO\"", "\"TIME\""
    };

    public QuickSearchDao(SQLiteDatabase db) {
        super(db);
    }

    public static void createTable(SQLiteDatabase db, boolean ifNotExists) {
        String constraint = ifNotExists ? "IF NOT EXISTS " : "";
        db.execSQL("CREATE TABLE " + constraint + "\"QUICK_SEARCH\" (" +
                "\"_id\" INTEGER PRIMARY KEY AUTOINCREMENT ," +
                "\"NAME\" TEXT," +
                "\"MODE\" INTEGER NOT NULL ," +
                "\"CATEGORY\" INTEGER NOT NULL ," +
                "\"KEYWORD\" TEXT," +
                "\"ADVANCE_SEARCH\" INTEGER NOT NULL ," +
                "\"MIN_RATING\" INTEGER NOT NULL ," +
                "\"PAGE_FROM\" INTEGER NOT NULL ," +
                "\"PAGE_TO\" INTEGER NOT NULL ," +
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
    protected QuickSearch readEntity(Cursor cursor, int offset) {
        QuickSearch entity = new QuickSearch();
        entity.id = cursor.isNull(offset + 0) ? null : cursor.getLong(offset + 0);
        entity.name = cursor.isNull(offset + 1) ? null : cursor.getString(offset + 1);
        entity.mode = cursor.getInt(offset + 2);
        entity.category = cursor.getInt(offset + 3);
        entity.keyword = cursor.isNull(offset + 4) ? null : cursor.getString(offset + 4);
        entity.advanceSearch = cursor.getInt(offset + 5);
        entity.minRating = cursor.getInt(offset + 6);
        entity.pageFrom = cursor.getInt(offset + 7);
        entity.pageTo = cursor.getInt(offset + 8);
        entity.time = cursor.getLong(offset + 9);
        return entity;
    }

    @Override
    protected void bindValues(ContentValues values, QuickSearch entity) {
        if (entity.id != null) {
            values.put("_id", entity.id);
        }
        values.put("NAME", entity.name);
        values.put("MODE", entity.mode);
        values.put("CATEGORY", entity.category);
        values.put("KEYWORD", entity.keyword);
        values.put("ADVANCE_SEARCH", entity.advanceSearch);
        values.put("MIN_RATING", entity.minRating);
        values.put("PAGE_FROM", entity.pageFrom);
        values.put("PAGE_TO", entity.pageTo);
        values.put("TIME", entity.time);
    }

    @Override
    protected Long getKey(QuickSearch entity) {
        return entity.id;
    }

    @Override
    protected boolean hasKey(QuickSearch entity) {
        return entity.id != null;
    }

    @Override
    protected void setKey(QuickSearch entity, Long key) {
        entity.id = key;
    }
}
