package com.hippo.ehviewer.client.parser;

import static org.junit.Assert.assertEquals;

import org.json.JSONException;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class VoteCommentParserTest {

  @Test
  public void testParse() throws JSONException {
    String body = "{\"comment_id\":1253922,\"comment_score\":-19,\"comment_vote\":0}";
    VoteCommentParser.Result result = VoteCommentParser.parse(body, 1);
    assertEquals(1253922, result.id);
    assertEquals(-19, result.score);
    assertEquals(0, result.vote);
    assertEquals(1, result.expectVote);
  }

  @Test
  public void testParsePositiveVote() throws JSONException {
    String body = "{\"comment_id\":999,\"comment_score\":42,\"comment_vote\":1}";
    VoteCommentParser.Result result = VoteCommentParser.parse(body, 1);
    assertEquals(999, result.id);
    assertEquals(42, result.score);
    assertEquals(1, result.vote);
    assertEquals(1, result.expectVote);
  }

  @Test(expected = JSONException.class)
  public void testParseInvalidJson() throws JSONException {
    VoteCommentParser.parse("not json", 0);
  }
}
