$ErrorActionPreference = 'Stop'
$flutter = Join-Path $env:USERPROFILE 'develop\flutter\bin\flutter.bat'
$sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
$adb = Join-Path $sdk 'platform-tools\adb.exe'
$emulator = Join-Path $sdk 'emulator\emulator.exe'
$avdName = 'Gaxiola_API_36'
$device = 'emulator-5554'

foreach ($tool in @($flutter, $adb, $emulator)) {
    if (!(Test-Path $tool)) { throw "Falta instalar: $tool" }
}

$env:ANDROID_HOME = $sdk
$javaDir = Get-ChildItem (Join-Path $env:USERPROFILE 'develop') -Directory -Filter 'jdk-21*' | Select-Object -First 1
if ($javaDir) { $env:JAVA_HOME = $javaDir.FullName }
& $adb start-server | Out-Null
$devices = & $adb devices
if ($devices -match "^$device\s") {
    $currentAvd = (& $adb -s $device shell getprop ro.boot.qemu.avd_name 2>$null | Out-String).Trim()
    if ($currentAvd -ne $avdName) { throw "El puerto 5554 lo usa otro emulador. Cierralo antes de continuar." }
} else {
    & $emulator -accel-check
    if ($LASTEXITCODE -ne 0) { throw 'La aceleracion no esta disponible. Reinicia Windows si acabas de instalarla.' }
    Write-Host 'Iniciando el emulador Android...'
    Start-Process -FilePath $emulator -ArgumentList @('-avd', $avdName, '-port', '5554', '-no-boot-anim') | Out-Null
}

$deadline = (Get-Date).AddMinutes(5)
do {
    $ErrorActionPreference = 'Continue'
    $booted = (& $adb -s $device shell getprop sys.boot_completed 2>$null | Out-String).Trim()
    $ErrorActionPreference = 'Stop'
    if ($booted -eq '1') { break }
    Start-Sleep -Seconds 2
} while ((Get-Date) -lt $deadline)
if ($booted -ne '1') { throw 'El emulador no termino de arrancar en cinco minutos.' }

Push-Location $PSScriptRoot
try {
    & $flutter run -d $device
    if ($LASTEXITCODE -ne 0) { throw 'Flutter no pudo ejecutar la aplicacion. Revisa los mensajes anteriores.' }
} finally { Pop-Location }
