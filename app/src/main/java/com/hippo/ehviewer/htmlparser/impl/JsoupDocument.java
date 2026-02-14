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

package com.hippo.ehviewer.htmlparser.impl;

import androidx.annotation.NonNull;
import com.hippo.ehviewer.htmlparser.HDocument;
import org.jsoup.nodes.Document;

/**
 * Wraps a jsoup {@link Document} into the read-only {@link HDocument} interface.
 * Extends {@link JsoupElement} since Document is a subclass of Element.
 */
public final class JsoupDocument extends JsoupElement implements HDocument {

    public JsoupDocument(@NonNull Document document) {
        super(document);
    }
}
