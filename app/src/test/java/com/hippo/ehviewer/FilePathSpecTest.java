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

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

public class FilePathSpecTest {

    @Test
    public void directoryConstantsAreNonEmpty() {
        assertNotNull(FilePathSpec.SHARE_DIR);
        assertFalse(FilePathSpec.SHARE_DIR.isEmpty());
        assertNotNull(FilePathSpec.TEMP_DIR);
        assertNotNull(FilePathSpec.IMAGE_DIR);
        assertNotNull(FilePathSpec.DOWNLOAD_DIR);
    }

    @Test
    public void supportImageExtensionsHasEntriesWithLeadingDot() {
        assertNotNull(FilePathSpec.SUPPORT_IMAGE_EXTENSIONS);
        assertTrue(FilePathSpec.SUPPORT_IMAGE_EXTENSIONS.length > 0);
        for (String ext : FilePathSpec.SUPPORT_IMAGE_EXTENSIONS) {
            assertTrue("Extension should start with dot: " + ext, ext.startsWith("."));
        }
    }

    @Test
    public void formatGalleryDirnameProducesGidPrefixAndSanitizes() {
        String dirname = FilePathSpec.formatGalleryDirname(12345L, "My Gallery Title");
        assertNotNull(dirname);
        assertTrue(dirname.startsWith("12345-"));
        assertTrue(dirname.contains("My") || dirname.contains("Gallery") || dirname.contains("Title"));
    }

    @Test
    public void formatGalleryDirnameSanitizesPathSeparators() {
        String dirname = FilePathSpec.formatGalleryDirname(1L, "a/b\\c");
        assertNotNull(dirname);
        assertFalse("Should not contain path separators", dirname.contains("/"));
        assertFalse("Should not contain backslash", dirname.contains("\\"));
    }

    @Test
    public void formatDownloadImageFilenameZeroBasedIndex() {
        assertEquals("00000001.jpg", FilePathSpec.formatDownloadImageFilename(0, ".jpg"));
        assertEquals("00000002.png", FilePathSpec.formatDownloadImageFilename(1, ".png"));
        assertEquals("00001000.gif", FilePathSpec.formatDownloadImageFilename(999, ".gif"));
    }

    @Test
    public void formatEhGalleryImageFilenameFormat() {
        assertEquals("123-abc-00000001", FilePathSpec.formatEhGalleryImageFilename(123, "abc", 0));
        assertEquals("123-abc-00000002", FilePathSpec.formatEhGalleryImageFilename(123, "abc", 1));
        assertEquals("1-token-00000100", FilePathSpec.formatEhGalleryImageFilename(1, "token", 99));
    }

    @Test
    public void isSupportedImageExtensionAcceptsKnownExtensions() {
        assertTrue(FilePathSpec.isSupportedImageExtension(".jpg"));
        assertTrue(FilePathSpec.isSupportedImageExtension(".jpeg"));
        assertTrue(FilePathSpec.isSupportedImageExtension(".png"));
        assertTrue(FilePathSpec.isSupportedImageExtension(".gif"));
        assertTrue(FilePathSpec.isSupportedImageExtension(".JPG"));
        assertTrue(FilePathSpec.isSupportedImageExtension(".PNG"));
    }

    @Test
    public void isSupportedImageExtensionRejectsUnknown() {
        assertFalse(FilePathSpec.isSupportedImageExtension(".bmp"));
        assertFalse(FilePathSpec.isSupportedImageExtension(".webp"));
        assertFalse(FilePathSpec.isSupportedImageExtension("jpg"));
    }

    @Test
    public void normalizeImageExtensionReturnsSupported() {
        assertEquals(".jpg", FilePathSpec.normalizeImageExtension(".jpg"));
        assertEquals(".png", FilePathSpec.normalizeImageExtension(".png"));
        assertEquals(FilePathSpec.SUPPORT_IMAGE_EXTENSIONS[0], FilePathSpec.normalizeImageExtension(".unknown"));
    }
}
