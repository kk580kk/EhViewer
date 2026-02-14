/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { AppStorageManager } from './AppStorageManager.ets';
import { joinPath, getExtension, deleteFile } from './util/FileUtils.ets';
import type { FsOps } from './util/FileUtils.ets';
import type { WantDescriptor } from './util/AppHelper.ets';

/**
 * Extended FsOps with directory listing support, needed for
 * cleaning up temporary share files.
 */
export interface ShareFsOps extends FsOps {
  readdirSync(dirPath: string): string[];
  copyFileSync(src: string, dest: string): void;
}

// ---- MIME type mappings ----

const MIME_MAP: Record<string, string> = {
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'gif': 'image/gif',
  'webp': 'image/webp',
  'bmp': 'image/bmp',
  'svg': 'image/svg+xml',
  'pdf': 'application/pdf',
  'zip': 'application/zip',
  '7z': 'application/x-7z-compressed',
  'rar': 'application/x-rar-compressed',
  'txt': 'text/plain',
  'json': 'application/json',
  'xml': 'application/xml',
  'html': 'text/html',
};

const DEFAULT_MIME = 'application/octet-stream';

/**
 * Result of preparing a file for sharing.
 */
export interface ShareFileResult {
  /** The file URI suitable for sharing. In HarmonyOS this is a file:// URI. */
  uri: string;
  /** Detected MIME type. */
  mimeType: string;
  /** Filename (last path segment). */
  filename: string;
}

/**
 * Helper for sharing files with other applications.
 *
 * On HarmonyOS, file sharing works by:
 * 1. Copying the file to a staging directory (share temp dir)
 * 2. Granting temporary read access via the file URI
 * 3. Launching a Want with ACTION_SEND and the file URI
 *
 * This is the HarmonyOS equivalent of Android's FileProvider pattern.
 */
export class FileShareHelper {

  private static fs: ShareFsOps | null = null;

  /**
   * Initialize the share helper with a filesystem adapter.
   */
  static initialize(fs: ShareFsOps): void {
    FileShareHelper.fs = fs;
  }

  /** Reset state (for testing). */
  static reset(): void {
    FileShareHelper.fs = null;
  }

  /**
   * Infer MIME type from a filename or path.
   *
   * @param filename - filename or full path
   * @returns MIME type string, defaults to 'application/octet-stream'
   */
  static getMimeType(filename: string | null): string {
    if (filename === null || filename.length === 0) {
      return DEFAULT_MIME;
    }
    const ext = getExtension(filename).toLowerCase();
    return MIME_MAP[ext] ?? DEFAULT_MIME;
  }

  /**
   * Prepare a file for sharing by copying it to the share staging directory.
   *
   * @param sourcePath - absolute path to the source file
   * @returns share file result with URI and MIME type, or null on failure
   */
  static prepareFileForShare(sourcePath: string): ShareFileResult | null {
    if (!FileShareHelper.fs) return null;
    const fs = FileShareHelper.fs;

    const shareDir = AppStorageManager.getShareTempDir();
    if (shareDir === null) return null;

    // Extract filename from source path
    const lastSlash = sourcePath.lastIndexOf('/');
    const filename = lastSlash >= 0 ? sourcePath.substring(lastSlash + 1) : sourcePath;
    if (filename.length === 0) return null;

    const destPath = joinPath(shareDir, filename);

    try {
      // Copy file to share staging directory
      fs.copyFileSync(sourcePath, destPath);

      return {
        uri: `file://${destPath}`,
        mimeType: FileShareHelper.getMimeType(filename),
        filename: filename,
      };
    } catch (_e) {
      return null;
    }
  }

  /**
   * Create a Want descriptor for sharing a file.
   *
   * @param sourcePath - absolute path to the file to share
   * @param mimeType - optional MIME type override
   * @returns a WantDescriptor ready for startAbility, or null on failure
   */
  static createShareWant(sourcePath: string, mimeType?: string): WantDescriptor | null {
    const result = FileShareHelper.prepareFileForShare(sourcePath);
    if (result === null) return null;

    const type = mimeType ?? result.mimeType;

    return {
      action: 'ohos.want.action.select',
      uri: result.uri,
      type: type,
      parameters: {
        'shareFileUri': result.uri,
        'shareFileName': result.filename,
      },
    };
  }

  /**
   * Create a Want descriptor for sharing an image file.
   * Convenience method that defaults unknown MIME types to 'image/jpeg'.
   */
  static createImageShareWant(sourcePath: string): WantDescriptor | null {
    let mimeType = FileShareHelper.getMimeType(sourcePath);
    if (mimeType === DEFAULT_MIME) {
      mimeType = 'image/jpeg';
    }
    return FileShareHelper.createShareWant(sourcePath, mimeType);
  }

  /**
   * Clean all files from the share temp directory.
   * Should be called periodically to reclaim disk space.
   *
   * @returns the number of files deleted
   */
  static cleanShareTempDir(): number {
    if (!FileShareHelper.fs) return 0;
    const fs = FileShareHelper.fs;

    const shareDir = AppStorageManager.getShareTempDir();
    if (shareDir === null) return 0;

    let count = 0;
    try {
      const files = fs.readdirSync(shareDir);
      for (const name of files) {
        const filePath = joinPath(shareDir, name);
        if (deleteFile(fs, filePath)) {
          count++;
        }
      }
    } catch (_e) {
      // directory may not exist
    }
    return count;
  }
}
