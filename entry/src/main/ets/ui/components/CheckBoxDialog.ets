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
 * CheckBoxDialog — modal dialog with a message and a single checkbox.
 *
 * Equivalent to Android's CheckBoxDialogBuilder. Used for confirmations
 * like "Don't show again" or "Remember my choice".
 *
 * Usage:
 *   CheckBoxDialog({
 *     show: this.showDialog,
 *     title: 'Confirm',
 *     message: 'Are you sure?',
 *     checkBoxLabel: 'Don\'t ask again',
 *     checked: this.dontAskAgain,
 *     onConfirm: (checked) => { ... },
 *     onCancel: () => { this.showDialog = false; },
 *   })
 */

export { CheckBoxDialogConfig } from '../common/DialogConfigs.ets';

@Component
export struct CheckBoxDialog {
  @Prop show: boolean = false;
  @Prop title: string = '';
  @Prop message: string = '';
  @Prop checkBoxLabel: string = '';
  @State checked: boolean = false;
  onConfirm: (checked: boolean) => void = () => {};
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
              .margin({ bottom: 8 })
              .width('100%')
          }

          if (this.message.length > 0) {
            Text(this.message)
              .fontSize(14)
              .fontColor('#666666')
              .margin({ bottom: 16 })
              .width('100%')
          }

          // Checkbox row
          Row() {
            Toggle({ type: ToggleType.Checkbox, isOn: this.checked })
              .width(20)
              .height(20)
              .selectedColor('#4169E1')
              .onChange((isOn: boolean) => {
                this.checked = isOn;
              })

            Text(this.checkBoxLabel)
              .fontSize(14)
              .fontColor('#333333')
              .margin({ left: 8 })
          }
          .width('100%')
          .margin({ bottom: 20 })

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
              .onClick(() => this.onConfirm(this.checked))
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
