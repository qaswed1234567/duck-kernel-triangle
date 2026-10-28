# Duck Kernel Triangle

中文简介：

Duck Kernel Triangle 是一个面向 Android / NDK 的构建与打包工程，主要用于将原生 ELF 可执行文件编译、注入和打包为 APK，并提供二进制加密与校验流程。项目保留了脚本化构建能力，适合在 Windows 环境下快速生成 APK，并便于后续接入 Android 工程或自定义加载逻辑。

English overview:

Duck Kernel Triangle is an Android / NDK-oriented build and packaging project focused on compiling, injecting, and packaging native ELF binaries into APKs. It includes a script-based build workflow for Windows environments and a binary encryption / verification flow to help protect embedded native payloads.

## 项目功能 / Features

- NDK 构建原生 ELF 可执行文件
  - Native ELF compilation with ndk-build
- APK 自动化打包
  - Automated APK packaging with Gradle or Android SDK tools
- 资源注入
  - Copy native binary into app assets before packaging
- 二进制加密保护
  - XOR + nonce encryption for embedded kernel payload
- 解密校验
  - Verification script ensures restored data is still valid ELF
- 开发者友好结构
  - Clear directory layout and documentation for maintainability

## 仓库结构 / Repository Layout

```text
duck-kernel-triangle/
├── README.md
├── docs/
│   └── BUILD_GUIDE.md
├── config/
│   ├── build.gradle
│   ├── settings.gradle
│   └── gradle.properties
├── scripts/
│   ├── windows/
│   │   ├── build.bat
│   │   ├── build_apk.ps1
│   │   └── 打包APK.ps1
│   └── crypto/
│       ├── encrypt_binary.py
│       └── verify_decrypt.py
├── .gitignore
└── legacy/
    └── deprecated stubs for old entry points
```

## 关键脚本说明 / Key Scripts

### 1) build.bat

Windows 一键构建脚本：
- 调用 ndk-build 编译原生二进制
- 复制产物到 `app/src/main/assets`
- 调用 Gradle 打包 APK

### 2) build_apk.ps1

纯 SDK 工具链打包脚本：
- 不依赖 Android Studio / Gradle
- 使用 `javac`、`d8`、`aapt2`、`zipalign`、`apksigner`
- 适合本地 Windows 电脑直接生成 APK

### 3) encrypt_binary.py

对 `duck_kernel` 进行加密：
- 使用 16-byte nonce
- 使用 XOR 流加密
- 输出 `duck_kernel.enc`

### 4) verify_decrypt.py

验证加密文件：
- 解密后校验 ELF 魔数
- 比较还原结果与原始二进制是否一致

## 快速开始 / Quick Start

### 环境要求 / Requirements

- JDK 8+
- Android SDK
- Android NDK (`ndk-build` available in PATH)
- Windows 10/11 recommended

### 一键构建 / One-click build

```bat
scripts\windows\build.bat
```

### 纯 SDK 打包 / SDK-only packaging

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\build_apk.ps1
```

### 加密二进制 / Encrypt binary

```bash
python scripts/crypto/encrypt_binary.py
```

### 验证解密 / Verify decryption

```bash
python scripts/crypto/verify_decrypt.py
```

## 构建流程 / Build Flow

1. 编译原生可执行文件
   - `ndk-build`
2. 复制产物到 assets
   - `app/src/main/assets/duck_kernel`
3. 构建 APK
   - Gradle or SDK toolchain
4. 为原生文件加密
   - `encrypt_binary.py`
5. 验证恢复结果
   - `verify_decrypt.py`

## 重要说明 / Important Notes

- 某些脚本中附带硬编码路径，需根据本机 SDK / NDK 路径修改
- `ndk-build` 必须位于 PATH 中
- `encrypt_binary.py` 与 Java 端必须使用相同的密钥与算法
- 本仓库偏向脚本化工具���和自动化构建流程，而不是完整 Android 工程源代码

## 适用场景 / Use Cases

- Android 原生加载器研究
- NDK 二进制注入流程实验
- APK 打包自动化脚本
- 原生与 Java 互操作的工程验证

## 安全提示 / Security Note

本仓库中的脚本用于演示和构建流程管理，不应直接用于生产环境中的敏感文件分发或密钥管理。若用于实际项目，请自行评估安全策略，并妥善管理签名密钥、SDK 路径和二进制分发方式。

## 开发者说明 / Developer Notes

This repository is intentionally structured to keep the canonical build flow in one place and deprecate duplicate root-level scripts. The active scripts live under `scripts/`, while project-level build configuration is grouped under `config/`.

If you are integrating with a real Android project, place the actual application source under the expected `app/src/main/...` layout and update the paths in the scripts accordingly.
