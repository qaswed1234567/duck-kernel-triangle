# 鸭子内核三角州

这是一个 Android / NDK APK 构建与二进制加解密脚本仓库，主要用于：

- 使用 ndk-build 编译原生可执行文件
- 复制可执行文件到 Android 资源目录
- 使用 Gradle / Android SDK 工具链打包 APK
- 对 `duck_kernel` 做 XOR + nonce 加密/校验

## 目录说明

- `build.bat`：Windows 一键构建脚本，调用 ndk-build 后打包 APK
- `build.gradle`：顶层 Gradle 插件声明
- `build_apk.ps1`：纯 SDK 工具链打包脚本（不依赖 Gradle）
- `encrypt_binary.py`：把 `duck_kernel` 加密成 `duck_kernel.enc`
- `verify_decrypt.py`：验证加密后的文件能被 Java 端正确还原
- `gradle.properties`：Gradle 常用配置
- `settings.gradle`：工程配置
- `打包APK.ps1`：另一个手动打包脚本（中文注释版）

## 建议工作流

1. 在项目根目录运行 `build.bat`（常用）
2. 若环境中没有 Gradle / Android Studio，可使用 `build_apk.ps1`
3. 编译后使用 `encrypt_binary.py` 生成加密二进制
4. 用 `verify_decrypt.py` 校验解密结果与原始 ELF 一致

## 注意事项

- `ndk-build` 必须在 `PATH` 中可见
- Android SDK / JDK / build-tools 需要提前安装并配置
- 一些脚本中使用了本机目录路径，实际部署时请按自己的环境修改
- 目录中有中文脚本名，Windows 环境通常可直接执行

## 说明

这个仓库保留了原始脚本内容，并做了更清晰的目录说明，便于后续继续维护和扩展。
