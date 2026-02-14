/*
 * Copyright (C) 2014 The Android Open Source Project
 * Ported to HarmonyOS ArkTS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Platform differences:
 *   Android: Uses View.SYSTEM_UI_FLAG_* flags across multiple SDK levels
 *            (HC, ICS, JB, KK) with separate impl classes per version.
 *   HarmonyOS: Uses @ohos.window WindowStage API for full-screen /
 *              status-bar / navigation-bar control. A single implementation
 *              covers all HarmonyOS versions. The WindowManager abstraction
 *              allows dependency injection for testability.
 */

import { Logger } from './Logger.ets';

const log = Logger.tag('SystemUiHelper');

// ---- Visibility levels (matching Android constants) ----

/**
 * Visibility level for system UI control.
 */
export const SystemUiLevel = {
  /** Toggle low-profile mode (dim system bars). */
  LOW_PROFILE: 0,
  /** Hide the status bar. */
  HIDE_STATUS_BAR: 1,
  /** Hide both status bar and navigation bar (lean-back). */
  LEAN_BACK: 2,
  /** Immersive mode — hide bars, user can reveal via swipe. */
  IMMERSIVE: 3,
} as const;

export type SystemUiLevel = (typeof SystemUiLevel)[keyof typeof SystemUiLevel];

/**
 * Flags for fine-tuning system UI behaviour.
 */
export const SystemUiFlag = {
  /** No special flags. */
  NONE: 0,
  /**
   * Use sticky immersive mode — bars auto-hide after a brief reveal.
   * Only meaningful when level is IMMERSIVE.
   */
  IMMERSIVE_STICKY: 0x2,
} as const;

export type SystemUiFlag = number;

// ---- Abstraction over window management ----

/**
 * Abstraction over HarmonyOS window APIs for system bar control.
 *
 * Production: wraps @ohos.window.Window obtained via WindowStage.
 * Tests: supply a mock implementation.
 */
export interface WindowManager {
  /** Set whether the status bar is visible. */
  setStatusBarVisible(visible: boolean): void;
  /** Set whether the navigation bar is visible. */
  setNavigationBarVisible(visible: boolean): void;
  /** Enable or disable full-screen layout (content extends behind bars). */
  setFullScreen(fullScreen: boolean): void;
  /** Set the status bar to a translucent/dim appearance. */
  setStatusBarDimmed(dimmed: boolean): void;
}

/**
 * Callback for system UI visibility changes.
 */
export interface OnVisibilityChangeListener {
  onVisibilityChange(visible: boolean): void;
}

// ---- SystemUiHelper ----

/**
 * SystemUiHelper — controls system bar visibility in HarmonyOS.
 *
 * Equivalent to Android's SystemUiHelper with its level-based
 * hiding strategy (LOW_PROFILE, HIDE_STATUS_BAR, LEAN_BACK, IMMERSIVE).
 *
 * Usage:
 *   const helper = new SystemUiHelper(windowManager, SystemUiLevel.IMMERSIVE);
 *   helper.hide();
 *   helper.toggle();
 *   helper.delayHide(3000);
 */
export class SystemUiHelper {
  private windowManager: WindowManager;
  private level: SystemUiLevel;
  private flags: SystemUiFlag;
  private listener: OnVisibilityChangeListener | null;
  private showing: boolean = true;
  private hideTimer: ReturnType<typeof setTimeout> | null = null;

  constructor(
    windowManager: WindowManager,
    level: SystemUiLevel,
    flags: SystemUiFlag = SystemUiFlag.NONE,
    listener?: OnVisibilityChangeListener,
  ) {
    this.windowManager = windowManager;
    this.level = level;
    this.flags = flags;
    this.listener = listener ?? null;
  }

  /** Whether the system UI is currently showing. */
  isShowing(): boolean {
    return this.showing;
  }

  /**
   * Show the system UI. Cancels any pending delayed hide.
   */
  show(): void {
    this.cancelPendingHide();
    this.applyShow();
  }

  /**
   * Hide the system UI. Cancels any pending delayed hide.
   */
  hide(): void {
    this.cancelPendingHide();
    this.applyHide();
  }

  /**
   * Request that the system UI is hidden after a delay.
   * Cancels any previously queued delayed hide.
   */
  delayHide(delayMs: number): void {
    this.cancelPendingHide();
    this.hideTimer = setTimeout(() => {
      this.hideTimer = null;
      this.applyHide();
    }, delayMs);
  }

  /**
   * Toggle system UI visibility.
   */
  toggle(): void {
    if (this.showing) {
      this.hide();
    } else {
      this.show();
    }
  }

  /** Cancel any pending delayed hide. */
  cancelPendingHide(): void {
    if (this.hideTimer !== null) {
      clearTimeout(this.hideTimer);
      this.hideTimer = null;
    }
  }

  /** Current visibility level. */
  getLevel(): SystemUiLevel {
    return this.level;
  }

  // ---- Internal ----

  private applyShow(): void {
    try {
      switch (this.level) {
        case SystemUiLevel.LOW_PROFILE:
          this.windowManager.setStatusBarDimmed(false);
          break;
        case SystemUiLevel.HIDE_STATUS_BAR:
          this.windowManager.setStatusBarVisible(true);
          this.windowManager.setFullScreen(false);
          break;
        case SystemUiLevel.LEAN_BACK:
        case SystemUiLevel.IMMERSIVE:
          this.windowManager.setStatusBarVisible(true);
          this.windowManager.setNavigationBarVisible(true);
          this.windowManager.setFullScreen(false);
          break;
      }
    } catch (e) {
      log.e('Failed to show system UI', e instanceof Error ? e : new Error(String(e)));
    }
    this.setIsShowing(true);
  }

  private applyHide(): void {
    try {
      switch (this.level) {
        case SystemUiLevel.LOW_PROFILE:
          this.windowManager.setStatusBarDimmed(true);
          break;
        case SystemUiLevel.HIDE_STATUS_BAR:
          this.windowManager.setStatusBarVisible(false);
          this.windowManager.setFullScreen(true);
          break;
        case SystemUiLevel.LEAN_BACK:
        case SystemUiLevel.IMMERSIVE:
          this.windowManager.setStatusBarVisible(false);
          this.windowManager.setNavigationBarVisible(false);
          this.windowManager.setFullScreen(true);
          break;
      }
    } catch (e) {
      log.e('Failed to hide system UI', e instanceof Error ? e : new Error(String(e)));
    }
    this.setIsShowing(false);
  }

  private setIsShowing(showing: boolean): void {
    this.showing = showing;
    if (this.listener !== null) {
      this.listener.onVisibilityChange(showing);
    }
  }
}
