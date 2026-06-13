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

function Assert-NotContains([string]$relativePath, [string]$pattern, [string]$message) {
    $text = Read-Text $relativePath
    if ($text -match $pattern) {
        Add-Failure("${relativePath}: $message")
    }
}

$base = "gmod_addon\lua\entities\bmb_base_mob.lua"

Assert-Contains $base "DebugPathNoProgressTimeout" "debug target movement needs a command-level no-progress timeout for unreachable gap/dead-end cases"
Assert-Contains $base "debug_no_progress" "debug path should clear gracefully after repeated no-progress repaths instead of staying in debug_repath"
Assert-Contains $base "debugLastProgressAt" "debug path should track progress across segment retries"

Assert-Contains $base "SetCollisionGroup\(COLLISION_GROUP_NPC\)" "collision should use the original GMod/NextBot NPC collision feel"
Assert-NotContains $base "MobCollisionGroup" "MC-like collision plan should be removed"
Assert-NotContains $base "COLLISION_GROUP_PLAYER" "do not force player-like collision groups after physgun/bullet regressions"
Assert-NotContains $base "SetCustomCollisionCheck" "custom ShouldCollide path broke physgun/bullet interactions and should be removed"
Assert-NotContains $base "ShouldCollide" "no hard-collision override should remain"
Assert-NotContains $base "BMB_SoftEntityCollision" "player/mob hard collision hook should be removed"
Assert-NotContains $base "SoftSeparation" "soft separation plan should be removed to keep GMod feel"
Assert-NotContains $base "ApplyBMBSoftSeparation" "soft separation velocity overlay should not run"

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Host "ERROR: $_" }
    exit 1
}

Write-Host "Debug gap and GMod collision regression checks passed."
