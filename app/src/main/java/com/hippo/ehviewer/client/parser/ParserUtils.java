/*
 * Copyright 2015 Hippo Seven
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

import com.hippo.yorozuya.NumberUtils;
import com.hippo.yorozuya.StringUtils;

import org.jsoup.nodes.Element;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class ParserUtils {

    public static final DateFormat sDateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.US);

    public static synchronized String formatDate(long time) {
        return sDateFormat.format(new Date(time));
    }

    public static String trim(String str) {
        // Avoid null
        if (str == null) {
            str = "";
        }
        return StringUtils.unescapeXml(str).trim();
    }

    public static int parseInt(String str, int defValue) {
        return NumberUtils.parseIntSafely(trim(str).replace(",", ""), defValue);
    }

    public static long parseLong(String str, long defValue) {
        return NumberUtils.parseLongSafely(trim(str).replace(",", ""), defValue);
    }

    public static float parseFloat(String str, float defValue) {
        return NumberUtils.parseFloatSafely(trim(str).replace(",", ""), defValue);
    }

    /** Get attribute value from element, trimmed. Returns "" if element is null or attribute missing. */
    public static String getAttr(Element e, String name) {
        return getAttr(e, name, "");
    }

    /** Get attribute value from element, trimmed. Returns def if element is null or attribute missing. */
    public static String getAttr(Element e, String name, String def) {
        if (e == null) {
            return def;
        }
        String v = e.attr(name);
        return v == null || v.isEmpty() ? def : trim(v);
    }

    /** Get text from element, trimmed. Returns "" if element is null. */
    public static String getText(Element e) {
        return getText(e, "");
    }

    /** Get text from element, trimmed. Returns def if element is null. */
    public static String getText(Element e, String def) {
        if (e == null) {
            return def;
        }
        return trim(e.text());
    }

    /**
     * Run pattern on input; if match found, return trimmed capture group. Otherwise return def.
     * group 1 is first capturing group.
     */
    public static String matchGroup(Pattern p, String input, int group, String def) {
        if (p == null || input == null) {
            return def;
        }
        Matcher m = p.matcher(input);
        return m.find() ? groupTrim(m, group, def) : def;
    }

    /** Trim of matcher's capture group. Call only after matcher.find() returned true. */
    public static String groupTrim(Matcher m, int group) {
        return groupTrim(m, group, "");
    }

    /** Trim of matcher's capture group, or def if invalid. Call only after matcher.find() returned true. */
    public static String groupTrim(Matcher m, int group, String def) {
        if (m == null || group < 0 || group > m.groupCount()) {
            return def;
        }
        try {
            String s = m.group(group);
            return s == null ? def : trim(s);
        } catch (IllegalStateException | IndexOutOfBoundsException e) {
            return def;
        }
    }

    /** Parse matcher's capture group as int. Call only after matcher.find() returned true. */
    public static int groupInt(Matcher m, int group, int def) {
        return parseInt(groupTrim(m, group), def);
    }

    /** Parse matcher's capture group as long. Call only after matcher.find() returned true. */
    public static long groupLong(Matcher m, int group, long def) {
        return parseLong(groupTrim(m, group), def);
    }
}
