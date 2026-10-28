# 构建说明

## 一、环境要求

- JDK
- Android SDK
- Android NDK（`ndk-build` 可用）
- Windows 环境（建议）

## 二、常用构建脚本

### 1) 一键构建

脚本：`scripts/windows/build.bat`

用途：
- 调用 `ndk-build`
- 复制 ELF 到 `app/src/main/assets/duck_kernel`
- 调用 `gradlew assembleDebug`

### 2) 纯 SDK 构建

脚本：`scripts/windows/build_apk.ps1`

用途：
- 不依赖 Gradle
- 直接使用 `javac`、`d8`、`aapt2`、`zipalign`、`apksigner`
- 适合在没有 Android Studio 的 Windows 环境中直接打包 APK

### 3) 生成加密后的二进制

脚本：`scripts/crypto/encrypt_binary.py`

用途：
- 将 `duck_kernel` 编码为 `duck_kernel.enc`
- 采用 16 字节 nonce + XOR 流加密

### 4) 解密校验

脚本：`scripts/crypto/verify_decrypt.py`

用途：
- 读取 `duck_kernel.enc`
- 校验恢复后的内容仍然是有效 ELF
- 确认其与原始 `duck_kernel` 完全一致

## 三、项目文件说明

### `config/`

- `build.gradle`：Android Gradle 插件声明
- `settings.gradle`：项目 root 配置
- `gradle.properties`：Gradle 常见运行参数

### `scripts/`

- `windows/`：Windows 构建与打包脚本
- `crypto/`：加密/校验脚本

## 四、建议工作流

1. 执行 `scripts/windows/build.bat`
2. 若未安装 Gradle 或 Android Studio，则执行 `scripts/windows/build_apk.ps1`
3. 生成加密二进制：`encrypt_binary.py`
4. 通过 `verify_decrypt.py` 确认二进制解密正确

## 五、注意事项

- 硬编码路径需按个人环境调整
- 运行前确认 NDK / SDK 路径有效
- 部分脚本使用中文文件名，Windows 上通常可直接执行
