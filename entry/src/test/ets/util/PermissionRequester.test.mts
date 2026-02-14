import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import {
  PermissionRequester,
  GrantStatus,
  RequestResult,
} from '../../../main/ets/util/PermissionRequester.ets';
import type {
  PermissionManager,
  RationalePresenter,
} from '../../../main/ets/util/PermissionRequester.ets';

// ---- Mock implementations ----

class MockPermissionManager implements PermissionManager {
  private granted = new Set<string>();
  requestedPermissions: string[][] = [];
  /** When set, requestPermissions will reject with this error. */
  requestError: Error | null = null;
  /** Results returned by requestPermissions. Default: all GRANTED. */
  requestResults: GrantStatus[] | null = null;

  grant(permission: string): void {
    this.granted.add(permission);
  }

  revoke(permission: string): void {
    this.granted.delete(permission);
  }

  checkPermission(permission: string): GrantStatus {
    return this.granted.has(permission) ? GrantStatus.GRANTED : GrantStatus.DENIED;
  }

  async requestPermissions(permissions: string[]): Promise<GrantStatus[]> {
    this.requestedPermissions.push([...permissions]);
    if (this.requestError) {
      throw this.requestError;
    }
    if (this.requestResults !== null) {
      return this.requestResults;
    }
    // Default: grant everything
    return permissions.map(() => GrantStatus.GRANTED);
  }
}

class MockRationalePresenter implements RationalePresenter {
  messages: string[] = [];
  shouldAccept = true;
  shouldThrow = false;

  async showRationale(message: string): Promise<boolean> {
    if (this.shouldThrow) {
      throw new Error('Dialog error');
    }
    this.messages.push(message);
    return this.shouldAccept;
  }
}

describe('PermissionRequester', () => {
  let manager: MockPermissionManager;
  let presenter: MockRationalePresenter;
  let requester: PermissionRequester;

  beforeEach(() => {
    manager = new MockPermissionManager();
    presenter = new MockRationalePresenter();
    requester = new PermissionRequester(manager, presenter);
  });

  // ---- request (single permission) ----

  describe('request', () => {
    it('should return ALREADY_GRANTED if permission is already granted', async () => {
      manager.grant('ohos.permission.READ_MEDIA');
      const result = await requester.request('ohos.permission.READ_MEDIA', 'Need access');
      assert.strictEqual(result, RequestResult.ALREADY_GRANTED);
      // Should not have shown rationale or made a request
      assert.strictEqual(presenter.messages.length, 0);
      assert.strictEqual(manager.requestedPermissions.length, 0);
    });

    it('should show rationale and request permission when not granted', async () => {
      const result = await requester.request('ohos.permission.CAMERA', 'Need camera');
      assert.strictEqual(result, RequestResult.GRANTED);
      assert.deepStrictEqual(presenter.messages, ['Need camera']);
      assert.deepStrictEqual(manager.requestedPermissions, [['ohos.permission.CAMERA']]);
    });

    it('should return CANCELLED when user dismisses rationale', async () => {
      presenter.shouldAccept = false;
      const result = await requester.request('ohos.permission.CAMERA', 'Need camera');
      assert.strictEqual(result, RequestResult.CANCELLED);
      // Should not have made a request
      assert.strictEqual(manager.requestedPermissions.length, 0);
    });

    it('should request without rationale when rationale is undefined', async () => {
      const result = await requester.request('ohos.permission.CAMERA');
      assert.strictEqual(result, RequestResult.GRANTED);
      assert.strictEqual(presenter.messages.length, 0);
      assert.strictEqual(manager.requestedPermissions.length, 1);
    });

    it('should request without rationale when rationale is empty', async () => {
      const result = await requester.request('ohos.permission.CAMERA', '');
      assert.strictEqual(result, RequestResult.GRANTED);
      assert.strictEqual(presenter.messages.length, 0);
    });

    it('should return DENIED when user denies permission', async () => {
      manager.requestResults = [GrantStatus.DENIED];
      const result = await requester.request('ohos.permission.CAMERA', 'Need camera');
      assert.strictEqual(result, RequestResult.DENIED);
    });

    it('should return ERROR when request throws', async () => {
      manager.requestError = new Error('System error');
      const result = await requester.request('ohos.permission.CAMERA', 'Need camera');
      assert.strictEqual(result, RequestResult.ERROR);
    });

    it('should return ERROR when rationale dialog throws', async () => {
      presenter.shouldThrow = true;
      const result = await requester.request('ohos.permission.CAMERA', 'Need camera');
      assert.strictEqual(result, RequestResult.ERROR);
    });
  });

  // ---- requestMultiple ----

  describe('requestMultiple', () => {
    it('should return all granted for already-granted permissions', async () => {
      manager.grant('perm.A');
      manager.grant('perm.B');
      const result = await requester.requestMultiple(['perm.A', 'perm.B']);
      assert.strictEqual(result.get('perm.A'), true);
      assert.strictEqual(result.get('perm.B'), true);
      assert.strictEqual(manager.requestedPermissions.length, 0);
    });

    it('should request only non-granted permissions', async () => {
      manager.grant('perm.A');
      const result = await requester.requestMultiple(['perm.A', 'perm.B', 'perm.C']);
      assert.strictEqual(result.get('perm.A'), true);
      assert.strictEqual(result.get('perm.B'), true);
      assert.strictEqual(result.get('perm.C'), true);
      assert.deepStrictEqual(manager.requestedPermissions, [['perm.B', 'perm.C']]);
    });

    it('should handle mixed grant results', async () => {
      manager.requestResults = [GrantStatus.GRANTED, GrantStatus.DENIED];
      const result = await requester.requestMultiple(['perm.A', 'perm.B']);
      assert.strictEqual(result.get('perm.A'), true);
      assert.strictEqual(result.get('perm.B'), false);
    });

    it('should mark all as denied when request throws', async () => {
      manager.requestError = new Error('System error');
      const result = await requester.requestMultiple(['perm.A', 'perm.B']);
      assert.strictEqual(result.get('perm.A'), false);
      assert.strictEqual(result.get('perm.B'), false);
    });

    it('should handle empty permissions array', async () => {
      const result = await requester.requestMultiple([]);
      assert.strictEqual(result.size, 0);
    });
  });

  // ---- GrantStatus constants ----

  describe('GrantStatus', () => {
    it('should have correct values', () => {
      assert.strictEqual(GrantStatus.GRANTED, 0);
      assert.strictEqual(GrantStatus.DENIED, -1);
    });
  });

  // ---- RequestResult constants ----

  describe('RequestResult', () => {
    it('should have all expected values', () => {
      assert.strictEqual(RequestResult.ALREADY_GRANTED, 'already_granted');
      assert.strictEqual(RequestResult.GRANTED, 'granted');
      assert.strictEqual(RequestResult.DENIED, 'denied');
      assert.strictEqual(RequestResult.CANCELLED, 'cancelled');
      assert.strictEqual(RequestResult.ERROR, 'error');
    });
  });
});
