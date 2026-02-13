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
public class CancelledExceptionTest {

  @Test
  public void noArgConstructor_setsCanceledMessage() {
    CancelledException e = new CancelledException();
    assertEquals("CANCELED", e.getMessage());
    assertNull(e.getCause());
  }

  @Test
  public void isInstanceOfException() {
    CancelledException e = new CancelledException();
    assertTrue(e instanceof Exception);
  }

  @Test
  public void isNotInstanceOfEhException() {
    CancelledException e = new CancelledException();
    assertTrue(!(e instanceof EhException));
  }
}
