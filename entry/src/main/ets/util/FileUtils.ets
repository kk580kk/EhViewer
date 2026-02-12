/*
 * Copyright 2016 Hippo Seven
 * Ported to HarmonyOS ArkTS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

/**
 * Abstraction over filesystem operations.
 *
 * Production: backed by @ohos.file.fs
 * Tests: backed by node:fs
 */
export interface FsOps {
  mkdirSync(path: string, options?: { recursive?: boolean }): void;
  existsSync(path: string): boolean;
  statSync(path: string): { isDirectory(): boolean; isFile(): boolean };
  writeFileSync(path: string, data: string | Uint8Array, encoding?: string): void;
  unlinkSync(path: string): void;
}

// ---- Pure path utilities (no FS access) ----

/** Platform-independent path separator. */
const SEP = '/';

/**
 * Join path segments using '/'.
 * Strips trailing slashes from base and leading slashes from appended segments.
 */
export function joinPath(...segments: string[]): string {
  return segments
    .filter(s => s.length > 0)
    .reduce((acc, seg) => {
      if (acc.length === 0) return seg;
      const left = acc.endsWith(SEP) ? acc.slice(0, -1) : acc;
      const right = seg.startsWith(SEP) ? seg.slice(1) : seg;
      return `${left}${SEP}${right}`;
    }, '');
}

/**
 * Return the parent directory path, or empty string if none.
 */
export function getParent(path: string): string {
  const idx = path.lastIndexOf(SEP);
  return idx <= 0 ? '' : path.slice(0, idx);
}

/**
 * Return the filename (last segment) of a path.
 */
export function getFileName(path: string): string {
  const idx = path.lastIndexOf(SEP);
  return idx < 0 ? path : path.slice(idx + 1);
}

/**
 * Return the file extension (without dot), or empty string if none.
 */
export function getExtension(path: string): string {
  const name = getFileName(path);
  const idx = name.lastIndexOf('.');
  return idx < 0 ? '' : name.slice(idx + 1);
}

/**
 * Return the filename without extension.
 */
export function getNameWithoutExtension(path: string): string {
  const name = getFileName(path);
  const idx = name.lastIndexOf('.');
  return idx < 0 ? name : name.slice(0, idx);
}

// ---- FS-backed utilities ----

/**
 * Ensure the given directory exists (create recursively if needed).
 * Returns true if the directory exists after the call.
 */
export function ensureDirectory(fs: FsOps, dirPath: string): boolean {
  try {
    if (fs.existsSync(dirPath)) {
      const stat = fs.statSync(dirPath);
      return stat.isDirectory();
    }
    fs.mkdirSync(dirPath, { recursive: true });
    return true;
  } catch (_e) {
    return false;
  }
}

/**
 * Ensure a file's parent directory exists and the file itself exists
 * (creates an empty file if needed).
 * Returns true if the file exists after the call.
 */
export function ensureFile(fs: FsOps, filePath: string): boolean {
  try {
    if (fs.existsSync(filePath)) {
      const stat = fs.statSync(filePath);
      return stat.isFile();
    }
    const parent = getParent(filePath);
    if (parent.length > 0 && !ensureDirectory(fs, parent)) {
      return false;
    }
    fs.writeFileSync(filePath, '', 'utf-8');
    return true;
  } catch (_e) {
    return false;
  }
}

/**
 * Create a uniquely-named temporary file in the given directory.
 * Returns the full path, or null on failure.
 *
 * @param fs       Filesystem adapter
 * @param dir      Directory to create the temp file in
 * @param extension Optional extension (without dot), e.g. "tmp"
 */
export function createTempFile(fs: FsOps, dir: string | null, extension?: string): string | null {
  if (dir === null || !ensureDirectory(fs, dir)) {
    return null;
  }
  try {
    const ext = extension ? `.${extension}` : '.tmp';
    const name = `ehv_${Date.now()}_${randomSuffix()}${ext}`;
    const filePath = joinPath(dir, name);
    fs.writeFileSync(filePath, '', 'utf-8');
    return filePath;
  } catch (_e) {
    return null;
  }
}

/**
 * Delete a file. Returns true on success.
 */
export function deleteFile(fs: FsOps, filePath: string): boolean {
  try {
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
    }
    return true;
  } catch (_e) {
    return false;
  }
}

/**
 * Write string content to a file, creating parent directories as needed.
 * Returns true on success.
 */
export function writeToFile(fs: FsOps, filePath: string, content: string): boolean {
  try {
    const parent = getParent(filePath);
    if (parent.length > 0 && !ensureDirectory(fs, parent)) {
      return false;
    }
    fs.writeFileSync(filePath, content, 'utf-8');
    return true;
  } catch (_e) {
    return false;
  }
}

// ---- Internal helpers ----

function randomSuffix(): string {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  for (let i = 0; i < 8; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}
