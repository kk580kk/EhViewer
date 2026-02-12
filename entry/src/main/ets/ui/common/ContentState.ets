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
 * ContentState — describes the current display state of a content area.
 * Used by ContentLayout and by business logic to drive UI.
 *
 * Pure logic — no UI framework dependencies.
 */
export const ContentState = {
  LOADING: 0,
  CONTENT: 1,
  ERROR: 2,
  EMPTY: 3,
} as const;

export type ContentStateType = (typeof ContentState)[keyof typeof ContentState];

/**
 * Determines the appropriate ContentState given loading/error/empty flags.
 * Pure function — testable without UI framework.
 */
export function resolveContentState(
  isLoading: boolean,
  hasError: boolean,
  isEmpty: boolean,
): ContentStateType {
  if (isLoading) return ContentState.LOADING;
  if (hasError) return ContentState.ERROR;
  if (isEmpty) return ContentState.EMPTY;
  return ContentState.CONTENT;
}
