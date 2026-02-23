# DEPRECATED

[![Telegram](https://img.shields.io/badge/chat-Telegram-blue.svg)](https://t.me/ehviewer)

# EhViewer

![Icon](art/launcher_icon-web.png)

E-Hentai 应用，**当前为 HarmonyOS / OpenHarmony 版本**。

An E-Hentai Application for **HarmonyOS** (OpenHarmony).


# Screenshot

![screenshot-01](art/screenshot-01.png)


# Build（产出安装包 HAP）

本项目为 **HarmonyOS 工程**，主构建产物为可安装的 **HAP 包**。

编译环境说明（含 DevEco Studio 安装路径等）见 [docs/编译环境说明.md](docs/编译环境说明.md)。

**1. 配置 SDK 路径**

在项目根目录创建或编辑 `local.properties`（若不存在），设置 OpenHarmony / HarmonyOS SDK 目录：

```properties
hwsdk.dir=/path/to/your/OpenHarmony/Sdk
```

请将路径改为本机实际 SDK 安装位置（如 DevEco Studio 的 Sdk 目录）。

**2. 构建 HAP 安装包**

需先安装 **DevEco Studio**（ohpm 随其提供）：<https://developer.harmonyos.com/cn/develop/deveco-studio>

```bash
# 在 DevEco Studio 自带的终端或已配置 ohpm 的终端中执行：
# 安装依赖（首次或依赖变更时）
npm install
ohpm install

# 构建 release HAP（默认）
npm run build

# 构建 debug HAP
npm run build:debug

# 清理
npm run clean
```

若命令行构建失败，请使用 **DevEco Studio** 打开项目根目录，在 `File > Settings > SDK` 中配置 SDK 路径后，在 IDE 中直接构建/运行。

**3. HAP 输出与安装**

- **输出路径**：`entry/build/default/outputs/default/` 下生成 `entry-default-unsigned.hap`（或 signed 版本）。
- **安装方式**：
  - 在 DevEco Studio 中连接设备/模拟器，点击 Run 安装并运行；
  - 或使用命令行：`hdc install entry/build/default/outputs/default/entry-default-unsigned.hap`（需设备已连接并开启调试）。

**4. Release 签名（可选）**

如需可分发的 release 安装包，请在 `build-profile.json5` 的 `app.signingConfigs` 中配置签名，或在 DevEco Studio 中配置 Signing。未配置时仅生成 unsigned HAP，可用于 debug 安装。


# Build（Android 源码，仅作参考）

`app/`、`daogenerator/` 下的 Android 源码保留作参考，**不参与主构建**。若需本地构建 Android APK，可恢复 `settings.gradle` 中的 `include ':app', ':daogenerator'` 后使用 Gradle：

    ./gradlew app:assembleDebug

生成的 apk 在 `app/build/outputs/apk` 目录下。


# Download

[下载](https://github.com/seven332/EhViewer/releases)

[Download](https://github.com/seven332/EhViewer/releases)


# Thanks

本项目受到了诸多开源项目的帮助

Here is the libraries

- [AOSP](http://source.android.com/)
- [android-advancedrecyclerview](https://github.com/h6ah4i/android-advancedrecyclerview)
- [Apache Commons Lang](https://commons.apache.org/proper/commons-lang/)
- [apng](http://apng.sourceforge.net/)
- [giflib](http://giflib.sourceforge.net)
- [greenDAO](https://github.com/greenrobot/greenDAO)
- [jsoup](https://github.com/jhy/jsoup)
- [libjpeg-turbo](http://libjpeg-turbo.virtualgl.org/)
- [libpng](http://www.libpng.org/pub/png/libpng.html)
- [okhttp](https://github.com/square/okhttp)
- [roaster](https://github.com/forge/roaster)
- [ShowcaseView](https://github.com/amlcurran/ShowcaseView)
- [Slabo](https://github.com/TiroTypeworks/Slabo)
- [TagSoup](http://home.ccil.org/~cowan/tagsoup/)


# License

    Copyright (C) 2014-2019 Hippo Seven

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

ic_launcher 图标为 Hippo Seven 所有，所有权利保留
