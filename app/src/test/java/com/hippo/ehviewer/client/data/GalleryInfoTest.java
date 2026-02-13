package com.hippo.ehviewer.client.data;

import android.os.Parcel;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class GalleryInfoTest {

  @Test
  public void languageConstantsMatchLength() {
    assertEquals(GalleryInfo.S_LANGS.length, GalleryInfo.S_LANG_TAGS.length);
    assertEquals(GalleryInfo.S_LANGS.length, GalleryInfo.S_LANG_PATTERNS.length);
  }

  @Test
  public void generateSLangFromTag_japanese() {
    GalleryInfo gi = new GalleryInfo();
    gi.simpleTags = new String[]{"language:japanese", "artist:someone"};
    gi.generateSLang();
    assertEquals(GalleryInfo.S_LANG_JA, gi.simpleLanguage);
  }

  @Test
  public void generateSLangFromTag_english() {
    GalleryInfo gi = new GalleryInfo();
    gi.simpleTags = new String[]{"language:english"};
    gi.generateSLang();
    assertEquals(GalleryInfo.S_LANG_EN, gi.simpleLanguage);
  }

  @Test
  public void generateSLangFromTag_chinese() {
    GalleryInfo gi = new GalleryInfo();
    gi.simpleTags = new String[]{"language:chinese"};
    gi.generateSLang();
    assertEquals(GalleryInfo.S_LANG_ZH, gi.simpleLanguage);
  }

  @Test
  public void generateSLangFromTitle_english() {
    GalleryInfo gi = new GalleryInfo();
    gi.simpleTags = new String[0];
    gi.title = "Gallery [English]";
    gi.generateSLang();
    assertEquals(GalleryInfo.S_LANG_EN, gi.simpleLanguage);
  }

  @Test
  public void generateSLangFromTitle_japanese() {
    GalleryInfo gi = new GalleryInfo();
    gi.title = "Title 日本語";
    gi.generateSLang();
    assertEquals(GalleryInfo.S_LANG_JA, gi.simpleLanguage);
  }

  @Test
  public void generateSLang_tagOverridesTitle() {
    GalleryInfo gi = new GalleryInfo();
    gi.simpleTags = new String[]{"language:korean"};
    gi.title = "Gallery [English]";
    gi.generateSLang();
    assertEquals(GalleryInfo.S_LANG_KO, gi.simpleLanguage);
  }

  @Test
  public void parcelRoundTrip_preservesAllFields() {
    GalleryInfo src = new GalleryInfo();
    src.gid = 1000L;
    src.token = "tk";
    src.title = "Title";
    src.titleJpn = "タイトル";
    src.thumb = "https://thumb";
    src.category = 2;
    src.posted = "2020-01-01";
    src.uploader = "up";
    src.rating = 4.5f;
    src.rated = true;
    src.pages = 42;
    src.simpleLanguage = GalleryInfo.S_LANG_ZH;
    src.simpleTags = new String[]{"language:chinese"};
    src.thumbWidth = 100;
    src.thumbHeight = 150;
    src.favoriteSlot = 1;
    src.favoriteName = "Fav";

    Parcel parcel = Parcel.obtain();
    src.writeToParcel(parcel, 0);
    parcel.setDataPosition(0);

    GalleryInfo dst = GalleryInfo.CREATOR.createFromParcel(parcel);
    parcel.recycle();

    assertEquals(src.gid, dst.gid);
    assertEquals(src.token, dst.token);
    assertEquals(src.title, dst.title);
    assertEquals(src.titleJpn, dst.titleJpn);
    assertEquals(src.thumb, dst.thumb);
    assertEquals(src.category, dst.category);
    assertEquals(src.posted, dst.posted);
    assertEquals(src.uploader, dst.uploader);
    assertEquals(src.rating, dst.rating, 0f);
    assertEquals(src.rated, dst.rated);
    assertEquals(src.pages, dst.pages);
    assertEquals(src.simpleLanguage, dst.simpleLanguage);
    assertNotNull(dst.simpleTags);
    assertEquals(1, dst.simpleTags.length);
    assertEquals("language:chinese", dst.simpleTags[0]);
    assertEquals(src.thumbWidth, dst.thumbWidth);
    assertEquals(src.thumbHeight, dst.thumbHeight);
    assertEquals(src.favoriteSlot, dst.favoriteSlot);
    assertEquals(src.favoriteName, dst.favoriteName);
  }
}
