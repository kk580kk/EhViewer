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

export class GalleryTagGroup {
  groupName: string = '';
  private tagList: string[] = [];

  addTag(tag: string): void {
    this.tagList.push(tag);
  }

  size(): number {
    return this.tagList.length;
  }

  getTagAt(position: number): string {
    return this.tagList[position];
  }

  getTags(): string[] {
    return this.tagList;
  }

  /** Serialize to a plain JSON-compatible object. */
  toJSON(): Record<string, Object> {
    return {
      groupName: this.groupName,
      tagList: [...this.tagList],
    };
  }

  /** Deserialize from a plain object. */
  static fromJSON(json: Record<string, Object | null>): GalleryTagGroup {
    const group = new GalleryTagGroup();
    group.groupName = json['groupName'] as string ?? '';
    const tags = json['tagList'] as string[] | null;
    if (tags) {
      for (const tag of tags) {
        group.addTag(tag);
      }
    }
    return group;
  }
}
