package com.hippo.ehviewer.client.exception;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertSame;
import static org.junit.Assert.assertTrue;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class ParseExceptionTest {

  @Test
  public void messageAndBodyConstructor() {
    String msg = "Parse error";
    String body = "<html>invalid</html>";
    ParseException e = new ParseException(msg, body);
    assertEquals(msg, e.getMessage());
    assertEquals(body, e.getBody());
    assertNull(e.getCause());
  }

  @Test
  public void messageBodyAndCauseConstructor() {
    String msg = "Parse error";
    String body = "<html>invalid</html>";
    Throwable cause = new RuntimeException("root");
    ParseException e = new ParseException(msg, body, cause);
    assertEquals(msg, e.getMessage());
    assertEquals(body, e.getBody());
    assertSame(cause, e.getCause());
  }

  @Test
  public void isInstanceOfEhException() {
    ParseException e = new ParseException("msg", "body");
    assertTrue(e instanceof EhException);
  }

  @Test
  public void getBodyReturnsNullWhenBodyNotProvided() {
    ParseException e = new ParseException("error", null);
    assertNull(e.getBody());
  }
}
