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
$behaviors = "gmod_addon\lua\bmb\sv_behaviors.lua"
$sheep = "gmod_addon\lua\entities\bmb_sheep.lua"
$state = "docs\STATE.md"
$claude = "CLAUDE.md"

Assert-Contains $base "BMBActivitySpeed" "base mob should track animation/behavior intent speed separately from transient loco command speed"
Assert-Contains $base "function\s+ENT:GetBMBRunActivityThreshold" "base mob should expose a shared run activity threshold for all mobs"
Assert-Contains $base "function\s+ENT:MaintainBMBMoveSpeed\s*\([^)]*activitySpeed" "movement speed helper should accept an optional stable activity speed"
Assert-Contains $base "options\.moveIntentSpeed" "path movement should preserve behavior intent speed while following corners/hop/drop"
Assert-Contains $base "options\.minPathSpeed" "path movement should be able to clamp transient corner slowdowns for panic/run states"
Assert-Contains $base "math\.min\(desiredSpeed,\s*options\.minPathSpeed" "minPathSpeed should not accelerate beyond the behavior's requested speed"
Assert-Contains $base 'GetNWFloat\("BMBActivitySpeed"' "activity selection should use BMBActivitySpeed, not only transient BMBDesiredSpeed"

Assert-Contains $behaviors "moveIntentSpeed\s*=\s*mob\.RunSpeed" "Flee should keep run animation intent stable for the full panic segment"
Assert-Contains $behaviors "minPathSpeed\s*=\s*fleeMinPathSpeed" "Flee should clamp path corner slowdowns above the run/walk threshold"
Assert-Contains $behaviors "GetBMBRunActivityThreshold" "Flee should derive its minimum path speed from the base run threshold"
Assert-Contains $behaviors "FleeKeepFullSpeed" "Flee should allow mobs to keep their full run speed through corner control"

Assert-Contains $sheep "RunSpeed\s*=\s*100" "Sheep flee run speed should be tuned to 100u/s"
Assert-Contains $sheep "FleeKeepFullSpeed\s*=\s*true" "Sheep flee should not expose 81/90-style target speed shifts in the HUD"
Assert-Contains $sheep "FleeDurationMin\s*=\s*3\.5" "Sheep flee should last longer than the old 2s MC window in GMod tuning"
Assert-Contains $sheep "FleeDurationMax\s*=\s*5\.0" "Sheep flee max duration should be tuned to 5s"
Assert-Contains $sheep "FleeDurationMax or 5\.0" "Sheep injury refresh fallback should match the tuned 5s max window"

Assert-Contains $claude "BMBActivitySpeed" "CLAUDE.md should document intent speed vs transient loco command speed"
Assert-Contains $state "Flee" "STATE.md should record the flee speed stability fix"

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Host "ERROR: $_" }
    exit 1
}

Write-Host "Flee speed stability checks passed."
