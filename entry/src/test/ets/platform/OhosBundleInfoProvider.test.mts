import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import {
  OhosBundleInfoProvider,
  GET_BUNDLE_INFO_WITH_SIGNATURE_INFO,
} from '../../../main/ets/platform/OhosBundleInfoProvider.ets';
import type {
  OhosBundleManagerApi,
  OhosBundleInfo,
} from '../../../main/ets/platform/OhosBundleInfoProvider.ets';

// ---- Mock implementations ----

class MockBundleManagerApi implements OhosBundleManagerApi {
  private bundles = new Map<string, OhosBundleInfo>();
  lastFlags: number = 0;
  shouldThrow = false;

  addBundle(bundleName: string, info: OhosBundleInfo): void {
    this.bundles.set(bundleName, info);
  }

  getBundleInfo(bundleName: string, flags: number): OhosBundleInfo {
    this.lastFlags = flags;
    if (this.shouldThrow) {
      throw new Error('bundleManager error');
    }
    const info = this.bundles.get(bundleName);
    if (!info) {
      throw new Error(`Bundle not found: ${bundleName}`);
    }
    return info;
  }
}

describe('OhosBundleInfoProvider', () => {
  let api: MockBundleManagerApi;
  let provider: OhosBundleInfoProvider;

  beforeEach(() => {
    api = new MockBundleManagerApi();
    provider = new OhosBundleInfoProvider(api);
  });

  it('should return certificate data for a known bundle', () => {
    const certData = new Uint8Array([0x30, 0x82, 0x01, 0x22]);
    api.addBundle('com.example.app', {
      signatureInfo: {
        fingerprint: 'AB:CD:EF',
        certificate: certData,
      },
    });

    const result = provider.getSignatureInfo('com.example.app');
    assert.ok(result !== null);
    assert.deepStrictEqual(result!.certificateData, certData);
  });

  it('should pass GET_BUNDLE_INFO_WITH_SIGNATURE_INFO flag', () => {
    api.addBundle('com.example.app', {
      signatureInfo: {
        fingerprint: 'AB:CD',
        certificate: new Uint8Array([1, 2, 3]),
      },
    });

    provider.getSignatureInfo('com.example.app');
    assert.strictEqual(api.lastFlags, GET_BUNDLE_INFO_WITH_SIGNATURE_INFO);
  });

  it('should return null when bundle is not found', () => {
    const result = provider.getSignatureInfo('com.unknown.app');
    assert.strictEqual(result, null);
  });

  it('should return null when signatureInfo is missing', () => {
    api.addBundle('com.example.app', {});
    const result = provider.getSignatureInfo('com.example.app');
    assert.strictEqual(result, null);
  });

  it('should return null when certificate data is empty', () => {
    api.addBundle('com.example.app', {
      signatureInfo: {
        fingerprint: 'AB:CD',
        certificate: new Uint8Array(0),
      },
    });

    const result = provider.getSignatureInfo('com.example.app');
    assert.strictEqual(result, null);
  });

  it('should return null when api throws', () => {
    api.shouldThrow = true;
    const result = provider.getSignatureInfo('com.example.app');
    assert.strictEqual(result, null);
  });

  it('should return consistent results for same bundle', () => {
    api.addBundle('com.example.app', {
      signatureInfo: {
        fingerprint: 'AB:CD',
        certificate: new Uint8Array([10, 20, 30]),
      },
    });

    const r1 = provider.getSignatureInfo('com.example.app');
    const r2 = provider.getSignatureInfo('com.example.app');
    assert.deepStrictEqual(r1, r2);
  });

  it('GET_BUNDLE_INFO_WITH_SIGNATURE_INFO should be 0x00000800', () => {
    assert.strictEqual(GET_BUNDLE_INFO_WITH_SIGNATURE_INFO, 0x00000800);
  });
});
