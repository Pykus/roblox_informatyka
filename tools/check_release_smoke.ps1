$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$buildIdFile = Join-Path $root 'build\playtest\release-smoke-build-id.txt'
if (-not (Test-Path $buildIdFile)) {
    throw 'Release smoke build ID file not found. Rebuild release QA first.'
}
$expectedBuildId = (Get-Content $buildIdFile -Raw).Trim()
if ($expectedBuildId -eq '') {
    throw 'Release smoke build ID is empty.'
}

$harnessFile = Join-Path $PSScriptRoot 'ReleaseSmokeHarness.server.lua'
$matrixLines = @(
    Select-String -Path $harnessFile -Pattern '^\s*\{\s*"[A-Z0-9]+"\s*,\s*\d+\s*,\s*"'
)
$expectedFamilies = $matrixLines.Count
$expectedPromptFamilies = @(
    $matrixLines | Where-Object { $_.Line -match ',\s*true\s*\},?\s*$' }
).Count
if ($expectedFamilies -lt 1) {
    throw 'Release smoke matrix is empty.'
}

$logDir = Join-Path $env:LOCALAPPDATA 'Roblox\logs'
if (-not (Test-Path $logDir)) {
    throw 'Roblox Studio log directory not found.'
}

$buildMarker = '[CER-RELEASE] BUILD_ID ' + $expectedBuildId
$log = $null
$lines = $null
$buildIndex = -1

foreach ($candidate in (Get-ChildItem $logDir -File | Sort-Object LastWriteTime -Descending)) {
    $candidateLines = Get-Content $candidate.FullName
    $candidateBuildIndex = -1
    for ($i = 0; $i -lt $candidateLines.Count; $i++) {
        if ($candidateLines[$i].Contains($buildMarker)) {
            $candidateBuildIndex = $i
        }
    }
    if ($candidateBuildIndex -ge 0) {
        $log = $candidate
        $lines = $candidateLines
        $buildIndex = $candidateBuildIndex
        break
    }
}

$buildMatch = $null -ne $log -and $buildIndex -ge 0
$release = @()
if ($buildMatch) {
    $release = @($lines[$buildIndex..($lines.Count - 1)] | Where-Object { $_ -match '\[CER-RELEASE\]' })
}
$passPattern = '\[CER-RELEASE\] PASS \d{2}/' + $expectedFamilies + ' '
$allOkPattern = '\[CER-RELEASE\] ALL_OK families=' + $expectedFamilies
$passes = @($release | Where-Object { $_ -match $passPattern })
$clientPasses = @($passes | Where-Object { $_ -match ' client=1 ' })
$fails = @($release | Where-Object { $_ -match '\[CER-RELEASE\] FAIL ' })
$allOk = @($release | Where-Object { $_ -match $allOkPattern })
$manualGate = @($release | Where-Object { $_ -match '\[CER-RELEASE\] MANUAL_GATE ' })
$restartGuide = @($release | Where-Object { $_ -match '\[CER-RELEASE\] RESTART_GUIDE_OK SP4/03' })
$respawnOk = @($release | Where-Object { $_ -match '\[CER-RELEASE\] RESPAWN_OK SP4/03 distance=' })
$firstActionDistances = @(
    foreach ($line in $passes) {
        if ($line -match ' first=(-?\d+(?:\.\d+)?) ') {
            $distance = [double]$Matches[1]
            if ($distance -ge 0) { $distance }
        }
    }
)
$walkSpeeds = @(
    foreach ($line in $passes) {
        if ($line -match ' walk=(\d+(?:\.\d+)?) ') {
            [double]$Matches[1]
        }
    }
)
$groundDistances = @(
    foreach ($line in $passes) {
        if ($line -match ' ground=(\d+(?:\.\d+)?) ') {
            [double]$Matches[1]
        }
    }
)
$worldTextCounts = @(
    foreach ($line in $passes) {
        if ($line -match ' world=(\d+) ') {
            [int]$Matches[1]
        }
    }
)
$inputFreedom = @(
    foreach ($line in $passes) {
        if ($line -match ' input=(\d+) ') {
            [int]$Matches[1]
        }
    }
)
$constraintRecovery = @(
    foreach ($line in $passes) {
        if ($line -match ' constraints=(\d+) ') {
            [int]$Matches[1]
        }
    }
)
$maxFirstAction = if ($firstActionDistances.Count -gt 0) {
    ($firstActionDistances | Measure-Object -Maximum).Maximum
} else {
    -1
}
$minWalkSpeed = if ($walkSpeeds.Count -gt 0) {
    ($walkSpeeds | Measure-Object -Minimum).Minimum
} else {
    -1
}
$maxGroundDistance = if ($groundDistances.Count -gt 0) {
    ($groundDistances | Measure-Object -Maximum).Maximum
} else {
    -1
}
$minWorldTextCount = if ($worldTextCounts.Count -gt 0) {
    ($worldTextCounts | Measure-Object -Minimum).Minimum
} else {
    -1
}
$minInputFreedom = if ($inputFreedom.Count -gt 0) {
    ($inputFreedom | Measure-Object -Minimum).Minimum
} else {
    -1
}
$minConstraintRecovery = if ($constraintRecovery.Count -gt 0) {
    ($constraintRecovery | Measure-Object -Minimum).Minimum
} else {
    -1
}

Write-Output ('RELEASE_SMOKE_LOG=' + $log.FullName)
Write-Output ('RELEASE_SMOKE_EXPECTED_BUILD_ID=' + $expectedBuildId)
Write-Output ('RELEASE_SMOKE_BUILD_MATCH=' + [int]$buildMatch)
Write-Output ('RELEASE_SMOKE_PASS_COUNT=' + $passes.Count)
Write-Output ('RELEASE_SMOKE_CLIENT_PASS_COUNT=' + $clientPasses.Count)
Write-Output ('RELEASE_SMOKE_FAIL_COUNT=' + $fails.Count)
Write-Output ('RELEASE_SMOKE_ALL_OK=' + [int]($allOk.Count -gt 0))
Write-Output ('RELEASE_SMOKE_MANUAL_GATE=' + [int]($manualGate.Count -gt 0))
Write-Output ('RELEASE_SMOKE_RESTART_GUIDE=' + [int]($restartGuide.Count -eq 1))
Write-Output ('RELEASE_SMOKE_RESPAWN_OK=' + [int]($respawnOk.Count -eq 1))
Write-Output ('RELEASE_SMOKE_FIRST_ACTION_COUNT=' + $firstActionDistances.Count)
Write-Output ('RELEASE_SMOKE_MAX_FIRST_ACTION_DISTANCE=' + $maxFirstAction)
Write-Output ('RELEASE_SMOKE_MOBILITY_COUNT=' + $walkSpeeds.Count)
Write-Output ('RELEASE_SMOKE_MIN_WALK_SPEED=' + $minWalkSpeed)
Write-Output ('RELEASE_SMOKE_MAX_GROUND_DISTANCE=' + $maxGroundDistance)
Write-Output ('RELEASE_SMOKE_WORLD_TEXT_COUNT=' + $worldTextCounts.Count)
Write-Output ('RELEASE_SMOKE_MIN_WORLD_TEXT=' + $minWorldTextCount)
Write-Output ('RELEASE_SMOKE_INPUT_FREEDOM_COUNT=' + $inputFreedom.Count)
Write-Output ('RELEASE_SMOKE_MIN_INPUT_FREEDOM=' + $minInputFreedom)
Write-Output ('RELEASE_SMOKE_CONSTRAINT_RECOVERY_COUNT=' + $constraintRecovery.Count)
Write-Output ('RELEASE_SMOKE_MIN_CONSTRAINT_RECOVERY=' + $minConstraintRecovery)

if (-not $buildMatch) {
    throw 'Release smoke log does not match the current release QA build ID.'
}

if ($fails.Count -gt 0) {
    $fails | Select-Object -Last 10
    throw 'Release smoke contains FAIL entries.'
}

if ($passes.Count -ne $expectedFamilies) {
    throw "Release smoke expected $expectedFamilies PASS entries, got $($passes.Count)."
}

if ($clientPasses.Count -ne $expectedFamilies) {
    throw "Release smoke expected $expectedFamilies client-verified PASS entries, got $($clientPasses.Count)."
}

if ($firstActionDistances.Count -ne $expectedPromptFamilies) {
    throw "Release smoke expected $expectedPromptFamilies prompt-family first-action distances, got $($firstActionDistances.Count)."
}

if ($maxFirstAction -gt 80) {
    throw "Release smoke first action too far: max=$maxFirstAction, limit=80."
}

if ($walkSpeeds.Count -ne $expectedFamilies -or $groundDistances.Count -ne $expectedFamilies) {
    throw "Release smoke expected $expectedFamilies mobility samples, got walk=$($walkSpeeds.Count), ground=$($groundDistances.Count)."
}

if ($minWalkSpeed -lt 8) {
    throw "Release smoke player WalkSpeed too low: min=$minWalkSpeed, limit=8."
}

if ($maxGroundDistance -gt 16) {
    throw "Release smoke spawn ground too far: max=$maxGroundDistance, limit=16."
}

if ($worldTextCounts.Count -ne $expectedFamilies) {
    throw "Release smoke expected $expectedFamilies world-text samples, got $($worldTextCounts.Count)."
}

if ($minWorldTextCount -lt 1) {
    throw "Release smoke found a family without readable world text."
}

if ($inputFreedom.Count -ne $expectedFamilies) {
    throw "Release smoke expected $expectedFamilies input-freedom samples, got $($inputFreedom.Count)."
}

if ($minInputFreedom -lt 1) {
    throw "Release smoke found a family with hidden TextBox focus."
}

if ($constraintRecovery.Count -ne $expectedFamilies) {
    throw "Release smoke expected $expectedFamilies constraint-recovery samples, got $($constraintRecovery.Count)."
}

if ($minConstraintRecovery -lt 1) {
    throw "Release smoke found duplicate or unreadable UITextSizeConstraint state."
}

if ($restartGuide.Count -ne 1) {
    throw "Release smoke did not verify First Action Guide after same-title restart."
}

if ($respawnOk.Count -ne 1) {
    throw "Release smoke did not verify mission recovery after character respawn."
}

if ($allOk.Count -eq 0) {
    throw 'Release smoke did not reach ALL_OK.'
}

if ($manualGate.Count -eq 0) {
    throw 'Release smoke did not emit manual visual gate marker.'
}

Write-Output 'RELEASE_SMOKE_VERIFIED=1'