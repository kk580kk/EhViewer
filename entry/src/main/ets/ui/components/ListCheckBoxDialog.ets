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
 * ListCheckBoxDialog — modal dialog with a list of checkbox items.
 *
 * Equivalent to Android's ListCheckBoxDialogBuilder. Used for
 * multi-selection scenarios like excluded languages, category filters, etc.
 *
 * Usage:
 *   ListCheckBoxDialog({
 *     show: this.showFilter,
 *     title: 'Select Categories',
 *     items: ['Doujinshi', 'Manga', 'Artist CG'],
 *     checkedItems: this.selectedCategories,
 *     onConfirm: (checked) => { ... },
 *     onCancel: () => { this.showFilter = false; },
 *   })
 */

import { ListCheckBoxItem, extractCheckedState } from '../common/DialogConfigs.ets';

export { ListCheckBoxItem, buildListCheckBoxItems, extractCheckedState } from '../common/DialogConfigs.ets';

@Component
export struct ListCheckBoxDialog {
  @Prop show: boolean = false;
  @Prop title: string = '';
  @State items: ListCheckBoxItem[] = [];
  onConfirm: (checked: boolean[]) => void = () => {};
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

          // Scrollable checkbox list
          Scroll() {
            Column() {
              ForEach(this.items, (item: ListCheckBoxItem, index: number) => {
                Row() {
                  Toggle({ type: ToggleType.Checkbox, isOn: item.checked })
                    .width(20)
                    .height(20)
                    .selectedColor('#4169E1')
                    .onChange((isOn: boolean) => {
                      const updated = [...this.items];
                      updated[index] = new ListCheckBoxItem(item.label, isOn);
                      this.items = updated;
                    })

                  Text(item.label)
                    .fontSize(14)
                    .fontColor('#333333')
                    .margin({ left: 10 })
                    .layoutWeight(1)
                }
                .width('100%')
                .padding({ top: 8, bottom: 8 })
              }, (item: ListCheckBoxItem, index: number) => `${index}_${item.label}`)
            }
          }
          .constraintSize({ maxHeight: 300 })
          .margin({ bottom: 16 })

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
              .onClick(() => this.onConfirm(extractCheckedState(this.items)))
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
