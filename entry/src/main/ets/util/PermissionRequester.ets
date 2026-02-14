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

const log = Logger.tag('PermissionRequester');

// ---- Grant result constants ----

export const GrantStatus = {
  /** Permission is granted. */
  GRANTED: 0,
  /** Permission is denied. */
  DENIED: -1,
} as const;

export type GrantStatus = (typeof GrantStatus)[keyof typeof GrantStatus];

// ---- Abstractions for testability ----

/**
 * Callback invoked when a permission request completes.
 *
 * @param permission - the permission that was requested
 * @param granted - whether the permission was granted
 */
export type PermissionResultCallback = (permission: string, granted: boolean) => void;

/**
 * Abstraction over HarmonyOS abilityAccessCtrl + UI context for permission operations.
 *
 * Production: wraps abilityAccessCtrl.createAtManager() and UIAbilityContext.
 * Tests: supply a mock implementation.
 */
export interface PermissionManager {
  /**
   * Check if a permission is already granted.
   * Maps to atManager.checkAccessTokenSync(tokenId, permission).
   */
  checkPermission(permission: string): GrantStatus;

  /**
   * Request one or more permissions from the user.
   * Maps to atManager.requestPermissionsFromUser(context, permissions).
   *
   * Returns a promise that resolves with the grant statuses.
   */
  requestPermissions(permissions: string[]): Promise<GrantStatus[]>;
}

/**
 * Abstraction for showing a rationale dialog before requesting permission.
 *
 * Production: shows an AlertDialog / CustomDialog.
 * Tests: supply a mock that auto-confirms or auto-cancels.
 */
export interface RationalePresenter {
  /**
   * Show a rationale message and wait for user decision.
   * Returns true if the user tapped "OK" (proceed), false if "Cancel".
   */
  showRationale(message: string): Promise<boolean>;
}

// ---- Request result ----

export const RequestResult = {
  /** Permission was already granted — caller can proceed immediately. */
  ALREADY_GRANTED: 'already_granted',
  /** Permission was just granted after user approval. */
  GRANTED: 'granted',
  /** User denied the permission. */
  DENIED: 'denied',
  /** User dismissed the rationale dialog without granting. */
  CANCELLED: 'cancelled',
  /** An error occurred during the request. */
  ERROR: 'error',
} as const;

export type RequestResult = (typeof RequestResult)[keyof typeof RequestResult];

// ---- PermissionRequester ----

/**
 * PermissionRequester — request runtime permissions with optional rationale dialog.
 *
 * Equivalent to the Android PermissionRequester class.
 *
 * HarmonyOS permission model:
 *  - Normal permissions: granted at install, no need to request at runtime.
 *  - User_grant permissions: must be requested at runtime via abilityAccessCtrl.
 *
 * Usage (production):
 *   const mgr: PermissionManager = new OhosPermissionManager(context);
 *   const presenter: RationalePresenter = new DialogRationalePresenter(context);
 *   const requester = new PermissionRequester(mgr, presenter);
 *   const result = await requester.request('ohos.permission.READ_MEDIA', 'We need access...');
 */
export class PermissionRequester {
  private manager: PermissionManager;
  private presenter: RationalePresenter;

  constructor(manager: PermissionManager, presenter: RationalePresenter) {
    this.manager = manager;
    this.presenter = presenter;
  }

  /**
   * Request a single permission. Shows a rationale dialog if `rationale` is provided
   * and the permission has not been granted yet.
   *
   * @param permission - the permission string (e.g. 'ohos.permission.READ_MEDIA')
   * @param rationale - human-readable explanation of why the permission is needed
   * @returns a RequestResult indicating what happened
   */
  async request(permission: string, rationale?: string): Promise<RequestResult> {
    // 1. Check if already granted
    if (this.manager.checkPermission(permission) === GrantStatus.GRANTED) {
      return RequestResult.ALREADY_GRANTED;
    }

    // 2. Show rationale if provided
    if (rationale !== undefined && rationale.length > 0) {
      let userAccepted: boolean;
      try {
        userAccepted = await this.presenter.showRationale(rationale);
      } catch (e) {
        log.e('Rationale dialog error', e instanceof Error ? e : new Error(String(e)));
        return RequestResult.ERROR;
      }
      if (!userAccepted) {
        return RequestResult.CANCELLED;
      }
    }

    // 3. Request the permission
    try {
      const results = await this.manager.requestPermissions([permission]);
      if (results.length > 0 && results[0] === GrantStatus.GRANTED) {
        return RequestResult.GRANTED;
      }
      return RequestResult.DENIED;
    } catch (e) {
      log.e('Permission request error', e instanceof Error ? e : new Error(String(e)));
      return RequestResult.ERROR;
    }
  }

  /**
   * Request multiple permissions at once (no rationale dialog).
   *
   * @param permissions - array of permission strings
   * @returns map of permission to whether it was granted
   */
  async requestMultiple(permissions: string[]): Promise<Map<string, boolean>> {
    const resultMap = new Map<string, boolean>();

    // Separate already-granted from needs-request
    const needsRequest: string[] = [];
    for (const perm of permissions) {
      if (this.manager.checkPermission(perm) === GrantStatus.GRANTED) {
        resultMap.set(perm, true);
      } else {
        needsRequest.push(perm);
      }
    }

    if (needsRequest.length === 0) {
      return resultMap;
    }

    try {
      const results = await this.manager.requestPermissions(needsRequest);
      for (let i = 0; i < needsRequest.length; i++) {
        resultMap.set(needsRequest[i], results[i] === GrantStatus.GRANTED);
      }
    } catch (e) {
      log.e('Multi-permission request error', e instanceof Error ? e : new Error(String(e)));
      for (const perm of needsRequest) {
        resultMap.set(perm, false);
      }
    }

    return resultMap;
  }
}
