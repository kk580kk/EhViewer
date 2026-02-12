/*
 * Copyright (C) 2007 The Android Open Source Project
 * Ported to HarmonyOS ArkTS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 */

/**
 * Represents a single cell in the 3×3 lock pattern grid.
 * Row and column are each in range [0, 2].
 */
export class PatternCell {
  readonly row: number;
  readonly column: number;

  private constructor(row: number, column: number) {
    this.row = row;
    this.column = column;
  }

  /** Cache of all 9 cells to avoid repeated allocations. */
  private static readonly CELLS: PatternCell[][] = PatternCell.buildCells();

  private static buildCells(): PatternCell[][] {
    const cells: PatternCell[][] = [];
    for (let r = 0; r < 3; r++) {
      const row: PatternCell[] = [];
      for (let c = 0; c < 3; c++) {
        row.push(new PatternCell(r, c));
      }
      cells.push(row);
    }
    return cells;
  }

  static of(row: number, column: number): PatternCell {
    if (row < 0 || row > 2 || column < 0 || column > 2) {
      throw new Error(`Invalid cell (${row}, ${column})`);
    }
    return PatternCell.CELLS[row][column];
  }
}

/**
 * Utilities for the lock pattern and its settings.
 * Mirrors com.hippo.widget.lockpattern.LockPatternUtils.
 */
export class LockPatternUtils {
  /** Minimum number of cells for a valid pattern. */
  static readonly MIN_PATTERN_SIZE = 2;
  /** Maximum number of cells (3×3 grid). */
  static readonly MAX_PATTERN_SIZE = 9;

  /**
   * Deserialize a pattern string into a list of cells.
   * Each byte in the string encodes (row * 3 + column).
   */
  static stringToPattern(s: string): PatternCell[] {
    const result: PatternCell[] = [];
    for (let i = 0; i < s.length; i++) {
      const b = s.charCodeAt(i);
      result.push(PatternCell.of(Math.floor(b / 3), b % 3));
    }
    return result;
  }

  /**
   * Serialize a pattern into a string.
   * Each cell is encoded as a single char: row * 3 + column.
   */
  static patternToString(pattern: PatternCell[]): string {
    const codes: number[] = [];
    for (const cell of pattern) {
      codes.push(cell.row * 3 + cell.column);
    }
    return String.fromCharCode(...codes);
  }

  /**
   * Check whether a pattern string is structurally valid.
   * - Length between MIN_PATTERN_SIZE and MAX_PATTERN_SIZE.
   * - Each byte value in [0, 8].
   */
  static isPatternValid(pattern: string): boolean {
    if (pattern.length < LockPatternUtils.MIN_PATTERN_SIZE ||
        pattern.length > LockPatternUtils.MAX_PATTERN_SIZE) {
      return false;
    }
    for (let i = 0; i < pattern.length; i++) {
      const b = pattern.charCodeAt(i);
      if (b < 0 || b >= 9) {
        return false;
      }
    }
    return true;
  }
}
