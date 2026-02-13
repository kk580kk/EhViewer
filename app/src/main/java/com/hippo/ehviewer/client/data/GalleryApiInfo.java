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

package com.hippo.ehviewer.client.data;

import android.os.Parcel;
import android.os.Parcelable;
import androidx.annotation.Nullable;

import com.hippo.ehviewer.client.EhUtils;
import com.hippo.ehviewer.client.parser.ParserUtils;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class GalleryApiInfo implements Parcelable {

    public long gid;
    public String token;
    public String archiverKey;
    public String title;
    public String titleJpn;
    public int category;
    public String thumb;
    public String uploader;
    public long posted;
    public int filecount;
    public long filesize;
    public boolean expunged;
    public float rating;
    public int torrentcount;
    @Nullable
    public String[] tags;

    /**
     * Parses a single gallery object from the gmetadata API response.
     *
     * @param g JSON object for one gallery (e.g. from the "gmetadata" array)
     * @return parsed GalleryApiInfo, never null
     */
    public static GalleryApiInfo fromJson(JSONObject g) throws JSONException {
        GalleryApiInfo info = new GalleryApiInfo();
        info.gid = g.getLong("gid");
        info.token = g.optString("token", null);
        info.archiverKey = g.optString("archiver_key", null);
        info.title = ParserUtils.trim(g.optString("title", ""));
        info.titleJpn = ParserUtils.trim(g.optString("title_jpn", ""));
        info.category = EhUtils.getCategory(g.optString("category", ""));
        info.thumb = g.optString("thumb", null);
        info.uploader = g.optString("uploader", null);
        info.posted = ParserUtils.parseLong(g.optString("posted", "0"), 0L);
        info.filecount = ParserUtils.parseInt(g.optString("filecount", "0"), 0);
        info.filesize = ParserUtils.parseLong(g.optString("filesize", "0"), 0L);
        info.expunged = g.optBoolean("expunged", false);
        info.rating = ParserUtils.parseFloat(g.optString("rating", "0"), 0.0f);
        info.torrentcount = ParserUtils.parseInt(g.optString("torrentcount", "0"), 0);
        JSONArray tagArr = g.optJSONArray("tags");
        if (tagArr != null) {
            int len = tagArr.length();
            info.tags = new String[len];
            for (int i = 0; i < len; i++) {
                info.tags[i] = tagArr.getString(i);
            }
        } else {
            info.tags = null;
        }
        return info;
    }

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeLong(this.gid);
        dest.writeString(this.token);
        dest.writeString(this.archiverKey);
        dest.writeString(this.title);
        dest.writeString(this.titleJpn);
        dest.writeInt(this.category);
        dest.writeString(this.thumb);
        dest.writeString(this.uploader);
        dest.writeLong(this.posted);
        dest.writeInt(this.filecount);
        dest.writeLong(this.filesize);
        dest.writeByte(expunged ? (byte) 1 : (byte) 0);
        dest.writeFloat(this.rating);
        dest.writeInt(this.torrentcount);
        dest.writeStringArray(this.tags);
    }

    public GalleryApiInfo() {
    }

    protected GalleryApiInfo(Parcel in) {
        this.gid = in.readLong();
        this.token = in.readString();
        this.archiverKey = in.readString();
        this.title = in.readString();
        this.titleJpn = in.readString();
        this.category = in.readInt();
        this.thumb = in.readString();
        this.uploader = in.readString();
        this.posted = in.readLong();
        this.filecount = in.readInt();
        this.filesize = in.readLong();
        this.expunged = in.readByte() != 0;
        this.rating = in.readFloat();
        this.torrentcount = in.readInt();
        this.tags = in.createStringArray();
    }

    public static final Parcelable.Creator<GalleryApiInfo> CREATOR = new Parcelable.Creator<GalleryApiInfo>() {
        @Override
        public GalleryApiInfo createFromParcel(Parcel source) {
            return new GalleryApiInfo(source);
        }

        @Override
        public GalleryApiInfo[] newArray(int size) {
            return new GalleryApiInfo[size];
        }
    };
}
