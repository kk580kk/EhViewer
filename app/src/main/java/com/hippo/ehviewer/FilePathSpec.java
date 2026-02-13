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

package com.hippo.ehviewer;

import androidx.annotation.NonNull;
import com.hippo.yorozuya.FileUtils;
import java.util.Locale;

/**
 * Central specification for application file and path conventions.
 * <p>
 * Download and gallery modules must use these constants and helpers so that:
 * <ul>
 *   <li>Downloaded galleries live under a root download dir in directories named
 *       {@code {gid}-{sanitized_title}}.</li>
 *   <li>Images inside a gallery directory are named with an 8-digit index plus
 *       extension (e.g. {@code 00000001.jpg}).</li>
 *   <li>EhGallery display/save filenames (no extension) use
 *       {@code {gid}-{token}-{index_8d}}.</li>
 *   <li>Directory names for cache, share, temp, image save, and download are
 *       consistent across {@link AppFileProvider} and any path resolution.</li>
 * </ul>
 */
public final class FilePathSpec {

    private FilePathSpec() {
        throw new AssertionError("No instances");
    }

    // ---- Directory names (used by AppFileProvider and path resolution) ----

    /** Subdir under cache for temporary file sharing (FileProvider). */
    public static final String SHARE_DIR = "share";
    /** Subdir under cache for temp files. */
    public static final String TEMP_DIR = "temp";
    /** Subdir for image save location (e.g. getExternalFilesDir). */
    public static final String IMAGE_DIR = "image";
    /** Subdir for default download root (e.g. getExternalFilesDir). */
    public static final String DOWNLOAD_DIR = "download";

    /**
     * Supported image file extensions for gallery and download, with leading dot.
     * Order may be used as default when extension is unknown.
     */
    public static final String[] SUPPORT_IMAGE_EXTENSIONS = {
            ".jpg",
            ".jpeg",
            ".png",
            ".gif",
    };

    // ---- Gallery download directory ----

    /**
     * Builds the gallery download directory name: {@code {gid}-{suitableTitle}},
     * sanitized for filesystem use.
     *
     * @param gid           gallery id
     * @param suitableTitle title suitable for display (e.g. from EhUtils.getSuitableTitle)
     * @return sanitized dirname
     */
    @NonNull
    public static String formatGalleryDirname(long gid, @NonNull String suitableTitle) {
        String raw = gid + "-" + suitableTitle;
        String sanitized = FileUtils.sanitizeFilename(raw);
        return sanitized != null ? sanitized : raw;
    }

    // ---- Downloaded image filename (on disk) ----

    /**
     * Format for a single image file inside a gallery download directory:
     * 8-digit 1-based index plus extension (e.g. 00000001.jpg).
     *
     * @param index            0-based page index
     * @param extensionWithDot extension including dot (e.g. ".jpg")
     * @return filename for the image file
     */
    @NonNull
    public static String formatDownloadImageFilename(int index, @NonNull String extensionWithDot) {
        return String.format(Locale.US, "%08d%s", index + 1, extensionWithDot);
    }

    /**
     * Checks whether the given extension (with dot) is one of the supported image types.
     */
    public static boolean isSupportedImageExtension(@NonNull String extensionWithDot) {
        for (String ext : SUPPORT_IMAGE_EXTENSIONS) {
            if (ext.equalsIgnoreCase(extensionWithDot)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Normalizes an extension to a supported one; returns the first supported extension if unknown.
     *
     * @param extensionWithDot extension including dot
     * @return a supported extension (with dot)
     */
    @NonNull
    public static String normalizeImageExtension(@NonNull String extensionWithDot) {
        if (isSupportedImageExtension(extensionWithDot)) {
            return extensionWithDot;
        }
        return SUPPORT_IMAGE_EXTENSIONS[0];
    }

    // ---- EhGallery display / save filename (no extension) ----

    /**
     * Display/save filename for EhGallery (online) images, without extension.
     * Format: {@code {gid}-{token}-{index_8d}}.
     *
     * @param gid   gallery id
     * @param token gallery token
     * @param index 0-based page index
     * @return filename without extension
     */
    @NonNull
    public static String formatEhGalleryImageFilename(long gid, @NonNull String token, int index) {
        return String.format(Locale.US, "%d-%s-%08d", gid, token, index + 1);
    }
}
