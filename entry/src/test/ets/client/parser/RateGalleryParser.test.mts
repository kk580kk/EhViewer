import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { RateGalleryParser } from '../../../../main/ets/client/parser/RateGalleryParser.ets';
import { ParseException } from '../../../../main/ets/client/exception/ParseException.ets';

describe('RateGalleryParser', () => {
  it('should parse rating and ratingCount from JSON', () => {
    const body = '{"rating_avg":4.25,"rating_cnt":50}';
    const result = RateGalleryParser.parse(body);
    assert.strictEqual(result.rating, 4.25);
    assert.strictEqual(result.ratingCount, 50);
  });

  it('should parse zero rating', () => {
    const body = '{"rating_avg":0.0,"rating_cnt":0}';
    const result = RateGalleryParser.parse(body);
    assert.strictEqual(result.rating, 0);
    assert.strictEqual(result.ratingCount, 0);
  });

  it('should throw ParseException for invalid JSON', () => {
    assert.throws(
      () => RateGalleryParser.parse('not json'),
      (err: Error) => {
        assert.ok(err instanceof ParseException);
        assert.ok(err.message.includes("Can't parse rate gallery"));
        return true;
      },
    );
  });
});
