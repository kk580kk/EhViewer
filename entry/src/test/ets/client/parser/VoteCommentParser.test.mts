import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { VoteCommentParser } from '../../../../main/ets/client/parser/VoteCommentParser.ets';

describe('VoteCommentParser', () => {
  it('should parse comment vote result', () => {
    const body = '{"comment_id":1253922,"comment_score":-19,"comment_vote":0}';
    const result = VoteCommentParser.parse(body, 1);
    assert.strictEqual(result.id, 1253922);
    assert.strictEqual(result.score, -19);
    assert.strictEqual(result.vote, 0);
    assert.strictEqual(result.expectVote, 1);
  });

  it('should parse positive vote result', () => {
    const body = '{"comment_id":999,"comment_score":42,"comment_vote":1}';
    const result = VoteCommentParser.parse(body, 1);
    assert.strictEqual(result.id, 999);
    assert.strictEqual(result.score, 42);
    assert.strictEqual(result.vote, 1);
    assert.strictEqual(result.expectVote, 1);
  });

  it('should throw for invalid JSON', () => {
    assert.throws(
      () => VoteCommentParser.parse('not json', 0),
      SyntaxError,
    );
  });
});
