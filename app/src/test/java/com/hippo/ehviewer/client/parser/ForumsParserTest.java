package com.hippo.ehviewer.client.parser;

import static org.junit.Assert.assertEquals;

import com.hippo.ehviewer.client.exception.ParseException;
import java.io.InputStream;
import okio.BufferedSource;
import okio.Okio;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class ForumsParserTest {

  @Test
  public void testParse() throws Exception {
    InputStream resource = ForumsParserTest.class.getResourceAsStream("ForumsParserTest.html");
    BufferedSource source = Okio.buffer(Okio.source(resource));
    String body = source.readUtf8();

    String profileUrl = ForumsParser.parse(body);
    assertEquals("https://forums.e-hentai.org/index.php?showuser=12345", profileUrl);
  }

  @Test(expected = ParseException.class)
  public void testParseInvalid() throws Exception {
    ForumsParser.parse("<html></html>");
  }
}
