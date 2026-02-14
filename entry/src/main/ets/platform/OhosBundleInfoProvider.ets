/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { Logger } from '../util/Logger.ets';
import type { BundleInfoProvider, BundleSignatureInfo } from '../util/PackageUtils.ets';

const log = Logger.tag('OhosBundleInfoProvider');

// ---- Harmony bundleManager abstraction ----

/**
 * Abstraction over @ohos.bundle.bundleManager.BundleInfo.SignatureInfo.
 *
 * In production, this maps to the signatureInfo field of BundleInfo
 * returned by bundleManager.getBundleInfoForSelf() or getBundleInfo().
 */
export interface OhosSignatureInfo {
  /** The app's signing certificate fingerprint. */
  fingerprint: string;
  /** Raw certificate data (DER-encoded). May be empty. */
  certificate: Uint8Array;
}

/**
 * Abstraction over @ohos.bundle.bundleManager.BundleInfo.
 */
export interface OhosBundleInfo {
  signatureInfo?: OhosSignatureInfo;
}

/**
 * Abstraction over the @ohos.bundle.bundleManager API.
 *
 * Production: pass the real bundleManager module.
 * Tests: supply a mock implementation.
 */
export interface OhosBundleManagerApi {
  /**
   * Get bundle info for the specified bundle name.
   * Maps to bundleManager.getBundleInfo(bundleName, flags).
   *
   * @param bundleName - the bundle name to query
   * @param flags - bundle info flags (e.g. GET_BUNDLE_INFO_WITH_SIGNATURE_INFO = 0x00000800)
   * @returns the bundle info object
   * @throws if the bundle is not found
   */
  getBundleInfo(bundleName: string, flags: number): OhosBundleInfo;
}

/** Flag to include signature info in bundle query results. */
export const GET_BUNDLE_INFO_WITH_SIGNATURE_INFO = 0x00000800;

/**
 * OhosBundleInfoProvider — production implementation of BundleInfoProvider
 * using HarmonyOS @ohos.bundle.bundleManager API.
 *
 * Retrieves the signing certificate data for a given bundle (package) name.
 *
 * Usage (production):
 *   import bundleManager from '@ohos.bundle.bundleManager';
 *   const provider = new OhosBundleInfoProvider(bundleManager);
 *   const sig = PackageUtils.getSignature(provider, 'com.example.app');
 */
export class OhosBundleInfoProvider implements BundleInfoProvider {
  private api: OhosBundleManagerApi;

  constructor(api: OhosBundleManagerApi) {
    this.api = api;
  }

  getSignatureInfo(bundleName: string): BundleSignatureInfo | null {
    try {
      const info = this.api.getBundleInfo(bundleName, GET_BUNDLE_INFO_WITH_SIGNATURE_INFO);
      if (!info.signatureInfo) {
        log.e(`No signature info for bundle ${bundleName}`);
        return null;
      }

      const cert = info.signatureInfo.certificate;
      if (!cert || cert.length === 0) {
        log.e(`Empty certificate data for bundle ${bundleName}`);
        return null;
      }

      return { certificateData: cert };
    } catch (e) {
      log.e(`Failed to get bundle info for ${bundleName}`, e instanceof Error ? e : new Error(String(e)));
      return null;
    }
  }
}
