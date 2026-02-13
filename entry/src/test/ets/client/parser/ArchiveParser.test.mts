import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { ArchiveParser } from '../../../../main/ets/client/parser/ArchiveParser.ets';

describe('ArchiveParser', () => {
  it('should parse form and archive links', () => {
    const body = '<form id="hathdl_form" action="https://e-hentai.org/archiver.php?gid=123&token=abc&or=testOrParam" method="post">'
      + '<a href="#" onclick="return do_hathdl(\'org\')">Original</a>'
      + '<a href="#" onclick="return do_hathdl(\'780x\')">780x Resample</a>'
      + '</form>';

    const result = ArchiveParser.parse(body);
    assert.strictEqual(result.paramOr, 'testOrParam');
    assert.strictEqual(result.items.length, 2);
    assert.strictEqual(result.items[0].res, 'org');
    assert.strictEqual(result.items[0].name, 'Original');
    assert.strictEqual(result.items[1].res, '780x');
    assert.strictEqual(result.items[1].name, '780x Resample');
  });

  it('should return empty paramOr and items when no form', () => {
    const result = ArchiveParser.parse('<html></html>');
    assert.strictEqual(result.paramOr, '');
    assert.strictEqual(result.items.length, 0);
  });
});
