/*
 * Copyright 2019 Hippo Seven
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

import androidx.annotation.Nullable;

/**
 * Helper class for parsing and building excluded languages strings.
 * The excluded languages string format is language codes joined by "x",
 * e.g. "0x1024x2048".
 */
public final class ExcludedLanguagesHelper {

    public static final int ROW_COUNT = 17;
    public static final int COLUMN_COUNT = 3;

    /**
     * All language codes in order: [row][column] where column 0=original, 1=translated, 2=rewrite.
     */
    public static final String[] LANGUAGES = {
            EhConfig.JAPANESE_ORIGINAL,
            EhConfig.JAPANESE_TRANSLATED,
            EhConfig.JAPANESE_REWRITE,
            EhConfig.ENGLISH_ORIGINAL,
            EhConfig.ENGLISH_TRANSLATED,
            EhConfig.ENGLISH_REWRITE,
            EhConfig.CHINESE_ORIGINAL,
            EhConfig.CHINESE_TRANSLATED,
            EhConfig.CHINESE_REWRITE,
            EhConfig.DUTCH_ORIGINAL,
            EhConfig.DUTCH_TRANSLATED,
            EhConfig.DUTCH_REWRITE,
            EhConfig.FRENCH_ORIGINAL,
            EhConfig.FRENCH_TRANSLATED,
            EhConfig.FRENCH_REWRITE,
            EhConfig.GERMAN_ORIGINAL,
            EhConfig.GERMAN_TRANSLATED,
            EhConfig.GERMAN_REWRITE,
            EhConfig.HUNGARIAN_ORIGINAL,
            EhConfig.HUNGARIAN_TRANSLATED,
            EhConfig.HUNGARIAN_REWRITE,
            EhConfig.ITALIAN_ORIGINAL,
            EhConfig.ITALIAN_TRANSLATED,
            EhConfig.ITALIAN_REWRITE,
            EhConfig.KOREAN_ORIGINAL,
            EhConfig.KOREAN_TRANSLATED,
            EhConfig.KOREAN_REWRITE,
            EhConfig.POLISH_ORIGINAL,
            EhConfig.POLISH_TRANSLATED,
            EhConfig.POLISH_REWRITE,
            EhConfig.PORTUGUESE_ORIGINAL,
            EhConfig.PORTUGUESE_TRANSLATED,
            EhConfig.PORTUGUESE_REWRITE,
            EhConfig.RUSSIAN_ORIGINAL,
            EhConfig.RUSSIAN_TRANSLATED,
            EhConfig.RUSSIAN_REWRITE,
            EhConfig.SPANISH_ORIGINAL,
            EhConfig.SPANISH_TRANSLATED,
            EhConfig.SPANISH_REWRITE,
            EhConfig.THAI_ORIGINAL,
            EhConfig.THAI_TRANSLATED,
            EhConfig.THAI_REWRITE,
            EhConfig.VIETNAMESE_ORIGINAL,
            EhConfig.VIETNAMESE_TRANSLATED,
            EhConfig.VIETNAMESE_REWRITE,
            EhConfig.NA_ORIGINAL,
            EhConfig.NA_TRANSLATED,
            EhConfig.NA_REWRITE,
            EhConfig.OTHER_ORIGINAL,
            EhConfig.OTHER_TRANSLATED,
            EhConfig.OTHER_REWRITE,
    };

    private ExcludedLanguagesHelper() {}

    /**
     * Parse an excluded languages string into a selections array.
     *
     * @param excludedLanguages the string from Settings, e.g. "0x1024x2048", or null
     * @return a boolean[ROW_COUNT][COLUMN_COUNT] array of selections
     */
    public static boolean[][] parseExcludedLanguages(@Nullable String excludedLanguages) {
        boolean[][] selections = new boolean[ROW_COUNT][COLUMN_COUNT];
        if (excludedLanguages == null) {
            return selections;
        }

        String[] parts = excludedLanguages.split("x");
        int partsLength = parts.length;
        int languagesLength = LANGUAGES.length;
        for (int i = 0, j = 0; i < partsLength; i++) {
            String part = parts[i];
            if (!isDecimal(part)) {
                continue;
            }
            for (; j < languagesLength; j++) {
                if (LANGUAGES[j].equals(part)) {
                    int row = j / COLUMN_COUNT;
                    int column = j % COLUMN_COUNT;
                    selections[row][column] = true;
                    break;
                }
            }
        }
        return selections;
    }

    /**
     * Build an excluded languages string from a selections array.
     *
     * @param selections a boolean[ROW_COUNT][COLUMN_COUNT] array
     * @return the excluded languages string, e.g. "0x1024x2048"
     */
    public static String buildExcludedLanguages(boolean[][] selections) {
        StringBuilder sb = new StringBuilder();
        int i = 0;
        boolean first = true;
        for (boolean[] row : selections) {
            for (boolean selected : row) {
                if (selected) {
                    if (!first) {
                        sb.append("x");
                    } else {
                        first = false;
                    }
                    sb.append(LANGUAGES[i]);
                }
                i++;
            }
        }
        return sb.toString();
    }

    private static boolean isDecimal(String str) {
        int length = str.length();
        if (length <= 0) {
            return false;
        }
        for (int i = 0; i < length; i++) {
            char ch = str.charAt(i);
            if (ch < '0' || ch > '9') {
                return false;
            }
        }
        return true;
    }
}
