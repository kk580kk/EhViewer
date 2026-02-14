package com.hippo.ehviewer.client.exception;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class OffensiveExceptionTest {

  @Test
  public void defaultConstructor() {
    OffensiveException e = new OffensiveException();
    assertEquals("OFFENSIVE", e.getMessage());
    assertNull(e.getCause());
  }

  @Test
  public void messageConstructor() {
    String msg = "敏感内容";
    OffensiveException e = new OffensiveException(msg);
    assertEquals(msg, e.getMessage());
    assertNull(e.getCause());
  }

  @Test
  public void isInstanceOfEhException() {
    OffensiveException e = new OffensiveException();
    assertTrue(e instanceof EhException);
  }
}
