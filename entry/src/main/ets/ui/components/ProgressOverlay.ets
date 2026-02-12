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
 * ProgressOverlay — full-screen loading overlay with optional cancel.
 *
 * Equivalent to Android's ProgressDialog. Displays a spinner and
 * optional message text over a dimmed backdrop.
 *
 * Usage:
 *   ProgressOverlay({
 *     show: this.loading,
 *     message: 'Loading...',
 *     cancellable: true,
 *     onCancel: () => { this.loading = false; },
 *   })
 */
@Component
export struct ProgressOverlay {
  @Prop show: boolean = false;
  @Prop message: string = 'Loading...';
  @Prop cancellable: boolean = false;
  onCancel: () => void = () => {};

  build() {
    if (this.show) {
      Stack() {
        // Dimmed backdrop
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.4)')
          .onClick(() => {
            if (this.cancellable) {
              this.onCancel();
            }
          })

        // Spinner card
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color('#4169E1')

          if (this.message.length > 0) {
            Text(this.message)
              .fontSize(14)
              .fontColor('#666666')
              .margin({ top: 12 })
              .textAlign(TextAlign.Center)
          }

          if (this.cancellable) {
            Button('Cancel')
              .type(ButtonType.Normal)
              .height(36)
              .fontSize(13)
              .backgroundColor('#E0E0E0')
              .fontColor('#333333')
              .borderRadius(8)
              .margin({ top: 16 })
              .onClick(() => this.onCancel())
          }
        }
        .padding(24)
        .borderRadius(16)
        .backgroundColor('#FFFFFF')
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
    }
  }
}
