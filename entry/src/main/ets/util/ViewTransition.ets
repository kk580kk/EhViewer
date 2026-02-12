/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

/**
 * TransitionType — defines the kind of transition between views.
 */
export const TransitionType = {
  FADE: 'fade',
  SLIDE_LEFT: 'slide_left',
  SLIDE_RIGHT: 'slide_right',
  SLIDE_UP: 'slide_up',
  SLIDE_DOWN: 'slide_down',
} as const;

export type TransitionTypeValue = (typeof TransitionType)[keyof typeof TransitionType];

/**
 * TransitionConfig — configuration for a view transition.
 * Pure data class — testable without UI framework.
 */
export class TransitionConfig {
  type: TransitionTypeValue;
  duration: number;
  curve: string;

  constructor(
    type: TransitionTypeValue = TransitionType.FADE,
    duration: number = 300,
    curve: string = 'ease-in-out',
  ) {
    this.type = type;
    this.duration = duration;
    this.curve = curve;
  }

  /** Whether this is a slide-based transition. */
  isSlide(): boolean {
    return this.type !== TransitionType.FADE;
  }
}

/**
 * ViewTransition — utility for managing view state transitions.
 *
 * Equivalent to Android's ViewTransition / TransitionHelper.
 * Provides transition configuration builders for ArkTS animations.
 *
 * In HarmonyOS ArkTS, actual animations are applied via the .transition()
 * modifier on components. This class provides the configuration data.
 */
export class ViewTransition {
  /** Create a fade transition config. */
  static fade(duration: number = 300): TransitionConfig {
    return new TransitionConfig(TransitionType.FADE, duration);
  }

  /** Create a slide-left transition config (entering from right). */
  static slideLeft(duration: number = 300): TransitionConfig {
    return new TransitionConfig(TransitionType.SLIDE_LEFT, duration);
  }

  /** Create a slide-right transition config (entering from left). */
  static slideRight(duration: number = 300): TransitionConfig {
    return new TransitionConfig(TransitionType.SLIDE_RIGHT, duration);
  }

  /** Create a slide-up transition config. */
  static slideUp(duration: number = 300): TransitionConfig {
    return new TransitionConfig(TransitionType.SLIDE_UP, duration);
  }

  /** Create a slide-down transition config. */
  static slideDown(duration: number = 300): TransitionConfig {
    return new TransitionConfig(TransitionType.SLIDE_DOWN, duration);
  }

  /**
   * Get the opposite transition for a back navigation.
   * e.g. SLIDE_LEFT -> SLIDE_RIGHT, FADE -> FADE
   */
  static reverse(config: TransitionConfig): TransitionConfig {
    let reverseType: TransitionTypeValue;
    switch (config.type) {
      case TransitionType.SLIDE_LEFT:
        reverseType = TransitionType.SLIDE_RIGHT;
        break;
      case TransitionType.SLIDE_RIGHT:
        reverseType = TransitionType.SLIDE_LEFT;
        break;
      case TransitionType.SLIDE_UP:
        reverseType = TransitionType.SLIDE_DOWN;
        break;
      case TransitionType.SLIDE_DOWN:
        reverseType = TransitionType.SLIDE_UP;
        break;
      default:
        reverseType = TransitionType.FADE;
    }
    return new TransitionConfig(reverseType, config.duration, config.curve);
  }
}
