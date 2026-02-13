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

package com.hippo.ehviewer.client.parser;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;

import com.hippo.ehviewer.client.exception.EhException;
import com.hippo.ehviewer.client.exception.ParseException;
import java.io.InputStream;
import okio.BufferedSource;
import okio.Okio;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class FavoritesParserTest {

  private static final String FIXTURE = "GalleryListParserTestEMinimal.html";

  @Test
  public void testParse() throws Exception {
    InputStream resource = FavoritesParserTest.class.getResourceAsStream(FIXTURE);
    BufferedSource source = Okio.buffer(Okio.source(resource));
    String body = source.readUtf8();

    FavoritesParser.Result result = FavoritesParser.parse(body);

    assertEquals(10, result.catArray.length);
    assertEquals(10, result.countArray.length);
    for (int i = 0; i < 10; i++) {
      assertEquals(i + 1, result.countArray[i]);
      assertEquals("Favorites " + i, result.catArray[i]);
    }
    assertNotNull(result.galleryInfoList);
    assertEquals(25, result.galleryInfoList.size());
    assertEquals(1928, result.pages);
    assertEquals(1, result.nextPage);
  }

  @Test(expected = EhException.class)
  public void testParseNeedSignIn() throws Exception {
    String body = "<p>This page requires you to log on.</p>";
    FavoritesParser.parse(body);
  }

  @Test(expected = ParseException.class)
  public void testParseInvalidFavoritesBlock() throws Exception {
    String body = "<html><body><div class=\"ido\"></div></body></html>";
    FavoritesParser.parse(body);
  }
}
