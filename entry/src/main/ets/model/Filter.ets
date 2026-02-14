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
 * A content filter rule (title, uploader, tag, etc.).
 *
 * Mirrors the Android Filter DAO entity.
 */
export class Filter {
  static readonly MODE_TITLE: number = 0;
  static readonly MODE_UPLOADER: number = 1;
  static readonly MODE_TAG: number = 2;
  static readonly MODE_TAG_NAMESPACE: number = 3;

  id: number | null = null;
  mode: number = 0;
  text: string | null = null;
  enable: boolean = true;

  /** Copy all fields from another Filter instance. */
  copyFrom(other: Filter): void {
    this.id = other.id;
    this.mode = other.mode;
    this.text = other.text;
    this.enable = other.enable;
  }

  /** Check equality by mode and text. */
  equals(other: Filter | null): boolean {
    if (other === null) return false;
    return this.mode === other.mode && this.text === other.text;
  }

  /** Serialize to a plain JSON-compatible object. */
  toJSON(): Record<string, Object | null> {
    return {
      id: this.id,
      mode: this.mode,
      text: this.text,
      enable: this.enable,
    };
  }

  /** Deserialize from a plain object. */
  static fromJSON(json: Record<string, Object | null>): Filter {
    const f = new Filter();
    f.id = json['id'] as number | null ?? null;
    f.mode = json['mode'] as number ?? 0;
    f.text = json['text'] as string | null ?? null;
    f.enable = json['enable'] as boolean ?? true;
    return f;
  }
}
