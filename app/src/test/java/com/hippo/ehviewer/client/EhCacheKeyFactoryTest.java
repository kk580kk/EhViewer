/*
 * Copyright 2016 Hippo Seven
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.hippo.ehviewer.client;

import static org.junit.Assert.assertEquals;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class EhCacheKeyFactoryTest {

  @Test
  public void getThumbKey_format() {
    assertEquals("preview:large:123:0", EhCacheKeyFactory.getThumbKey(123L));
    assertEquals("preview:large:0:0", EhCacheKeyFactory.getThumbKey(0L));
  }

  @Test
  public void getNormalPreviewKey_format() {
    assertEquals("preview:normal:100:5", EhCacheKeyFactory.getNormalPreviewKey(100L, 5));
    assertEquals("preview:normal:0:0", EhCacheKeyFactory.getNormalPreviewKey(0L, 0));
  }

  @Test
  public void getLargePreviewKey_format() {
    assertEquals("preview:large:200:3", EhCacheKeyFactory.getLargePreviewKey(200L, 3));
    assertEquals("preview:large:123:0", EhCacheKeyFactory.getLargePreviewKey(123L, 0));
  }

  @Test
  public void getThumbKey_sameAsLargePreviewKeyAtIndexZero() {
    long gid = 456L;
    assertEquals(EhCacheKeyFactory.getLargePreviewKey(gid, 0), EhCacheKeyFactory.getThumbKey(gid));
  }

  @Test
  public void getLargePreviewSetKey_format() {
    assertEquals("large_preview_set:300:2", EhCacheKeyFactory.getLargePreviewSetKey(300L, 2));
    assertEquals("large_preview_set:0:0", EhCacheKeyFactory.getLargePreviewSetKey(0L, 0));
  }

  @Test
  public void getImageKey_format() {
    assertEquals("image:500:7", EhCacheKeyFactory.getImageKey(500L, 7));
    assertEquals("image:0:0", EhCacheKeyFactory.getImageKey(0L, 0));
  }
}
