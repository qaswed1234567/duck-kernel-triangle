# 鸭子内核三角州

这是一个 Android / NDK APK 构建与二进制加密脚本仓库，适合用于：

- 使用 ndk-build 编译原生 ELF 可执行文件
- 将可执行文件复制到 `assets` 目录
- 通过 Android SDK / Gradle 工具链构建 APK
- 对 `duck_kernel` 进行 XOR + nonce 加密校验

## 目录结构

```text
DuckKernel/
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
└── legacy/
    └── (兼容旧文件，保留原始脚本入口)
```

## 推荐使用方式

### 1) 一键构建

在 Windows 环境下运行：

```bat
scripts\windows\build.bat
```

### 2) 纯 SDK 工具链构建

如果你不想依赖 Gradle，可以使用：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\build_apk.ps1
```

### 3) 加密原生二进制

```bash
python scripts/crypto/encrypt_binary.py
```

### 4) 验证解密结果

```bash
python scripts/crypto/verify_decrypt.py
```

## 说明

- 这个仓库保留了原始脚本内容，便于从旧版本迁移。
- 新结构将脚本按用途分组，便于后续维护和扩展。
- 若工程中的路径需要移动到真实 Android 项目目录，请根据实际设备和 SDK 路径进行调整。

## 重要提醒

- `ndk-build` 必须处于 `PATH` 环境变量中
- Android SDK / JDK / build-tools 必须已安装
- 某些脚本中带有硬编码路径，需要根据自身电脑环境修改
- `encrypt_binary.py` 与 Java 端需使用相同 key / nonce 逻辑
