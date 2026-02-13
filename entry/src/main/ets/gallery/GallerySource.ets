/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

/**
 * Possible sources from which a gallery can be loaded.
 *
 * Used by {@link ReaderState} to tell the reading page and navigation bar
 * where the current gallery comes from.
 */
export type GallerySource = typeof GallerySource[keyof typeof GallerySource];

export const GallerySource = {
  /** Gallery loaded from E-Hentai / ExHentai (online). */
  EH: 'eh',
  /** Gallery loaded from a local directory. */
  DIR: 'dir',
  /** Gallery loaded from an archive file (zip / 7z). */
  ARCHIVE: 'archive',
} as const;
