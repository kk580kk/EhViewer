import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import {
  OhosPermissionManager,
} from '../../../main/ets/platform/OhosPermissionManager.ets';
import type {
  OhosAtManagerApi,
  OhosPermissionRequestResult,
} from '../../../main/ets/platform/OhosPermissionManager.ets';
import { GrantStatus } from '../../../main/ets/util/PermissionRequester.ets';

// ---- Mock implementations ----

class MockAtManager implements OhosAtManagerApi {
  private granted = new Set<string>();
  requestedCalls: Array<{ context: object; permissions: string[] }> = [];
  shouldThrowOnCheck = false;
  shouldThrowOnRequest = false;
  /** Override request results. Default: grant all. */
  requestResults: number[] | null = null;

  grant(permission: string): void {
    this.granted.add(permission);
  }

  checkAccessTokenSync(_tokenId: number, permission: string): number {
    if (this.shouldThrowOnCheck) {
      throw new Error('checkAccessToken error');
    }
    return this.granted.has(permission) ? 0 : -1;
  }

  async requestPermissionsFromUser(context: object, permissions: string[]): Promise<OhosPermissionRequestResult> {
    this.requestedCalls.push({ context, permissions: [...permissions] });
    if (this.shouldThrowOnRequest) {
      throw new Error('requestPermissions error');
    }
    const authResults = this.requestResults
      ?? permissions.map(() => 0); // default: grant all
    return { permissions: [...permissions], authResults };
  }
}

describe('OhosPermissionManager', () => {
  let atManager: MockAtManager;
  let manager: OhosPermissionManager;
  const TOKEN_ID = 12345;
  const context = {};

  beforeEach(() => {
    atManager = new MockAtManager();
    manager = new OhosPermissionManager(atManager, TOKEN_ID, context);
  });

  // ---- checkPermission ----

  describe('checkPermission', () => {
    it('should return GRANTED for granted permission', () => {
      atManager.grant('ohos.permission.READ_MEDIA');
      const result = manager.checkPermission('ohos.permission.READ_MEDIA');
      assert.strictEqual(result, GrantStatus.GRANTED);
    });

    it('should return DENIED for non-granted permission', () => {
      const result = manager.checkPermission('ohos.permission.CAMERA');
      assert.strictEqual(result, GrantStatus.DENIED);
    });

    it('should return DENIED when atManager throws', () => {
      atManager.shouldThrowOnCheck = true;
      const result = manager.checkPermission('ohos.permission.CAMERA');
      assert.strictEqual(result, GrantStatus.DENIED);
    });
  });

  // ---- requestPermissions ----

  describe('requestPermissions', () => {
    it('should return GRANTED for all permissions when user approves', async () => {
      const results = await manager.requestPermissions(['ohos.permission.CAMERA', 'ohos.permission.LOCATION']);
      assert.deepStrictEqual(results, [GrantStatus.GRANTED, GrantStatus.GRANTED]);
    });

    it('should pass context and permissions to atManager', async () => {
      await manager.requestPermissions(['ohos.permission.CAMERA']);
      assert.strictEqual(atManager.requestedCalls.length, 1);
      assert.strictEqual(atManager.requestedCalls[0].context, context);
      assert.deepStrictEqual(atManager.requestedCalls[0].permissions, ['ohos.permission.CAMERA']);
    });

    it('should return DENIED for denied permissions', async () => {
      atManager.requestResults = [0, -1];
      const results = await manager.requestPermissions(['perm.A', 'perm.B']);
      assert.deepStrictEqual(results, [GrantStatus.GRANTED, GrantStatus.DENIED]);
    });

    it('should return all DENIED when atManager throws', async () => {
      atManager.shouldThrowOnRequest = true;
      const results = await manager.requestPermissions(['perm.A', 'perm.B']);
      assert.deepStrictEqual(results, [GrantStatus.DENIED, GrantStatus.DENIED]);
    });

    it('should handle empty permissions array', async () => {
      const results = await manager.requestPermissions([]);
      assert.deepStrictEqual(results, []);
    });
  });
});
