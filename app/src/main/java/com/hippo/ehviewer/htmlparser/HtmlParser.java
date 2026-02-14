/*
 * Copyright 2024 EhViewer Contributors
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

package com.hippo.ehviewer.htmlparser;

import androidx.annotation.NonNull;
import com.hippo.ehviewer.htmlparser.impl.JsoupDocument;
import org.jsoup.Jsoup;

/**
 * Entry point for parsing HTML into the read-only adapter API.
 * <p>
 * Replaces direct calls to {@code Jsoup.parse()} so that the underlying
 * HTML parser can be swapped without modifying parser code.
 */
public final class HtmlParser {

    private HtmlParser() {}

    /**
     * Parse HTML into a read-only {@link HDocument}.
     */
    @NonNull
    public static HDocument parse(@NonNull String html) {
        return new JsoupDocument(Jsoup.parse(html));
    }

    /**
     * Parse HTML with a base URI into a read-only {@link HDocument}.
     */
    @NonNull
    public static HDocument parse(@NonNull String html, @NonNull String baseUri) {
        return new JsoupDocument(Jsoup.parse(html, baseUri));
    }
}
