import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { TorrentParser } from '../../../../main/ets/client/parser/TorrentParser.ets';

describe('TorrentParser', () => {
  it('should parse single torrent and strip ?p= from URL', () => {
    const body = '<table><tr>'
      + '<td colspan="5"> &nbsp; <a href="https://ehtracker.org/get/123456/aabbcc.torrent?p=12345" '
      + 'onclick="document.location=\'https://ehtracker.org/get/123456/aabbcc.torrent?p=12345\'; return false">'
      + 'Test Torrent Name</a></td>'
      + '</tr></table>';

    const result = TorrentParser.parse(body);
    assert.strictEqual(result.length, 1);
    assert.strictEqual(result[0].url, 'https://ehtracker.org/get/123456/aabbcc.torrent');
    assert.strictEqual(result[0].name, 'Test Torrent Name');
  });

  it('should parse multiple torrents', () => {
    const body = '<table>'
      + '<tr><td colspan="5"> &nbsp; <a href="https://ehtracker.org/get/1/a.torrent" '
      + 'onclick="">Torrent A</a></td></tr>'
      + '<tr><td colspan="5"> &nbsp; <a href="https://ehtracker.org/get/2/b.torrent" '
      + 'onclick="">Torrent B</a></td></tr>'
      + '</table>';

    const result = TorrentParser.parse(body);
    assert.strictEqual(result.length, 2);
    assert.strictEqual(result[0].name, 'Torrent A');
    assert.strictEqual(result[1].name, 'Torrent B');
  });

  it('should return empty array for HTML without torrent list', () => {
    const result = TorrentParser.parse('<html></html>');
    assert.strictEqual(result.length, 0);
  });
});
