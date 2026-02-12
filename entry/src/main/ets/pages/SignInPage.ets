/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { PageRouter, Routes } from '../router/PageRouter.ets';
import { SignInController } from '../client/SignInController.ets';
import type { SignInOutcome } from '../client/SignInController.ets';

/**
 * Sign-in page — username/password login.
 *
 * Equivalent to Android SignInScene:
 *  - Username + Password form
 *  - Sign In button → calls SignInController.signIn()
 *  - "Sign in via WebView" link → WebViewSignInPage
 *  - "Sign in via Cookies" link → CookieSignInPage
 *  - "Skip signing in" link → go to main page
 */
@Entry
@Component
struct SignInPage {
  @State username: string = '';
  @State password: string = '';
  @State usernameError: string = '';
  @State passwordError: string = '';
  @State isLoading: boolean = false;
  @State signInError: string = '';

  private validate(): boolean {
    let valid = true;

    if (this.username.trim().length === 0) {
      this.usernameError = 'Username cannot be empty';
      valid = false;
    } else {
      this.usernameError = '';
    }

    if (this.password.trim().length === 0) {
      this.passwordError = 'Password cannot be empty';
      valid = false;
    } else {
      this.passwordError = '';
    }

    return valid;
  }

  private onSignIn(): void {
    if (this.isLoading) return;
    if (!this.validate()) return;

    this.isLoading = true;
    this.signInError = '';

    SignInController.signIn(this.username.trim(), this.password.trim())
      .then((outcome: SignInOutcome) => {
        this.isLoading = false;
        if (outcome.success) {
          SignInController.completeSignIn();
          PageRouter.toMain();
        } else {
          this.signInError = outcome.error ?? 'Sign in failed';
        }
      })
      .catch((e: Error) => {
        this.isLoading = false;
        this.signInError = e.message || 'Unknown error';
      });
  }

  private onSkip(): void {
    SignInController.skipSignIn();
    PageRouter.toMain();
  }

  private onSignInViaWebView(): void {
    PageRouter.toWebViewSignIn();
  }

  private onSignInViaCookies(): void {
    PageRouter.toCookieSignIn();
  }

  build() {
    Column() {
      // Loading overlay
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color('#4169E1')
          Text('Signing in...')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 12 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#F5F5F5')
      } else {
        Scroll() {
          Column() {
            // App logo / title
            Text('EhViewer')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#4169E1')
              .margin({ top: 60, bottom: 8 })

            Text('Sign in to your account')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ bottom: 40 })

            // Error message
            if (this.signInError.length > 0) {
              Text(this.signInError)
                .fontSize(13)
                .fontColor('#FF3B30')
                .margin({ bottom: 16 })
                .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                .backgroundColor('#FFF0F0')
                .borderRadius(8)
                .width('100%')
            }

            // Username field
            Column() {
              TextInput({ placeholder: 'Username', text: this.username })
                .type(InputType.Normal)
                .onChange((value: string) => {
                  this.username = value;
                  if (this.usernameError.length > 0) this.usernameError = '';
                })
                .width('100%')
                .height(48)
                .borderRadius(8)
                .backgroundColor('#FFFFFF')
                .padding({ left: 12, right: 12 })

              if (this.usernameError.length > 0) {
                Text(this.usernameError)
                  .fontSize(12)
                  .fontColor('#FF3B30')
                  .margin({ top: 4, left: 4 })
              }
            }
            .width('100%')
            .margin({ bottom: 16 })

            // Password field
            Column() {
              TextInput({ placeholder: 'Password', text: this.password })
                .type(InputType.Password)
                .onChange((value: string) => {
                  this.password = value;
                  if (this.passwordError.length > 0) this.passwordError = '';
                })
                .width('100%')
                .height(48)
                .borderRadius(8)
                .backgroundColor('#FFFFFF')
                .padding({ left: 12, right: 12 })

              if (this.passwordError.length > 0) {
                Text(this.passwordError)
                  .fontSize(12)
                  .fontColor('#FF3B30')
                  .margin({ top: 4, left: 4 })
              }
            }
            .width('100%')
            .margin({ bottom: 24 })

            // Sign In button
            Button('Sign In')
              .type(ButtonType.Capsule)
              .width('100%')
              .height(48)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .backgroundColor('#4169E1')
              .onClick(() => this.onSignIn())

            // Alternative sign-in links
            Column() {
              Text('Sign in via WebView')
                .fontSize(14)
                .fontColor('#4169E1')
                .decoration({ type: TextDecorationType.Underline })
                .onClick(() => this.onSignInViaWebView())
                .margin({ bottom: 12 })

              Text('Sign in via Cookies')
                .fontSize(14)
                .fontColor('#4169E1')
                .decoration({ type: TextDecorationType.Underline })
                .onClick(() => this.onSignInViaCookies())
                .margin({ bottom: 12 })

              Text('Skip signing in')
                .fontSize(14)
                .fontColor('#999999')
                .decoration({ type: TextDecorationType.Underline })
                .onClick(() => this.onSkip())
            }
            .margin({ top: 24 })
            .alignItems(HorizontalAlign.Center)
          }
          .width('100%')
          .padding({ left: 32, right: 32 })
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
