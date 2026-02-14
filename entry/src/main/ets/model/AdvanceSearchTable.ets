/*
 * Copyright 2015 Hippo Seven
 * Ported to HarmonyOS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

/**
 * Advance search option bitmask constants.
 * Ported from Android AdvanceSearchTable widget — only the flag values
 * are needed on the model layer.
 */
export class AdvanceSearchTable {
  static readonly SNAME: number = 0x1;
  static readonly STAGS: number = 0x2;
  static readonly SDESC: number = 0x4;
  static readonly STORR: number = 0x8;
  static readonly STO: number = 0x10;
  static readonly SDT1: number = 0x20;
  static readonly SDT2: number = 0x40;
  static readonly SH: number = 0x80;
  static readonly SFL: number = 0x100;
  static readonly SFU: number = 0x200;
  static readonly SFT: number = 0x400;
}
