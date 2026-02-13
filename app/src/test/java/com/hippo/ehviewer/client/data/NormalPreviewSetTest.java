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
import static org.junit.Assert.assertEquals;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class NormalPreviewSetTest {

  private NormalPreviewSet previewSet;

  @Before
  public void setUp() {
    previewSet = new NormalPreviewSet();
  }

  @Test
  public void size_emptyInitially() {
    assertEquals(0, previewSet.size());
  }

  @Test
  public void addItem_increasesSizeAndReturnsCorrectValues() {
    previewSet.addItem(0, "https://ex.org/t/ab/cd/abcd.jpg", 5, 10, 100, 200, "https://ex.org/s/1");
    assertEquals(1, previewSet.size());
    assertEquals(0, previewSet.getPosition(0));
    assertEquals("https://ex.org/s/1", previewSet.getPageUrlAt(0));

    GalleryPreview p = previewSet.getGalleryPreview(999L, 0);
    assertEquals(0, p.position);
    assertEquals("t/ab/cd/abcd.jpg", p.imageKey);
    assertEquals("https://ex.org/t/ab/cd/abcd.jpg", p.imageUrl);
    assertEquals(5, p.offsetX);
    assertEquals(10, p.offsetY);
    assertEquals(100, p.clipWidth);
    assertEquals(200, p.clipHeight);
  }

  @Test
  public void addItem_multipleItems() {
    previewSet.addItem(0, "https://ex.org/img0.jpg", 0, 0, 50, 50, "https://ex.org/p/1");
    previewSet.addItem(1, "https://ex.org/img1.jpg", 10, 20, 60, 70, "https://ex.org/p/2");
    assertEquals(2, previewSet.size());
    assertEquals(0, previewSet.getPosition(0));
    assertEquals(1, previewSet.getPosition(1));
    assertEquals("https://ex.org/img0.jpg", previewSet.getGalleryPreview(0L, 0).imageUrl);
    assertEquals("https://ex.org/img1.jpg", previewSet.getGalleryPreview(0L, 1).imageUrl);
  }

  @Test
  public void parcelRoundTrip_preservesData() {
    previewSet.addItem(0, "https://ex.org/t/ab/cd/abcd.jpg", 5, 10, 100, 200, "https://ex.org/s/1");
    previewSet.addItem(1, "https://ex.org/other.jpg", 0, 0, 80, 90, "https://ex.org/s/2");

    Parcel parcel = Parcel.obtain();
    previewSet.writeToParcel(parcel, 0);
    parcel.setDataPosition(0);

    NormalPreviewSet restored = NormalPreviewSet.CREATOR.createFromParcel(parcel);
    parcel.recycle();

    assertEquals(2, restored.size());
    assertEquals(0, restored.getPosition(0));
    assertEquals(1, restored.getPosition(1));
    assertEquals("https://ex.org/s/1", restored.getPageUrlAt(0));
    assertEquals("https://ex.org/s/2", restored.getPageUrlAt(1));
    GalleryPreview p0 = restored.getGalleryPreview(100L, 0);
    assertEquals("t/ab/cd/abcd.jpg", p0.imageKey);
    assertEquals(5, p0.offsetX);
    assertEquals(10, p0.offsetY);
    assertEquals(100, p0.clipWidth);
    assertEquals(200, p0.clipHeight);
  }
}
