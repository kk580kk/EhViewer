package com.hippo.ehviewer.client.parser;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;

import com.hippo.ehviewer.client.data.GalleryDetail;
import com.hippo.ehviewer.client.exception.OffensiveException;
import com.hippo.ehviewer.client.exception.PiningException;
import java.io.InputStream;
import okio.BufferedSource;
import okio.Okio;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class GalleryDetailParserTest {

  @Test
  public void testParse() throws Exception {
    InputStream resource = GalleryDetailParserTest.class.getResourceAsStream("GalleryDetailParserTest.html");
    BufferedSource source = Okio.buffer(Okio.source(resource));
    String body = source.readUtf8();

    GalleryDetail detail = GalleryDetailParser.parse(body);

    assertEquals(1234567L, detail.gid);
    assertEquals("abcdef1234", detail.token);
    assertEquals(12345L, detail.apiUid);
    assertEquals("fedcba4321", detail.apiKey);
    assertEquals("Test Gallery Title", detail.title);
    assertEquals("テストギャラリータイトル", detail.titleJpn);
    assertEquals("testuser", detail.uploader);
    assertEquals(3, detail.torrentCount);
    assertEquals("2019-02-15 12:00", detail.posted);
    assertEquals("Japanese", detail.language);
    assertEquals("45.3 MB", detail.size);
    assertEquals(25, detail.pages);
    assertEquals(123, detail.favoriteCount);
    assertEquals(50, detail.ratingCount);
    assertEquals(4.25f, detail.rating, 0.01f);

    // Tags
    assertNotNull(detail.tags);
    assertTrue(detail.tags.length >= 2);
    assertEquals("language", detail.tags[0].groupName);
    assertEquals("japanese", detail.tags[0].getTagAt(0));
    assertEquals("parody", detail.tags[1].groupName);
    assertEquals("original", detail.tags[1].getTagAt(0));

    // Comments
    assertNotNull(detail.comments);
    assertTrue(detail.comments.comments.length >= 1);
    assertEquals("TestUser1", detail.comments.comments[0].user);
    assertEquals("This is a test comment", detail.comments.comments[0].comment);

    // Preview
    assertEquals(2, detail.previewPages);
    assertNotNull(detail.previewSet);
    assertEquals(2, detail.previewSet.size());
  }

  @Test(expected = OffensiveException.class)
  public void testParseOffensive() throws Exception {
    String body = "<p>(And if you choose to ignore this warning, you lose all rights to complain about it in the future.)</p>";
    GalleryDetailParser.parse(body);
  }

  @Test(expected = PiningException.class)
  public void testParsePining() throws Exception {
    String body = "<p>This gallery is pining for the fjords.</p>";
    GalleryDetailParser.parse(body);
  }

  @Test
  public void testParsePages() throws Exception {
    String body = "<tr><td class=\"gdt1\">Length:</td><td class=\"gdt2\">123 pages</td></tr>";
    int pages = GalleryDetailParser.parsePages(body);
    assertEquals(123, pages);
  }
}
