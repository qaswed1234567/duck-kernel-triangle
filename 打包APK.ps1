# 鸭子内核 APK 手动打包脚本（无需 gradle）
# 依赖: JDK + Android SDK (aapt2 / d8 / apksigner / zipalign)
# 用法: 在 PowerShell 里执行本脚本

$ErrorActionPreference = 'Stop'
$sdk = 'D:\Android\Sdk'
$bt = "$sdk\build-tools\35.0.0"
$platform = "$sdk\platforms\android-36\android.jar"
$base = 'C:\Users\少宇NB666\Documents\deepseek-harness\default-workspace\delta_android'
$work = "$env:TEMP\duck_apk_build"
$outApk = "$base\鸭子内核.apk"

Write-Output "[1/6] 清理并创建工作目录"
if (Test-Path $work) { Remove-Item -Recurse -Force $work }
New-Item -ItemType Directory -Path $work\classes | Out-Null
New-Item -ItemType Directory -Path $work\dex | Out-Null

Write-Output "[2/6] 编译 Java 源码"
$javasrc = "$base\app\src\main\java\com\duck\kernel\*.java"
javac -d $work\classes -cp $platform -encoding UTF-8 -source 8 -target 8 $javasrc
if ($LASTEXITCODE -ne 0) { throw "javac 失败" }

Write-Output "[3/6] d8 生成 dex"
$classfiles = Get-ChildItem "$work\classes\com\duck\kernel\*.class" | ForEach-Object { $_.FullName }
& "$bt\d8.bat" --release --lib $platform --min-api 21 --output "$work\dex" $classfiles
if ($LASTEXITCODE -ne 0) { throw "d8 失败" }

Write-Output "[4/6] aapt2 编译资源 + 链接"
# 编译 AndroidManifest（使用 --manifest 直接编译）
& "$bt\aapt2.exe" compile --dir "$base\app\src\main" -o "$work\res.zip"
if ($LASTEXITCODE -ne 0) { throw "aapt2 compile 失败" }

& "$bt\aapt2.exe" link -o "$work\base.apk" `
  -I $platform `
  --manifest "$base\app\src\main\AndroidManifest.xml" `
  --java "$work\gen" `
  -A "$base\app\src\main\assets" `
  "$work\res.zip" `
  --auto-add-overlay
if ($LASTEXITCODE -ne 0) { throw "aapt2 link 失败" }

Write-Output "[5/6] 打包 dex 进 APK"
# 先把 dex 塞进 base.apk（用 jar 方式重建）
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::Open("$work\base.apk", 'Update')
$entry = $zip.CreateEntry('classes.dex')
$s = $entry.Open()
$bytes = [System.IO.File]::ReadAllBytes("$work\dex\classes.dex")
$s.Write($bytes, 0, $bytes.Length)
s.Close()
$zip.Dispose()

Write-Output "[6/6] 签名 APK"
# 生成调试密钥（若不存在）
$ks = "$work\debug.keystore"
if (-not (Test-Path $ks)) {
  & keytool -genkeypair -v -keystore $ks -storepass android -alias androiddebugkey `
    -keypass android -keyalg RSA -keysize 2048 -validity 10000 `
    -dname "CN=Android Debug,O=Android,C=US" 2>&1 | Out-Null
}

& "$bt\apksigner.bat" sign --ks $ks --ks-pass pass:android --key-pass pass:android `
  --out $outApk "$work\base.apk"
if ($LASTEXITCODE -ne 0) { throw "apksigner 失败" }

Write-Output ""
Write-Output "完成! APK: $outApk"
Write-Output ("大小: " + (Get-Item $outApk).Length + " 字节")
Write-Output "安装: adb install 上面的路径"
