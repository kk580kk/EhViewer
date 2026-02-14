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

/**
 * Visitor interface for HTML node tree traversal, modeled after jsoup's {@code NodeVisitor}.
 */
public interface HNodeVisitor {

    /** Called when a node is first visited (entering). */
    void head(HNode node, int depth);

    /** Called when a node's descendants have all been visited (leaving). */
    void tail(HNode node, int depth);
}
