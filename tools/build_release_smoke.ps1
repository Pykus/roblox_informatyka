$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$harnessSource = Join-Path $PSScriptRoot 'ReleaseSmokeHarness.server.lua'
$harnessTarget = Join-Path $root 'src\ServerScriptService\StudioSmokeRelease.server.lua'
$clientProbeSource = Join-Path $PSScriptRoot 'ReleaseClientProbe.client.lua'
$clientProbeTarget = Join-Path $root 'src\StarterPlayer\StarterPlayerScripts\StudioReleaseClientProbe.client.lua'
$outDir = Join-Path $root 'build\playtest'
$outFile = Join-Path $outDir 'CyberEscapeRoom_RELEASE_QA.rbxlx'
$buildIdFile = Join-Path $outDir 'release-smoke-build-id.txt'
$rojo = [System.IO.Path]::GetFullPath((Join-Path $root '..\..\tools\rojo\rojo.exe'))

if (-not (Test-Path $harnessSource)) { throw 'Release smoke harness source missing.' }
if (-not (Test-Path $clientProbeSource)) { throw 'Release smoke client probe source missing.' }
if (-not (Test-Path $rojo)) { throw 'Local Rojo binary missing.' }

$staleServerSmoke = @(Get-ChildItem (Join-Path $root 'src\ServerScriptService') -Filter 'StudioSmoke*.server.lua' -File -ErrorAction SilentlyContinue)
$staleClientSmoke = @(Get-ChildItem (Join-Path $root 'src\StarterPlayer\StarterPlayerScripts') -Filter 'StudioRelease*.client.lua' -File -ErrorAction SilentlyContinue)
if ($staleServerSmoke.Count -gt 0 -or $staleClientSmoke.Count -gt 0) {
    $names = @($staleServerSmoke + $staleClientSmoke | ForEach-Object { $_.FullName })
    throw ('Refusing release build: stale Studio smoke source present: ' + ($names -join '; '))
}

New-Item -ItemType Directory -Force -Path $outDir | Out-Null
Remove-Item -Force $buildIdFile -ErrorAction SilentlyContinue
$buildId = [Guid]::NewGuid().ToString('N')
Copy-Item -Force $harnessSource $harnessTarget
Copy-Item -Force $clientProbeSource $clientProbeTarget
$renderedHarness = (Get-Content $harnessTarget -Raw).Replace('__RELEASE_BUILD_ID__', $buildId)
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($harnessTarget, $renderedHarness, $utf8NoBom)
try {
    & $rojo build (Join-Path $root 'default.project.json') -o $outFile
    if ($LASTEXITCODE -ne 0) { throw "Rojo release-smoke build failed: $LASTEXITCODE" }
    $item = Get-Item $outFile
    Set-Content -Path $buildIdFile -Value $buildId -NoNewline
    Write-Output ("RELEASE_SMOKE_BUILD=" + $item.FullName)
    Write-Output ("RELEASE_SMOKE_BYTES=" + $item.Length)
    Write-Output ("RELEASE_SMOKE_BUILD_ID=" + $buildId)
} finally {
    Remove-Item -Force $harnessTarget -ErrorAction SilentlyContinue
    Remove-Item -Force $clientProbeTarget -ErrorAction SilentlyContinue
}