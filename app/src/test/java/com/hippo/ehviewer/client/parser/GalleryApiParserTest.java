package com.hippo.ehviewer.client.parser;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;

import com.hippo.ehviewer.client.data.GalleryInfo;
import java.util.ArrayList;
import java.util.List;
import org.json.JSONException;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class GalleryApiParserTest {

  @Test
  public void testParse() throws JSONException {
    String body = "{\"gmetadata\":[{"
        + "\"gid\":12345,"
        + "\"token\":\"abcdef1234\","
        + "\"title\":\"Test Gallery\","
        + "\"title_jpn\":\"テストギャラリー\","
        + "\"category\":\"Doujinshi\","
        + "\"thumb\":\"https://ehgt.org/ab/cd/thumb.jpg\","
        + "\"uploader\":\"testuser\","
        + "\"posted\":\"1550000000\","
        + "\"rating\":\"4.25\","
        + "\"tags\":[\"language:japanese\",\"parody:original\"],"
        + "\"filecount\":\"25\""
        + "}]}";

    List<GalleryInfo> list = new ArrayList<>();
    GalleryInfo gi = new GalleryInfo();
    gi.gid = 12345;
    list.add(gi);

    GalleryApiParser.parse(body, list);

    assertEquals("Test Gallery", gi.title);
    assertEquals("テストギャラリー", gi.titleJpn);
    assertEquals("testuser", gi.uploader);
    assertEquals(4.25f, gi.rating, 0.001f);
    assertNotNull(gi.simpleTags);
    assertEquals(2, gi.simpleTags.length);
    assertEquals("language:japanese", gi.simpleTags[0]);
    assertEquals(25, gi.pages);
    assertEquals(GalleryInfo.S_LANG_JA, gi.simpleLanguage);
  }

  @Test
  public void testParseUnmatchedGid() throws JSONException {
    String body = "{\"gmetadata\":[{"
        + "\"gid\":99999,"
        + "\"token\":\"abcdef1234\","
        + "\"title\":\"Other Gallery\","
        + "\"title_jpn\":\"\","
        + "\"category\":\"Manga\","
        + "\"thumb\":\"https://ehgt.org/thumb.jpg\","
        + "\"uploader\":\"other\","
        + "\"posted\":\"1550000000\","
        + "\"rating\":\"3.0\","
        + "\"tags\":[],"
        + "\"filecount\":\"10\""
        + "}]}";

    List<GalleryInfo> list = new ArrayList<>();
    GalleryInfo gi = new GalleryInfo();
    gi.gid = 12345;
    list.add(gi);

    GalleryApiParser.parse(body, list);
    // Title should remain unchanged since gid doesn't match
    assertEquals(null, gi.title);
  }
}
