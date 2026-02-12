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
 * EditTextDialog — modal dialog with a text input field.
 *
 * Equivalent to Android's EditTextDialogBuilder. Used for user input
 * like renaming, adding labels, entering search terms, etc.
 *
 * Usage:
 *   EditTextDialog({
 *     show: this.showInput,
 *     title: 'Add Label',
 *     hint: 'Enter label name',
 *     initialText: '',
 *     onConfirm: (text) => { ... },
 *     onCancel: () => { this.showInput = false; },
 *   })
 */

export { EditTextDialogConfig } from '../common/DialogConfigs.ets';

@Component
export struct EditTextDialog {
  @Prop show: boolean = false;
  @Prop title: string = '';
  @Prop hint: string = '';
  @State inputText: string = '';
  onConfirm: (text: string) => void = () => {};
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
          if (this.title.length > 0) {
            Text(this.title)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1a1a1a')
              .margin({ bottom: 12 })
              .width('100%')
          }

          TextInput({ placeholder: this.hint, text: this.inputText })
            .width('100%')
            .height(44)
            .fontSize(15)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .padding({ left: 12, right: 12 })
            .margin({ bottom: 20 })
            .onChange((value: string) => {
              this.inputText = value;
            })

          // Action buttons
          Row() {
            Button('Cancel')
              .type(ButtonType.Normal)
              .height(40)
              .fontSize(14)
              .backgroundColor('#E0E0E0')
              .fontColor('#333333')
              .borderRadius(8)
              .layoutWeight(1)
              .margin({ right: 8 })
              .onClick(() => this.onCancel())

            Button('OK')
              .type(ButtonType.Normal)
              .height(40)
              .fontSize(14)
              .backgroundColor('#4169E1')
              .fontColor('#FFFFFF')
              .borderRadius(8)
              .layoutWeight(1)
              .margin({ left: 8 })
              .onClick(() => this.onConfirm(this.inputText))
          }
          .width('100%')
        }
        .width('80%')
        .padding(24)
        .borderRadius(16)
        .backgroundColor('#FFFFFF')
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height('100%')
    }
  }
}
