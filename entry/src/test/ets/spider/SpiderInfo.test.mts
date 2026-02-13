import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

import { SpiderInfo, TOKEN_FAILED } from '../../../main/ets/spider/SpiderInfo.ets';

// ---- Helper to build a valid VERSION2 text ----

function buildV2Text(opts?: {
  startPage?: number;
  gid?: number;
  token?: string;
  previewPages?: number;
  previewPerPage?: number;
  pages?: number;
  pTokens?: [number, string][];
}): string {
  const o = {
    startPage: 0,
    gid: 12345,
    token: 'abc123',
    previewPages: 10,
    previewPerPage: 20,
    pages: 100,
    pTokens: [] as [number, string][],
    ...opts,
  };
  const lines: string[] = [];
  lines.push('VERSION2');
  lines.push(o.startPage.toString(16).padStart(8, '0'));
  lines.push(o.gid.toString());
  lines.push(o.token);
  lines.push('1'); // deprecated mode
  lines.push(o.previewPages.toString());
  lines.push(o.previewPerPage.toString());
  lines.push(o.pages.toString());
  for (const [idx, pt] of o.pTokens) {
    lines.push(`${idx} ${pt}`);
  }
  return lines.join('\n') + '\n';
}

// ---- Tests ----

describe('SpiderInfo', () => {
  // ---- read() basic parsing ----

  it('should parse valid VERSION2 text', () => {
    const text = buildV2Text();
    const info = SpiderInfo.read(text);
    assert.ok(info !== null);
    assert.strictEqual(info.startPage, 0);
    assert.strictEqual(info.gid, 12345);
    assert.strictEqual(info.token, 'abc123');
    assert.strictEqual(info.previewPages, 10);
    assert.strictEqual(info.previewPerPage, 20);
    assert.strictEqual(info.pages, 100);
    assert.strictEqual(info.pTokenMap.size, 0);
  });

  it('should parse pToken entries', () => {
    const text = buildV2Text({
      pages: 5,
      pTokens: [[0, 'tok0'], [2, 'tok2'], [4, 'tok4']],
    });
    const info = SpiderInfo.read(text);
    assert.ok(info !== null);
    assert.strictEqual(info.pTokenMap.size, 3);
    assert.strictEqual(info.pTokenMap.get(0), 'tok0');
    assert.strictEqual(info.pTokenMap.get(2), 'tok2');
    assert.strictEqual(info.pTokenMap.get(4), 'tok4');
  });

  it('should parse non-zero startPage', () => {
    const text = buildV2Text({ startPage: 255 }); // 0x000000ff
    const info = SpiderInfo.read(text);
    assert.ok(info !== null);
    assert.strictEqual(info.startPage, 255);
  });

  // ---- read() VERSION1 ----

  it('should parse VERSION1 text (no VERSION header, no previewPerPage)', () => {
    // v1 format: no VERSION line, startPage hex, gid, token, mode, previewPages, (extra line), pages, pTokens
    const lines = [
      '00000003', // startPage = 3
      '9999',     // gid
      'mytoken',  // token
      '1',        // deprecated mode
      '5',        // previewPages
      'ignored',  // in v1 the previewPerPage line is skipped
      '10',       // pages
      '0 ptA',
    ];
    const text = lines.join('\n') + '\n';
    const info = SpiderInfo.read(text);
    assert.ok(info !== null);
    assert.strictEqual(info.startPage, 3);
    assert.strictEqual(info.gid, 9999);
    assert.strictEqual(info.token, 'mytoken');
    assert.strictEqual(info.previewPages, 5);
    assert.strictEqual(info.previewPerPage, -1); // not set in v1
    assert.strictEqual(info.pages, 10);
    assert.strictEqual(info.pTokenMap.get(0), 'ptA');
  });

  // ---- read() error handling ----

  it('should return null for null input', () => {
    assert.strictEqual(SpiderInfo.read(null), null);
  });

  it('should return null for empty string', () => {
    assert.strictEqual(SpiderInfo.read(''), null);
  });

  it('should return null for invalid version', () => {
    const text = 'VERSION99\n00000000\n1\ntok\n1\n5\n5\n10\n';
    assert.strictEqual(SpiderInfo.read(text), null);
  });

  it('should return null when pages is zero', () => {
    const text = buildV2Text({ pages: 0 });
    assert.strictEqual(SpiderInfo.read(text), null);
  });

  it('should return null when pages is negative', () => {
    const text = buildV2Text({ pages: -5 });
    assert.strictEqual(SpiderInfo.read(text), null);
  });

  it('should return null for truncated input (too few lines)', () => {
    const text = 'VERSION2\n00000000\n';
    assert.strictEqual(SpiderInfo.read(text), null);
  });

  it('should return null when gid is missing / NaN', () => {
    const lines = [
      'VERSION2',
      '00000000',
      'not_a_number', // gid
      'tok',
      '1',
      '5',
      '5',
      '10',
    ];
    assert.strictEqual(SpiderInfo.read(lines.join('\n') + '\n'), null);
  });

  // ---- read() edge cases ----

  it('should skip empty lines in pToken section', () => {
    const base = buildV2Text({ pages: 3, pTokens: [[0, 'a']] });
    // Append some blank lines
    const text = base + '\n\n\n';
    const info = SpiderInfo.read(text);
    assert.ok(info !== null);
    assert.strictEqual(info.pTokenMap.size, 1);
  });

  it('should skip malformed pToken lines (no space)', () => {
    const base = buildV2Text({ pages: 3 });
    const text = base.trimEnd() + '\nbadline\n0 good\n';
    const info = SpiderInfo.read(text);
    assert.ok(info !== null);
    assert.strictEqual(info.pTokenMap.size, 1);
    assert.strictEqual(info.pTokenMap.get(0), 'good');
  });

  // ---- write() ----

  it('should produce valid VERSION2 output', () => {
    const info = new SpiderInfo();
    info.gid = 42;
    info.token = 'tokXYZ';
    info.startPage = 5;
    info.pages = 50;
    info.previewPages = 8;
    info.previewPerPage = 10;

    const text = info.write();
    const lines = text.split('\n');
    assert.strictEqual(lines[0], 'VERSION2');
    assert.strictEqual(lines[1], '00000005'); // startPage hex
    assert.strictEqual(lines[2], '42');
    assert.strictEqual(lines[3], 'tokXYZ');
    assert.strictEqual(lines[4], '1'); // deprecated mode
    assert.strictEqual(lines[5], '8');
    assert.strictEqual(lines[6], '10');
    assert.strictEqual(lines[7], '50');
  });

  it('should write pToken entries sorted by index', () => {
    const info = new SpiderInfo();
    info.gid = 1;
    info.token = 't';
    info.pages = 10;
    info.pTokenMap.set(5, 'e');
    info.pTokenMap.set(0, 'a');
    info.pTokenMap.set(3, 'c');

    const text = info.write();
    const lines = text.split('\n').filter(l => l.includes(' '));
    assert.strictEqual(lines[0], '0 a');
    assert.strictEqual(lines[1], '3 c');
    assert.strictEqual(lines[2], '5 e');
  });

  it('should skip TOKEN_FAILED entries in write()', () => {
    const info = new SpiderInfo();
    info.gid = 1;
    info.token = 't';
    info.pages = 10;
    info.pTokenMap.set(0, 'valid');
    info.pTokenMap.set(1, TOKEN_FAILED);
    info.pTokenMap.set(2, '');

    const text = info.write();
    const tokenLines = text.split('\n').filter(l => /^\d+ /.test(l));
    assert.strictEqual(tokenLines.length, 1);
    assert.strictEqual(tokenLines[0], '0 valid');
  });

  it('should clamp negative startPage to 0 in write()', () => {
    const info = new SpiderInfo();
    info.gid = 1;
    info.token = 't';
    info.pages = 1;
    info.startPage = -10;

    const text = info.write();
    const lines = text.split('\n');
    assert.strictEqual(lines[1], '00000000');
  });

  // ---- Round-trip: write then read ----

  it('should round-trip correctly', () => {
    const original = new SpiderInfo();
    original.gid = 98765;
    original.token = 'roundtrip_token';
    original.startPage = 42;
    original.pages = 200;
    original.previewPages = 15;
    original.previewPerPage = 25;
    original.pTokenMap.set(0, 'first');
    original.pTokenMap.set(99, 'middle');
    original.pTokenMap.set(199, 'last');

    const text = original.write();
    const restored = SpiderInfo.read(text);

    assert.ok(restored !== null);
    assert.strictEqual(restored.gid, original.gid);
    assert.strictEqual(restored.token, original.token);
    assert.strictEqual(restored.startPage, original.startPage);
    assert.strictEqual(restored.pages, original.pages);
    assert.strictEqual(restored.previewPages, original.previewPages);
    assert.strictEqual(restored.previewPerPage, original.previewPerPage);
    assert.strictEqual(restored.pTokenMap.size, original.pTokenMap.size);
    assert.strictEqual(restored.pTokenMap.get(0), 'first');
    assert.strictEqual(restored.pTokenMap.get(99), 'middle');
    assert.strictEqual(restored.pTokenMap.get(199), 'last');
  });

  it('should round-trip with zero pTokens', () => {
    const original = new SpiderInfo();
    original.gid = 1;
    original.token = 'x';
    original.pages = 1;

    const restored = SpiderInfo.read(original.write());
    assert.ok(restored !== null);
    assert.strictEqual(restored.pTokenMap.size, 0);
  });

  it('should round-trip with large startPage', () => {
    const original = new SpiderInfo();
    original.gid = 1;
    original.token = 'x';
    original.pages = 1;
    original.startPage = 0xFFFFFF;

    const restored = SpiderInfo.read(original.write());
    assert.ok(restored !== null);
    assert.strictEqual(restored.startPage, 0xFFFFFF);
  });

  // ---- TOKEN_FAILED constant ----

  it('should export TOKEN_FAILED as "failed"', () => {
    assert.strictEqual(TOKEN_FAILED, 'failed');
  });

  // ---- Default field values ----

  it('should have correct default field values', () => {
    const info = new SpiderInfo();
    assert.strictEqual(info.startPage, 0);
    assert.strictEqual(info.gid, -1);
    assert.strictEqual(info.token, '');
    assert.strictEqual(info.pages, -1);
    assert.strictEqual(info.previewPages, -1);
    assert.strictEqual(info.previewPerPage, -1);
    assert.strictEqual(info.pTokenMap.size, 0);
  });
});
