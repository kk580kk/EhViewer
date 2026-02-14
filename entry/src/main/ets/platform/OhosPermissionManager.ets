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
import { GrantStatus } from '../util/PermissionRequester.ets';
import type { PermissionManager } from '../util/PermissionRequester.ets';

const log = Logger.tag('OhosPermissionManager');

// ---- Harmony abilityAccessCtrl abstraction ----

/**
 * Result returned by the HarmonyOS permission request dialog.
 */
export interface OhosPermissionRequestResult {
  permissions: string[];
  authResults: number[];
}

/**
 * Abstraction over @ohos.abilityAccessCtrl.AtManager.
 *
 * Production: pass atManager created via abilityAccessCtrl.createAtManager().
 * Tests: supply a mock implementation.
 */
export interface OhosAtManagerApi {
  /**
   * Synchronously check if a permission is granted for the given token.
   * Maps to atManager.checkAccessTokenSync(tokenId, permission).
   *
   * @returns GrantStatus.GRANTED (0) or GrantStatus.DENIED (-1)
   */
  checkAccessTokenSync(tokenId: number, permission: string): number;

  /**
   * Request permissions from the user via system dialog.
   * Maps to atManager.requestPermissionsFromUser(context, permissions).
   *
   * @returns promise resolving to the request result
   */
  requestPermissionsFromUser(context: object, permissions: string[]): Promise<OhosPermissionRequestResult>;
}

/**
 * OhosPermissionManager — production implementation of PermissionManager
 * using HarmonyOS @ohos.abilityAccessCtrl API.
 *
 * Handles runtime permission checking and requesting using HarmonyOS's
 * abilityAccessCtrl module (AtManager).
 *
 * Usage (production):
 *   import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
 *   import bundleManager from '@ohos.bundle.bundleManager';
 *   const atManager = abilityAccessCtrl.createAtManager();
 *   const tokenId = bundleManager.getBundleInfoForSelfSync(0).appInfo.accessTokenId;
 *   const mgr = new OhosPermissionManager(atManager, tokenId, context);
 */
export class OhosPermissionManager implements PermissionManager {
  private atManager: OhosAtManagerApi;
  private tokenId: number;
  private context: object;

  constructor(atManager: OhosAtManagerApi, tokenId: number, context: object) {
    this.atManager = atManager;
    this.tokenId = tokenId;
    this.context = context;
  }

  checkPermission(permission: string): GrantStatus {
    try {
      const result = this.atManager.checkAccessTokenSync(this.tokenId, permission);
      return result === GrantStatus.GRANTED ? GrantStatus.GRANTED : GrantStatus.DENIED;
    } catch (e) {
      log.e(`Failed to check permission ${permission}`, e instanceof Error ? e : new Error(String(e)));
      return GrantStatus.DENIED;
    }
  }

  async requestPermissions(permissions: string[]): Promise<GrantStatus[]> {
    try {
      const result = await this.atManager.requestPermissionsFromUser(this.context, permissions);
      return result.authResults.map(r => r === GrantStatus.GRANTED ? GrantStatus.GRANTED : GrantStatus.DENIED);
    } catch (e) {
      log.e('Failed to request permissions', e instanceof Error ? e : new Error(String(e)));
      return permissions.map(() => GrantStatus.DENIED);
    }
  }
}
