import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { ForumsParser } from '../../../../main/ets/client/parser/ForumsParser.ets';
import { ParseException } from '../../../../main/ets/client/exception/ParseException.ets';

describe('ForumsParser', () => {
  it('should extract profile URL from forums page', () => {
    const body =
      '<div id="userlinks"><a href="https://forums.e-hentai.org/index.php?showuser=12345">Profile</a></div>';
    const url = ForumsParser.parse(body);
    assert.strictEqual(url, 'https://forums.e-hentai.org/index.php?showuser=12345');
  });

  it('should extract first link from userlinks div', () => {
    const body =
      '<div id="userlinks">' +
      '<a href="https://forums.e-hentai.org/profile/1">First</a>' +
      '<a href="https://forums.e-hentai.org/profile/2">Second</a>' +
      '</div>';
    const url = ForumsParser.parse(body);
    assert.strictEqual(url, 'https://forums.e-hentai.org/profile/1');
  });

  it('should extract profile URL from forums page with table structure (Java fixture)', () => {
    const body =
      '<html>\n<body>\n<div id="userlinks">\n<table><tr><td>\n' +
      '<a href="https://forums.e-hentai.org/index.php?showuser=12345">My Profile</a>\n' +
      '</td></tr></table>\n</div>\n</body>\n</html>';
    const url = ForumsParser.parse(body);
    assert.strictEqual(url, 'https://forums.e-hentai.org/index.php?showuser=12345');
  });

  it('should throw ParseException when userlinks div is missing', () => {
    assert.throws(
      () => ForumsParser.parse('<html><body>No userlinks</body></html>'),
      (err: Error) => {
        assert.ok(err instanceof ParseException);
        return true;
      },
    );
  });

  it('should throw ParseException for empty body', () => {
    assert.throws(
      () => ForumsParser.parse(''),
      (err: Error) => {
        assert.ok(err instanceof ParseException);
        return true;
      },
    );
  });
});
