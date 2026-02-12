import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { ProfileParser } from '../../../../main/ets/client/parser/ProfileParser.ets';
import { ParseException } from '../../../../main/ets/client/exception/ParseException.ets';

describe('ProfileParser', () => {
  it('should extract display name from profile page', () => {
    const body = '<div id="profilename"><a href="/member.php?uid=123">CoolUser</a></div>';
    const result = ProfileParser.parse(body);
    assert.strictEqual(result.displayName, 'CoolUser');
  });

  it('should trim whitespace in display name', () => {
    const body = '<div id="profilename"><a href="/member.php">  SpacedName  </a></div>';
    const result = ProfileParser.parse(body);
    assert.strictEqual(result.displayName, 'SpacedName');
  });

  it('should extract avatar URL', () => {
    const body =
      '<div id="profilename"><a href="#">UserX</a>' +
      '<img src="https://forums.e-hentai.org/uploads/avatar_123.jpg" /></div>';
    const result = ProfileParser.parse(body);
    assert.strictEqual(result.displayName, 'UserX');
    assert.strictEqual(result.avatar, 'https://forums.e-hentai.org/uploads/avatar_123.jpg');
  });

  it('should prepend base URL for relative avatar paths', () => {
    const body =
      '<div id="profilename"><a href="#">UserY</a>' +
      '<img src="uploads/avatar_456.png" /></div>';
    const result = ProfileParser.parse(body);
    assert.strictEqual(result.displayName, 'UserY');
    assert.ok(result.avatar!.startsWith('https://forums.e-hentai.org/'));
    assert.ok(result.avatar!.includes('uploads/avatar_456.png'));
  });

  it('should return null avatar when no img present', () => {
    const body = '<div id="profilename"><a href="#">NoAvatar</a></div>';
    const result = ProfileParser.parse(body);
    assert.strictEqual(result.displayName, 'NoAvatar');
    assert.strictEqual(result.avatar, null);
  });

  it('should throw ParseException for invalid body', () => {
    assert.throws(
      () => ProfileParser.parse('<html>No profile here</html>'),
      (err: Error) => {
        assert.ok(err instanceof ParseException);
        return true;
      },
    );
  });

  it('should throw ParseException for empty body', () => {
    assert.throws(
      () => ProfileParser.parse(''),
      (err: Error) => {
        assert.ok(err instanceof ParseException);
        return true;
      },
    );
  });
});
