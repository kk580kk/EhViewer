import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { SecurityGuard, VerifyResult } from '../../../main/ets/security/SecurityGuard.ets';
import { MemorySecureStorage } from '../../../main/ets/security/SecureStorage.ets';
import { PatternCell, LockPatternUtils } from '../../../main/ets/security/LockPatternUtils.ets';

describe('SecurityGuard', () => {
  let storage: MemorySecureStorage;
  let guard: SecurityGuard;

  // Helper: create a simple L-shaped pattern
  const L_PATTERN: PatternCell[] = [
    PatternCell.of(0, 0),
    PatternCell.of(1, 0),
    PatternCell.of(2, 0),
    PatternCell.of(2, 1),
    PatternCell.of(2, 2),
  ];

  const DIAGONAL: PatternCell[] = [
    PatternCell.of(0, 0),
    PatternCell.of(1, 1),
    PatternCell.of(2, 2),
  ];

  beforeEach(() => {
    storage = new MemorySecureStorage();
    guard = new SecurityGuard(storage);
  });

  // ---- Pattern Management ----

  describe('pattern management', () => {
    it('should report no pattern set initially', () => {
      assert.strictEqual(guard.isPatternSet(), false);
    });

    it('should set and detect a pattern', () => {
      guard.setPattern(L_PATTERN);
      assert.strictEqual(guard.isPatternSet(), true);
    });

    it('should clear pattern with empty array', () => {
      guard.setPattern(L_PATTERN);
      guard.setPattern([]);
      assert.strictEqual(guard.isPatternSet(), false);
    });

    it('should clear pattern with single cell (too short)', () => {
      guard.setPattern(L_PATTERN);
      guard.setPattern([PatternCell.of(0, 0)]);
      assert.strictEqual(guard.isPatternSet(), false);
    });

    it('should clear pattern with clearPattern()', () => {
      guard.setPattern(L_PATTERN);
      guard.clearPattern();
      assert.strictEqual(guard.isPatternSet(), false);
    });

    it('should get pattern string after setting', () => {
      guard.setPattern(L_PATTERN);
      const str = guard.getPatternString();
      assert.strictEqual(str.length, L_PATTERN.length);
    });

    it('should return empty string when no pattern set', () => {
      assert.strictEqual(guard.getPatternString(), '');
    });
  });

  describe('setPatternString', () => {
    it('should set pattern from string', () => {
      const str = LockPatternUtils.patternToString(L_PATTERN);
      guard.setPatternString(str);
      assert.strictEqual(guard.isPatternSet(), true);
      assert.strictEqual(guard.getPatternString(), str);
    });

    it('should clear pattern with empty string', () => {
      guard.setPattern(L_PATTERN);
      guard.setPatternString('');
      assert.strictEqual(guard.isPatternSet(), false);
    });
  });

  // ---- Verification ----

  describe('verifyPattern', () => {
    it('should return NOT_SET when no pattern configured', () => {
      assert.strictEqual(guard.verifyPattern(DIAGONAL), VerifyResult.NOT_SET);
    });

    it('should return SUCCESS for correct pattern', () => {
      guard.setPattern(L_PATTERN);
      assert.strictEqual(guard.verifyPattern(L_PATTERN), VerifyResult.SUCCESS);
    });

    it('should return WRONG for incorrect pattern', () => {
      guard.setPattern(L_PATTERN);
      assert.strictEqual(guard.verifyPattern(DIAGONAL), VerifyResult.WRONG);
    });

    it('should reset failed attempts on success', () => {
      guard.setPattern(L_PATTERN);
      guard.verifyPattern(DIAGONAL); // fail 1
      guard.verifyPattern(DIAGONAL); // fail 2
      assert.strictEqual(guard.getFailedAttempts(), 2);
      guard.verifyPattern(L_PATTERN); // success
      assert.strictEqual(guard.getFailedAttempts(), 0);
    });

    it('should lock out after MAX_RETRIES failures', () => {
      guard.setPattern(L_PATTERN);
      for (let i = 0; i < SecurityGuard.MAX_RETRIES - 1; i++) {
        const result = guard.verifyPattern(DIAGONAL);
        assert.strictEqual(result, VerifyResult.WRONG);
      }
      // The 5th failure should trigger lockout
      const lockout = guard.verifyPattern(DIAGONAL);
      assert.strictEqual(lockout, VerifyResult.LOCKED_OUT);
    });

    it('should stay locked out on subsequent attempts', () => {
      guard.setPattern(L_PATTERN);
      for (let i = 0; i < SecurityGuard.MAX_RETRIES; i++) {
        guard.verifyPattern(DIAGONAL);
      }
      // Even correct pattern should be locked out
      assert.strictEqual(guard.verifyPattern(L_PATTERN), VerifyResult.LOCKED_OUT);
    });

    it('should unlock after resetFailedAttempts', () => {
      guard.setPattern(L_PATTERN);
      for (let i = 0; i < SecurityGuard.MAX_RETRIES; i++) {
        guard.verifyPattern(DIAGONAL);
      }
      guard.resetFailedAttempts();
      assert.strictEqual(guard.verifyPattern(L_PATTERN), VerifyResult.SUCCESS);
    });
  });

  describe('verifyPatternString', () => {
    it('should return SUCCESS for correct pattern string', () => {
      guard.setPattern(L_PATTERN);
      const str = LockPatternUtils.patternToString(L_PATTERN);
      assert.strictEqual(guard.verifyPatternString(str), VerifyResult.SUCCESS);
    });

    it('should return WRONG for incorrect pattern string', () => {
      guard.setPattern(L_PATTERN);
      const wrongStr = LockPatternUtils.patternToString(DIAGONAL);
      assert.strictEqual(guard.verifyPatternString(wrongStr), VerifyResult.WRONG);
    });

    it('should return NOT_SET when no pattern configured', () => {
      assert.strictEqual(guard.verifyPatternString('anything'), VerifyResult.NOT_SET);
    });
  });

  // ---- Remaining Attempts ----

  describe('remaining attempts', () => {
    it('should start at MAX_RETRIES', () => {
      assert.strictEqual(guard.getRemainingAttempts(), SecurityGuard.MAX_RETRIES);
    });

    it('should decrease with each failure', () => {
      guard.setPattern(L_PATTERN);
      guard.verifyPattern(DIAGONAL);
      assert.strictEqual(guard.getRemainingAttempts(), SecurityGuard.MAX_RETRIES - 1);
    });

    it('should be 0 when locked out', () => {
      guard.setPattern(L_PATTERN);
      for (let i = 0; i < SecurityGuard.MAX_RETRIES; i++) {
        guard.verifyPattern(DIAGONAL);
      }
      assert.strictEqual(guard.getRemainingAttempts(), 0);
    });
  });

  // ---- Biometric ----

  describe('fingerprint', () => {
    it('should be disabled by default', () => {
      assert.strictEqual(guard.isFingerprintEnabled(), false);
    });

    it('should enable fingerprint', () => {
      guard.setFingerprintEnabled(true);
      assert.strictEqual(guard.isFingerprintEnabled(), true);
    });

    it('should disable fingerprint', () => {
      guard.setFingerprintEnabled(true);
      guard.setFingerprintEnabled(false);
      assert.strictEqual(guard.isFingerprintEnabled(), false);
    });
  });

  // ---- shouldShowLockScreen ----

  describe('shouldShowLockScreen', () => {
    it('should return false when no pattern set', () => {
      assert.strictEqual(guard.shouldShowLockScreen(), false);
    });

    it('should return true when pattern is set', () => {
      guard.setPattern(L_PATTERN);
      assert.strictEqual(guard.shouldShowLockScreen(), true);
    });

    it('should return false after clearing pattern', () => {
      guard.setPattern(L_PATTERN);
      guard.clearPattern();
      assert.strictEqual(guard.shouldShowLockScreen(), false);
    });
  });
});
