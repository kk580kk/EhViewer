import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { GalleryTokenApiParser } from '../../../../main/ets/client/parser/GalleryTokenApiParser.ets';
import { EhException } from '../../../../main/ets/client/exception/EhException.ets';

describe('GalleryTokenApiParser', () => {
  it('should parse token from valid response', () => {
    const body = JSON.stringify({ tokenlist: [{ token: 'abc123def456' }] });
    const token = GalleryTokenApiParser.parse(body);
    assert.strictEqual(token, 'abc123def456');
  });

  it('should throw EhException when error in response', () => {
    const body = JSON.stringify({ tokenlist: [{ error: 'invalid gid' }] });
    assert.throws(
      () => GalleryTokenApiParser.parse(body),
      (err: Error) => err instanceof EhException && err.message.includes('invalid gid'),
    );
  });

  it('should throw EhException when tokenlist is empty', () => {
    const body = JSON.stringify({ tokenlist: [] });
    assert.throws(
      () => GalleryTokenApiParser.parse(body),
      (err: Error) => err instanceof EhException && err.message.includes('No token'),
    );
  });

  it('should throw on invalid JSON', () => {
    assert.throws(() => GalleryTokenApiParser.parse('not json'));
  });

  it('should throw EhException when tokenlist missing', () => {
    const body = JSON.stringify({ other: 'data' });
    assert.throws(
      () => GalleryTokenApiParser.parse(body),
      (err: Error) => err instanceof EhException,
    );
  });
});
