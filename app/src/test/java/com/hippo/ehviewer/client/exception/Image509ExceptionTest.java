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
public class Image509ExceptionTest {

  @Test
  public void noArgConstructor() {
    Image509Exception e = new Image509Exception();
    assertEquals("509", e.getMessage());
    assertNull(e.getCause());
  }

  @Test
  public void isInstanceOfEhException() {
    Image509Exception e = new Image509Exception();
    assertTrue(e instanceof EhException);
  }
}
