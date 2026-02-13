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
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;

import android.os.Bundle;
import com.hippo.ehviewer.ui.scene.GalleryDetailScene;
import com.hippo.ehviewer.ui.scene.GalleryListScene;
import com.hippo.ehviewer.ui.scene.ProgressScene;
import com.hippo.scene.Announcer;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class EhUrlOpenerTest {

  @Test
  public void parseUrl_listUrl_returnsGalleryListSceneAnnouncer() {
    Announcer a = EhUrlOpener.parseUrl("https://e-hentai.org/");
    assertNotNull(a);
    assertEquals(GalleryListScene.class, a.getClazz());
    Bundle args = a.getArgs();
    assertNotNull(args);
    assertNotNull(args.getParcelable(GalleryListScene.KEY_LIST_URL_BUILDER));
  }

  @Test
  public void parseUrl_detailUrl_returnsGalleryDetailSceneAnnouncer() {
    Announcer a = EhUrlOpener.parseUrl("https://e-hentai.org/g/530350/8b3c7e4a21/");
    assertNotNull(a);
    assertEquals(GalleryDetailScene.class, a.getClazz());
    Bundle args = a.getArgs();
    assertNotNull(args);
    assertEquals(530350L, args.getLong(GalleryDetailScene.KEY_GID));
    assertEquals("8b3c7e4a21", args.getString(GalleryDetailScene.KEY_TOKEN));
  }

  @Test
  public void parseUrl_pageUrl_returnsProgressSceneAnnouncer() {
    Announcer a = EhUrlOpener.parseUrl("https://e-hentai.org/s/7b87643838/530350-1");
    assertNotNull(a);
    assertEquals(ProgressScene.class, a.getClazz());
    Bundle args = a.getArgs();
    assertNotNull(args);
    assertEquals(530350L, args.getLong(ProgressScene.KEY_GID));
    assertEquals("7b87643838", args.getString(ProgressScene.KEY_PTOKEN));
    assertEquals(0, args.getInt(ProgressScene.KEY_PAGE));
  }

  @Test
  public void parseUrl_empty_returnsNull() {
    assertNull(EhUrlOpener.parseUrl(""));
    assertNull(EhUrlOpener.parseUrl(null));
  }

  @Test
  public void parseUrl_externalUrl_returnsNull() {
    assertNull(EhUrlOpener.parseUrl("https://example.com/"));
    assertNull(EhUrlOpener.parseUrl("https://forums.e-hentai.org/index.php"));
  }

  @Test
  public void parseUrl_invalidUrl_returnsNull() {
    assertNull(EhUrlOpener.parseUrl("not a url"));
  }
}
