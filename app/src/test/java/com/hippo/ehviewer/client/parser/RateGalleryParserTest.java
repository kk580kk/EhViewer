package com.hippo.ehviewer.client.parser;

import static org.junit.Assert.assertEquals;

import com.hippo.ehviewer.client.exception.ParseException;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class RateGalleryParserTest {

  @Test
  public void testParse() throws Exception {
    String body = "{\"rating_avg\":4.25,\"rating_cnt\":50}";
    RateGalleryParser.Result result = RateGalleryParser.parse(body);
    assertEquals(4.25f, result.rating, 0.001f);
    assertEquals(50, result.ratingCount);
  }

  @Test
  public void testParseZeroRating() throws Exception {
    String body = "{\"rating_avg\":0.0,\"rating_cnt\":0}";
    RateGalleryParser.Result result = RateGalleryParser.parse(body);
    assertEquals(0.0f, result.rating, 0.001f);
    assertEquals(0, result.ratingCount);
  }

  @Test(expected = ParseException.class)
  public void testParseInvalidJson() throws Exception {
    RateGalleryParser.parse("not json");
  }
}
