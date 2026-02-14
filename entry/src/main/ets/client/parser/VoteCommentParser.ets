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

export interface VoteCommentResult {
  id: number;
  score: number;
  vote: number;
  expectVote: number;
}

export class VoteCommentParser {

  static parse(body: string, vote: number): VoteCommentResult {
    const jo = JSON.parse(body);
    return {
      id: Number(jo['comment_id']),
      score: Number(jo['comment_score']),
      vote: Number(jo['comment_vote']),
      expectVote: vote,
    };
  }
}
