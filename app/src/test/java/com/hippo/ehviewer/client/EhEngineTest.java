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

import com.hippo.ehviewer.client.exception.EhException;
import com.hippo.network.StatusCodeException;
import java.io.IOException;
import okhttp3.Interceptor;
import okhttp3.OkHttpClient;
import okhttp3.Protocol;
import okhttp3.Response;
import okhttp3.ResponseBody;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

/**
 * Tests that EhEngine executes EhRequestBuilder-built requests, parses with the corresponding
 * Parser, and maps errors (HTTP 4xx/5xx, sad panda, kokomade, etc.) to the exception system.
 */
@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class EhEngineTest {

    private static final String GALLERY_URL = "https://e-hentai.org/g/123/abc/";

    private static OkHttpClient clientWithResponse(final int code, final String body,
            final String contentType) {
        return new OkHttpClient.Builder()
                .addInterceptor(new Interceptor() {
                    @Override
                    public Response intercept(Chain chain) throws IOException {
                        ResponseBody responseBody = body != null
                                ? ResponseBody.create(null, body) : null;
                        return new Response.Builder()
                                .request(chain.request())
                                .protocol(Protocol.HTTP_1_1)
                                .code(code)
                                .message("")
                                .body(responseBody)
                                .header("Content-Type", contentType != null ? contentType : "text/html")
                                .build();
                    }
                })
                .build();
    }

    @Test
    public void http403_mapsToStatusCodeException() throws Throwable {
        OkHttpClient client = clientWithResponse(403, "", "text/html");
        try {
            EhEngine.getGalleryDetail(null, client, GALLERY_URL);
        } catch (StatusCodeException e) {
            assertEquals(403, e.getResponseCode());
            return;
        }
        assertTrue("Expected StatusCodeException", false);
    }

    @Test
    public void http500_mapsToStatusCodeException() throws Throwable {
        OkHttpClient client = clientWithResponse(500, "error", "text/plain");
        try {
            EhEngine.getGalleryDetail(null, client, GALLERY_URL);
        } catch (StatusCodeException e) {
            assertEquals(500, e.getResponseCode());
            return;
        }
        assertTrue("Expected StatusCodeException", false);
    }

    @Test
    public void kokomadeBody_mapsToEhException() throws Throwable {
        String bodyWithKokomade = "<html><body><img src=\"https://exhentai.org/img/kokomade.jpg\"></body></html>";
        OkHttpClient client = clientWithResponse(200, bodyWithKokomade, "text/html");
        try {
            EhEngine.getGalleryDetail(null, client, GALLERY_URL);
        } catch (EhException e) {
            assertNotNull(e.getMessage());
            assertTrue(e.getMessage().contains("ここまで"));
            return;
        }
        assertTrue("Expected EhException", false);
    }

    @Test
    public void sadPandaHeaders_mapsToEhException() throws Throwable {
        OkHttpClient client = new OkHttpClient.Builder()
                .addInterceptor(new Interceptor() {
                    @Override
                    public Response intercept(Chain chain) throws IOException {
                        return new Response.Builder()
                                .request(chain.request())
                                .protocol(Protocol.HTTP_1_1)
                                .code(200)
                                .message("")
                                .body(ResponseBody.create(null, ""))
                                .addHeader("Content-Disposition", "inline; filename=\"sadpanda.jpg\"")
                                .addHeader("Content-Type", "image/gif")
                                .addHeader("Content-Length", "9615")
                                .build();
                    }
                })
                .build();
        try {
            EhEngine.getGalleryDetail(null, client, GALLERY_URL);
        } catch (EhException e) {
            assertEquals("Sad Panda", e.getMessage());
            return;
        }
        assertTrue("Expected EhException", false);
    }
}
