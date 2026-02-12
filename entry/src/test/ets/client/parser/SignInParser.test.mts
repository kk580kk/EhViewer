import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { SignInParser } from '../../../../main/ets/client/parser/SignInParser.ets';
import { EhException } from '../../../../main/ets/client/exception/EhException.ets';
import { ParseException } from '../../../../main/ets/client/exception/ParseException.ets';

describe('SignInParser', () => {
  it('should extract display name from success response', () => {
    const body = '<html><body><p>You are now logged in as: TestUser</p></body></html>';
    const name = SignInParser.parse(body);
    assert.strictEqual(name, 'TestUser');
  });

  it('should extract display name with special characters', () => {
    const body = '<p>You are now logged in as: User_123-abc</p>';
    const name = SignInParser.parse(body);
    assert.strictEqual(name, 'User_123-abc');
  });

  it('should throw EhException for error response with h4 format', () => {
    const body = '<h4>The error returned was:</h4>\n<p>The username or password is incorrect.</p>';
    assert.throws(
      () => SignInParser.parse(body),
      (err: Error) => {
        assert.ok(err instanceof EhException);
        assert.strictEqual(err.message, 'The username or password is incorrect.');
        return true;
      },
    );
  });

  it('should throw EhException for error response with span format', () => {
    const body = '<span class="postcolor">Account has been suspended.</span>';
    assert.throws(
      () => SignInParser.parse(body),
      (err: Error) => {
        assert.ok(err instanceof EhException);
        assert.strictEqual(err.message, 'Account has been suspended.');
        return true;
      },
    );
  });

  it('should throw ParseException for unrecognized response', () => {
    const body = '<html><body>Something completely unexpected</body></html>';
    assert.throws(
      () => SignInParser.parse(body),
      (err: Error) => {
        assert.ok(err instanceof ParseException);
        assert.ok(err.message.includes("Can't parse sign in"));
        return true;
      },
    );
  });

  it('should throw ParseException for empty body', () => {
    assert.throws(
      () => SignInParser.parse(''),
      (err: Error) => {
        assert.ok(err instanceof ParseException);
        return true;
      },
    );
  });
});
