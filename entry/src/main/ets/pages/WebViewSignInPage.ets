/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { EhUrl } from '../client/EhUrl.ets';
import { EhCookieStore } from '../client/EhCookieStore.ets';
import { SignInController } from '../client/SignInController.ets';
import type { SignInOutcome } from '../client/SignInController.ets';
import { PageRouter } from '../router/PageRouter.ets';

/**
 * WebView sign-in page.
 *
 * Equivalent to Android WebViewSignInScene:
 *  - Loads the E-Hentai forums login page in a Web component
 *  - Monitors cookies after each page load
 *  - When ipb_member_id and ipb_pass_hash cookies are detected, sign-in is complete
 *
 * Note: The HarmonyOS Web component requires @ohos.web.webview which is only
 * available in a device/emulator environment. This page provides the structural
 * implementation; the actual Web component will work at runtime.
 */
@Entry
@Component
struct WebViewSignInPage {
  @State isLoading: boolean = true;
  @State loadError: string = '';
  @State isProcessing: boolean = false;

  private onBack(): void {
    PageRouter.toSignIn();
  }

  /**
   * Called after each page load in the WebView.
   * Checks if the required sign-in cookies (ipb_member_id and ipb_pass_hash)
   * are present. If so, stores them and completes sign-in.
   *
   * @param cookieString - the raw cookie string from the WebView's cookie manager
   */
  onPageFinished(cookieString: string): void {
    if (this.isProcessing) return;

    const cookies = WebViewSignInPage.parseCookieString(cookieString);
    const hasId = cookies.has(EhCookieStore.KEY_IPD_MEMBER_ID);
    const hasHash = cookies.has(EhCookieStore.KEY_IPD_PASS_HASH);

    if (hasId && hasHash) {
      this.isProcessing = true;
      this.isLoading = true;

      SignInController.onWebViewSignInComplete()
        .then((outcome: SignInOutcome) => {
          this.isProcessing = false;
          this.isLoading = false;
          if (outcome.success) {
            SignInController.completeSignIn();
            PageRouter.toMain();
          } else {
            this.loadError = outcome.error ?? 'Sign in failed';
          }
        })
        .catch((e: Error) => {
          this.isProcessing = false;
          this.isLoading = false;
          this.loadError = e.message || 'Unknown error';
        });
    }
  }

  /**
   * Parse a semicolon-separated cookie string into a name→value map.
   * This is a pure utility method for testability.
   */
  static parseCookieString(cookieString: string): Map<string, string> {
    const result = new Map<string, string>();
    if (!cookieString) return result;

    const pieces = cookieString.split(';');
    for (const piece of pieces) {
      const trimmed = piece.trim();
      const eqIdx = trimmed.indexOf('=');
      if (eqIdx > 0) {
        const name = trimmed.substring(0, eqIdx).trim();
        const value = trimmed.substring(eqIdx + 1).trim();
        result.set(name, value);
      }
    }
    return result;
  }

  build() {
    Column() {
      // Top bar
      Row() {
        Text('<')
          .fontSize(20)
          .fontColor('#4169E1')
          .onClick(() => this.onBack())
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })

        Text('Sign in via WebView')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1a1a1a')
          .layoutWeight(1)
      }
      .width('100%')
      .height(56)
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#FFFFFF')

      // Loading / processing indicator
      if (this.isLoading || this.isProcessing) {
        LoadingProgress()
          .width(32)
          .height(32)
          .color('#4169E1')
          .margin({ top: 4 })
      }

      // Placeholder for Web component
      // In a real device environment this would be:
      //   Web({ src: EhUrl.URL_SIGN_IN, controller: webController })
      //     .onPageEnd((event) => {
      //       const cookieStr = CookieManager.getInstance().getCookie(EhUrl.HOST_E);
      //       this.onPageFinished(cookieStr);
      //     })
      Column() {
        if (this.loadError.length > 0) {
          Text(this.loadError)
            .fontSize(14)
            .fontColor('#FF3B30')
            .margin({ top: 20 })
        } else {
          Text('WebView login will load:')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 40 })

          Text(EhUrl.URL_SIGN_IN)
            .fontSize(13)
            .fontColor('#4169E1')
            .margin({ top: 8 })

          Text('The Web component requires a device/emulator runtime.')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 16 })
            .textAlign(TextAlign.Center)
        }
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)
      .padding({ left: 32, right: 32 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
