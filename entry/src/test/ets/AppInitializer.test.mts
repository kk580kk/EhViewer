import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { AppInitializer } from '../../main/ets/AppInitializer.ets';

describe('AppInitializer', () => {
  beforeEach(() => {
    AppInitializer.reset();
  });

  it('should not be initialized initially', () => {
    assert.strictEqual(AppInitializer.isInitialized(), false);
  });

  it('should mark as initialized after initialize()', () => {
    AppInitializer.initialize();
    assert.strictEqual(AppInitializer.isInitialized(), true);
  });

  it('should return all-true status on success', () => {
    const status = AppInitializer.initialize();
    assert.strictEqual(status.settings, true);
    assert.strictEqual(status.database, true);
    assert.strictEqual(status.signIn, true);
    assert.strictEqual(status.security, true);
  });

  it('should be idempotent', () => {
    const first = AppInitializer.initialize();
    const second = AppInitializer.initialize();
    assert.deepStrictEqual(first, second);
  });

  it('should reset to uninitialized', () => {
    AppInitializer.initialize();
    AppInitializer.reset();
    assert.strictEqual(AppInitializer.isInitialized(), false);
  });

  it('getDiagnostics should return settings snapshot', () => {
    AppInitializer.initialize();
    const diag = AppInitializer.getDiagnostics();
    assert.ok('gallerySite' in diag);
    assert.ok('needSignIn' in diag);
    assert.ok('securityEnabled' in diag);
  });
});
