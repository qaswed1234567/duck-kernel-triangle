@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM ============================================================
REM  鸭子内核 一键构建脚本
REM  流程: ndk-build 编译可执行文件 -> 复制到 assets -> 打 APK
REM  需要: NDK 环境变量 (ndk-build 在 PATH 中) + JDK
REM ============================================================

cd /d "%~dp0"

echo [1/3] ndk-build 编译可执行文件 ...
pushd jni
call ndk-build NDK_PROJECT_PATH=. APP_BUILD_SCRIPT=Android.mk APP_PLATFORM=android-21
if errorlevel 1 (
    echo [错误] ndk-build 失败
    popd
    exit /b 1
)
popd

set BIN=jni\libs\arm64-v8a\duck_kernel
if not exist "%BIN%" (
    echo [错误] 未找到产物 %BIN%
    exit /b 1
)

echo [2/3] 复制可执行文件到 assets ...
copy /y "%BIN%" "app\src\main\assets\duck_kernel" >nul
if errorlevel 1 (
    echo [错误] 复制失败
    exit /b 1
)

echo [3/3] 打 APK (gradlew) ...
if not exist gradlew.bat (
    echo [提示] 未找到 gradlew.bat, 请用 Android Studio 打开工程根目录手动 Build APK
    echo        或用: gradle assembleDebug
    exit /b 0
)

call gradlew.bat assembleDebug
if errorlevel 1 (
    echo [错误] 打包失败
    exit /b 1
)

echo.
echo [完成] APK 产物: app\build\outputs\apk\debug\app-debug.apk
echo 安装: adb install app\build\outputs\apk\debug\app-debug.apk
endlocal
