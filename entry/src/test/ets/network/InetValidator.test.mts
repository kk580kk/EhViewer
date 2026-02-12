import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  isValidInet4Address,
  isValidInetPort,
} from '../../../main/ets/network/InetValidator.ets';

describe('isValidInet4Address', () => {
  it('should accept valid IPv4 addresses', () => {
    assert.strictEqual(isValidInet4Address('0.0.0.0'), true);
    assert.strictEqual(isValidInet4Address('127.0.0.1'), true);
    assert.strictEqual(isValidInet4Address('192.168.1.100'), true);
    assert.strictEqual(isValidInet4Address('255.255.255.255'), true);
    assert.strictEqual(isValidInet4Address('10.0.0.1'), true);
  });

  it('should reject null and empty', () => {
    assert.strictEqual(isValidInet4Address(null), false);
    assert.strictEqual(isValidInet4Address(''), false);
  });

  it('should reject segments > 255', () => {
    assert.strictEqual(isValidInet4Address('256.0.0.1'), false);
    assert.strictEqual(isValidInet4Address('1.2.3.999'), false);
  });

  it('should reject leading zeros', () => {
    assert.strictEqual(isValidInet4Address('01.02.03.04'), false);
    assert.strictEqual(isValidInet4Address('192.168.01.1'), false);
  });

  it('should reject incomplete addresses', () => {
    assert.strictEqual(isValidInet4Address('1.2.3'), false);
    assert.strictEqual(isValidInet4Address('1.2.3.4.5'), false);
  });

  it('should reject non-numeric', () => {
    assert.strictEqual(isValidInet4Address('a.b.c.d'), false);
    assert.strictEqual(isValidInet4Address('192.168.1.abc'), false);
  });
});

describe('isValidInetPort', () => {
  it('should accept valid ports', () => {
    assert.strictEqual(isValidInetPort(0), true);
    assert.strictEqual(isValidInetPort(80), true);
    assert.strictEqual(isValidInetPort(443), true);
    assert.strictEqual(isValidInetPort(8080), true);
    assert.strictEqual(isValidInetPort(65535), true);
  });

  it('should reject negative ports', () => {
    assert.strictEqual(isValidInetPort(-1), false);
  });

  it('should reject ports > 65535', () => {
    assert.strictEqual(isValidInetPort(65536), false);
    assert.strictEqual(isValidInetPort(100000), false);
  });

  it('should reject non-integer ports', () => {
    assert.strictEqual(isValidInetPort(80.5), false);
    assert.strictEqual(isValidInetPort(NaN), false);
  });
});
