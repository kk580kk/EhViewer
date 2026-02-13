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

import com.hippo.okhttp.ChromeRequestBuilder;
import java.util.ArrayList;
import java.util.List;
import okhttp3.Request;
import okhttp3.RequestBody;

/**
 * Builds GET/POST requests for the Eh HTTP client (OkHttp).
 * Supports Header, Body, and Cookie injection.
 */
public class EhRequestBuilder extends ChromeRequestBuilder {

    private final List<String> mCookies = new ArrayList<>();

    public EhRequestBuilder(String url, String referer) {
        this(url, referer, null);
    }

    public EhRequestBuilder(String url, String referer, String origin) {
        super(url);
        if (referer != null) {
            addHeader("Referer", referer);
        }
        if (origin != null) {
            addHeader("Origin", origin);
        }
    }

    /** Explicit GET request (no body). */
    public EhRequestBuilder get() {
        return this;
    }

    /** POST with body. Returns this for chaining. */
    @Override
    public EhRequestBuilder post(RequestBody body) {
        super.post(body);
        return this;
    }

    /** Add a cookie to be sent in the Cookie header. */
    public EhRequestBuilder addCookie(String name, String value) {
        if (name != null && value != null) {
            mCookies.add(name + "=" + value);
        }
        return this;
    }

    @Override
    public Request build() {
        if (!mCookies.isEmpty()) {
            addHeader("Cookie", String.join("; ", mCookies));
        }
        return super.build();
    }
}
