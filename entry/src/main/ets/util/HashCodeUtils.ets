/*
 * Copyright 2017 Hippo Seven
 * Ported to HarmonyOS ArkTS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

/**
 * Computes a hash code for a single value.
 *
 * - `null` / `undefined` → 0
 * - `number` → integer bits (safe-integer range) via bit-mixing
 * - `boolean` → 1 / 0
 * - `string` → Java-compatible `String.hashCode()` (s[0]*31^(n-1) + … + s[n-1])
 * - anything else → 0
 */
function hashValue(o: unknown): number {
  if (o === null || o === undefined) {
    return 0;
  }
  switch (typeof o) {
    case 'string':
      return hashString(o as string);
    case 'number':
      return hashNumber(o as number);
    case 'boolean':
      return (o as boolean) ? 1 : 0;
    default:
      return 0;
  }
}

/**
 * Java-compatible string hash: s[0]*31^(n-1) + s[1]*31^(n-2) + … + s[n-1].
 * Uses 32-bit integer arithmetic via bitwise OR to match Java behaviour.
 */
function hashString(s: string): number {
  let h = 0;
  for (let i = 0; i < s.length; i++) {
    h = (Math.imul(31, h) + s.charCodeAt(i)) | 0;
  }
  return h;
}

/**
 * Hash a number by converting to a 32-bit integer.
 * For integers that fit in 32 bits, this is equivalent to `(int) value` in Java.
 * For floats / large integers, we mix hi and lo 32-bit words of the IEEE-754 representation.
 */
function hashNumber(n: number): number {
  if (Number.isInteger(n) && n >= -2147483648 && n <= 2147483647) {
    return n | 0;
  }
  // Mix bits for floats / large numbers
  const buf = new ArrayBuffer(8);
  new Float64Array(buf)[0] = n;
  const view = new Uint32Array(buf);
  return (view[0] ^ view[1]) | 0;
}

/**
 * Utility for combining multiple values into a single hash code, mirroring
 * the Java `HashCodeUtils.hashCode(Object... args)` pattern.
 *
 * Formula: args[0].hash*31^(n-1) + args[1].hash*31^(n-2) + … + args[n-1].hash
 *
 * Usage:
 * ```
 * const h = HashCodeUtils.hashCode('hello', 42, true);
 * ```
 */
export class HashCodeUtils {
  private static readonly X: number = 31;

  /**
   * Compute a combined hash for the given values.
   * Returns 0 if no arguments are provided.
   */
  static hashCode(...args: unknown[]): number {
    let hash = 0;
    for (const o of args) {
      hash = (Math.imul(HashCodeUtils.X, hash) + hashValue(o)) | 0;
    }
    return hash;
  }

  /**
   * Compute the hash code of a single string.
   * Equivalent to Java's `String.hashCode()`.
   */
  static stringHashCode(s: string): number {
    return hashString(s);
  }
}
