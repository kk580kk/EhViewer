import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { LockPatternUtils, PatternCell } from '../../../main/ets/security/LockPatternUtils.ets';

describe('PatternCell', () => {
  it('should create cells with of()', () => {
    const cell = PatternCell.of(1, 2);
    assert.strictEqual(cell.row, 1);
    assert.strictEqual(cell.column, 2);
  });

  it('should return the same instance for the same coordinates', () => {
    const a = PatternCell.of(0, 0);
    const b = PatternCell.of(0, 0);
    assert.strictEqual(a, b);
  });

  it('should throw for out-of-range coordinates', () => {
    assert.throws(() => PatternCell.of(-1, 0));
    assert.throws(() => PatternCell.of(3, 0));
    assert.throws(() => PatternCell.of(0, 3));
    assert.throws(() => PatternCell.of(0, -1));
  });

  it('should cover all 9 cells', () => {
    for (let r = 0; r < 3; r++) {
      for (let c = 0; c < 3; c++) {
        const cell = PatternCell.of(r, c);
        assert.strictEqual(cell.row, r);
        assert.strictEqual(cell.column, c);
      }
    }
  });
});

describe('LockPatternUtils', () => {
  describe('patternToString / stringToPattern round-trip', () => {
    it('should round-trip a simple pattern', () => {
      const cells = [PatternCell.of(0, 0), PatternCell.of(1, 1), PatternCell.of(2, 2)];
      const str = LockPatternUtils.patternToString(cells);
      const back = LockPatternUtils.stringToPattern(str);
      assert.strictEqual(back.length, 3);
      assert.strictEqual(back[0].row, 0);
      assert.strictEqual(back[0].column, 0);
      assert.strictEqual(back[1].row, 1);
      assert.strictEqual(back[1].column, 1);
      assert.strictEqual(back[2].row, 2);
      assert.strictEqual(back[2].column, 2);
    });

    it('should round-trip all 9 cells', () => {
      const cells: PatternCell[] = [];
      for (let r = 0; r < 3; r++) {
        for (let c = 0; c < 3; c++) {
          cells.push(PatternCell.of(r, c));
        }
      }
      const str = LockPatternUtils.patternToString(cells);
      assert.strictEqual(str.length, 9);
      const back = LockPatternUtils.stringToPattern(str);
      assert.strictEqual(back.length, 9);
      for (let i = 0; i < 9; i++) {
        assert.strictEqual(back[i].row, cells[i].row);
        assert.strictEqual(back[i].column, cells[i].column);
      }
    });

    it('should handle 2-cell pattern', () => {
      const cells = [PatternCell.of(0, 0), PatternCell.of(2, 2)];
      const str = LockPatternUtils.patternToString(cells);
      const back = LockPatternUtils.stringToPattern(str);
      assert.strictEqual(back.length, 2);
    });
  });

  describe('patternToString encoding', () => {
    it('should encode cell (0,0) as char code 0', () => {
      const str = LockPatternUtils.patternToString([PatternCell.of(0, 0)]);
      assert.strictEqual(str.charCodeAt(0), 0);
    });

    it('should encode cell (2,2) as char code 8', () => {
      const str = LockPatternUtils.patternToString([PatternCell.of(2, 2)]);
      assert.strictEqual(str.charCodeAt(0), 8);
    });

    it('should encode cell (1,0) as char code 3', () => {
      const str = LockPatternUtils.patternToString([PatternCell.of(1, 0)]);
      assert.strictEqual(str.charCodeAt(0), 3);
    });
  });

  describe('isPatternValid', () => {
    it('should accept a valid 2-cell pattern', () => {
      const str = LockPatternUtils.patternToString([
        PatternCell.of(0, 0),
        PatternCell.of(1, 1),
      ]);
      assert.strictEqual(LockPatternUtils.isPatternValid(str), true);
    });

    it('should accept a valid 9-cell pattern', () => {
      const cells: PatternCell[] = [];
      for (let r = 0; r < 3; r++) {
        for (let c = 0; c < 3; c++) {
          cells.push(PatternCell.of(r, c));
        }
      }
      const str = LockPatternUtils.patternToString(cells);
      assert.strictEqual(LockPatternUtils.isPatternValid(str), true);
    });

    it('should reject empty string', () => {
      assert.strictEqual(LockPatternUtils.isPatternValid(''), false);
    });

    it('should reject single-cell string', () => {
      const str = LockPatternUtils.patternToString([PatternCell.of(0, 0)]);
      assert.strictEqual(LockPatternUtils.isPatternValid(str), false);
    });

    it('should reject string with out-of-range char codes', () => {
      // char code 9 is out of range for a 3x3 grid
      const bad = String.fromCharCode(0, 9);
      assert.strictEqual(LockPatternUtils.isPatternValid(bad), false);
    });

    it('should reject string longer than 9', () => {
      const bad = String.fromCharCode(0, 1, 2, 3, 4, 5, 6, 7, 8, 0);
      assert.strictEqual(LockPatternUtils.isPatternValid(bad), false);
    });
  });
});
