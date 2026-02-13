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

package com.hippo.ehviewer.client.parser;

import com.hippo.ehviewer.client.exception.EhException;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class GalleryTokenApiParser {

    /**
     * Parses Token API response.
     * Expected format:
     * {
     *  "tokenlist": [
     *   { "gid": 618395, "token": "0439fa3666" }
     *  ]
     * }
     * Or on error: { "tokenlist": [{ "gid": 618395, "error": "Key missing, ..." }] }
     */
    public static String parse(String body) throws JSONException, EhException {
        JSONObject root = new JSONObject(body);
        if (!root.has("tokenlist")) {
            throw new EhException("No tokenlist in response");
        }
        JSONArray tokenlist = root.getJSONArray("tokenlist");
        if (tokenlist.length() == 0) {
            throw new EhException("No token in response");
        }
        JSONObject item = tokenlist.getJSONObject(0);
        if (item.has("token")) {
            return item.getString("token");
        }
        if (item.has("error")) {
            throw new EhException(item.getString("error"));
        }
        throw new EhException("No token in response");
    }
}
