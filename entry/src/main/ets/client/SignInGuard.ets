/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { SignInController } from './SignInController.ets';
import { PageRouter } from '../router/PageRouter.ets';
import type { NavResult } from '../router/PageRouter.ets';

/**
 * Result of a sign-in requirement check.
 */
export interface SignInCheckResult {
  /** Whether the user is signed in. */
  signedIn: boolean;
  /** Navigation result if redirecting to sign-in, null otherwise. */
  navigation: NavResult | null;
}

/**
 * Checks whether the user is signed in.
 * If not, returns a navigation result to the sign-in page.
 *
 * This is the core logic behind the "sign in required" prompt,
 * separated from UI for testability.
 */
export function checkSignedIn(): SignInCheckResult {
  if (SignInController.hasSignedIn()) {
    return { signedIn: true, navigation: null };
  }
  const nav = PageRouter.toSignIn();
  return { signedIn: false, navigation: nav };
}

/**
 * Perform an action that requires sign-in.
 * If signed in, executes the action immediately.
 * If not signed in, calls onNotSignedIn callback.
 *
 * @param action - The action to perform if signed in
 * @param onNotSignedIn - Called when user is not signed in (show dialog, etc.)
 * @returns true if action was executed, false if sign-in is needed
 */
export function requireSignIn(
  action: () => void,
  onNotSignedIn?: () => void,
): boolean {
  if (SignInController.hasSignedIn()) {
    action();
    return true;
  }
  if (onNotSignedIn) {
    onNotSignedIn();
  }
  return false;
}
