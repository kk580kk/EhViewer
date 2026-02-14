package com.hippo.ehviewer.client.parser;

import static org.junit.Assert.assertEquals;

import android.util.Pair;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class ArchiveParserTest {

  @Test
  public void testParse() {
    String body = "<form id=\"hathdl_form\" action=\"https://e-hentai.org/archiver.php?gid=123&token=abc&or=testOrParam\" method=\"post\">"
        + "<a href=\"#\" onclick=\"return do_hathdl('org')\">Original</a>"
        + "<a href=\"#\" onclick=\"return do_hathdl('780x')\">780x Resample</a>"
        + "</form>";

    Pair<String, Pair<String, String>[]> result = ArchiveParser.parse(body);
    assertEquals("testOrParam", result.first);
    assertEquals(2, result.second.length);
    assertEquals("org", result.second[0].first);
    assertEquals("Original", result.second[0].second);
    assertEquals("780x", result.second[1].first);
    assertEquals("780x Resample", result.second[1].second);
  }

  @Test
  public void testParseNoForm() {
    Pair<String, Pair<String, String>[]> result = ArchiveParser.parse("<html></html>");
    assertEquals("", result.first);
    assertEquals(0, result.second.length);
  }
}
