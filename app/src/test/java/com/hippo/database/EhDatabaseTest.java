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

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;

import android.content.ContentValues;
import android.database.Cursor;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class EhDatabaseTest {

  private static final String TABLE = "TEST_TABLE";
  private static final String COL_ID = "_id";
  private static final String COL_NAME = "NAME";
  private static final String COL_VALUE = "VALUE";
  private static final int DB_VERSION = 1;

  @Test
  public void createTable_insert_query_update_delete() {
    MSQLiteBuilder builder = new MSQLiteBuilder()
        .version(DB_VERSION)
        .createTable(TABLE)
        .insertColumn(TABLE, COL_NAME, String.class)
        .insertColumn(TABLE, COL_VALUE, int.class);

    EhDatabase db = new EhDatabase(
        RuntimeEnvironment.getApplication(),
        "eh_db_test.db",
        DB_VERSION,
        builder);

    try {
      // Insert
      ContentValues row = new ContentValues();
      row.put(COL_ID, 1);
      row.put(COL_NAME, "a");
      row.put(COL_VALUE, 10);
      long id = db.insert(TABLE, null, row);
      assertTrue(id > 0);

      // Query one row
      Cursor c = db.query(TABLE, null, null, null, null);
      assertNotNull(c);
      assertEquals(1, c.getCount());
      assertTrue(c.moveToFirst());
      assertEquals(1, c.getInt(c.getColumnIndex(COL_ID)));
      assertEquals("a", c.getString(c.getColumnIndex(COL_NAME)));
      assertEquals(10, c.getInt(c.getColumnIndex(COL_VALUE)));
      c.close();

      // Update
      ContentValues update = new ContentValues();
      update.put(COL_NAME, "b");
      update.put(COL_VALUE, 20);
      int updated = db.update(TABLE, update, COL_ID + " = ?", new String[]{"1"});
      assertEquals(1, updated);

      // Query after update
      c = db.query(TABLE, null, COL_ID + " = ?", new String[]{"1"}, null);
      assertNotNull(c);
      assertEquals(1, c.getCount());
      assertTrue(c.moveToFirst());
      assertEquals("b", c.getString(c.getColumnIndex(COL_NAME)));
      assertEquals(20, c.getInt(c.getColumnIndex(COL_VALUE)));
      c.close();

      // Delete
      int deleted = db.delete(TABLE, COL_ID + " = ?", new String[]{"1"});
      assertEquals(1, deleted);

      // Query empty
      c = db.query(TABLE, null, null, null, null);
      assertNotNull(c);
      assertEquals(0, c.getCount());
      c.close();
    } finally {
      db.close();
    }
  }

  @Test
  public void rawQuery_returnsResult() {
    MSQLiteBuilder builder = new MSQLiteBuilder()
        .version(DB_VERSION)
        .createTable(TABLE)
        .insertColumn(TABLE, COL_NAME, String.class);

    EhDatabase db = new EhDatabase(
        RuntimeEnvironment.getApplication(),
        "eh_db_raw_test.db",
        DB_VERSION,
        builder);

    try {
      ContentValues row = new ContentValues();
      row.put(COL_ID, 1);
      row.put(COL_NAME, "x");
      db.insert(TABLE, null, row);

      Cursor c = db.rawQuery("SELECT * FROM " + TABLE + " WHERE " + COL_ID + " = ?", new String[]{"1"});
      assertNotNull(c);
      assertEquals(1, c.getCount());
      assertTrue(c.moveToFirst());
      assertEquals("x", c.getString(c.getColumnIndex(COL_NAME)));
      c.close();
    } finally {
      db.close();
    }
  }
}
