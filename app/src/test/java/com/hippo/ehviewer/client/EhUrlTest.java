/*
 * Copyright 2016 Hippo Seven
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
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;

import com.hippo.ehviewer.Settings;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class EhUrlTest {

    @Before
    public void setUp() {
        Settings.initialize(RuntimeEnvironment.application);
    }

    @Test
    public void getHost_siteE_returnsHostE() {
        Settings.putGallerySite(EhUrl.SITE_E);
        assertEquals(EhUrl.HOST_E, EhUrl.getHost());
    }

    @Test
    public void getHost_siteEx_returnsHostEx() {
        Settings.putGallerySite(EhUrl.SITE_EX);
        assertEquals(EhUrl.HOST_EX, EhUrl.getHost());
    }

    @Test
    public void getApiUrl_siteE_returnsApiE() {
        Settings.putGallerySite(EhUrl.SITE_E);
        assertEquals(EhUrl.API_E, EhUrl.getApiUrl());
    }

    @Test
    public void getApiUrl_siteEx_returnsApiEx() {
        Settings.putGallerySite(EhUrl.SITE_EX);
        assertEquals(EhUrl.API_EX, EhUrl.getApiUrl());
    }

    @Test
    public void getFavoritesUrl_siteE_returnsFavoritesE() {
        Settings.putGallerySite(EhUrl.SITE_E);
        assertEquals(EhUrl.URL_FAVORITES_E, EhUrl.getFavoritesUrl());
    }

    @Test
    public void getFavoritesUrl_siteEx_returnsFavoritesEx() {
        Settings.putGallerySite(EhUrl.SITE_EX);
        assertEquals(EhUrl.URL_FAVORITES_EX, EhUrl.getFavoritesUrl());
    }

    @Test
    public void getReferer_siteE_returnsRefererE() {
        Settings.putGallerySite(EhUrl.SITE_E);
        assertEquals(EhUrl.REFERER_E, EhUrl.getReferer());
    }

    @Test
    public void getReferer_siteEx_returnsRefererEx() {
        Settings.putGallerySite(EhUrl.SITE_EX);
        assertEquals(EhUrl.REFERER_EX, EhUrl.getReferer());
    }

    @Test
    public void getOrigin_siteE_returnsOriginE() {
        Settings.putGallerySite(EhUrl.SITE_E);
        assertEquals(EhUrl.ORIGIN_E, EhUrl.getOrigin());
    }

    @Test
    public void getOrigin_siteEx_returnsOriginEx() {
        Settings.putGallerySite(EhUrl.SITE_EX);
        assertEquals(EhUrl.ORIGIN_EX, EhUrl.getOrigin());
    }

    @Test
    public void getUConfigUrl_siteE_returnsUConfigE() {
        Settings.putGallerySite(EhUrl.SITE_E);
        assertEquals(EhUrl.URL_UCONFIG_E, EhUrl.getUConfigUrl());
    }

    @Test
    public void getUConfigUrl_siteEx_returnsUConfigEx() {
        Settings.putGallerySite(EhUrl.SITE_EX);
        assertEquals(EhUrl.URL_UCONFIG_EX, EhUrl.getUConfigUrl());
    }

    @Test
    public void getMyTagsUrl_siteE_returnsMyTagsE() {
        Settings.putGallerySite(EhUrl.SITE_E);
        assertEquals(EhUrl.URL_MY_TAGS_E, EhUrl.getMyTagsUrl());
    }

    @Test
    public void getMyTagsUrl_siteEx_returnsMyTagsEx() {
        Settings.putGallerySite(EhUrl.SITE_EX);
        assertEquals(EhUrl.URL_MY_TAGS_EX, EhUrl.getMyTagsUrl());
    }

    @Test
    public void getPopularUrl_siteE_returnsPopularE() {
        Settings.putGallerySite(EhUrl.SITE_E);
        assertEquals(EhUrl.URL_POPULAR_E, EhUrl.getPopularUrl());
    }

    @Test
    public void getPopularUrl_siteEx_returnsPopularEx() {
        Settings.putGallerySite(EhUrl.SITE_EX);
        assertEquals(EhUrl.URL_POPULAR_EX, EhUrl.getPopularUrl());
    }

    @Test
    public void getImageSearchUrl_siteE_returnsImageSearchE() {
        Settings.putGallerySite(EhUrl.SITE_E);
        assertEquals(EhUrl.URL_IMAGE_SEARCH_E, EhUrl.getImageSearchUrl());
    }

    @Test
    public void getImageSearchUrl_siteEx_returnsImageSearchEx() {
        Settings.putGallerySite(EhUrl.SITE_EX);
        assertEquals(EhUrl.URL_IMAGE_SEARCH_EX, EhUrl.getImageSearchUrl());
    }

    @Test
    public void getWatchedUrl_siteE_returnsWatchedE() {
        Settings.putGallerySite(EhUrl.SITE_E);
        assertEquals(EhUrl.URL_WATCHED_E, EhUrl.getWatchedUrl());
    }

    @Test
    public void getWatchedUrl_siteEx_returnsWatchedEx() {
        Settings.putGallerySite(EhUrl.SITE_EX);
        assertEquals(EhUrl.URL_WATCHED_EX, EhUrl.getWatchedUrl());
    }

    @Test
    public void getGalleryDetailUrl_twoArgs_buildsBaseDetailUrl() {
        Settings.putGallerySite(EhUrl.SITE_E);
        String url = EhUrl.getGalleryDetailUrl(12345L, "abc123token");
        assertTrue(url.startsWith(EhUrl.HOST_E + "g/12345/abc123token/"));
        assertTrue(!url.contains("p="));
    }

    @Test
    public void getGalleryDetailUrl_withIndex_addsPageParam() {
        Settings.putGallerySite(EhUrl.SITE_E);
        String url = EhUrl.getGalleryDetailUrl(100L, "tok", 2, false);
        assertTrue(url.contains("p=2"));
    }

    @Test
    public void getGalleryDetailUrl_allComment_addsHcParam() {
        Settings.putGallerySite(EhUrl.SITE_E);
        String url = EhUrl.getGalleryDetailUrl(100L, "tok", 0, true);
        assertTrue(url.contains("hc=1"));
    }

    @Test
    public void getPageUrl_buildsCorrectFormat() {
        Settings.putGallerySite(EhUrl.SITE_E);
        String url = EhUrl.getPageUrl(999L, 0, "ptoken123");
        assertEquals(EhUrl.HOST_E + "s/ptoken123/999-1", url);
    }

    @Test
    public void getPageUrl_indexOne_buildsPageTwo() {
        Settings.putGallerySite(EhUrl.SITE_E);
        String url = EhUrl.getPageUrl(100L, 1, "pt");
        assertEquals(EhUrl.HOST_E + "s/pt/100-2", url);
    }

    @Test
    public void getAddFavorites_buildsCorrectUrl() {
        Settings.putGallerySite(EhUrl.SITE_E);
        String url = EhUrl.getAddFavorites(50L, "t0k");
        assertEquals(EhUrl.HOST_E + "gallerypopups.php?gid=50&t=t0k&act=addfav", url);
    }

    @Test
    public void getDownloadArchive_buildsCorrectUrl() {
        Settings.putGallerySite(EhUrl.SITE_E);
        String url = EhUrl.getDownloadArchive(100L, "token", "dl");
        assertEquals(EhUrl.HOST_E + "archiver.php?gid=100&token=token&or=dl", url);
    }

    @Test
    public void getTagDefinitionUrl_replacesSpaces() {
        String url = EhUrl.getTagDefinitionUrl("female:big breasts");
        assertEquals("https://ehwiki.org/wiki/female:big_breasts", url);
    }

    @Test
    public void getTagDefinitionUrl_noSpaces_unchanged() {
        String url = EhUrl.getTagDefinitionUrl("artist:name");
        assertEquals("https://ehwiki.org/wiki/artist:name", url);
    }

    @Test
    public void getThumbUrlPrefix_returnsEhgtPrefix() {
        assertNotNull(EhUrl.getThumbUrlPrefix());
        assertTrue(EhUrl.getThumbUrlPrefix().startsWith("https://ehgt.org/"));
    }

    @Test
    public void getFixedPreviewThumbUrl_validSegments_rewritesToThumbPrefix() {
        String origin = "https://exhentai.org/t/31/7a/317a1a254cd9c3269e71b2aa2671fe8d28c91097-260198-640-480-png_250.jpg";
        String fixed = EhUrl.getFixedPreviewThumbUrl(origin);
        assertTrue(fixed.startsWith("https://ehgt.org/"));
        assertTrue(fixed.contains("31/7a/"));
        assertTrue(fixed.endsWith("317a1a254cd9c3269e71b2aa2671fe8d28c91097-260198-640-480-png_250.jpg"));
    }

    @Test
    public void getFixedPreviewThumbUrl_tooFewSegments_returnsOrigin() {
        String origin = "https://exhentai.org/short";
        assertEquals(origin, EhUrl.getFixedPreviewThumbUrl(origin));
    }

    @Test
    public void getFixedPreviewThumbUrl_invalidUrl_returnsOrigin() {
        String origin = "not-a-url";
        assertEquals(origin, EhUrl.getFixedPreviewThumbUrl(origin));
    }

    @Test
    public void constants_loginAndForums_areCorrect() {
        assertTrue(EhUrl.API_SIGN_IN.contains("forums.e-hentai.org"));
        assertTrue(EhUrl.API_SIGN_IN.contains("Login"));
        assertTrue(EhUrl.URL_SIGN_IN.contains("forums.e-hentai.org"));
        assertTrue(EhUrl.URL_REGISTER.contains("forums.e-hentai.org"));
        assertEquals("https://forums.e-hentai.org/", EhUrl.URL_FORUMS);
    }
}
