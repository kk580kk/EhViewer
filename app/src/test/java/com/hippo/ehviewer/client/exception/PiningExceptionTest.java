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
public class PiningExceptionTest {

  @Test
  public void defaultConstructor() {
    PiningException e = new PiningException();
    assertEquals("pining for the fjords", e.getMessage());
    assertNull(e.getCause());
  }

  @Test
  public void messageConstructor() {
    String msg = "Gallery removed";
    PiningException e = new PiningException(msg);
    assertEquals(msg, e.getMessage());
    assertNull(e.getCause());
  }

  @Test
  public void isInstanceOfEhException() {
    PiningException e = new PiningException();
    assertTrue(e instanceof EhException);
  }
}
