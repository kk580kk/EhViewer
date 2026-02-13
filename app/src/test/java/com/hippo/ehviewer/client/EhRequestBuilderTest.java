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
import static org.junit.Assert.assertNull;

import okhttp3.MediaType;
import okhttp3.Request;
import okhttp3.RequestBody;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class EhRequestBuilderTest {

    private static final String URL = "https://e-hentai.org/";
    private static final String REFERER = "https://e-hentai.org/";
    private static final String ORIGIN = "https://e-hentai.org";

    @Test
    public void get_buildsGetRequestWithNoBody() {
        Request request = new EhRequestBuilder(URL, REFERER).get().build();
        assertEquals("GET", request.method());
        assertNull(request.body());
        assertEquals(URL, request.url().toString());
        assertEquals(REFERER, request.header("Referer"));
    }

    @Test
    public void build_withoutGet_returnsGetByDefault() {
        Request request = new EhRequestBuilder(URL, REFERER).build();
        assertEquals("GET", request.method());
        assertNull(request.body());
    }

    @Test
    public void post_withBody_buildsPostRequest() {
        RequestBody body = RequestBody.create(MediaType.parse("text/plain"), "data");
        Request request = new EhRequestBuilder(URL, REFERER, ORIGIN).post(body).build();
        assertEquals("POST", request.method());
        assertNotNull(request.body());
        assertEquals(REFERER, request.header("Referer"));
        assertEquals(ORIGIN, request.header("Origin"));
    }

    @Test
    public void addHeader_addsCustomHeader() {
        Request request = new EhRequestBuilder(URL, REFERER)
                .addHeader("X-Custom", "value")
                .build();
        assertEquals("value", request.header("X-Custom"));
    }

    @Test
    public void addCookie_single_addsCookieHeader() {
        Request request = new EhRequestBuilder(URL, REFERER)
                .addCookie("session", "abc123")
                .build();
        assertEquals("session=abc123", request.header("Cookie"));
    }

    @Test
    public void addCookie_multiple_joinsWithSemicolon() {
        Request request = new EhRequestBuilder(URL, REFERER)
                .addCookie("a", "1")
                .addCookie("b", "2")
                .build();
        assertEquals("a=1; b=2", request.header("Cookie"));
    }

    @Test
    public void addCookie_nullName_ignored() {
        Request request = new EhRequestBuilder(URL, REFERER)
                .addCookie(null, "v")
                .build();
        assertNull(request.header("Cookie"));
    }

    @Test
    public void addCookie_nullValue_ignored() {
        Request request = new EhRequestBuilder(URL, REFERER)
                .addCookie("n", null)
                .build();
        assertNull(request.header("Cookie"));
    }

    @Test
    public void constructor_nullReferer_skipsReferer() {
        Request request = new EhRequestBuilder(URL, null).build();
        assertNull(request.header("Referer"));
    }

    @Test
    public void constructor_nullOrigin_skipsOrigin() {
        Request request = new EhRequestBuilder(URL, REFERER, null).build();
        assertNull(request.header("Origin"));
    }
}
