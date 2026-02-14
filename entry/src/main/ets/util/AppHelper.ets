/*
 * Copyright 2015 Hippo Seven
 * Ported to HarmonyOS ArkTS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { Logger } from './Logger.ets';

const log = Logger.tag('AppHelper');

// ---- Abstractions for testability ----

/**
 * Abstraction over HarmonyOS Want-based intent launching.
 *
 * Production: wraps UIAbilityContext.startAbility().
 * Tests: supply a mock that records calls.
 */
export interface WantLauncher {
  /**
   * Launch a Want (intent). Returns true on success, false on failure.
   * @param want - A Want-like object with action, uri, type, parameters etc.
   */
  startAbility(want: WantDescriptor): boolean;
}

/**
 * Minimal Want descriptor that maps to @ohos.app.ability.Want fields.
 */
export interface WantDescriptor {
  action?: string;
  uri?: string;
  type?: string;
  parameters?: Record<string, string>;
}

/**
 * Abstraction for showing a toast/prompt to the user.
 */
export interface ToastPresenter {
  showShort(message: string): void;
}

/**
 * Abstraction over input-method (soft keyboard) operations.
 *
 * Production: wraps @ohos.inputMethod.InputMethodController.
 * Tests: supply a mock.
 */
export interface InputMethodController {
  showSoftKeyboard(): boolean;
  hideSoftKeyboard(): boolean;
}

// ---- Harmony Want action constants ----

/** HarmonyOS action for sending data (equivalent to ACTION_SENDTO). */
export const ACTION_SEND_TO = 'ohos.want.action.sendToData';
/** HarmonyOS action for sharing data (equivalent to ACTION_SEND). */
export const ACTION_SHARE = 'ohos.want.action.select';

// ---- AppHelper ----

/**
 * AppHelper — utility for common app-level operations.
 *
 * Equivalent to the Android AppHelper class.
 * Provides:
 *  - sendEmail: launch the email client
 *  - share: share text via system share sheet
 *  - showSoftInput / hideSoftInput: keyboard management
 *
 * All system interactions go through injected interfaces for testability.
 */
export class AppHelper {
  private launcher: WantLauncher;
  private toast: ToastPresenter;
  private ime: InputMethodController;

  constructor(launcher: WantLauncher, toast: ToastPresenter, ime: InputMethodController) {
    this.launcher = launcher;
    this.toast = toast;
    this.ime = ime;
  }

  /**
   * Launch the system email client.
   *
   * @param address - recipient email address
   * @param subject - optional email subject
   * @param text - optional email body
   * @returns true if the intent was launched successfully
   */
  sendEmail(address: string, subject?: string, text?: string): boolean {
    const parameters: Record<string, string> = {};
    if (subject !== undefined) {
      parameters['email_subject'] = subject;
    }
    if (text !== undefined) {
      parameters['email_body'] = text;
    }

    const want: WantDescriptor = {
      action: ACTION_SEND_TO,
      uri: `mailto:${address}`,
      parameters: Object.keys(parameters).length > 0 ? parameters : undefined,
    };

    try {
      const result = this.launcher.startAbility(want);
      if (!result) {
        this.toast.showShort('Cannot find email application');
      }
      return result;
    } catch (e) {
      log.e('Failed to send email', e instanceof Error ? e : new Error(String(e)));
      this.toast.showShort('Cannot find email application');
      return false;
    }
  }

  /**
   * Share text via the system share sheet.
   *
   * @param text - the text content to share
   * @returns true if the share sheet was launched successfully
   */
  share(text: string): boolean {
    const want: WantDescriptor = {
      action: ACTION_SHARE,
      type: 'text/plain',
      parameters: {
        'shareText': text,
      },
    };

    try {
      const result = this.launcher.startAbility(want);
      if (!result) {
        this.toast.showShort('Cannot find sharing application');
      }
      return result;
    } catch (e) {
      log.e('Failed to share', e instanceof Error ? e : new Error(String(e)));
      this.toast.showShort('Cannot find sharing application');
      return false;
    }
  }

  /**
   * Show the soft keyboard.
   *
   * @returns true if the keyboard was shown successfully
   */
  showSoftInput(): boolean {
    try {
      return this.ime.showSoftKeyboard();
    } catch (e) {
      log.e('Failed to show soft input', e instanceof Error ? e : new Error(String(e)));
      return false;
    }
  }

  /**
   * Hide the soft keyboard.
   *
   * @returns true if the keyboard was hidden successfully
   */
  hideSoftInput(): boolean {
    try {
      return this.ime.hideSoftKeyboard();
    } catch (e) {
      log.e('Failed to hide soft input', e instanceof Error ? e : new Error(String(e)));
      return false;
    }
  }
}
