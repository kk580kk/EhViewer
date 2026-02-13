package com.hippo.ehviewer.client.parser;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;

import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Element;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class ParserUtilsTest {

  @Test
  public void testTrimNull() {
    assertEquals("", ParserUtils.trim(null));
  }

  @Test
  public void testTrimNormal() {
    assertEquals("hello", ParserUtils.trim("  hello  "));
  }

  @Test
  public void testTrimXmlEntities() {
    assertEquals("a&b", ParserUtils.trim("a&amp;b"));
  }

  @Test
  public void testParseInt() {
    assertEquals(123, ParserUtils.parseInt("123", 0));
  }

  @Test
  public void testParseIntWithComma() {
    assertEquals(1234, ParserUtils.parseInt("1,234", 0));
  }

  @Test
  public void testParseIntDefault() {
    assertEquals(-1, ParserUtils.parseInt("abc", -1));
  }

  @Test
  public void testParseLong() {
    assertEquals(1234567890L, ParserUtils.parseLong("1234567890", 0));
  }

  @Test
  public void testParseLongDefault() {
    assertEquals(0L, ParserUtils.parseLong("abc", 0));
  }

  @Test
  public void testParseFloat() {
    assertEquals(4.25f, ParserUtils.parseFloat("4.25", 0f), 0.001f);
  }

  @Test
  public void testParseFloatDefault() {
    assertEquals(0f, ParserUtils.parseFloat("abc", 0f), 0.001f);
  }

  @Test
  public void testFormatDate() {
    String result = ParserUtils.formatDate(0);
    assertNotNull(result);
  }

  // --- getAttr ---

  @Test
  public void testGetAttrNullElement() {
    assertEquals("", ParserUtils.getAttr(null, "href"));
    assertEquals("x", ParserUtils.getAttr(null, "href", "x"));
  }

  @Test
  public void testGetAttrPresent() {
    Element e = Jsoup.parse("<a href=\"  /foo?q=1  \">").selectFirst("a");
    assertEquals("/foo?q=1", ParserUtils.getAttr(e, "href"));
    assertEquals("/foo?q=1", ParserUtils.getAttr(e, "href", "def"));
  }

  @Test
  public void testGetAttrMissing() {
    Element e = Jsoup.parse("<a>link</a>").selectFirst("a");
    assertEquals("", ParserUtils.getAttr(e, "href"));
    assertEquals("default", ParserUtils.getAttr(e, "href", "default"));
  }

  // --- getText ---

  @Test
  public void testGetTextNullElement() {
    assertEquals("", ParserUtils.getText(null));
    assertEquals("n", ParserUtils.getText(null, "n"));
  }

  @Test
  public void testGetTextNormal() {
    Element e = Jsoup.parse("<p>  hello &amp; world  </p>").selectFirst("p");
    assertEquals("hello & world", ParserUtils.getText(e));
    assertEquals("hello & world", ParserUtils.getText(e, "x"));
  }

  // --- regex: matchGroup, groupTrim, groupInt, groupLong ---

  private static final Pattern PATTERN_TWO_GROUPS = Pattern.compile("(\\d+)\\s+(\\w+)");

  @Test
  public void testMatchGroupNoMatch() {
    assertEquals("", ParserUtils.matchGroup(PATTERN_TWO_GROUPS, "no digits here", 1, ""));
    assertEquals("d", ParserUtils.matchGroup(PATTERN_TWO_GROUPS, "no digits", 1, "d"));
  }

  @Test
  public void testMatchGroupMatch() {
    assertEquals("42", ParserUtils.matchGroup(PATTERN_TWO_GROUPS, "42 pages", 1, ""));
    assertEquals("pages", ParserUtils.matchGroup(PATTERN_TWO_GROUPS, "42 pages", 2, ""));
  }

  @Test
  public void testMatchGroupNullInputOrPattern() {
    assertEquals("d", ParserUtils.matchGroup(null, "42 pages", 1, "d"));
    assertEquals("d", ParserUtils.matchGroup(PATTERN_TWO_GROUPS, null, 1, "d"));
  }

  @Test
  public void testGroupTrimAfterFind() {
    Matcher m = PATTERN_TWO_GROUPS.matcher("  99  hello  ");
    assertEquals(true, m.find());
    assertEquals("99", ParserUtils.groupTrim(m, 1));
    assertEquals("hello", ParserUtils.groupTrim(m, 2));
    assertEquals("", ParserUtils.groupTrim(null, 1));
    assertEquals("x", ParserUtils.groupTrim(null, 1, "x"));
  }

  @Test
  public void testGroupIntGroupLong() {
    Matcher m = PATTERN_TWO_GROUPS.matcher("  123  abc  ");
    assertEquals(true, m.find());
    assertEquals(123, ParserUtils.groupInt(m, 1, -1));
    assertEquals(-1, ParserUtils.groupInt(m, 2, -1)); // "abc" not int
    assertEquals(-1, ParserUtils.groupInt(null, 1, -1));

    Pattern pLong = Pattern.compile("(\\d+)");
    Matcher mL = pLong.matcher(" 999 ");
    assertEquals(true, mL.find());
    assertEquals(999L, ParserUtils.groupLong(mL, 1, 0L));
  }
}
