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
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;

import com.hippo.ehviewer.Settings;
import java.util.List;
import okhttp3.Request;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class EhUtilsTest {

    @Before
    public void setUp() {
        Settings.initialize(RuntimeEnvironment.application);
    }

    @Test
    public void requestHeaderConstants_areNonEmpty() {
        assertNotNull(EhUtils.USER_AGENT);
        assertFalse(EhUtils.USER_AGENT.isEmpty());
        assertTrue(EhUtils.USER_AGENT.contains("Chrome"));
        assertNotNull(EhUtils.ACCEPT_HEADER);
        assertFalse(EhUtils.ACCEPT_HEADER.isEmpty());
        assertNotNull(EhUtils.ACCEPT_LANGUAGE_HEADER);
        assertFalse(EhUtils.ACCEPT_LANGUAGE_HEADER.isEmpty());
    }

    @Test
    public void getReferer_siteE_returnsRefererE() {
        Settings.putGallerySite(EhUrl.SITE_E);
        assertEquals(EhUrl.REFERER_E, EhUtils.getReferer());
    }

    @Test
    public void getReferer_siteEx_returnsRefererEx() {
        Settings.putGallerySite(EhUrl.SITE_EX);
        assertEquals(EhUrl.REFERER_EX, EhUtils.getReferer());
    }

    @Test
    public void getOrigin_siteE_returnsOriginE() {
        Settings.putGallerySite(EhUrl.SITE_E);
        assertEquals(EhUrl.ORIGIN_E, EhUtils.getOrigin());
    }

    @Test
    public void getOrigin_siteEx_returnsOriginEx() {
        Settings.putGallerySite(EhUrl.SITE_EX);
        assertEquals(EhUrl.ORIGIN_EX, EhUtils.getOrigin());
    }

    @Test
    public void applyEhHeaders_addsRefererAndOrigin() {
        Request.Builder builder = new Request.Builder().url("https://e-hentai.org/");
        EhUtils.applyEhHeaders(builder, "https://e-hentai.org/", "https://e-hentai.org");
        Request request = builder.build();
        assertEquals("https://e-hentai.org/", request.header("Referer"));
        assertEquals("https://e-hentai.org", request.header("Origin"));
    }

    @Test
    public void applyEhHeaders_nullReferer_skipsReferer() {
        Request.Builder builder = new Request.Builder().url("https://e-hentai.org/");
        EhUtils.applyEhHeaders(builder, null, "https://e-hentai.org");
        Request request = builder.build();
        assertEquals(null, request.header("Referer"));
        assertEquals("https://e-hentai.org", request.header("Origin"));
    }

    @Test
    public void applyEhHeaders_nullOrigin_skipsOrigin() {
        Request.Builder builder = new Request.Builder().url("https://e-hentai.org/");
        EhUtils.applyEhHeaders(builder, "https://e-hentai.org/", null);
        Request request = builder.build();
        assertEquals("https://e-hentai.org/", request.header("Referer"));
        assertEquals(null, request.header("Origin"));
    }

    @Test
    public void getRequiredSignInCookieNames_returnsMemberIdAndPassHash() {
        List<String> names = EhUtils.getRequiredSignInCookieNames();
        assertEquals(2, names.size());
        assertTrue(names.contains(EhCookieStore.KEY_IPD_MEMBER_ID));
        assertTrue(names.contains(EhCookieStore.KEY_IPD_PASS_HASH));
    }

    @Test
    public void getRequiredSignInCookieNames_isUnmodifiable() {
        List<String> names = EhUtils.getRequiredSignInCookieNames();
        try {
            names.add("other");
            throw new AssertionError("Expected UnsupportedOperationException");
        } catch (UnsupportedOperationException expected) {
            // expected
        }
    }

    @Test
    public void hasSignedIn_noCookies_returnsFalse() {
        // Fresh app has no sign-in cookies
        assertFalse(EhUtils.hasSignedIn(RuntimeEnvironment.application));
    }

    @Test
    public void needSignedIn_default_afterInit_returnsTrue() {
        // Settings.getNeedSignIn() default is true, and no cookies => need sign in
        assertTrue(EhUtils.needSignedIn(RuntimeEnvironment.application));
    }
}
