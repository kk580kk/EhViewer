@Entry
@Component
struct Index {
  @State message: string = 'EhViewer';

  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 8 })
        Text('HarmonyOS')
          .fontSize(14)
          .fontColor('#666666')
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
