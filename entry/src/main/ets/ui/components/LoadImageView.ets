/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { ImageLoadState } from '../common/ImageLoadState.ets';
import type { ImageLoadStateType } from '../common/ImageLoadState.ets';

export { ImageLoadState, resolveImageState } from '../common/ImageLoadState.ets';
export type { ImageLoadStateType } from '../common/ImageLoadState.ets';

/**
 * LoadImageView — image component with placeholder, loading, and error states.
 *
 * Equivalent to Android's LoadImageView. Wraps the ArkTS Image component
 * with automatic state management for network images.
 *
 * Features:
 *  - Placeholder while loading
 *  - Error fallback display
 *  - Corner radius support
 *  - Click callback
 *
 * Usage:
 *   LoadImageView({
 *     src: galleryInfo.thumb,
 *     width: 72,
 *     height: 96,
 *     radius: 6,
 *   })
 */
@Component
export struct LoadImageView {
  @Prop src: string = '';
  @Prop imageWidth: number = 72;
  @Prop imageHeight: number = 96;
  @Prop radius: number = 6;
  @Prop placeholderIcon: string = '\u{1F5BC}';
  onImageClick: () => void = () => {};

  @State loadState: ImageLoadStateType = ImageLoadState.IDLE;

  aboutToAppear(): void {
    this.loadState = this.src.length > 0 ? ImageLoadState.LOADING : ImageLoadState.IDLE;
  }

  build() {
    Column() {
      if (this.src.length > 0 && this.loadState !== ImageLoadState.ERROR) {
        Image(this.src)
          .width(this.imageWidth)
          .height(this.imageHeight)
          .borderRadius(this.radius)
          .objectFit(ImageFit.Cover)
          .onComplete(() => {
            this.loadState = ImageLoadState.SUCCESS;
          })
          .onError(() => {
            this.loadState = ImageLoadState.ERROR;
          })
          .onClick(() => this.onImageClick())
      } else {
        // Placeholder / error fallback
        Column() {
          Text(this.loadState === ImageLoadState.ERROR ? '\u26A0' : this.placeholderIcon)
            .fontSize(28)
            .fontColor('#CCCCCC')
        }
        .width(this.imageWidth)
        .height(this.imageHeight)
        .backgroundColor('#EEEEEE')
        .borderRadius(this.radius)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => this.onImageClick())
      }
    }
  }
}
