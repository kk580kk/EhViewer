import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  isValidInet4Address,
  isValidInet6Address,
  isValidInetAddress,
  isValidHost,
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

describe('isValidInet6Address', () => {
  it('should accept valid full IPv6 addresses', () => {
    assert.strictEqual(isValidInet6Address('2001:0db8:0000:0000:0000:0000:0000:0001'), true);
    assert.strictEqual(isValidInet6Address('fe80:0000:0000:0000:0000:0000:0000:0001'), true);
  });

  it('should accept compressed IPv6 addresses', () => {
    assert.strictEqual(isValidInet6Address('::1'), true);
    assert.strictEqual(isValidInet6Address('::'), true);
    assert.strictEqual(isValidInet6Address('2001:db8::1'), true);
    assert.strictEqual(isValidInet6Address('fe80::1'), true);
    assert.strictEqual(isValidInet6Address('ff02::1'), true);
  });

  it('should accept IPv6 with embedded IPv4', () => {
    assert.strictEqual(isValidInet6Address('::ffff:192.168.1.1'), true);
    assert.strictEqual(isValidInet6Address('2001:db8::192.168.1.1'), true);
  });

  it('should reject null and empty', () => {
    assert.strictEqual(isValidInet6Address(null), false);
    assert.strictEqual(isValidInet6Address(''), false);
  });

  it('should reject single leading colon', () => {
    assert.strictEqual(isValidInet6Address(':1'), false);
  });

  it('should reject single trailing colon', () => {
    assert.strictEqual(isValidInet6Address('1:'), false);
  });

  it('should reject multiple :: groups', () => {
    assert.strictEqual(isValidInet6Address('1::2::3'), false);
  });

  it('should reject groups with >4 hex digits', () => {
    assert.strictEqual(isValidInet6Address('12345::1'), false);
  });

  it('should reject non-hex characters', () => {
    assert.strictEqual(isValidInet6Address('gggg::1'), false);
  });

  it('should reject too many groups', () => {
    assert.strictEqual(isValidInet6Address('2001:db8:0:0:0:0:0:0:1'), false);
  });
});

describe('isValidInetAddress', () => {
  it('should accept valid IPv4', () => {
    assert.strictEqual(isValidInetAddress('127.0.0.1'), true);
    assert.strictEqual(isValidInetAddress('192.168.0.1'), true);
  });

  it('should accept valid IPv6', () => {
    assert.strictEqual(isValidInetAddress('::1'), true);
    assert.strictEqual(isValidInetAddress('2001:db8::1'), true);
  });

  it('should reject invalid addresses', () => {
    assert.strictEqual(isValidInetAddress(null), false);
    assert.strictEqual(isValidInetAddress(''), false);
    assert.strictEqual(isValidInetAddress('not-an-ip'), false);
    assert.strictEqual(isValidInetAddress('999.999.999.999'), false);
  });
});

describe('isValidHost', () => {
  it('should accept valid hostnames', () => {
    assert.strictEqual(isValidHost('example.com'), true);
    assert.strictEqual(isValidHost('sub.example.com'), true);
    assert.strictEqual(isValidHost('e-h.example.com'), true);
    assert.strictEqual(isValidHost('a'), true);
    assert.strictEqual(isValidHost('123.456'), true);
    assert.strictEqual(isValidHost('my-host'), true);
  });

  it('should reject null and empty', () => {
    assert.strictEqual(isValidHost(null), false);
    assert.strictEqual(isValidHost(''), false);
  });

  it('should reject dot-only or leading/trailing dots', () => {
    assert.strictEqual(isValidHost('.'), false);
    assert.strictEqual(isValidHost('.example.com'), false);
    assert.strictEqual(isValidHost('example.com.'), false);
  });

  it('should reject consecutive dots', () => {
    assert.strictEqual(isValidHost('example..com'), false);
  });

  it('should reject invalid characters', () => {
    assert.strictEqual(isValidHost('exam ple.com'), false);
    assert.strictEqual(isValidHost('exam~ple.com'), false);
    assert.strictEqual(isValidHost('EXAMPLE.COM'), false);
  });

  it('should reject labels longer than 63 characters', () => {
    const longLabel = 'a'.repeat(64) + '.com';
    assert.strictEqual(isValidHost(longLabel), false);
  });

  it('should accept labels up to 63 characters', () => {
    const maxLabel = 'a'.repeat(63) + '.com';
    assert.strictEqual(isValidHost(maxLabel), true);
  });

  it('should reject hostnames longer than 253 characters', () => {
    // Build a hostname just over 253 chars: "aa.aa.aa..." pattern
    const parts: string[] = [];
    while (parts.join('.').length < 254) {
      parts.push('aa');
    }
    const longHost = parts.join('.');
    assert.strictEqual(isValidHost(longHost), longHost.length <= 253);
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
