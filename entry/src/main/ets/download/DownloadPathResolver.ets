/*
 * Copyright 2024 EhViewer Contributors
 * Ported to HarmonyOS ArkTS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { GalleryInfo } from '../model/GalleryInfo.ets';
import { SettingsService } from '../service/SettingsService.ets';
import { AppConfig } from '../AppConfig.ets';
import { formatGalleryDirname, sanitizeFilename } from '../FilePathSpec.ets';
import { joinPath, ensureDirectory } from '../util/FileUtils.ets';
import type { FsOps } from '../util/FileUtils.ets';
import type { EhDB } from '../database/EhDB.ets';

/**
 * Get the "suitable title" for filesystem use.
 * Prefers Japanese title when show-jpn-title is enabled, otherwise English title.
 */
function getSuitableTitle(gi: GalleryInfo): string {
  if (SettingsService.getShowJpnTitle()) {
    return gi.titleJpn || gi.title || `Gallery ${gi.gid}`;
  }
  return gi.title || gi.titleJpn || `Gallery ${gi.gid}`;
}

/**
 * Resolves the effective download root directory.
 *
 * Priority:
 *   1. User-configured download location (from SettingsService)
 *   2. Default download dir (from AppConfig)
 *
 * Returns null if neither is available.
 */
export function getDownloadRoot(): string | null {
  const custom = SettingsService.getDownloadLocation();
  if (custom !== null && custom.length > 0) {
    return custom;
  }
  return AppConfig.getDownloadDir();
}

/**
 * Resolve the download directory for a specific gallery.
 *
 * Follows the same algorithm as Android SpiderDen.getGalleryDownloadDir:
 *   1. Get the download root directory.
 *   2. Look up a persisted dirname from EhDB.
 *      - If found, re-sanitize it and persist (in case an old version wrote invalid chars).
 *   3. If no persisted dirname, generate one via FilePathSpec.formatGalleryDirname
 *      and persist it.
 *   4. Return the full path: `{downloadRoot}/{dirname}`.
 *
 * Does NOT create the directory on disk — call `ensureGalleryDownloadDir` for that.
 *
 * @param galleryInfo the gallery to resolve the path for
 * @param db          EhDB instance for dirname lookup/persist
 * @returns full directory path, or null if no download root is available
 */
export function getGalleryDownloadDir(galleryInfo: GalleryInfo, db: EhDB): string | null {
  const root = getDownloadRoot();
  if (root === null) {
    return null;
  }

  // 1. Check persisted dirname
  let dirname = db.getDownloadDirname(galleryInfo.gid);

  if (dirname !== null) {
    // Re-sanitize (guard against legacy invalid dirnames)
    const sanitized = sanitizeFilename(dirname);
    if (sanitized !== null && sanitized !== dirname) {
      dirname = sanitized;
      db.putDownloadDirname(galleryInfo.gid, dirname);
    }
  }

  // 2. Generate and persist a new dirname
  if (dirname === null) {
    dirname = formatGalleryDirname(galleryInfo.gid, getSuitableTitle(galleryInfo));
    db.putDownloadDirname(galleryInfo.gid, dirname);
  }

  return joinPath(root, dirname);
}

/**
 * Resolve AND ensure the gallery download directory exists on disk.
 *
 * @param galleryInfo the gallery
 * @param db          EhDB instance
 * @param fs          filesystem adapter
 * @returns full directory path if created/exists, or null on failure
 */
export function ensureGalleryDownloadDir(
  galleryInfo: GalleryInfo,
  db: EhDB,
  fs: FsOps,
): string | null {
  const dir = getGalleryDownloadDir(galleryInfo, db);
  if (dir === null) {
    return null;
  }
  return ensureDirectory(fs, dir) ? dir : null;
}
