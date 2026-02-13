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

package com.hippo.ehviewer.client.exception;

/**
 * Thrown when response body cannot be parsed (e.g. HTML/JSON structure unexpected).
 * Carries the raw body for debugging via {@link #getBody()}.
 */
public class ParseException extends EhException {

    private static final long serialVersionUID = 1L;

    private final String mBody;

    public ParseException(String detailMessage, String body) {
        super(detailMessage);
        mBody = body;
    }

    public ParseException(String detailMessage, String body, Throwable cause) {
        super(detailMessage, cause);
        mBody = body;
    }

    public String getBody() {
        return mBody;
    }
}
