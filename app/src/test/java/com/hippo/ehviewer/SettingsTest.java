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

package com.hippo.ehviewer;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class SettingsTest {

    @Before
    public void setUp() {
        Settings.initialize(RuntimeEnvironment.application);
    }

    @Test
    public void testProxyDefaults() {
        assertEquals(EhProxySelector.TYPE_SYSTEM, Settings.getProxyType());
        assertNull(Settings.getProxyIp());
        assertEquals(-1, Settings.getProxyPort());
    }

    @Test
    public void testPutAndGetProxyType() {
        Settings.putProxyType(EhProxySelector.TYPE_HTTP);
        assertEquals(EhProxySelector.TYPE_HTTP, Settings.getProxyType());

        Settings.putProxyType(EhProxySelector.TYPE_SOCKS);
        assertEquals(EhProxySelector.TYPE_SOCKS, Settings.getProxyType());

        Settings.putProxyType(EhProxySelector.TYPE_DIRECT);
        assertEquals(EhProxySelector.TYPE_DIRECT, Settings.getProxyType());
    }

    @Test
    public void testPutAndGetProxyIp() {
        Settings.putProxyIp("127.0.0.1");
        assertEquals("127.0.0.1", Settings.getProxyIp());

        Settings.putProxyIp("192.168.1.100");
        assertEquals("192.168.1.100", Settings.getProxyIp());
    }

    @Test
    public void testPutAndGetProxyPort() {
        Settings.putProxyPort(8080);
        assertEquals(8080, Settings.getProxyPort());

        Settings.putProxyPort(1080);
        assertEquals(1080, Settings.getProxyPort());
    }

    @Test
    public void testExcludedLanguagesDefault() {
        assertNull(Settings.getExcludedLanguages());
    }

    @Test
    public void testPutAndGetExcludedLanguages() {
        Settings.putExcludedLanguages("0x1024x2048");
        assertEquals("0x1024x2048", Settings.getExcludedLanguages());

        // Verify it updates EhConfig
        assertEquals("0x1024x2048", Settings.getEhConfig().excludedLanguages);
    }

    @Test
    public void testDefaultCategoriesDefault() {
        assertEquals(com.hippo.ehviewer.client.EhUtils.ALL_CATEGORY, Settings.getDefaultCategories());
    }

    @Test
    public void testPutAndGetDefaultCategories() {
        int categories = 0x3; // MISC | DOUJINSHI
        Settings.putDefaultCategories(categories);
        assertEquals(categories, Settings.getDefaultCategories());

        // Verify it updates EhConfig
        assertEquals(categories, Settings.getEhConfig().defaultCategories);
    }

    @Test
    public void testExcludedTagNamespacesDefault() {
        assertEquals(0, Settings.getExcludedTagNamespaces());
    }

    @Test
    public void testPutAndGetExcludedTagNamespaces() {
        int namespaces = 0x5; // RECLASS | PARODY
        Settings.putExcludedTagNamespaces(namespaces);
        assertEquals(namespaces, Settings.getExcludedTagNamespaces());

        // Verify it updates EhConfig
        assertEquals(namespaces, Settings.getEhConfig().excludedNamespaces);
    }

    @Test
    public void testPutEnabledSecurityWritesCorrectKey() {
        // This test verifies the bug fix: putEnabledSecurity should write to
        // KEY_SEC_SECURITY, not KEY_READING_FULLSCREEN
        boolean originalReadingFullscreen = Settings.getReadingFullscreen();

        Settings.putEnabledSecurity(true);
        assertTrue(Settings.getEnabledSecurity());
        // Reading fullscreen should remain unchanged
        assertEquals(originalReadingFullscreen, Settings.getReadingFullscreen());

        Settings.putEnabledSecurity(false);
        assertFalse(Settings.getEnabledSecurity());
        assertEquals(originalReadingFullscreen, Settings.getReadingFullscreen());
    }

    @Test
    public void testDownloadLocationDefault() {
        // Default should return a non-null UniFile from default download dir
        // (may be null depending on environment, but the method shouldn't throw)
        Settings.getDownloadLocation();
    }

    @Test
    public void testMediaScanDefault() {
        assertFalse(Settings.getMediaScan());
    }

    @Test
    public void testImageResolutionDefault() {
        assertEquals(com.hippo.ehviewer.client.EhConfig.IMAGE_SIZE_AUTO, Settings.getImageResolution());
    }

    @Test
    public void testPutAndGetImageResolution() {
        Settings.putImageResolution(com.hippo.ehviewer.client.EhConfig.IMAGE_SIZE_1280X);
        assertEquals(com.hippo.ehviewer.client.EhConfig.IMAGE_SIZE_1280X, Settings.getImageResolution());

        // Verify it updates EhConfig
        assertEquals(com.hippo.ehviewer.client.EhConfig.IMAGE_SIZE_1280X, Settings.getEhConfig().imageSize);
    }

    @Test
    public void testMultiThreadDownloadDefault() {
        assertEquals(3, Settings.getMultiThreadDownload());
    }

    @Test
    public void testPutAndGetMultiThreadDownload() {
        Settings.putMultiThreadDownload(5);
        assertEquals(5, Settings.getMultiThreadDownload());
    }

    @Test
    public void testConcurrentDownloadLimitDefault() {
        assertEquals(1, Settings.getConcurrentDownloadLimit());
    }

    @Test
    public void testPutAndGetConcurrentDownloadLimit() {
        Settings.putConcurrentDownloadLimit(3);
        assertEquals(3, Settings.getConcurrentDownloadLimit());
    }

    @Test
    public void testConcurrentDownloadLimitClamped() {
        Settings.putConcurrentDownloadLimit(0);
        assertEquals(1, Settings.getConcurrentDownloadLimit());

        Settings.putConcurrentDownloadLimit(10);
        assertEquals(5, Settings.getConcurrentDownloadLimit());
    }

    @Test
    public void testPreloadImageDefault() {
        assertEquals(5, Settings.getPreloadImage());
    }

    @Test
    public void testPutAndGetPreloadImage() {
        Settings.putPreloadImage(10);
        assertEquals(10, Settings.getPreloadImage());
    }

    @Test
    public void testDownloadOriginImageDefault() {
        assertFalse(Settings.getDownloadOriginImage());
    }

    @Test
    public void testPutAndGetDownloadOriginImage() {
        Settings.putDownloadOriginImage(true);
        assertTrue(Settings.getDownloadOriginImage());
    }

    @Test
    public void testCellularNetworkWarningDefault() {
        assertFalse(Settings.getCellularNetworkWarning());
    }

    @Test
    public void testBuiltInHostsDefault() {
        // Default depends on locale; just verify it doesn't crash
        Settings.getBuiltInHosts();
    }

    @Test
    public void testPutAndGetBuiltInHosts() {
        Settings.putBuiltInHosts(true);
        assertTrue(Settings.getBuiltInHosts());
        Settings.putBuiltInHosts(false);
        assertFalse(Settings.getBuiltInHosts());
    }

    @Test
    public void testExcludedLanguagesNullDefaultProducesEmptyInEhConfig() {
        // When no excluded languages are set, EhConfig should use empty string, not null
        assertNull(Settings.getExcludedLanguages());
        assertNotNull(Settings.getEhConfig().excludedLanguages);
        assertEquals("", Settings.getEhConfig().excludedLanguages);
    }

    @Test
    public void testPutExcludedLanguagesNullSetsEmptyInEhConfig() {
        Settings.putExcludedLanguages(null);
        // EhConfig should never have null excludedLanguages
        assertNotNull(Settings.getEhConfig().excludedLanguages);
        assertEquals("", Settings.getEhConfig().excludedLanguages);
    }

    @Test
    public void testReadSettingsDefaults() {
        assertFalse(Settings.getKeepScreenOn());
        assertTrue(Settings.getShowClock());
        assertTrue(Settings.getShowProgress());
        assertTrue(Settings.getShowBattery());
        assertTrue(Settings.getShowPageInterval());
        assertFalse(Settings.getVolumePage());
        assertTrue(Settings.getReadingFullscreen());
        assertFalse(Settings.getCustomScreenLightness());
        assertEquals(50, Settings.getScreenLightness());
    }

    @Test
    public void testSecurityDefaults() {
        assertEquals("", Settings.getSecurity());
        assertFalse(Settings.getEnabledSecurity());
        assertFalse(Settings.getEnableFingerprint());
    }

    @Test
    public void testAppLanguageDefault() {
        assertEquals("system", Settings.getAppLanguage());
    }

    @Test
    public void testPutAndGetAppLanguage() {
        Settings.putAppLanguage("zh");
        assertEquals("zh", Settings.getAppLanguage());
    }
}
