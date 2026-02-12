import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

// WebViewSignInPage.parseCookieString is a static method on the page struct.
// Since HarmonyOS @Component structs can't be instantiated in Node, we import
// the same logic re-exported for testability.
// The static method is defined inline in the .ets file, so we test the
// equivalent logic here directly.

/**
 * Mirror of WebViewSignInPage.parseCookieString for testing.
 * (The actual page struct cannot be imported in Node, but the logic is trivial.)
 */
function parseCookieString(cookieString: string): Map<string, string> {
  const result = new Map<string, string>();
  if (!cookieString) return result;

  const pieces = cookieString.split(';');
  for (const piece of pieces) {
    const trimmed = piece.trim();
    const eqIdx = trimmed.indexOf('=');
    if (eqIdx > 0) {
      const name = trimmed.substring(0, eqIdx).trim();
      const value = trimmed.substring(eqIdx + 1).trim();
      result.set(name, value);
    }
  }
  return result;
}

describe('WebViewSignInPage.parseCookieString', () => {
  it('should parse single cookie', () => {
    const result = parseCookieString('ipb_member_id=12345');
    assert.strictEqual(result.get('ipb_member_id'), '12345');
    assert.strictEqual(result.size, 1);
  });

  it('should parse multiple cookies', () => {
    const result = parseCookieString(
      'ipb_member_id=12345; ipb_pass_hash=abcdef0123456789abcdef0123456789; igneous=xyz',
    );
    assert.strictEqual(result.get('ipb_member_id'), '12345');
    assert.strictEqual(result.get('ipb_pass_hash'), 'abcdef0123456789abcdef0123456789');
    assert.strictEqual(result.get('igneous'), 'xyz');
    assert.strictEqual(result.size, 3);
  });

  it('should handle empty string', () => {
    const result = parseCookieString('');
    assert.strictEqual(result.size, 0);
  });

  it('should handle null-like undefined', () => {
    const result = parseCookieString(undefined as unknown as string);
    assert.strictEqual(result.size, 0);
  });

  it('should skip entries without = sign', () => {
    const result = parseCookieString('valid=1; invalid; another=2');
    assert.strictEqual(result.size, 2);
    assert.strictEqual(result.get('valid'), '1');
    assert.strictEqual(result.get('another'), '2');
  });

  it('should skip entries with = at position 0 (empty name)', () => {
    const result = parseCookieString('=noname; good=value');
    assert.strictEqual(result.size, 1);
    assert.strictEqual(result.get('good'), 'value');
  });

  it('should handle values containing =', () => {
    const result = parseCookieString('token=abc=def=ghi');
    assert.strictEqual(result.get('token'), 'abc=def=ghi');
  });

  it('should trim whitespace around names and values', () => {
    const result = parseCookieString('  name  =  value  ;  key  =  val  ');
    assert.strictEqual(result.get('name'), 'value');
    assert.strictEqual(result.get('key'), 'val');
  });

  it('should detect sign-in cookies presence', () => {
    const cookies = parseCookieString(
      'ipb_member_id=12345; ipb_pass_hash=aabbccdd11223344aabbccdd11223344',
    );
    const hasId = cookies.has('ipb_member_id');
    const hasHash = cookies.has('ipb_pass_hash');
    assert.strictEqual(hasId && hasHash, true);
  });

  it('should return false when sign-in cookies are missing', () => {
    const cookies = parseCookieString('some_other_cookie=value');
    const hasId = cookies.has('ipb_member_id');
    const hasHash = cookies.has('ipb_pass_hash');
    assert.strictEqual(hasId && hasHash, false);
  });
});
