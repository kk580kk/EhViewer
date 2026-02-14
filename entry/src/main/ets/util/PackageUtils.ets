/*
 * Copyright 2015 Hippo Seven
 * Ported to HarmonyOS ArkTS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { Logger } from './Logger.ets';

const log = Logger.tag('PackageUtils');

// ---- Abstractions for testability ----

/**
 * Information about an installed bundle (app package).
 * Maps to @ohos.bundle.bundleManager.BundleInfo fields.
 */
export interface BundleSignatureInfo {
  /** Raw certificate bytes (DER-encoded). */
  certificateData: Uint8Array;
}

/**
 * Abstraction over HarmonyOS bundleManager for querying bundle info.
 *
 * Production: wraps @ohos.bundle.bundleManager.getBundleInfoForSelf().
 * Tests: supply a mock that returns known certificate data.
 */
export interface BundleInfoProvider {
  /**
   * Get the signing certificate data for the given bundle name.
   * Returns null if the bundle is not found or has no signatures.
   */
  getSignatureInfo(bundleName: string): BundleSignatureInfo | null;
}

// ---- PackageUtils ----

/**
 * PackageUtils — utilities for querying package/bundle information.
 *
 * Equivalent to the Android PackageUtils class.
 * Provides:
 *  - getSignature: retrieve the SHA1 fingerprint of a bundle's signing certificate
 *  - computeSHA1: compute the SHA1 hash of arbitrary byte data
 */
export class PackageUtils {

  /**
   * Get the SHA1 signature fingerprint for a given bundle name.
   *
   * @param provider - bundle info provider (injectable for testing)
   * @param bundleName - the bundle/package name to query
   * @returns SHA1 fingerprint string like "A1:43:6B:..." or null
   */
  static getSignature(provider: BundleInfoProvider, bundleName: string): string | null {
    try {
      const info = provider.getSignatureInfo(bundleName);
      if (info === null) {
        log.e(`Cannot find signature for bundle ${bundleName}`);
        return null;
      }
      return PackageUtils.computeSHA1(info.certificateData);
    } catch (e) {
      log.e(`Cannot find bundle ${bundleName}`, e instanceof Error ? e : new Error(String(e)));
      return null;
    }
  }

  /**
   * Compute the SHA1 fingerprint of raw certificate bytes.
   *
   * @param certRaw - the raw bytes to hash
   * @returns fingerprint string like "A1:43:6B:34:..." (uppercase, colon-separated) or null
   */
  static computeSHA1(certRaw: Uint8Array): string | null {
    try {
      const sha1 = PackageUtils.sha1Digest(certRaw);
      const parts: string[] = [];
      for (let i = 0; i < sha1.length; i++) {
        const hex = sha1[i].toString(16).padStart(2, '0');
        parts.push(hex);
      }
      return parts.join(':').toUpperCase();
    } catch (e) {
      log.e('Cannot compute SHA1', e instanceof Error ? e : new Error(String(e)));
      return null;
    }
  }

  /**
   * Pure SHA-1 digest implementation.
   *
   * In production, this can be replaced with @ohos.security.cryptoFramework:
   *   import cryptoFramework from '@ohos.security.cryptoFramework';
   *   let md = cryptoFramework.createMd('SHA1');
   *   md.updateSync({ data: certRaw });
   *   return new Uint8Array(md.digestSync().data);
   *
   * The built-in implementation here avoids native dependencies for testability.
   */
  static sha1Digest(data: Uint8Array): Uint8Array {
    // SHA-1 constants
    const H0 = 0x67452301;
    const H1 = 0xEFCDAB89;
    const H2 = 0x98BADCFE;
    const H3 = 0x10325476;
    const H4 = 0xC3D2E1F0;

    // Pre-processing: pad the message
    const msgLen = data.length;
    const bitLen = msgLen * 8;
    // Message needs to be padded to 64-byte (512-bit) blocks
    // Padding: 1 byte 0x80, then zeros, then 8-byte big-endian length
    const padLen = 64 - ((msgLen + 9) % 64);
    const totalLen = msgLen + 1 + (padLen === 64 ? 0 : padLen) + 8;
    const padded = new Uint8Array(totalLen);
    padded.set(data, 0);
    padded[msgLen] = 0x80;
    // Write bit length as big-endian 64-bit at end
    // JavaScript numbers are 64-bit floats, safe for lengths up to 2^53
    const view = new DataView(padded.buffer);
    // High 32 bits of bit length (for messages < 512 MB this is 0)
    view.setUint32(totalLen - 8, Math.floor(bitLen / 0x100000000), false);
    view.setUint32(totalLen - 4, bitLen >>> 0, false);

    let h0 = H0, h1 = H1, h2 = H2, h3 = H3, h4 = H4;
    const w = new Int32Array(80);

    for (let offset = 0; offset < totalLen; offset += 64) {
      // Break chunk into sixteen 32-bit big-endian words
      for (let i = 0; i < 16; i++) {
        w[i] = view.getInt32(offset + i * 4, false);
      }
      // Extend to 80 words
      for (let i = 16; i < 80; i++) {
        w[i] = rotl(w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1);
      }

      let a = h0, b = h1, c = h2, d = h3, e = h4;
      for (let i = 0; i < 80; i++) {
        let f: number, k: number;
        if (i < 20) {
          f = (b & c) | (~b & d);
          k = 0x5A827999;
        } else if (i < 40) {
          f = b ^ c ^ d;
          k = 0x6ED9EBA1;
        } else if (i < 60) {
          f = (b & c) | (b & d) | (c & d);
          k = 0x8F1BBCDC;
        } else {
          f = b ^ c ^ d;
          k = 0xCA62C1D6;
        }
        const temp = (rotl(a, 5) + f + e + k + w[i]) | 0;
        e = d;
        d = c;
        c = rotl(b, 30);
        b = a;
        a = temp;
      }

      h0 = (h0 + a) | 0;
      h1 = (h1 + b) | 0;
      h2 = (h2 + c) | 0;
      h3 = (h3 + d) | 0;
      h4 = (h4 + e) | 0;
    }

    // Produce the final hash as 20 bytes
    const result = new Uint8Array(20);
    const rv = new DataView(result.buffer);
    rv.setUint32(0, h0, false);
    rv.setUint32(4, h1, false);
    rv.setUint32(8, h2, false);
    rv.setUint32(12, h3, false);
    rv.setUint32(16, h4, false);
    return result;
  }
}

/** Circular left rotation of a 32-bit integer. */
function rotl(value: number, count: number): number {
  return ((value << count) | (value >>> (32 - count))) | 0;
}
