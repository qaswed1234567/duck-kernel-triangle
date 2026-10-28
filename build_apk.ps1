# ============================================================
#  Duck Kernel APK builder (no gradle, pure SDK toolchain)
#  Steps: stage to ASCII path -> javac -> d8 -> aapt2 link -> inject dex -> zipalign -> sign
#  Output: Desktop\鸭子内核.apk
#  Note: aapt2 cannot handle non-ASCII paths, so stage to C:\duckbuild first.
# ============================================================
$ErrorActionPreference = 'Stop'

$src     = 'C:\Users\少宇NB666\Desktop\鸭子内核源码\app\src\main'
$stage   = 'C:\duckbuild'
$sdk     = 'D:\Android\Sdk'
$bt      = "$sdk\build-tools\35.0.0"
$platform= "$sdk\platforms\android-34\android.jar"
$work    = "$stage\_out"
$outApk  = 'C:\Users\少宇NB666\Desktop\鸭子内核源码\鸭子内核.apk'

Write-Host "[0/6] Stage project to ASCII path" -ForegroundColor Yellow
if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
New-Item -ItemType Directory -Path $stage -Force | Out-Null
Copy-Item "$src\AndroidManifest.xml" "$stage\" -Force
Copy-Item "$src\java"   "$stage\java"   -Recurse -Force
Copy-Item "$src\assets" "$stage\assets" -Recurse -Force
# Custom launcher icon: app\src\main\res\mipmap-*\ic_launcher.png (manifest: @mipmap/ic_launcher)
if (Test-Path "$src\res") { Copy-Item "$src\res" "$stage\res" -Recurse -Force }
Write-Host "      OK" -ForegroundColor Green

New-Item -ItemType Directory -Path "$work\classes" -Force | Out-Null
New-Item -ItemType Directory -Path "$work\dex"     -Force | Out-Null

Write-Host "[1/6] javac" -ForegroundColor Yellow
$javasrc = Get-ChildItem "$stage\java\com\duck\kernel" -Filter '*.java' | ForEach-Object { $_.FullName }
# javac deprecation notes go to stderr; relax error policy and judge by exit code.
$ErrorActionPreference = 'Continue'
& javac -d "$work\classes" -cp $platform -encoding UTF-8 -source 8 -target 8 -nowarn $javasrc 2>&1 | Out-Null
$javacExit = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
if ($javacExit -ne 0) { throw "javac failed (exit $javacExit)" }
Write-Host "      OK: $((Get-ChildItem "$work\classes" -Recurse -Filter '*.class').Count) classes" -ForegroundColor Green

Write-Host "[2/6] d8 -> classes.dex" -ForegroundColor Yellow
$classfiles = Get-ChildItem "$work\classes" -Recurse -Filter '*.class' | ForEach-Object { $_.FullName }
$ErrorActionPreference = 'Continue'
& "$bt\d8.bat" --release --lib $platform --min-api 21 --output "$work\dex" $classfiles 2>&1 | Out-Null
$d8Exit = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
if (-not (Test-Path "$work\dex\classes.dex")) { throw "d8 failed (exit $d8Exit)" }
Write-Host "      OK: $((Get-Item "$work\dex\classes.dex").Length) bytes" -ForegroundColor Green

Write-Host "[3/6] aapt2 link (with assets)" -ForegroundColor Yellow
# Compile res (mipmap icon) first, then pass the flat zip to link as positional arg.
$resZip = ''
if (Test-Path "$stage\res") {
  $ErrorActionPreference = 'Continue'
  & "$bt\aapt2.exe" compile --dir "$stage\res" -o "$work\res.zip" 2>&1 | Out-Null
  $resExit = $LASTEXITCODE
  $ErrorActionPreference = 'Stop'
  if ($resExit -ne 0) { throw "aapt2 compile failed (exit $resExit)" }
  if (Test-Path "$work\res.zip") { $resZip = "$work\res.zip" }
  Write-Host "      res: $((Get-Item "$work\res.zip").Length) bytes" -ForegroundColor DarkGray
}
$linkArgs = @('link', '-o', "$work\base.apk", '-I', $platform,
              '--manifest', "$stage\AndroidManifest.xml", '-A', "$stage\assets")
if ($resZip) { $linkArgs += $resZip }
$linkArgs += @('--min-sdk-version', '21', '--target-sdk-version', '34', '--auto-add-overlay')
$ErrorActionPreference = 'Continue'
& "$bt\aapt2.exe" @linkArgs 2>&1 | Out-Null
$aaptExit = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
if ($aaptExit -ne 0) { throw "aapt2 link failed (exit $aaptExit)" }
Write-Host "      OK: $((Get-Item "$work\base.apk").Length) bytes" -ForegroundColor Green

Write-Host "[4/6] inject classes.dex" -ForegroundColor Yellow
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::Open("$work\base.apk", 'Update')
$existing = $zip.GetEntry('classes.dex')
if ($existing) { $existing.Delete() }
$entry = $zip.CreateEntry('classes.dex', [System.IO.Compression.CompressionLevel]::Optimal)
$s = $entry.Open()
$dexBytes = [System.IO.File]::ReadAllBytes("$work\dex\classes.dex")
$s.Write($dexBytes, 0, $dexBytes.Length)
$s.Close()
$zip.Dispose()
Write-Host "      OK" -ForegroundColor Green

Write-Host "[5/6] zipalign" -ForegroundColor Yellow
$ErrorActionPreference = 'Continue'
& "$bt\zipalign.exe" -f -p 4 "$work\base.apk" "$work\aligned.apk" 2>&1 | Out-Null
$alignExit = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
if ($alignExit -ne 0) { throw "zipalign failed (exit $alignExit)" }
Write-Host "      OK" -ForegroundColor Green

Write-Host "[6/6] apksigner" -ForegroundColor Yellow
$ks = "$work\debug.keystore"
if (-not (Test-Path $ks)) {
    $ErrorActionPreference = 'Continue'
    & keytool -genkeypair -keystore $ks -storepass android -alias androiddebugkey `
      -keypass android -keyalg RSA -keysize 2048 -validity 10000 `
      -dname 'CN=Android Debug,O=Android,C=US' 2>&1 | Out-Null
    $ErrorActionPreference = 'Stop'
}
$ErrorActionPreference = 'Continue'
& "$bt\apksigner.bat" sign --ks $ks --ks-pass pass:android --key-pass pass:android `
  --out $outApk "$work\aligned.apk" 2>&1 | Out-Null
$signExit = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
if ($signExit -ne 0) { throw "apksigner failed (exit $signExit)" }
Write-Host "      OK" -ForegroundColor Green

$f = Get-Item $outApk
Write-Host ""
Write-Host "================ BUILD DONE ================" -ForegroundColor Green
Write-Host "APK : $($f.FullName)" -ForegroundColor Cyan
Write-Host "Size: $([math]::Round($f.Length/1MB,2)) MB" -ForegroundColor Cyan
Write-Host "Time: $($f.LastWriteTime)" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Green
