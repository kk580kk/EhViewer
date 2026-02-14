import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { PackageUtils } from '../../../main/ets/util/PackageUtils.ets';
import type { BundleInfoProvider, BundleSignatureInfo } from '../../../main/ets/util/PackageUtils.ets';

// ---- Mock implementations ----

class MockBundleInfoProvider implements BundleInfoProvider {
  private signatures = new Map<string, BundleSignatureInfo>();
  shouldThrow = false;

  addSignature(bundleName: string, certData: Uint8Array): void {
    this.signatures.set(bundleName, { certificateData: certData });
  }

  getSignatureInfo(bundleName: string): BundleSignatureInfo | null {
    if (this.shouldThrow) {
      throw new Error('bundleManager error');
    }
    return this.signatures.get(bundleName) ?? null;
  }
}

describe('PackageUtils', () => {

  // ---- computeSHA1 ----

  describe('computeSHA1', () => {
    it('should compute SHA1 of empty data', () => {
      // SHA1("") = DA39A3EE5E6B4B0D3255BFEF95601890AFD80709
      const result = PackageUtils.computeSHA1(new Uint8Array(0));
      assert.strictEqual(result, 'DA:39:A3:EE:5E:6B:4B:0D:32:55:BF:EF:95:60:18:90:AF:D8:07:09');
    });

    it('should compute SHA1 of "abc"', () => {
      // SHA1("abc") = A9993E364706816ABA3E25717850C26C9CD0D89D
      const data = new TextEncoder().encode('abc');
      const result = PackageUtils.computeSHA1(data);
      assert.strictEqual(result, 'A9:99:3E:36:47:06:81:6A:BA:3E:25:71:78:50:C2:6C:9C:D0:D8:9D');
    });

    it('should compute SHA1 of longer message', () => {
      // SHA1("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq")
      // = 84983E441C3BD26EBAAE4AA1F95129E5E54670F1
      const msg = 'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq';
      const data = new TextEncoder().encode(msg);
      const result = PackageUtils.computeSHA1(data);
      assert.strictEqual(result, '84:98:3E:44:1C:3B:D2:6E:BA:AE:4A:A1:F9:51:29:E5:E5:46:70:F1');
    });

    it('should return uppercase colon-separated hex', () => {
      const result = PackageUtils.computeSHA1(new Uint8Array([0x00]));
      assert.ok(result !== null);
      // Check format: XX:XX:XX...
      assert.match(result!, /^[0-9A-F]{2}(:[0-9A-F]{2}){19}$/);
    });
  });

  // ---- sha1Digest ----

  describe('sha1Digest', () => {
    it('should return 20 bytes', () => {
      const result = PackageUtils.sha1Digest(new Uint8Array(0));
      assert.strictEqual(result.length, 20);
    });

    it('should produce correct raw bytes for empty input', () => {
      const result = PackageUtils.sha1Digest(new Uint8Array(0));
      // DA39A3EE...
      assert.strictEqual(result[0], 0xDA);
      assert.strictEqual(result[1], 0x39);
      assert.strictEqual(result[2], 0xA3);
      assert.strictEqual(result[3], 0xEE);
    });
  });

  // ---- getSignature ----

  describe('getSignature', () => {
    it('should return SHA1 fingerprint for known bundle', () => {
      const provider = new MockBundleInfoProvider();
      const certData = new TextEncoder().encode('test-certificate');
      provider.addSignature('com.example.app', certData);

      const result = PackageUtils.getSignature(provider, 'com.example.app');
      assert.ok(result !== null);
      // Should be a colon-separated SHA1 hash
      assert.match(result!, /^[0-9A-F]{2}(:[0-9A-F]{2}){19}$/);
    });

    it('should return null for unknown bundle', () => {
      const provider = new MockBundleInfoProvider();
      const result = PackageUtils.getSignature(provider, 'com.unknown.app');
      assert.strictEqual(result, null);
    });

    it('should return null when provider throws', () => {
      const provider = new MockBundleInfoProvider();
      provider.shouldThrow = true;
      const result = PackageUtils.getSignature(provider, 'com.example.app');
      assert.strictEqual(result, null);
    });

    it('should return consistent results for same certificate data', () => {
      const provider = new MockBundleInfoProvider();
      const certData = new TextEncoder().encode('consistent-cert');
      provider.addSignature('com.app', certData);

      const r1 = PackageUtils.getSignature(provider, 'com.app');
      const r2 = PackageUtils.getSignature(provider, 'com.app');
      assert.strictEqual(r1, r2);
    });
  });
});
