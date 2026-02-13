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
public class NoHAtHClientExceptionTest {

  @Test
  public void noArgConstructor() {
    NoHAtHClientException e = new NoHAtHClientException();
    assertEquals("No H@H client", e.getMessage());
    assertNull(e.getCause());
  }

  @Test
  public void messageConstructor() {
    String msg = "Custom no H@H client message";
    NoHAtHClientException e = new NoHAtHClientException(msg);
    assertEquals(msg, e.getMessage());
    assertNull(e.getCause());
  }

  @Test
  public void isInstanceOfEhException() {
    NoHAtHClientException e = new NoHAtHClientException();
    assertTrue(e instanceof EhException);
  }
}
