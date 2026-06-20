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

$behaviors = "gmod_addon\lua\bmb\sv_behaviors.lua"
$baseMob = "gmod_addon\lua\entities\bmb_base_mob.lua"
$sheep = "gmod_addon\lua\entities\bmb_sheep.lua"
$zombie = "gmod_addon\lua\entities\bmb_zombie.lua"
$skeleton = "gmod_addon\lua\entities\bmb_skeleton.lua"

Assert-Contains $behaviors "FL_NOTARGET" "SeekTarget must respect player notarget flags"
Assert-Contains $baseMob "FL_NOTARGET" "Base combat target validation must respect player notarget flags"

Assert-Contains $baseMob 'CreateConVar\("' "BaseMob must create server convars"
Assert-Contains $baseMob "bmb_freeze" "BaseMob must expose bmb_freeze for screenshot posing"
Assert-Contains $baseMob "function\s+ENT:MaintainBMBFreeze\s*\(" "BaseMob must own the common freeze maintenance helper"
Assert-Contains $baseMob "self:InterruptBMBMovement\(\)" "Freeze must interrupt active path/move coroutines"
Assert-Contains $baseMob "self:ClearBMBLookAtTarget\(\)" "Freeze must stop look-at motion while posing"
Assert-Contains $baseMob 'self:SetBMBState\("' "Freeze must publish a stable state/mode"
Assert-Contains $baseMob "self:MaintainBMBFreeze\(\)" "Base Think must maintain freeze every tick"

Assert-Contains $sheep "MaintainBMBFreeze" "Sheep RunBehaviour must stop behavior while bmb_freeze is enabled"
Assert-Contains $zombie "MaintainBMBFreeze" "Zombie RunBehaviour must stop behavior while bmb_freeze is enabled"
Assert-Contains $skeleton "MaintainBMBFreeze" "Skeleton RunBehaviour must stop behavior while bmb_freeze is enabled"

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Host "ERROR: $_" }
    exit 1
}

Write-Host "Notarget/freeze checks passed."
