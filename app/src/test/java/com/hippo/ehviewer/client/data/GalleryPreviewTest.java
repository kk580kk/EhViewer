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
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class GalleryPreviewTest {

  @Test
  public void getPosition_returnsPosition() {
    GalleryPreview preview = new GalleryPreview();
    preview.position = 3;
    assertEquals(3, preview.getPosition());
  }

  @Test
  public void parcelRoundTrip_preservesFieldsAndRestoresImageKey() {
    GalleryPreview src = new GalleryPreview();
    src.imageKey = "path/to/key.jpg";
    src.imageUrl = "https://example.com/path/to/key.jpg";
    src.pageUrl = "https://example.com/page/1";
    src.position = 2;
    src.offsetX = 10;
    src.offsetY = 20;
    src.clipWidth = 100;
    src.clipHeight = 150;

    Parcel parcel = Parcel.obtain();
    src.writeToParcel(parcel, 0);
    parcel.setDataPosition(0);

    GalleryPreview dst = GalleryPreview.CREATOR.createFromParcel(parcel);
    parcel.recycle();

    assertEquals("path/to/key.jpg", dst.imageKey);
    assertEquals(src.imageUrl, dst.imageUrl);
    assertEquals(src.pageUrl, dst.pageUrl);
    assertEquals(src.position, dst.position);
    assertEquals(src.offsetX, dst.offsetX);
    assertEquals(src.offsetY, dst.offsetY);
    assertEquals(src.clipWidth, dst.clipWidth);
    assertEquals(src.clipHeight, dst.clipHeight);
  }

  @Test
  public void parcelRoundTrip_imageKeyDerivedFromImageUrlWhenNoSlash() {
    GalleryPreview src = new GalleryPreview();
    src.imageUrl = "simplekey";
    src.pageUrl = "https://page";
    src.position = 0;

    Parcel parcel = Parcel.obtain();
    src.writeToParcel(parcel, 0);
    parcel.setDataPosition(0);

    GalleryPreview dst = GalleryPreview.CREATOR.createFromParcel(parcel);
    parcel.recycle();

    assertEquals("simplekey", dst.imageKey);
  }
}
