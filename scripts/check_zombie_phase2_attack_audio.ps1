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
$zombie = "gmod_addon\lua\entities\bmb_zombie.lua"
$behaviors = "gmod_addon\lua\bmb\sv_behaviors.lua"
$state = "docs\STATE.md"
$claude = "CLAUDE.md"
$plan = ".planning\mcgm-main\task_plan.md"

Assert-Contains $zombie "AttackCooldown\s*=\s*1\.0" "Phase 2 zombie should attack every 1.0s"
Assert-Contains $zombie "AttackHitDelay\s*=\s*0" "Phase 2 zombie should resolve melee hits immediately on entering range"
Assert-Contains $zombie "AttackKnockback\s*=\s*240" "Zombie melee should knock the player backward without over-pulling horizontally"
Assert-Contains $zombie "AttackVerticalKnockback\s*=\s*155" "Zombie melee should give a small vertical lift"
Assert-Contains $zombie "AttackGroundedVerticalKnockback\s*=\s*190" "Zombie melee should cross Source's grounded-player lift threshold without over-launching"
Assert-Contains $zombie "AttackKnockbackCorrectionTicks\s*=\s*3" "Zombie melee should run a short multi-tick knockback correction window"
Assert-Contains $zombie "AttackKnockbackSeparationDistance\s*=\s*6" "Zombie melee should use a tiny safe player separation nudge before knockback"
Assert-Contains $zombie "HitViewPunchPitch" "Zombie melee should give the hit player a mild view punch"
Assert-Contains $zombie "util\.ScreenShake" "Zombie melee should add a small screen shake on actual player hit"
Assert-Contains $zombie "target:EmitSound\(randomSound\(self\.Sounds\.Hit\)" "A successful zombie hit should play a player hurt sound"

Assert-Contains $behaviors "function\s+BMB\.Behaviors\.MeleeAttack\.ResolveHit" "Shared melee should keep damage/knockback/hit-sound in one hit resolver"
Assert-Contains $behaviors "hitDelay\s*<=\s*0" "Shared melee should support instant hit resolution"
Assert-Contains $behaviors "timer\.Simple\(hitDelay,\s*resolveHit\)" "Shared melee should still support delayed windup attacks for future mobs"
Assert-Contains $behaviors "AttackGroundedVerticalKnockback" "Melee knockback should support a separate grounded-player vertical launch threshold"
Assert-Contains $behaviors "target:SetGroundEntity\(NULL\)" "Melee knockback should detach grounded players before applying vertical lift"
Assert-Contains $behaviors "timer\.Simple\(\(i\s*-\s*1\)\s*\*\s*correctionInterval" "Melee knockback should schedule retries across a short correction window"
Assert-Contains $behaviors "correctKnockback\(i\)" "Melee knockback correction should log/use the retry attempt number"
Assert-Contains $behaviors "target:SetVelocity\(direction\s*\*\s*horizontal\s*\+\s*Vector\(0,\s*0,\s*launchVertical\)\)" "Melee knockback should include horizontal and vertical launch velocity"
Assert-Contains $behaviors "BMBLastMeleeDirection" "Melee knockback should cache a stable chase/attack direction for point-blank overlap hits"
Assert-Contains $behaviors "function\s+BMB\.Behaviors\.MeleeAttack\.GetTargetKnockbackDirection" "Melee knockback should resolve direction through a shared stable helper"
Assert-Contains $behaviors "bmb_debug_melee_knockback" "Melee knockback should expose an opt-in diagnostic log cvar"
Assert-Contains $behaviors "function\s+BMB\.Behaviors\.MeleeAttack\.NudgeTargetForKnockback" "Melee knockback should nudge deeply overlapping players before applying impulse"
Assert-Contains $behaviors "target:SetPos\(targetPos\)" "Melee knockback nudge should move the player only after a trace confirms the destination"
Assert-Contains $behaviors "AttackKnockbackCorrectionTicks" "Melee knockback should support a short multi-tick correction window for grounded players"
Assert-Contains $behaviors "for\s+i\s*=\s*1,\s*correctionTicks" "Melee knockback should retry missing impulse over a few ticks, not just the same tick"
Assert-Contains $behaviors "missingHorizontal" "Melee knockback should top up only missing horizontal push when Source ground/overlap eats it"
Assert-Contains $behaviors "missingLift" "Melee knockback should top up missing vertical lift when Source ground movement eats it"
Assert-Contains $behaviors "mob:GetForward\(\)" "Melee knockback should still have a forward fallback when no cached direction exists"
Assert-Contains $behaviors "function\s+BMB\.Behaviors\.Chase\.ApplySafePressure" "Direct zombie pressure should share cliff-safe steering"
Assert-Contains $behaviors "function\s+BMB\.Behaviors\.Chase\.IsSteerTargetSafe" "Direct zombie pressure should check the actual steering target for cliffs"
Assert-Contains $behaviors "_cliff" "Unsafe direct pressure should expose a cliff-blocked HUD mode instead of walking off edges"
Assert-Contains $base "function\s+ENT:IsBMBGridMovementTargetSafe" "Direct safety should include BMB grid support checks for MC block cliffs"
Assert-Contains $base "function\s+ENT:HasBMBGridBlockSupportAt" "Grid cliff safety should only activate on/near MC block support, not pure prop support"
Assert-Contains $base "function\s+ENT:IsMovementTargetSafe[\s\S]*IsBMBGridMovementTargetSafe\(forwardTarget,\s*probe\)" "IsMovementTargetSafe should run MC grid cliff checks after Source trace checks"
Assert-Contains $zombie "chase_repath" "Zombie should keep the repath pressure mode"
Assert-Contains $zombie "ApplySafePressure" "Zombie chase_repath should use cliff-safe pressure instead of raw direct steering"
Assert-NotContains $zombie "SteerTowards\(self\.TargetEntity:GetPos\(\)\)" "Zombie chase_repath must not bypass cliff safety with raw target steering"

Assert-Contains $zombie "AmbientSoundIntervalTicks\s*=\s*80" "Zombie ambient should use MC Mob#getAmbientSoundInterval = 80 ticks"
Assert-Contains $zombie "AmbientSoundChanceDenominator\s*=\s*1000" "Zombie ambient should use MC random.nextInt(1000) probability gate"
Assert-Contains $zombie "BMBNextAmbientSoundTickAt" "Zombie ambient should advance on a simulated 20Hz tick, not behavior loop timing"
Assert-Contains $zombie "self\.BMBAmbientSoundTime\s*=\s*-\(self\.AmbientSoundIntervalTicks" "Zombie ambient reset should mirror MC's negative interval reset"
Assert-Contains $base "self\.MaybePlayIdleSound" "Base Think should call optional ambient sound hooks so sounds play in any state"
Assert-NotContains $zombie "NextIdleSoundTime" "Zombie ambient should no longer use fixed random seconds from the behavior coroutine"
Assert-NotContains $zombie "math\.Rand\(5\.0,\s*12\.0\)" "Zombie ambient should not use the legacy fixed 5-12s interval"

Assert-Contains $state "Phase 2" "STATE.md should record Zombie Phase 2 attack/audio work"
Assert-Contains $claude "80 tick" "CLAUDE.md should document the MC ambient sound interval source"
Assert-Contains $plan "Phase 2" "task plan should track Zombie Phase 2"

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Host "ERROR: $_" }
    exit 1
}

Write-Host "Zombie phase 2 attack/audio checks passed."
