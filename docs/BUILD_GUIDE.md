# 构建指南 / Build Guide

## 1. 项目定位 / Project Positioning

本仓库以“脚本驱动的 Android NDK 构建 + 二进制安全流程”为核心，主要分为三部分：

- 原生构建：使用 NDK 编译 ELF
- APK 打包：使用 Gradle 或纯 SDK 工具链打包
- 二进制保护：使用加密与校验脚本保证完整性

This repository is centered around a script-driven Android NDK build and binary safety workflow, consisting of three main parts:

- Native build: compile ELF with NDK
- APK packaging: build APK via Gradle or SDK tools
- Binary protection: encrypt and verify payload integrity

## 2. 目录说明 / Directory Overview

```text
config/
  build.gradle      顶层 Gradle 配置 / root gradle config
  settings.gradle   项目设置 / project settings
  gradle.properties Gradle 运行参数 / gradle runtime options

scripts/
  windows/
    build.bat       一键构建脚本 / one-click build script
    build_apk.ps1   纯 SDK 打包脚本 / SDK-only packaging script
    打包APK.ps1     备用中文版打包脚本 / alternative Chinese packaging script
  crypto/
    encrypt_binary.py  二进制加密脚本 / binary encryption script
    verify_decrypt.py 校验脚本 / verification script
```

## 3. 运行环境 / Environment Setup

### Windows 环境 / Windows environment

需要准备：

- JDK
- Android SDK
- Android NDK（确保 `ndk-build` 在 PATH 中）
- PowerShell / cmd

### 必要检查 / Required checks

```bat
where ndk-build
where javac
where keytool
```

If any command is not found, fix your environment variables before running the build scripts.

## 4. 一键构建 / One-click Build

推荐入口：

```bat
scripts\windows\build.bat
```

执行流程：

1. 进入项目根目录
2. 调用 `ndk-build`
3. 复制输出的 `duck_kernel` 到 `app/src/main/assets`
4. 执行 `gradlew assembleDebug`
5. 输出 APK 文件

## 5. 纯 SDK 打包 / SDK-only Packaging

如果你的环境中没有 Gradle 或 Android Studio，可以使用：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\build_apk.ps1
```

步骤：

1. 拷贝 `AndroidManifest.xml`、Java 源码、资源和 assets 到 staging 目录
2. 使用 `javac` 编译 Java
3. 使用 `d8` 生成 Dex
4. 使用 `aapt2` 生成基础 APK
5. 注入 `classes.dex`
6. `zipalign`
7. `apksigner` 签名

## 6. 二进制加密 / Binary Encryption

脚本位置：

```bash
python scripts/crypto/encrypt_binary.py
```

功能：

- 读取原始 `duck_kernel`
- 随机生成 16 字节 nonce
- 进行 XOR 流加密
- 输出 `duck_kernel.enc`

## 7. 校验流程 / Verification Flow

```bash
python scripts/crypto/verify_decrypt.py
```

校验内容：

- 读取 `duck_kernel.enc`
- 恢复原始数据
- 检查 ELF 魔数是否为 `0x7F 'E' 'L' 'F'`
- 验证是否��原始 `duck_kernel` 完全一致

## 8. 适配真实 Android 工程 / Adapting to a Real Android Project

如果你要接入真正的 Android 工程，建议：

- 将 `app/src/main` 目录放入真实项目中
- 根据实际 SDK / NDK 路径更新脚本中的硬编码路径
- 确认 `AndroidManifest.xml`、资源目录和 Java 包路径正确
- 检查 `ndk-build` 的 `Android.mk` / `Application.mk` 配置

## 9. 维护建议 / Maintenance Advice

- 保持唯一的主构建入口，避免分散脚本逻辑
- 只保留最稳定的脚本版本，避免旧副本干扰
- 对加密密钥和签名信息做显式说明
- 逐步把脚本转成更清晰的模块化结构

## 10. 常见问题 / Troubleshooting

### Q: `ndk-build` not found

A: Ensure NDK is installed and `ndk-build` is on PATH.

### Q: `javac` or `d8` command fails

A: Check your JDK and Android SDK build-tools version.

### Q: APK not generated

A: Verify `AndroidManifest.xml` exists and all required resource files are present.

### Q: Decryption verification failed

A: Check whether the Java-side decryption logic matches the Python script exactly.
