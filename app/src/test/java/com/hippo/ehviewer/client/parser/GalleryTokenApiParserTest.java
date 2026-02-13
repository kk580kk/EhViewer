package com.hippo.ehviewer.client.parser;

import static org.junit.Assert.assertEquals;

import com.hippo.ehviewer.client.exception.EhException;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class GalleryTokenApiParserTest {

  @Test
  public void testParse() throws Exception {
    String body = "{\"tokenlist\":[{\"gid\":618395,\"token\":\"0439fa3666\"}]}";
    String token = GalleryTokenApiParser.parse(body);
    assertEquals("0439fa3666", token);
  }

  @Test(expected = EhException.class)
  public void testParseError() throws Exception {
    String body = "{\"tokenlist\":[{\"gid\":618395,\"error\":\"Key missing, or incorrect key provided.\"}]}";
    GalleryTokenApiParser.parse(body);
  }

  @Test(expected = EhException.class)
  public void testParseEmptyTokenlist() throws Exception {
    GalleryTokenApiParser.parse("{\"tokenlist\":[]}");
  }

  @Test(expected = EhException.class)
  public void testParseMissingTokenlist() throws Exception {
    GalleryTokenApiParser.parse("{}");
  }

  @Test(expected = EhException.class)
  public void testParseItemWithNeitherTokenNorError() throws Exception {
    GalleryTokenApiParser.parse("{\"tokenlist\":[{\"gid\":618395}]}");
  }
}
