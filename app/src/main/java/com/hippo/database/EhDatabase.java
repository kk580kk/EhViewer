/*
 * Copyright 2017 Hippo Seven
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.hippo.database;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;
import androidx.annotation.Nullable;

/**
 * Database facade: create tables (via {@link MSQLiteBuilder}), write and query.
 * Provides storage foundation for EhDB and download module.
 */
public final class EhDatabase {

  private final SQLiteOpenHelper helper;
  private final SQLiteDatabase db;

  /**
   * Opens the database. Tables are created/upgraded according to {@code builder}.
   */
  public EhDatabase(Context context, String name, int version, MSQLiteBuilder builder) {
    this.helper = builder.build(context, name, version);
    this.db = helper.getWritableDatabase();
  }

  public SQLiteDatabase getWritableDatabase() {
    return db;
  }

  public long insert(String table, @Nullable String nullColumnHack, ContentValues values) {
    return db.insert(table, nullColumnHack, values);
  }

  public int update(String table, ContentValues values, @Nullable String whereClause,
      @Nullable String[] whereArgs) {
    return db.update(table, values, whereClause, whereArgs);
  }

  public int delete(String table, @Nullable String whereClause, @Nullable String[] whereArgs) {
    return db.delete(table, whereClause, whereArgs);
  }

  public Cursor query(String table, @Nullable String[] columns, @Nullable String selection,
      @Nullable String[] selectionArgs, @Nullable String orderBy) {
    return db.query(table, columns, selection, selectionArgs, null, null, orderBy);
  }

  public Cursor rawQuery(String sql, @Nullable String[] selectionArgs) {
    return db.rawQuery(sql, selectionArgs);
  }

  public void close() {
    db.close();
    helper.close();
  }
}
