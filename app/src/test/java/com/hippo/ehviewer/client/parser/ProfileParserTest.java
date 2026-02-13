package com.hippo.ehviewer.client.parser;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;

import com.hippo.ehviewer.client.EhUrl;
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
public class ProfileParserTest {

  @Test
  public void testParse() throws Exception {
    InputStream resource = ProfileParserTest.class.getResourceAsStream("ProfileParserTest.html");
    BufferedSource source = Okio.buffer(Okio.source(resource));
    String body = source.readUtf8();

    ProfileParser.Result result = ProfileParser.parse(body);
    assertEquals("TestDisplayName", result.displayName);
    assertEquals("https://forums.e-hentai.org/uploads/avatar_12345.png", result.avatar);
  }

  @Test
  public void testParseNoAvatar() throws Exception {
    String body = "<html><body><div id=\"profilename\"><span>UserOnly</span></div></body></html>";
    ProfileParser.Result result = ProfileParser.parse(body);
    assertEquals("UserOnly", result.displayName);
    assertNull(result.avatar);
  }

  @Test
  public void testParseRelativeAvatar() throws Exception {
    String body = "<html><body><div id=\"profilename\">"
        + "<span>RelativeUser</span><div><img src=\"uploads/avatar.png\" /></div>"
        + "</div></body></html>";
    ProfileParser.Result result = ProfileParser.parse(body);
    assertEquals("RelativeUser", result.displayName);
    assertEquals(EhUrl.URL_FORUMS + "uploads/avatar.png", result.avatar);
  }

  @Test(expected = ParseException.class)
  public void testParseInvalid() throws Exception {
    ProfileParser.parse("<html></html>");
  }
}
