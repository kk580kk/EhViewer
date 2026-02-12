/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { EhSignIn } from '../client/EhSignIn.ets';
import { SignInController } from '../client/SignInController.ets';
import type { SignInOutcome } from '../client/SignInController.ets';
import { PageRouter } from '../router/PageRouter.ets';

/**
 * Cookie sign-in page — manual cookie entry.
 *
 * Equivalent to Android CookieSignInScene:
 *  - ipb_member_id input (digits only)
 *  - ipb_pass_hash input (32-char lowercase hex)
 *  - igneous input (optional, for ExHentai access)
 *  - Validates format and warns on suspicious values
 */
@Entry
@Component
struct CookieSignInPage {
  @State ipbMemberId: string = '';
  @State ipbPassHash: string = '';
  @State igneous: string = '';
  @State memberIdError: string = '';
  @State passHashError: string = '';
  @State showWarning: boolean = false;
  @State isLoading: boolean = false;
  @State signInError: string = '';

  private validate(): boolean {
    let valid = true;
    const memberId = this.ipbMemberId.trim();
    const passHash = this.ipbPassHash.trim();

    if (memberId.length === 0) {
      this.memberIdError = 'ipb_member_id cannot be empty';
      valid = false;
    } else {
      this.memberIdError = '';
    }

    if (passHash.length === 0) {
      this.passHashError = 'ipb_pass_hash cannot be empty';
      valid = false;
    } else {
      this.passHashError = '';
    }

    return valid;
  }

  private onOk(): void {
    if (this.isLoading) return;
    if (!this.validate()) return;

    const memberId = this.ipbMemberId.trim();
    const passHash = this.ipbPassHash.trim();

    // Validate format; warn if suspicious
    if (!EhSignIn.isValidMemberId(memberId) || !EhSignIn.isValidPassHash(passHash)) {
      this.showWarning = true;
      return;
    }

    this.doEnter();
  }

  private doEnter(): void {
    this.isLoading = true;
    this.signInError = '';

    const memberId = this.ipbMemberId.trim();
    const passHash = this.ipbPassHash.trim();
    const igneous = this.igneous.trim();

    SignInController.signInWithCookie(memberId, passHash, igneous.length > 0 ? igneous : undefined)
      .then((outcome: SignInOutcome) => {
        this.isLoading = false;
        if (outcome.success) {
          SignInController.completeSignIn();
          PageRouter.toMain();
        } else {
          this.signInError = outcome.error ?? 'Cookie sign in failed';
        }
      })
      .catch((e: Error) => {
        this.isLoading = false;
        this.signInError = e.message || 'Unknown error';
      });
  }

  private onBack(): void {
    PageRouter.toSignIn();
  }

  build() {
    Column() {
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
          // Title
          Text('Cookie Sign In')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1a1a1a')
            .margin({ top: 60, bottom: 8 })

          Text('Enter your E-Hentai cookies manually')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ bottom: 16 })

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

          // ipb_member_id
          Column() {
            Text('ipb_member_id')
              .fontSize(13)
              .fontColor('#333333')
              .margin({ bottom: 4, left: 4 })

            TextInput({ placeholder: 'e.g. 1234567', text: this.ipbMemberId })
              .type(InputType.Number)
              .onChange((value: string) => {
                this.ipbMemberId = value;
                if (this.memberIdError.length > 0) this.memberIdError = '';
              })
              .width('100%')
              .height(48)
              .borderRadius(8)
              .backgroundColor('#FFFFFF')
              .padding({ left: 12, right: 12 })

            if (this.memberIdError.length > 0) {
              Text(this.memberIdError)
                .fontSize(12)
                .fontColor('#FF3B30')
                .margin({ top: 4, left: 4 })
            }
          }
          .width('100%')
          .margin({ bottom: 16 })

          // ipb_pass_hash
          Column() {
            Text('ipb_pass_hash')
              .fontSize(13)
              .fontColor('#333333')
              .margin({ bottom: 4, left: 4 })

            TextInput({ placeholder: '32-character hash', text: this.ipbPassHash })
              .type(InputType.Normal)
              .onChange((value: string) => {
                this.ipbPassHash = value;
                if (this.passHashError.length > 0) this.passHashError = '';
              })
              .width('100%')
              .height(48)
              .borderRadius(8)
              .backgroundColor('#FFFFFF')
              .padding({ left: 12, right: 12 })

            if (this.passHashError.length > 0) {
              Text(this.passHashError)
                .fontSize(12)
                .fontColor('#FF3B30')
                .margin({ top: 4, left: 4 })
            }
          }
          .width('100%')
          .margin({ bottom: 16 })

          // igneous (optional)
          Column() {
            Text('igneous (optional, for ExHentai)')
              .fontSize(13)
              .fontColor('#333333')
              .margin({ bottom: 4, left: 4 })

            TextInput({ placeholder: 'Leave empty if not needed', text: this.igneous })
              .type(InputType.Normal)
              .onChange((value: string) => {
                this.igneous = value;
              })
              .width('100%')
              .height(48)
              .borderRadius(8)
              .backgroundColor('#FFFFFF')
              .padding({ left: 12, right: 12 })
          }
          .width('100%')
          .margin({ bottom: 24 })

          // Warning dialog (inline)
          if (this.showWarning) {
            Column() {
              Text('Warning')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FF9800')
                .margin({ bottom: 8 })

              Text('The cookie values you entered may be incorrect. '
                + 'ipb_member_id should be all digits and '
                + 'ipb_pass_hash should be a 32-character lowercase hex string.')
                .fontSize(13)
                .fontColor('#333333')
                .margin({ bottom: 16 })

              Row() {
                Button('Go Back')
                  .type(ButtonType.Normal)
                  .height(40)
                  .fontSize(14)
                  .backgroundColor('#E0E0E0')
                  .fontColor('#333333')
                  .borderRadius(8)
                  .onClick(() => { this.showWarning = false; })
                  .layoutWeight(1)
                  .margin({ right: 8 })

                Button('Use Anyway')
                  .type(ButtonType.Normal)
                  .height(40)
                  .fontSize(14)
                  .backgroundColor('#FF9800')
                  .fontColor('#FFFFFF')
                  .borderRadius(8)
                  .onClick(() => {
                    this.showWarning = false;
                    this.doEnter();
                  })
                  .layoutWeight(1)
                  .margin({ left: 8 })
              }
              .width('100%')
            }
            .width('100%')
            .padding(16)
            .borderRadius(12)
            .backgroundColor('#FFF8E1')
            .margin({ bottom: 24 })
          }

          // OK button
          Button('OK')
            .type(ButtonType.Capsule)
            .width('100%')
            .height(48)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .backgroundColor('#4169E1')
            .onClick(() => this.onOk())

          // Back link
          Text('Back to Sign In')
            .fontSize(14)
            .fontColor('#4169E1')
            .decoration({ type: TextDecorationType.Underline })
            .margin({ top: 20 })
            .onClick(() => this.onBack())
        }
        .width('100%')
        .padding({ left: 32, right: 32 })
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
      } // end else
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
