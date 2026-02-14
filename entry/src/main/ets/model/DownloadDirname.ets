/*
 * Copyright 2016 Hippo Seven
 * Ported to HarmonyOS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

/**
 * Maps a gallery gid to its download directory name.
 *
 * Mirrors the Android DownloadDirname DAO entity.
 */
export class DownloadDirname {
  gid: number = 0;
  dirname: string = '';

  /** Copy all fields from another DownloadDirname instance. */
  copyFrom(other: DownloadDirname): void {
    this.gid = other.gid;
    this.dirname = other.dirname;
  }

  /** Check equality by gid. */
  equals(other: DownloadDirname | null): boolean {
    if (other === null) return false;
    return this.gid === other.gid;
  }

  /** Serialize to a plain JSON-compatible object. */
  toJSON(): Record<string, Object> {
    return {
      gid: this.gid,
      dirname: this.dirname,
    };
  }

  /** Deserialize from a plain object. */
  static fromJSON(json: Record<string, Object>): DownloadDirname {
    const d = new DownloadDirname();
    d.gid = json['gid'] as number ?? 0;
    d.dirname = json['dirname'] as string ?? '';
    return d;
  }
}
