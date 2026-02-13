package com.hippo.ehviewer.client.parser;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.fail;

import com.hippo.ehviewer.client.exception.EhException;
import com.hippo.ehviewer.client.exception.ParseException;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class SignInParserTest {

  @Test
  public void testParseSuccess() throws Exception {
    String body = "<p>You are now logged in as: TestUser<br />";
    String name = SignInParser.parse(body);
    assertEquals("TestUser", name);
  }

  @Test
  public void testParseSuccessTrimsName() throws Exception {
    String body = "<p>You are now logged in as:  SomeUser  <br />";
    String name = SignInParser.parse(body);
    assertEquals("SomeUser", name);
  }

  @Test(expected = EhException.class)
  public void testParseErrorH4() throws Exception {
    String body = "<h4>The error returned was:</h4>\n<p>Username or password incorrect</p>";
    SignInParser.parse(body);
  }

  @Test
  public void testParseErrorH4Message() throws ParseException {
    String body = "<h4>The error returned was:</h4>\n<p>Username or password incorrect</p>";
    try {
      SignInParser.parse(body);
      fail("Expected EhException");
    } catch (EhException e) {
      assertEquals("Username or password incorrect", e.getMessage());
    }
  }

  @Test(expected = EhException.class)
  public void testParseErrorSpan() throws Exception {
    String body = "<span class=\"postcolor\">The captcha was wrong</span>";
    SignInParser.parse(body);
  }

  @Test
  public void testParseErrorSpanMessage() throws ParseException {
    String body = "<span class=\"postcolor\">The captcha was wrong</span>";
    try {
      SignInParser.parse(body);
      fail("Expected EhException");
    } catch (EhException e) {
      assertEquals("The captcha was wrong", e.getMessage());
    }
  }

  @Test(expected = ParseException.class)
  public void testParseUnknownBody() throws Exception {
    SignInParser.parse("<html><body>Unknown page</body></html>");
  }

  @Test(expected = ParseException.class)
  public void testParseEmptyBody() throws Exception {
    SignInParser.parse("");
  }

  @Test(expected = ParseException.class)
  public void testParseNullBody() throws Exception {
    SignInParser.parse(null);
  }
}
