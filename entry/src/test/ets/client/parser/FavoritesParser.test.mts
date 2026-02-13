import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { FavoritesParser } from '../../../../main/ets/client/parser/FavoritesParser.ets';
import { EhException } from '../../../../main/ets/client/exception/EhException.ets';

const NEED_SIGN_IN_BODY = '<html><body>This page requires you to log on.</p></body></html>';

const EMPTY_FAV_BODY = '<html><body>No hits found</p></body></html>';

describe('FavoritesParser', () => {
  it('should throw EhException when sign-in required', () => {
    assert.throws(
      () => FavoritesParser.parse(NEED_SIGN_IN_BODY),
      (err: Error) => err instanceof EhException && err.message.includes('sign in'),
    );
  });

  it('should parse empty favorites with no hits', () => {
    const result = FavoritesParser.parse(EMPTY_FAV_BODY);
    assert.strictEqual(result.galleryInfoList.length, 0);
    assert.strictEqual(result.pages, 0);
    assert.strictEqual(result.catArray.length, 10);
    assert.strictEqual(result.countArray.length, 10);
  });

  it('should pad catArray and countArray to 10 entries', () => {
    const result = FavoritesParser.parse(EMPTY_FAV_BODY);
    assert.strictEqual(result.catArray.length, 10);
    assert.strictEqual(result.countArray.length, 10);
    for (const count of result.countArray) {
      assert.strictEqual(count, 0);
    }
  });
});
