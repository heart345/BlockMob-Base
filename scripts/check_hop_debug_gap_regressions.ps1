param(
    [string]$Root = (Resolve-Path -LiteralPath "$PSScriptRoot\..").Path
)

$ErrorActionPreference = "Stop"

$failures = New-Object System.Collections.Generic.List[string]

function Add-Failure([string]$message) {
    $failures.Add($message) | Out-Null
}

function Read-Text([string]$relativePath) {
    $path = Join-Path $Root $relativePath
    if (-not (Test-Path -LiteralPath $path)) {
        Add-Failure("Missing expected file: $relativePath")
        return ""
    }

    return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

function Assert-Contains([string]$relativePath, [string]$pattern, [string]$message) {
    $text = Read-Text $relativePath
    if ($text -notmatch $pattern) {
        Add-Failure("${relativePath}: $message")
    }
}

$base = "gmod_addon\lua\entities\bmb_base_mob.lua"
$tool = "gmod_addon\lua\weapons\gmod_tool\stools\bmb_debug.lua"

Assert-Contains $base "BlockHopLaunchMinFaceDistanceScale" "BlockHop should gate launch by distance from the block face, not just center distance"
Assert-Contains $base "BlockHopLaunchIdealFaceDistanceScale" "BlockHop backoff should target a face-distance launch point"
Assert-Contains $base "faceDistance\s*>=\s*minFaceDistance" "hop ready condition must reject face-close launches"
Assert-Contains $base "reason\s*=\s*""face_close""" "HUD/debug should distinguish face-close hop setup from generic close distance"

Assert-Contains $base "DebugPathCommandTimeout" "debug target movement needs a long command lifetime for maze/hop paths"
Assert-Contains $tool "DebugPathCommandTimeout" "tool right-click target moves must use the debug path command timeout"
Assert-Contains $base "DebugPathProgressGrace" "debug path should extend while it is making progress"
Assert-Contains $base "BMBPathAdvanceCount" "debug path progress extension should consider node advancement"
Assert-Contains $base "BMBDebugMoveUntil\s*=\s*math\.max" "debug path progress should refresh the command expiry instead of dropping to wander"

Assert-Contains $base "IsBMBPathLineStandable" "carrot visibility must reject unsupported shortcuts over gaps"
Assert-Contains $base "Pathfinder\.IsStandablePosition" "gap check should use the same standable semantics as A*"
Assert-Contains $base "IsPathGridVisible\(rawCarrot" "carrot selection must run the grounded visibility check"
Assert-Contains $base "IsPathGridVisible\(candidate" "carrot bisection must also use the grounded visibility check"

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Host "ERROR: $_" }
    exit 1
}

Write-Host "Hop/debug/gap regression checks passed."
