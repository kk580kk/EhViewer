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

export class GalleryComment {
  /** id == 0 for uploader comment; uploader comments cannot be voted on. */
  id: number = 0;
  score: number = 0;
  editable: boolean = false;
  voteUpAble: boolean = false;
  voteUpEd: boolean = false;
  voteDownAble: boolean = false;
  voteDownEd: boolean = false;
  voteState: string = '';
  time: number = 0;
  user: string = '';
  comment: string = '';
  lastEdited: number = 0;

  /** Whether this is an uploader comment (id == 0, cannot be voted on). */
  isUploaderComment(): boolean {
    return this.id === 0;
  }

  /** Copy all fields from another GalleryComment instance. */
  copyFrom(other: GalleryComment): void {
    this.id = other.id;
    this.score = other.score;
    this.editable = other.editable;
    this.voteUpAble = other.voteUpAble;
    this.voteUpEd = other.voteUpEd;
    this.voteDownAble = other.voteDownAble;
    this.voteDownEd = other.voteDownEd;
    this.voteState = other.voteState;
    this.time = other.time;
    this.user = other.user;
    this.comment = other.comment;
    this.lastEdited = other.lastEdited;
  }

  /** Serialize to a plain JSON-compatible object. */
  toJSON(): Record<string, Object> {
    return {
      id: this.id,
      score: this.score,
      editable: this.editable,
      voteUpAble: this.voteUpAble,
      voteUpEd: this.voteUpEd,
      voteDownAble: this.voteDownAble,
      voteDownEd: this.voteDownEd,
      voteState: this.voteState,
      time: this.time,
      user: this.user,
      comment: this.comment,
      lastEdited: this.lastEdited,
    };
  }

  /** Deserialize from a plain object. */
  static fromJSON(json: Record<string, Object>): GalleryComment {
    const c = new GalleryComment();
    c.id = json['id'] as number ?? 0;
    c.score = json['score'] as number ?? 0;
    c.editable = json['editable'] as boolean ?? false;
    c.voteUpAble = json['voteUpAble'] as boolean ?? false;
    c.voteUpEd = json['voteUpEd'] as boolean ?? false;
    c.voteDownAble = json['voteDownAble'] as boolean ?? false;
    c.voteDownEd = json['voteDownEd'] as boolean ?? false;
    c.voteState = json['voteState'] as string ?? '';
    c.time = json['time'] as number ?? 0;
    c.user = json['user'] as string ?? '';
    c.comment = json['comment'] as string ?? '';
    c.lastEdited = json['lastEdited'] as number ?? 0;
    return c;
  }
}

export class GalleryCommentList {
  comments: GalleryComment[] = [];
  hasMore: boolean = false;

  /** Create a GalleryCommentList from comments and hasMore flag. */
  static of(comments: GalleryComment[], hasMore: boolean): GalleryCommentList {
    const list = new GalleryCommentList();
    list.comments = comments;
    list.hasMore = hasMore;
    return list;
  }

  /** Serialize to a plain JSON-compatible object. */
  toJSON(): Record<string, Object> {
    return {
      comments: this.comments.map(c => c.toJSON()),
      hasMore: this.hasMore,
    };
  }

  /** Deserialize from a plain object. */
  static fromJSON(json: Record<string, Object | null>): GalleryCommentList {
    const list = new GalleryCommentList();
    const arr = json['comments'] as Record<string, Object>[] | null;
    list.comments = arr ? arr.map(c => GalleryComment.fromJSON(c)) : [];
    list.hasMore = json['hasMore'] as boolean ?? false;
    return list;
  }
}
