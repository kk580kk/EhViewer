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

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;

import org.junit.Before;
import org.junit.Test;

public class EhConfigTest {

    private EhConfig config;

    @Before
    public void setUp() {
        config = new EhConfig();
    }

    @Test
    public void testUconfigContainsImageSize() {
        config.imageSize = EhConfig.IMAGE_SIZE_1280X;
        config.setDirty();
        String uconfig = config.uconfig();
        assertTrue(uconfig.contains("xr_1280"));
    }

    @Test
    public void testUconfigContainsExcludedLanguages() {
        config.excludedLanguages = "0x1024x2048";
        config.setDirty();
        String uconfig = config.uconfig();
        assertTrue(uconfig.contains("xl_0x1024x2048"));
    }

    @Test
    public void testUconfigEmptyExcludedLanguages() {
        config.excludedLanguages = "";
        config.setDirty();
        String uconfig = config.uconfig();
        assertTrue(uconfig.contains("xl_-"));
    }

    @Test
    public void testUconfigContainsExcludedNamespaces() {
        config.excludedNamespaces = 0x5;
        config.setDirty();
        String uconfig = config.uconfig();
        assertTrue(uconfig.contains("xns_5"));
    }

    @Test
    public void testUconfigContainsDefaultCategories() {
        config.defaultCategories = EhConfig.ALL_CATEGORY;
        config.setDirty();
        String uconfig = config.uconfig();
        assertTrue(uconfig.contains("cats_" + EhConfig.ALL_CATEGORY));
    }

    @Test
    public void testSetDirtyAndCaching() {
        config.imageSize = EhConfig.IMAGE_SIZE_AUTO;
        config.setDirty();
        String first = config.uconfig();

        // Second call should return cached value
        String second = config.uconfig();
        assertEquals(first, second);

        // After setDirty and change, should regenerate
        config.imageSize = EhConfig.IMAGE_SIZE_1600X;
        config.setDirty();
        String third = config.uconfig();
        assertFalse(first.equals(third));
        assertTrue(third.contains("xr_1600"));
    }

    @Test
    public void testClone() {
        config.imageSize = EhConfig.IMAGE_SIZE_780X;
        config.excludedLanguages = "1x2";
        config.defaultCategories = 0x3;

        EhConfig cloned = config.clone();

        assertEquals(config.imageSize, cloned.imageSize);
        assertEquals(config.excludedLanguages, cloned.excludedLanguages);
        assertEquals(config.defaultCategories, cloned.defaultCategories);
    }

    @Test
    public void testUconfigNotNull() {
        assertNotNull(config.uconfig());
    }

    @Test
    public void testDefaultValues() {
        assertEquals(EhConfig.IMAGE_SIZE_AUTO, config.imageSize);
        assertEquals("", config.excludedLanguages);
        assertEquals(0, config.excludedNamespaces);
        assertEquals(0, config.defaultCategories);
    }

    @Test
    public void testNamespaceConstants() {
        assertEquals(0x1, EhConfig.NAMESPACES_RECLASS);
        assertEquals(0x2, EhConfig.NAMESPACES_LANGUAGE);
        assertEquals(0x4, EhConfig.NAMESPACES_PARODY);
        assertEquals(0x8, EhConfig.NAMESPACES_CHARACTER);
        assertEquals(0x10, EhConfig.NAMESPACES_GROUP);
        assertEquals(0x20, EhConfig.NAMESPACES_ARTIST);
        assertEquals(0x40, EhConfig.NAMESPACES_MALE);
        assertEquals(0x80, EhConfig.NAMESPACES_FEMALE);
    }

    @Test
    public void testCategoryConstants() {
        assertEquals(0x1, EhConfig.MISC);
        assertEquals(0x2, EhConfig.DOUJINSHI);
        assertEquals(0x4, EhConfig.MANGA);
        assertEquals(0x3ff, EhConfig.ALL_CATEGORY);
    }
}
