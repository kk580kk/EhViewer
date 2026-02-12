/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { ContentState } from '../common/ContentState.ets';
import type { ContentStateType } from '../common/ContentState.ets';

export { ContentState, resolveContentState } from '../common/ContentState.ets';
export type { ContentStateType } from '../common/ContentState.ets';

/**
 * ContentLayout — a container that switches between loading, error, empty,
 * and content states.
 *
 * Equivalent to the Android ContentLayout / ViewTransition pattern.
 * Wraps child content and overlays loading/error/empty views as needed.
 *
 * Usage:
 *   ContentLayout({
 *     state: this.contentState,
 *     errorMessage: this.errorMsg,
 *     emptyIcon: '\u2606',
 *     emptyTitle: 'Nothing here',
 *     onRetry: () => { this.reload(); },
 *   }) {
 *     // child content builder
 *     List() { ... }
 *   }
 */
@Component
export struct ContentLayout {
  @Prop state: ContentStateType = ContentState.LOADING;
  @Prop errorMessage: string = 'Something went wrong';
  @Prop emptyIcon: string = '';
  @Prop emptyTitle: string = 'Nothing here';
  @Prop emptySubtitle: string = '';
  onRetry: () => void = () => {};

  /** Builder slot for the actual content (shown when state === CONTENT). */
  @BuilderParam contentBuilder: () => void;

  build() {
    Stack() {
      // Content layer — always present but only visible in CONTENT state
      if (this.state === ContentState.CONTENT) {
        Column() {
          if (this.contentBuilder) {
            this.contentBuilder()
          }
        }
        .width('100%')
        .height('100%')
      }

      // Loading state
      if (this.state === ContentState.LOADING) {
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color('#4169E1')

          Text('Loading...')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 12 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#F5F5F5')
      }

      // Error state
      if (this.state === ContentState.ERROR) {
        Column() {
          Text('\u26A0')
            .fontSize(48)
            .fontColor('#F44336')
            .margin({ bottom: 12 })

          Text(this.errorMessage)
            .fontSize(14)
            .fontColor('#666666')
            .textAlign(TextAlign.Center)
            .margin({ bottom: 16 })
            .padding({ left: 32, right: 32 })

          Button('Retry')
            .type(ButtonType.Normal)
            .height(40)
            .fontSize(14)
            .backgroundColor('#4169E1')
            .fontColor('#FFFFFF')
            .borderRadius(8)
            .padding({ left: 24, right: 24 })
            .onClick(() => this.onRetry())
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#F5F5F5')
      }

      // Empty state
      if (this.state === ContentState.EMPTY) {
        Column() {
          if (this.emptyIcon.length > 0) {
            Text(this.emptyIcon)
              .fontSize(64)
              .fontColor('#CCCCCC')
              .margin({ bottom: 16 })
          }

          Text(this.emptyTitle)
            .fontSize(16)
            .fontColor('#999999')
            .margin({ bottom: 4 })
            .textAlign(TextAlign.Center)

          if (this.emptySubtitle.length > 0) {
            Text(this.emptySubtitle)
              .fontSize(13)
              .fontColor('#BBBBBB')
              .textAlign(TextAlign.Center)
              .padding({ left: 32, right: 32 })
          }
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#F5F5F5')
      }
    }
    .width('100%')
    .height('100%')
  }
}
