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

function Assert-FunctionNotContains([string]$relativePath, [string]$functionName, [string]$pattern, [string]$message) {
    $text = Read-Text $relativePath
    $escapedName = [regex]::Escape($functionName)
    $match = [regex]::Match($text, "function\s+ENT:$escapedName\s*\([^)]*\)(?s:.*?)(?=\r?\nfunction\s+ENT:|\z)")

    if (-not $match.Success) {
        Add-Failure("${relativePath}: missing function ENT:$functionName")
        return
    }

    if ($match.Value -match $pattern) {
        Add-Failure("${relativePath}: $message")
    }
}

$base = "gmod_addon\lua\entities\bmb_base_mob.lua"
$behaviors = "gmod_addon\lua\bmb\sv_behaviors.lua"
$sheep = "gmod_addon\lua\entities\bmb_sheep.lua"
$state = "docs\STATE.md"
$claude = "CLAUDE.md"
$plan = ".planning\mcgm-main\task_plan.md"

Assert-Contains $base "DamageInvulnerabilityTime\s*=\s*0\.5" "base mob should use MC's effective 10 tick damage cooldown window"
Assert-Contains $base "HurtFlashTime\s*=\s*0\.5" "base mob should use MC's 10 tick hurt flash window"
Assert-Contains $base "BMBHurtFlashUntil" "accepted damage should network a hurt flash deadline for client red tint"
Assert-Contains $base "function\s+ENT:IsBMBInDamageInvulnerability" "damage pipeline should have one helper for invulnerability checks"
Assert-Contains $base "function\s+ENT:StartBMBHurtFlash" "damage pipeline should start the visual hurt flash only on accepted hits"
Assert-Contains $base "function\s+ENT:GetBMBKnockbackDirection" "knockback direction should be derived from attacker/source/force, not facing"
Assert-Contains $base "KnockbackDuration\s*=\s*0\.12" "knockback should be a short impulse arbitration window so flee can resume while airborne"
Assert-Contains $base "KnockbackVerticalSpeedScale" "knockback should include a small MC-like upward lift"
Assert-Contains $base "function\s+ENT:GetBMBKnockbackVerticalVelocity" "vertical knockback should be centralized and clamped"
Assert-Contains $base "function\s+ENT:StartBMBKnockback" "accepted non-physics hits should enter a first-class knockback state"
Assert-Contains $base "function\s+ENT:RunBMBKnockback" "behavior scheduler should have a dedicated knockback runner"
Assert-Contains $base "function\s+ENT:IsBMBKnockbackActive" "movement entry points should be able to yield while knockback owns velocity"
Assert-Contains $base "BMBKnockbackVelocity" "knockback should reset to a capped velocity instead of stacking"
Assert-Contains $base "BMBKnockbackVerticalSpeed" "accepted grounded hits should store an upward lift for the immediate impulse"
Assert-Contains $base "BMBKnockbackDesiredSpeed" "knockback should preserve a non-zero desired speed budget instead of writing BMBDesiredSpeed to 0"
Assert-Contains $base "self\.loco:Jump\(\)" "grounded knockback should open the locomotion jump state before applying vertical lift"
Assert-Contains $base 'SetBMBMoveMode\("knockback"\)' "knockback should publish a visible move mode"
Assert-Contains $base 'SetBMBState\("knockback"\)' "knockback should publish a visible state"
Assert-Contains $base "self:IsBMBKnockbackActive\(\)" "normal movement should refuse new steering while knockback is active"
Assert-Contains $base "DMG_CRUSH" "physics impact damage should remain identifiable so BMB knockback can avoid overriding prop/physics feel"
Assert-Contains $base "return\s+0\s*--\s*invulnerable" "ignored invulnerability hits should not deal damage, flee-refresh, or knock back"
Assert-NotContains $base "DMG_FALL" "fall damage is a later task and should not be implemented in this pass"
Assert-FunctionNotContains $base "StartBMBHurtFlash" "loco|Velocity|DesiredSpeed|MaintainBMBMoveSpeed|BMBDesiredSpeed" "hurt flash must be a pure visual/network effect and must not touch movement"
Assert-FunctionNotContains $base "RunBMBKnockback" "MaintainBMBMoveSpeed\s*\(\s*0" "knockback must not publish BMBDesiredSpeed=0; that freezes movement and can swallow SetVelocity knockback"
Assert-FunctionNotContains $base "RunBMBKnockback" "SetDesiredSpeed\s*\(\s*0" "knockback must not set loco desired speed to 0 while trying to apply horizontal knockback"

Assert-Contains $sheep "RunBMBKnockback" "sheep behavior should prioritize knockback before debug/stranded/flee steering"
Assert-Contains $sheep "wasFleeing" "sheep injury handling should know whether the current hit happened during an active flee"
Assert-Contains $sheep "not\s+wasFleeing" "hits during an active flee should refresh panic time without interrupting the current flee segment"
Assert-Contains $behaviors "airborneStart" "Flee should detect airborne starts after knockback"
Assert-Contains $behaviors "allowStrandedStart\s*=\s*airborneStart" "Flee should keep trying to path while airborne after knockback"

Assert-Contains $claude "hurtTime = 10 ticks" "CLAUDE.md should document the MC hurt flash timing"
Assert-Contains $claude "invulnerableTime > 10" "CLAUDE.md should document the MC effective damage cooldown timing"
Assert-Contains $state "hurtTime = 10 ticks" "STATE.md should record the hurt flash / invulnerability / knockback behavior"
Assert-Contains $plan "fall damage" "planning docs should record fall damage as pending, not done"

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Host "ERROR: $_" }
    exit 1
}

Write-Host "Damage invulnerability, hurt flash, knockback, and flee rehit checks passed."
