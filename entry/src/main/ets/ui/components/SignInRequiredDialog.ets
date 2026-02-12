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
 * SignInRequiredDialog — a reusable overlay component that prompts
 * the user to sign in when they try to use a feature that requires
 * authentication.
 *
 * Equivalent to Android's Snackbar/Toast "Please sign in first" prompt,
 * but as a modal dialog with "Sign In" and "Cancel" options.
 *
 * For the non-UI logic (checkSignedIn / requireSignIn), see SignInGuard.ets.
 *
 * Usage:
 *   SignInRequiredDialog({
 *     show: this.showSignInDialog,
 *     onSignIn: () => { PageRouter.toSignIn(); },
 *     onCancel: () => { this.showSignInDialog = false; },
 *   })
 */
@Component
export struct SignInRequiredDialog {
  @Prop show: boolean = false;
  onSignIn: () => void = () => {};
  onCancel: () => void = () => {};

  build() {
    if (this.show) {
      Stack() {
        // Dimmed backdrop
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.4)')
          .onClick(() => this.onCancel())

        // Dialog card
        Column() {
          // Title
          Text('Sign in required')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1a1a1a')
            .margin({ bottom: 8 })

          // Message
          Text('Please sign in to use this feature.')
            .fontSize(14)
            .fontColor('#666666')
            .textAlign(TextAlign.Center)
            .margin({ bottom: 24 })

          // Buttons
          Row() {
            Button('Cancel')
              .type(ButtonType.Normal)
              .height(40)
              .fontSize(14)
              .backgroundColor('#E0E0E0')
              .fontColor('#333333')
              .borderRadius(8)
              .onClick(() => this.onCancel())
              .layoutWeight(1)
              .margin({ right: 8 })

            Button('Sign In')
              .type(ButtonType.Normal)
              .height(40)
              .fontSize(14)
              .backgroundColor('#4169E1')
              .fontColor('#FFFFFF')
              .borderRadius(8)
              .onClick(() => this.onSignIn())
              .layoutWeight(1)
              .margin({ left: 8 })
          }
          .width('100%')
        }
        .width('80%')
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
