package com.hippo.ehviewer.client.parser;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;

import com.hippo.ehviewer.client.data.ListUrlBuilder;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class GalleryListUrlParserTest {

  @Test
  public void testParseNormalE() {
    ListUrlBuilder builder = GalleryListUrlParser.parse("https://e-hentai.org/");
    assertNotNull(builder);
  }

  @Test
  public void testParseNormalEx() {
    ListUrlBuilder builder = GalleryListUrlParser.parse("https://exhentai.org/");
    assertNotNull(builder);
  }

  @Test
  public void testParseUploader() {
    ListUrlBuilder builder = GalleryListUrlParser.parse("https://e-hentai.org/uploader/testuser");
    assertNotNull(builder);
    assertEquals(ListUrlBuilder.MODE_UPLOADER, builder.getMode());
    assertEquals("testuser", builder.getKeyword());
  }

  @Test
  public void testParseTag() {
    ListUrlBuilder builder = GalleryListUrlParser.parse("https://e-hentai.org/tag/artist:test");
    assertNotNull(builder);
    assertEquals(ListUrlBuilder.MODE_TAG, builder.getMode());
    assertEquals("artist:test", builder.getKeyword());
  }

  @Test
  public void testParseInvalidHost() {
    ListUrlBuilder builder = GalleryListUrlParser.parse("https://example.com/");
    assertNull(builder);
  }

  @Test
  public void testParseInvalidUrl() {
    ListUrlBuilder builder = GalleryListUrlParser.parse("not a url");
    assertNull(builder);
  }

  @Test
  public void testParseTagWithSlash() {
    ListUrlBuilder builder = GalleryListUrlParser.parse("https://e-hentai.org/tag/artist:test/1");
    assertNotNull(builder);
    assertEquals(ListUrlBuilder.MODE_TAG, builder.getMode());
    assertEquals("artist:test", builder.getKeyword());
  }

  @Test
  public void testParseUploaderWithSlash() {
    ListUrlBuilder builder = GalleryListUrlParser.parse("https://e-hentai.org/uploader/testuser/1");
    assertNotNull(builder);
    assertEquals(ListUrlBuilder.MODE_UPLOADER, builder.getMode());
    assertEquals("testuser", builder.getKeyword());
  }

  @Test
  public void testParsePageFromQuery() {
    ListUrlBuilder builder = GalleryListUrlParser.parse("https://e-hentai.org/?page=2");
    assertNotNull(builder);
    assertEquals(2, builder.getPageIndex());
  }

  @Test
  public void testParsePageFromUploaderPath() {
    ListUrlBuilder builder = GalleryListUrlParser.parse("https://e-hentai.org/uploader/testuser/3");
    assertNotNull(builder);
    assertEquals(ListUrlBuilder.MODE_UPLOADER, builder.getMode());
    assertEquals("testuser", builder.getKeyword());
    assertEquals(3, builder.getPageIndex());
  }

  @Test
  public void testParsePageFromTagPath() {
    ListUrlBuilder builder = GalleryListUrlParser.parse("https://e-hentai.org/tag/artist:test/2");
    assertNotNull(builder);
    assertEquals(ListUrlBuilder.MODE_TAG, builder.getMode());
    assertEquals("artist:test", builder.getKeyword());
    assertEquals(2, builder.getPageIndex());
  }

  @Test
  public void testParseCategoryWithPage() {
    ListUrlBuilder builder = GalleryListUrlParser.parse("https://e-hentai.org/1?page=1");
    assertNotNull(builder);
    assertEquals(1, builder.getCategory());
    assertEquals(1, builder.getPageIndex());
  }
}
