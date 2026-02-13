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
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import com.hippo.ehviewer.EhDB;
import com.hippo.ehviewer.client.data.GalleryInfo;
import com.hippo.ehviewer.dao.Filter;
import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.List;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class EhFilterTest {

  private static void resetEhFilterInstance() throws Exception {
    Field f = EhFilter.class.getDeclaredField("sInstance");
    f.setAccessible(true);
    f.set(null, null);
  }

  @Before
  public void setUp() throws Exception {
    EhDB.initialize(RuntimeEnvironment.getApplication());
    resetEhFilterInstance();
    EhFilter ef = EhFilter.getInstance();
    clearAllFilters(ef);
    resetEhFilterInstance();
  }

  private void clearAllFilters(EhFilter ef) {
    for (Filter f : new ArrayList<>(ef.getTitleFilterList())) {
      ef.deleteFilter(f);
    }
    for (Filter f : new ArrayList<>(ef.getUploaderFilterList())) {
      ef.deleteFilter(f);
    }
    for (Filter f : new ArrayList<>(ef.getTagFilterList())) {
      ef.deleteFilter(f);
    }
    for (Filter f : new ArrayList<>(ef.getTagNamespaceFilterList())) {
      ef.deleteFilter(f);
    }
  }

  @Test
  public void addFilter_persistsAndAppearsInList() throws Exception {
    EhFilter ef = EhFilter.getInstance();
    Filter f = new Filter();
    f.mode = EhFilter.MODE_TITLE;
    f.text = "Excluded";
    ef.addFilter(f);

    assertTrue(ef.getTitleFilterList().size() >= 1);
    assertTrue(findFilterByText(ef.getTitleFilterList(), "excluded"));
  }

  @Test
  public void addFilter_persistsAcrossNewInstance() throws Exception {
    EhFilter ef = EhFilter.getInstance();
    Filter f = new Filter();
    f.mode = EhFilter.MODE_UPLOADER;
    f.text = "uploader1";
    ef.addFilter(f);
    resetEhFilterInstance();

    EhFilter ef2 = EhFilter.getInstance();
    assertTrue(ef2.getUploaderFilterList().size() >= 1);
    assertTrue(findFilterByText(ef2.getUploaderFilterList(), "uploader1"));
  }

  @Test
  public void deleteFilter_removesFromStorage() throws Exception {
    EhFilter ef = EhFilter.getInstance();
    Filter f = new Filter();
    f.mode = EhFilter.MODE_TITLE;
    f.text = "gone";
    ef.addFilter(f);
    List<Filter> list = ef.getTitleFilterList();
    Filter added = list.get(list.size() - 1);
    ef.deleteFilter(added);
    assertFalse(findFilterByText(ef.getTitleFilterList(), "gone"));

    resetEhFilterInstance();
    EhFilter ef2 = EhFilter.getInstance();
    assertFalse(findFilterByText(ef2.getTitleFilterList(), "gone"));
  }

  @Test
  public void triggerFilter_togglesEnable() {
    EhFilter ef = EhFilter.getInstance();
    Filter f = new Filter();
    f.mode = EhFilter.MODE_TAG;
    f.text = "artist:foo";
    ef.addFilter(f);
    List<Filter> list = ef.getTagFilterList();
    Filter added = list.get(list.size() - 1);
    assertTrue(added.enable);
    ef.triggerFilter(added);
    assertFalse(added.enable);
    ef.triggerFilter(added);
    assertTrue(added.enable);
  }

  @Test
  public void needTags_falseWhenNoTagFilters() {
    EhFilter ef = EhFilter.getInstance();
    assertFalse(ef.needTags());
  }

  @Test
  public void needTags_trueWhenTagFilterPresent() {
    EhFilter ef = EhFilter.getInstance();
    Filter f = new Filter();
    f.mode = EhFilter.MODE_TAG;
    f.text = "artist:bar";
    ef.addFilter(f);
    assertTrue(ef.needTags());
  }

  @Test
  public void needTags_trueWhenTagNamespaceFilterPresent() {
    EhFilter ef = EhFilter.getInstance();
    Filter f = new Filter();
    f.mode = EhFilter.MODE_TAG_NAMESPACE;
    f.text = "language";
    ef.addFilter(f);
    assertTrue(ef.needTags());
  }

  @Test
  public void filterTitle_passWhenNoMatch() {
    EhFilter ef = EhFilter.getInstance();
    Filter f = new Filter();
    f.mode = EhFilter.MODE_TITLE;
    f.text = "excluded";
    ef.addFilter(f);
    GalleryInfo info = new GalleryInfo();
    info.title = "Good Title";
    assertTrue(ef.filterTitle(info));
  }

  @Test
  public void filterTitle_failWhenTitleContainsFilterText() {
    EhFilter ef = EhFilter.getInstance();
    Filter f = new Filter();
    f.mode = EhFilter.MODE_TITLE;
    f.text = "excluded";
    ef.addFilter(f);
    GalleryInfo info = new GalleryInfo();
    info.title = "This is excluded content";
    assertFalse(ef.filterTitle(info));
  }

  @Test
  public void filterTitle_caseInsensitive() {
    EhFilter ef = EhFilter.getInstance();
    Filter f = new Filter();
    f.mode = EhFilter.MODE_TITLE;
    f.text = "EXCLUDED";
    ef.addFilter(f);
    GalleryInfo info = new GalleryInfo();
    info.title = "This is Excluded content";
    assertFalse(ef.filterTitle(info));
  }

  @Test
  public void filterTitle_returnsFalseForNullInfo() {
    EhFilter ef = EhFilter.getInstance();
    assertFalse(ef.filterTitle(null));
  }

  @Test
  public void filterUploader_passWhenNoMatch() {
    EhFilter ef = EhFilter.getInstance();
    Filter f = new Filter();
    f.mode = EhFilter.MODE_UPLOADER;
    f.text = "bad_uploader";
    ef.addFilter(f);
    GalleryInfo info = new GalleryInfo();
    info.uploader = "good_uploader";
    assertTrue(ef.filterUploader(info));
  }

  @Test
  public void filterUploader_failWhenExactMatch() {
    EhFilter ef = EhFilter.getInstance();
    Filter f = new Filter();
    f.mode = EhFilter.MODE_UPLOADER;
    f.text = "bad_uploader";
    ef.addFilter(f);
    GalleryInfo info = new GalleryInfo();
    info.uploader = "bad_uploader";
    assertFalse(ef.filterUploader(info));
  }

  @Test
  public void filterUploader_returnsFalseForNullInfo() {
    EhFilter ef = EhFilter.getInstance();
    assertFalse(ef.filterUploader(null));
  }

  @Test
  public void filterTag_passWhenNoMatch() {
    EhFilter ef = EhFilter.getInstance();
    Filter f = new Filter();
    f.mode = EhFilter.MODE_TAG;
    f.text = "artist:blocked";
    ef.addFilter(f);
    GalleryInfo info = new GalleryInfo();
    info.simpleTags = new String[]{"language:japanese", "artist:other"};
    assertTrue(ef.filterTag(info));
  }

  @Test
  public void filterTag_failWhenTagMatches() {
    EhFilter ef = EhFilter.getInstance();
    Filter f = new Filter();
    f.mode = EhFilter.MODE_TAG;
    f.text = "artist:blocked";
    ef.addFilter(f);
    GalleryInfo info = new GalleryInfo();
    info.simpleTags = new String[]{"language:japanese", "artist:blocked"};
    assertFalse(ef.filterTag(info));
  }

  @Test
  public void filterTag_returnsFalseForNullInfo() {
    EhFilter ef = EhFilter.getInstance();
    assertFalse(ef.filterTag(null));
  }

  @Test
  public void filterTagNamespace_passWhenNoMatch() {
    EhFilter ef = EhFilter.getInstance();
    Filter f = new Filter();
    f.mode = EhFilter.MODE_TAG_NAMESPACE;
    f.text = "blocked_ns";
    ef.addFilter(f);
    GalleryInfo info = new GalleryInfo();
    info.simpleTags = new String[]{"language:japanese", "artist:someone"};
    assertTrue(ef.filterTagNamespace(info));
  }

  @Test
  public void filterTagNamespace_failWhenNamespaceMatches() {
    EhFilter ef = EhFilter.getInstance();
    Filter f = new Filter();
    f.mode = EhFilter.MODE_TAG_NAMESPACE;
    f.text = "language";
    ef.addFilter(f);
    GalleryInfo info = new GalleryInfo();
    info.simpleTags = new String[]{"language:japanese"};
    assertFalse(ef.filterTagNamespace(info));
  }

  @Test
  public void filterTagNamespace_returnsFalseForNullInfo() {
    EhFilter ef = EhFilter.getInstance();
    assertFalse(ef.filterTagNamespace(null));
  }

  @Test
  public void disabledFilter_doesNotFilterTitle() {
    EhFilter ef = EhFilter.getInstance();
    Filter f = new Filter();
    f.mode = EhFilter.MODE_TITLE;
    f.text = "excluded";
    ef.addFilter(f);
    List<Filter> list = ef.getTitleFilterList();
    list.get(list.size() - 1).enable = false;
    GalleryInfo info = new GalleryInfo();
    info.title = "This is excluded content";
    assertTrue(ef.filterTitle(info));
  }

  private static boolean findFilterByText(List<Filter> list, String text) {
    for (Filter f : list) {
      if (text.equals(f.text)) {
        return true;
      }
    }
    return false;
  }
}
