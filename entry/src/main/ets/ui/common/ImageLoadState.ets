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
 * ImageLoadState — tracks the loading lifecycle of an image.
 *
 * Pure logic — no UI framework dependencies.
 */
export const ImageLoadState = {
  IDLE: 0,
  LOADING: 1,
  SUCCESS: 2,
  ERROR: 3,
} as const;

export type ImageLoadStateType = (typeof ImageLoadState)[keyof typeof ImageLoadState];

/**
 * Resolves the display state for LoadImageView.
 * Pure function — testable without UI framework.
 */
export function resolveImageState(url: string, loaded: boolean, failed: boolean): ImageLoadStateType {
  if (url.length === 0) return ImageLoadState.IDLE;
  if (failed) return ImageLoadState.ERROR;
  if (loaded) return ImageLoadState.SUCCESS;
  return ImageLoadState.LOADING;
}
