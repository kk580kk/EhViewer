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

package com.hippo.ehviewer.client.data;

import android.os.Parcel;
import com.hippo.ehviewer.client.EhCacheKeyFactory;
import static org.junit.Assert.assertEquals;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class LargePreviewSetTest {

  private LargePreviewSet previewSet;

  @Before
  public void setUp() {
    previewSet = new LargePreviewSet();
  }

  @Test
  public void size_emptyInitially() {
    assertEquals(0, previewSet.size());
  }

  @Test
  public void addItem_increasesSizeAndReturnsCorrectValues() {
    previewSet.addItem(0, "https://ex.org/large0.jpg", "https://ex.org/s/1");
    assertEquals(1, previewSet.size());
    assertEquals(0, previewSet.getPosition(0));
    assertEquals("https://ex.org/s/1", previewSet.getPageUrlAt(0));

    long gid = 12345L;
    GalleryPreview p = previewSet.getGalleryPreview(gid, 0);
    assertEquals(0, p.position);
    assertEquals(EhCacheKeyFactory.getLargePreviewKey(gid, 0), p.imageKey);
    assertEquals("https://ex.org/large0.jpg", p.imageUrl);
    assertEquals("https://ex.org/s/1", p.pageUrl);
  }

  @Test
  public void addItem_multipleItems() {
    previewSet.addItem(0, "https://ex.org/large0.jpg", "https://ex.org/p/1");
    previewSet.addItem(1, "https://ex.org/large1.jpg", "https://ex.org/p/2");
    assertEquals(2, previewSet.size());
    assertEquals(0, previewSet.getPosition(0));
    assertEquals(1, previewSet.getPosition(1));
    assertEquals("https://ex.org/large0.jpg", previewSet.getGalleryPreview(0L, 0).imageUrl);
    assertEquals("https://ex.org/large1.jpg", previewSet.getGalleryPreview(0L, 1).imageUrl);
  }

  @Test
  public void parcelRoundTrip_preservesData() {
    previewSet.addItem(0, "https://ex.org/large0.jpg", "https://ex.org/s/1");
    previewSet.addItem(1, "https://ex.org/large1.jpg", "https://ex.org/s/2");

    Parcel parcel = Parcel.obtain();
    previewSet.writeToParcel(parcel, 0);
    parcel.setDataPosition(0);

    LargePreviewSet restored = LargePreviewSet.CREATOR.createFromParcel(parcel);
    parcel.recycle();

    assertEquals(2, restored.size());
    assertEquals(0, restored.getPosition(0));
    assertEquals(1, restored.getPosition(1));
    assertEquals("https://ex.org/s/1", restored.getPageUrlAt(0));
    assertEquals("https://ex.org/s/2", restored.getPageUrlAt(1));
    long gid = 999L;
    assertEquals(EhCacheKeyFactory.getLargePreviewKey(gid, 0), restored.getGalleryPreview(gid, 0).imageKey);
    assertEquals("https://ex.org/large0.jpg", restored.getGalleryPreview(gid, 0).imageUrl);
  }
}
