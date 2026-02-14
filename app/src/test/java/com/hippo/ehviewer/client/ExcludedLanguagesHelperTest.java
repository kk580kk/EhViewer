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

import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

public class ExcludedLanguagesHelperTest {

    @Test
    public void testParseNull() {
        boolean[][] selections = ExcludedLanguagesHelper.parseExcludedLanguages(null);
        assertNotNull(selections);
        assertEquals(ExcludedLanguagesHelper.ROW_COUNT, selections.length);
        for (boolean[] row : selections) {
            assertEquals(ExcludedLanguagesHelper.COLUMN_COUNT, row.length);
            for (boolean val : row) {
                assertFalse(val);
            }
        }
    }

    @Test
    public void testParseEmpty() {
        boolean[][] selections = ExcludedLanguagesHelper.parseExcludedLanguages("");
        for (boolean[] row : selections) {
            for (boolean val : row) {
                assertFalse(val);
            }
        }
    }

    @Test
    public void testParseSingleLanguage() {
        // "0" is JAPANESE_ORIGINAL -> row 0, column 0
        boolean[][] selections = ExcludedLanguagesHelper.parseExcludedLanguages("0");
        assertTrue(selections[0][0]);  // Japanese Original
        assertFalse(selections[0][1]); // Japanese Translated
        assertFalse(selections[0][2]); // Japanese Rewrite
    }

    @Test
    public void testParseJapaneseAllThree() {
        // Japanese: original=0, translated=1024, rewrite=2048
        boolean[][] selections = ExcludedLanguagesHelper.parseExcludedLanguages("0x1024x2048");
        assertTrue(selections[0][0]);  // Japanese Original
        assertTrue(selections[0][1]);  // Japanese Translated
        assertTrue(selections[0][2]);  // Japanese Rewrite
        // English should be unaffected
        assertFalse(selections[1][0]);
    }

    @Test
    public void testParseEnglishOriginal() {
        // "1" is ENGLISH_ORIGINAL -> row 1, column 0
        boolean[][] selections = ExcludedLanguagesHelper.parseExcludedLanguages("1");
        assertFalse(selections[0][0]); // Japanese Original
        assertTrue(selections[1][0]);  // English Original
        assertFalse(selections[1][1]); // English Translated
    }

    @Test
    public void testParseChineseTranslated() {
        // "1034" is CHINESE_TRANSLATED -> row 2, column 1
        boolean[][] selections = ExcludedLanguagesHelper.parseExcludedLanguages("1034");
        assertTrue(selections[2][1]);  // Chinese Translated
        assertFalse(selections[2][0]); // Chinese Original
        assertFalse(selections[2][2]); // Chinese Rewrite
    }

    @Test
    public void testParseMultipleLanguages() {
        // Japanese Original + English Original + Chinese Original
        boolean[][] selections = ExcludedLanguagesHelper.parseExcludedLanguages("0x1x10");
        assertTrue(selections[0][0]);  // Japanese Original
        assertTrue(selections[1][0]);  // English Original
        assertTrue(selections[2][0]);  // Chinese Original
        assertFalse(selections[3][0]); // Dutch Original
    }

    @Test
    public void testBuildEmpty() {
        boolean[][] selections = new boolean[ExcludedLanguagesHelper.ROW_COUNT][ExcludedLanguagesHelper.COLUMN_COUNT];
        String result = ExcludedLanguagesHelper.buildExcludedLanguages(selections);
        assertEquals("", result);
    }

    @Test
    public void testBuildSingleLanguage() {
        boolean[][] selections = new boolean[ExcludedLanguagesHelper.ROW_COUNT][ExcludedLanguagesHelper.COLUMN_COUNT];
        selections[0][0] = true; // Japanese Original = "0"
        String result = ExcludedLanguagesHelper.buildExcludedLanguages(selections);
        assertEquals("0", result);
    }

    @Test
    public void testBuildJapaneseAllThree() {
        boolean[][] selections = new boolean[ExcludedLanguagesHelper.ROW_COUNT][ExcludedLanguagesHelper.COLUMN_COUNT];
        selections[0][0] = true; // Japanese Original = "0"
        selections[0][1] = true; // Japanese Translated = "1024"
        selections[0][2] = true; // Japanese Rewrite = "2048"
        String result = ExcludedLanguagesHelper.buildExcludedLanguages(selections);
        assertEquals("0x1024x2048", result);
    }

    @Test
    public void testBuildMultipleLanguages() {
        boolean[][] selections = new boolean[ExcludedLanguagesHelper.ROW_COUNT][ExcludedLanguagesHelper.COLUMN_COUNT];
        selections[0][0] = true; // Japanese Original = "0"
        selections[1][0] = true; // English Original = "1"
        selections[2][0] = true; // Chinese Original = "10"
        String result = ExcludedLanguagesHelper.buildExcludedLanguages(selections);
        assertEquals("0x1x10", result);
    }

    @Test
    public void testRoundTrip() {
        // Build a string, parse it back, should get the same selections
        boolean[][] original = new boolean[ExcludedLanguagesHelper.ROW_COUNT][ExcludedLanguagesHelper.COLUMN_COUNT];
        original[0][0] = true;  // Japanese Original
        original[0][2] = true;  // Japanese Rewrite
        original[4][1] = true;  // French Translated
        original[16][0] = true; // Other Original

        String built = ExcludedLanguagesHelper.buildExcludedLanguages(original);
        boolean[][] parsed = ExcludedLanguagesHelper.parseExcludedLanguages(built);

        for (int i = 0; i < ExcludedLanguagesHelper.ROW_COUNT; i++) {
            assertArrayEquals("Row " + i + " mismatch", original[i], parsed[i]);
        }
    }

    @Test
    public void testRoundTripAllSelected() {
        boolean[][] original = new boolean[ExcludedLanguagesHelper.ROW_COUNT][ExcludedLanguagesHelper.COLUMN_COUNT];
        for (int i = 0; i < ExcludedLanguagesHelper.ROW_COUNT; i++) {
            for (int j = 0; j < ExcludedLanguagesHelper.COLUMN_COUNT; j++) {
                original[i][j] = true;
            }
        }

        String built = ExcludedLanguagesHelper.buildExcludedLanguages(original);
        boolean[][] parsed = ExcludedLanguagesHelper.parseExcludedLanguages(built);

        for (int i = 0; i < ExcludedLanguagesHelper.ROW_COUNT; i++) {
            assertArrayEquals("Row " + i + " mismatch", original[i], parsed[i]);
        }
    }

    @Test
    public void testLanguagesArraySize() {
        assertEquals(ExcludedLanguagesHelper.ROW_COUNT * ExcludedLanguagesHelper.COLUMN_COUNT,
                ExcludedLanguagesHelper.LANGUAGES.length);
    }
}
