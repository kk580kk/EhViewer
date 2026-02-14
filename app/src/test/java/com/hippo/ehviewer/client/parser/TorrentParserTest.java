package com.hippo.ehviewer.client.parser;

import static org.junit.Assert.assertEquals;

import android.util.Pair;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class TorrentParserTest {

  @Test
  public void testParse() {
    String body = "<table><tr>"
        + "<td colspan=\"5\"> &nbsp; <a href=\"https://ehtracker.org/get/123456/aabbcc.torrent?p=12345\" "
        + "onclick=\"document.location='https://ehtracker.org/get/123456/aabbcc.torrent?p=12345'; return false\">"
        + "Test Torrent Name</a></td>"
        + "</tr></table>";

    Pair<String, String>[] result = TorrentParser.parse(body);
    assertEquals(1, result.length);
    assertEquals("https://ehtracker.org/get/123456/aabbcc.torrent", result[0].first);
    assertEquals("Test Torrent Name", result[0].second);
  }

  @Test
  public void testParseMultiple() {
    String body = "<table>"
        + "<tr><td colspan=\"5\"> &nbsp; <a href=\"https://ehtracker.org/get/1/a.torrent\" "
        + "onclick=\"\">Torrent A</a></td></tr>"
        + "<tr><td colspan=\"5\"> &nbsp; <a href=\"https://ehtracker.org/get/2/b.torrent\" "
        + "onclick=\"\">Torrent B</a></td></tr>"
        + "</table>";

    Pair<String, String>[] result = TorrentParser.parse(body);
    assertEquals(2, result.length);
    assertEquals("Torrent A", result[0].second);
    assertEquals("Torrent B", result[1].second);
  }

  @Test
  public void testParseEmpty() {
    Pair<String, String>[] result = TorrentParser.parse("<html></html>");
    assertEquals(0, result.length);
  }
}
