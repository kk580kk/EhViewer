package com.hippo.ehviewer.client.data;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

import android.os.Parcel;
import org.json.JSONException;
import org.json.JSONObject;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class GalleryApiInfoTest {

  @Test
  public void fromJson_fullPayload() throws JSONException {
    String json = "{"
        + "\"gid\":12345,"
        + "\"token\":\"abcdef1234\","
        + "\"archiver_key\":\"archkey\","
        + "\"title\":\"Test Gallery\","
        + "\"title_jpn\":\"テストギャラリー\","
        + "\"category\":\"Doujinshi\","
        + "\"thumb\":\"https://ehgt.org/ab/cd/thumb.jpg\","
        + "\"uploader\":\"testuser\","
        + "\"posted\":\"1550000000\","
        + "\"filecount\":\"25\","
        + "\"filesize\":\"12345678\","
        + "\"expunged\":false,"
        + "\"rating\":\"4.25\","
        + "\"torrentcount\":\"3\","
        + "\"tags\":[\"language:japanese\",\"parody:original\"]"
        + "}";

    GalleryApiInfo info = GalleryApiInfo.fromJson(new JSONObject(json));

    assertEquals(12345L, info.gid);
    assertEquals("abcdef1234", info.token);
    assertEquals("archkey", info.archiverKey);
    assertEquals("Test Gallery", info.title);
    assertEquals("テストギャラリー", info.titleJpn);
    assertEquals("https://ehgt.org/ab/cd/thumb.jpg", info.thumb);
    assertEquals("testuser", info.uploader);
    assertEquals(1550000000L, info.posted);
    assertEquals(25, info.filecount);
    assertEquals(12345678L, info.filesize);
    assertFalse(info.expunged);
    assertEquals(4.25f, info.rating, 0.001f);
    assertEquals(3, info.torrentcount);
    assertNotNull(info.tags);
    assertEquals(2, info.tags.length);
    assertEquals("language:japanese", info.tags[0]);
    assertEquals("parody:original", info.tags[1]);
  }

  @Test
  public void fromJson_minimalPayload() throws JSONException {
    String json = "{\"gid\":1}";

    GalleryApiInfo info = GalleryApiInfo.fromJson(new JSONObject(json));

    assertEquals(1L, info.gid);
    assertEquals("", info.title);
    assertEquals("", info.titleJpn);
    assertEquals(0, info.filecount);
    assertEquals(0L, info.filesize);
    assertFalse(info.expunged);
    assertEquals(0.0f, info.rating, 0f);
    assertEquals(0, info.torrentcount);
    assertNull(info.tags);
  }

  @Test
  public void fromJson_expungedAndOptionalFields() throws JSONException {
    String json = "{"
        + "\"gid\":99,"
        + "\"expunged\":true,"
        + "\"rating\":\"3.5\","
        + "\"tags\":[]"
        + "}";

    GalleryApiInfo info = GalleryApiInfo.fromJson(new JSONObject(json));

    assertEquals(99L, info.gid);
    assertTrue(info.expunged);
    assertEquals(3.5f, info.rating, 0.001f);
    assertNotNull(info.tags);
    assertEquals(0, info.tags.length);
  }

  @Test
  public void parcelRoundTrip_preservesAllFields() throws JSONException {
    String json = "{"
        + "\"gid\":1000,"
        + "\"token\":\"tk\","
        + "\"archiver_key\":\"arch\","
        + "\"title\":\"Title\","
        + "\"title_jpn\":\"タイトル\","
        + "\"category\":\"Manga\","
        + "\"thumb\":\"https://thumb\","
        + "\"uploader\":\"up\","
        + "\"posted\":\"1600000000\","
        + "\"filecount\":\"42\","
        + "\"filesize\":\"999\","
        + "\"expunged\":true,"
        + "\"rating\":\"4.5\","
        + "\"torrentcount\":\"2\","
        + "\"tags\":[\"a\",\"b\"]"
        + "}";
    GalleryApiInfo src = GalleryApiInfo.fromJson(new JSONObject(json));

    Parcel parcel = Parcel.obtain();
    src.writeToParcel(parcel, 0);
    parcel.setDataPosition(0);

    GalleryApiInfo dst = GalleryApiInfo.CREATOR.createFromParcel(parcel);
    parcel.recycle();

    assertEquals(src.gid, dst.gid);
    assertEquals(src.token, dst.token);
    assertEquals(src.archiverKey, dst.archiverKey);
    assertEquals(src.title, dst.title);
    assertEquals(src.titleJpn, dst.titleJpn);
    assertEquals(src.category, dst.category);
    assertEquals(src.thumb, dst.thumb);
    assertEquals(src.uploader, dst.uploader);
    assertEquals(src.posted, dst.posted);
    assertEquals(src.filecount, dst.filecount);
    assertEquals(src.filesize, dst.filesize);
    assertEquals(src.expunged, dst.expunged);
    assertEquals(src.rating, dst.rating, 0f);
    assertEquals(src.torrentcount, dst.torrentcount);
    assertNotNull(dst.tags);
    assertEquals(2, dst.tags.length);
    assertEquals("a", dst.tags[0]);
    assertEquals("b", dst.tags[1]);
  }
}
