/*
 * Copyright 2019 Hippo Seven
 * Ported to HarmonyOS ArkTS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

/**
 * A mutable holder for a boolean value.
 *
 * Useful when a boolean needs to be modified inside a closure or callback
 * where reassigning a captured local variable is not possible.
 *
 * Mirrors Java's `com.hippo.util.MutableBoolean`.
 */
export class MutableBoolean {
  value: boolean;

  constructor(value: boolean = false) {
    this.value = value;
  }

  toString(): string {
    return String(this.value);
  }
}

/**
 * A mutable holder for a numeric value.
 *
 * Covers the use-cases of Java's `MutableInt`, `MutableLong`,
 * `MutableFloat`, and `MutableDouble` since ArkTS uses a single
 * `number` type for all numeric primitives.
 */
export class MutableNumber {
  value: number;

  constructor(value: number = 0) {
    this.value = value;
  }

  /** Increment by 1 and return the new value. */
  increment(): number {
    return ++this.value;
  }

  /** Decrement by 1 and return the new value. */
  decrement(): number {
    return --this.value;
  }

  /** Add `delta` and return the new value. */
  add(delta: number): number {
    this.value += delta;
    return this.value;
  }

  toString(): string {
    return String(this.value);
  }
}

/**
 * A generic mutable holder for any value.
 *
 * Useful for capturing and mutating a reference inside closures
 * where direct reassignment is not possible.
 */
export class MutableObject<T> {
  value: T;

  constructor(value: T) {
    this.value = value;
  }

  toString(): string {
    return String(this.value);
  }
}
