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

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.hippo.content.FileProvider;
import com.hippo.unifile.UniFile;
import com.hippo.yorozuya.FileUtils;
import java.io.File;

/**
 * Centralized utility for application file storage paths and share URI generation.
 * <p>
 * All file path operations in the app should go through this class to ensure
 * scoped-storage compliance and consistent FileProvider usage.
 * <p>
 * Provides directory access for:
 * <ul>
 *   <li>Download directories (File and UniFile)</li>
 *   <li>Cache directories (internal + external)</li>
 *   <li>Share/temp directories for FileProvider-based sharing</li>
 *   <li>Image save directories</li>
 * </ul>
 */
public final class AppFileProvider {

    private static final String SHARE_DIR = FilePathSpec.SHARE_DIR;
    private static final String TEMP_DIR = FilePathSpec.TEMP_DIR;
    private static final String IMAGE_DIR = FilePathSpec.IMAGE_DIR;
    private static final String DOWNLOAD_DIR = FilePathSpec.DOWNLOAD_DIR;

    private AppFileProvider() {
        throw new AssertionError("No instances");
    }

    // ---- Directory access ----

    /**
     * Returns the share directory under internal cache for temporary file sharing.
     * Files in this directory can be exposed via FileProvider.
     */
    @Nullable
    public static File getShareDir(@NonNull Context context) {
        File cacheDir = context.getCacheDir();
        if (cacheDir == null) {
            return null;
        }
        File dir = new File(cacheDir, SHARE_DIR);
        return FileUtils.ensureDirectory(dir) ? dir : null;
    }

    /**
     * Returns the temp directory under internal cache.
     */
    @Nullable
    public static File getTempDir(@NonNull Context context) {
        File cacheDir = context.getCacheDir();
        if (cacheDir == null) {
            return null;
        }
        File dir = new File(cacheDir, TEMP_DIR);
        return FileUtils.ensureDirectory(dir) ? dir : null;
    }

    /**
     * Returns the image save directory.
     * On Android 10+, uses scoped storage (getExternalFilesDir).
     * On older versions, falls back to AppConfig's external image dir.
     */
    @Nullable
    public static File getImageDir(@NonNull Context context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            File dir = context.getExternalFilesDir(IMAGE_DIR);
            if (dir != null && FileUtils.ensureDirectory(dir)) {
                return dir;
            }
        }
        return AppConfig.getExternalImageDir();
    }

    /**
     * Returns the download directory.
     * On Android 10+, uses Context.getExternalFilesDir("download").
     * On older versions, falls back to AppConfig's default download dir.
     */
    @Nullable
    public static File getDownloadDir(@NonNull Context context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            File dir = context.getExternalFilesDir(DOWNLOAD_DIR);
            if (dir != null && FileUtils.ensureDirectory(dir)) {
                return dir;
            }
        }
        return AppConfig.getDefaultDownloadDir();
    }

    /**
     * Returns the external cache directory.
     */
    @Nullable
    public static File getExternalCacheDir(@NonNull Context context) {
        return context.getExternalCacheDir();
    }

    // ---- UniFile wrappers ----

    /**
     * Returns the download directory as a UniFile.
     * Delegates to Settings.getDownloadLocation() if a custom location is configured,
     * otherwise falls back to the default download directory.
     */
    @Nullable
    public static UniFile getDownloadUniFile(@NonNull Context context) {
        UniFile location = Settings.getDownloadLocation();
        if (location != null) {
            return location;
        }
        File dir = getDownloadDir(context);
        return dir != null ? UniFile.fromFile(dir) : null;
    }

    /**
     * Returns the share directory as a UniFile.
     */
    @Nullable
    public static UniFile getShareUniFile(@NonNull Context context) {
        File dir = getShareDir(context);
        return dir != null ? UniFile.fromFile(dir) : null;
    }

    /**
     * Returns the image save directory as a UniFile.
     */
    @Nullable
    public static UniFile getImageUniFile(@NonNull Context context) {
        File dir = getImageDir(context);
        return dir != null ? UniFile.fromFile(dir) : null;
    }

    /**
     * Returns the temp directory as a UniFile.
     */
    @Nullable
    public static UniFile getTempUniFile(@NonNull Context context) {
        File dir = getTempDir(context);
        return dir != null ? UniFile.fromFile(dir) : null;
    }

    // ---- FileProvider / sharing ----

    /**
     * Generates a content:// URI for a file via the app's FileProvider.
     *
     * @param context Application context
     * @param file    The file to generate a URI for
     * @return A content URI suitable for sharing with other apps
     * @throws IllegalArgumentException if the file is outside configured FileProvider roots
     */
    @NonNull
    public static Uri getUriForFile(@NonNull Context context, @NonNull File file) {
        return FileProvider.getUriForFile(context, BuildConfig.FILE_PROVIDER_AUTHORITY, file);
    }

    /**
     * Creates a share Intent for a file with the given MIME type.
     *
     * @param context  Application context
     * @param file     The file to share
     * @param mimeType The MIME type of the file (e.g. "image/jpeg")
     * @return An ACTION_SEND Intent with the content URI and proper flags, or null if URI generation fails
     */
    @Nullable
    public static Intent createShareIntent(@NonNull Context context, @NonNull File file,
            @NonNull String mimeType) {
        Uri uri;
        try {
            uri = getUriForFile(context, file);
        } catch (IllegalArgumentException e) {
            return null;
        }

        Intent intent = new Intent(Intent.ACTION_SEND);
        intent.putExtra(Intent.EXTRA_STREAM, uri);
        intent.setType(mimeType);
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
        return intent;
    }

    /**
     * Clears the share directory to free temporary shared files.
     */
    public static void clearShareDir(@NonNull Context context) {
        File dir = getShareDir(context);
        if (dir != null) {
            FileUtils.deleteContent(dir);
        }
    }

    /**
     * Clears the temp directory.
     */
    public static void clearTempDir(@NonNull Context context) {
        File dir = getTempDir(context);
        if (dir != null) {
            FileUtils.deleteContent(dir);
        }
    }
}
