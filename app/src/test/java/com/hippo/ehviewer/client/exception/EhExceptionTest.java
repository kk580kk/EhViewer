package com.hippo.ehviewer.client.exception;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertSame;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class EhExceptionTest {

  @Test
  public void noArgConstructor() {
    EhException e = new EhException();
    assertNull(e.getMessage());
    assertNull(e.getCause());
  }

  @Test
  public void messageConstructor() {
    String msg = "Sad Panda";
    EhException e = new EhException(msg);
    assertEquals(msg, e.getMessage());
    assertNull(e.getCause());
  }

  @Test
  public void messageAndCauseConstructor() {
    String msg = "wrapped";
    Throwable cause = new RuntimeException("root");
    EhException e = new EhException(msg, cause);
    assertEquals(msg, e.getMessage());
    assertSame(cause, e.getCause());
  }

  @Test
  public void causeOnlyConstructor() {
    Throwable cause = new RuntimeException("root");
    EhException e = new EhException(cause);
    assertSame(cause, e.getCause());
    assertEquals(cause.toString(), e.getMessage());
  }
}
