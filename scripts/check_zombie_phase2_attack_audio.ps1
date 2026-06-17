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
$autorun = "gmod_addon\lua\autorun\bmb_autorun.lua"
$state = "docs\STATE.md"
$claude = "CLAUDE.md"
$plan = ".planning\mcgm-main\task_plan.md"

Assert-Contains $zombie "TargetRange\s*=\s*1350" "Zombie should acquire players at the 1.5x tuned range"
Assert-Contains $zombie "TargetLoseRange\s*=\s*1725" "Zombie should keep targets proportionally farther after acquiring them"
Assert-Contains $zombie "AttackRange\s*=\s*60" "Zombie melee should have a slightly wider same-level attack range"
Assert-Contains $zombie "AttackCooldown\s*=\s*1\.0" "Phase 2 zombie should attack every 1.0s"
Assert-Contains $zombie "AttackHitDelay\s*=\s*0" "Phase 2 zombie should resolve melee hits immediately on entering range"
Assert-Contains $zombie "AttackKnockback\s*=\s*150" "Zombie melee should knock the player backward without over-pulling horizontally"
Assert-Contains $zombie "AttackVerticalKnockback\s*=\s*155" "Zombie melee should give a small vertical lift"
Assert-Contains $zombie "AttackGroundedVerticalKnockback\s*=\s*190" "Zombie melee should cross Source's grounded-player lift threshold without over-launching"
Assert-Contains $zombie "KnockbackUseJump\s*=\s*false" "Zombie hurt knockback should not open locomotion jump state while chasing on MC blocks"
Assert-Contains $zombie "KnockbackVerticalMaxSpeed\s*=\s*0" "Zombie hurt knockback should stay horizontal; melee player knockback remains separate"
Assert-Contains $zombie "AttackVerticalOverlapRange\s*=\s*86" "Zombie should still hit a player standing directly on its head"
Assert-Contains $zombie "AttackVerticalOverlapFlatRange\s*=\s*24" "Head-overlap melee should stay narrow so high platforms still use chase/pathing"
Assert-NotContains $zombie "AttackKnockbackCorrectionTicks" "Zombie melee should no longer use multi-tick knockback correction"
Assert-NotContains $zombie "AttackKnockbackSeparationDistance" "Zombie melee should no longer rely on point-blank SetPos nudge"
Assert-Contains $zombie "HitViewPunchPitch" "Zombie melee should give the hit player a mild view punch"
Assert-Contains $zombie "util\.ScreenShake" "Zombie melee should add a small screen shake on actual player hit"
Assert-Contains $zombie "target:EmitSound\(soundName,\s*74" "A successful zombie hit should play a player hurt sound"
Assert-Contains $zombie "bmb/mob/zombie/say1\.ogg" "Zombie ambient should use unpacked Minecraft zombie say sounds"
Assert-Contains $zombie "bmb/mob/zombie/hurt1\.ogg" "Zombie hurt should use unpacked Minecraft zombie hurt sounds"
Assert-Contains $zombie "bmb/mob/zombie/death\.ogg" "Zombie death should use unpacked Minecraft zombie death sound"
Assert-Contains $zombie "bmb/mob/zombie/step1\.ogg" "Zombie footsteps should use unpacked Minecraft zombie step sounds"
Assert-Contains $zombie "bmb/damage/hit1\.ogg" "Zombie melee hit feedback should use Minecraft player damage sounds"
Assert-Contains $zombie "function\s+ENT:UpdateBMBZombieStepSound" "Zombie footsteps should be distance-driven like sheep"
Assert-Contains $zombie "speed \* FrameTime\(\)" "Zombie step timing should accumulate traveled distance, not elapsed time"
Assert-Contains $zombie "function\s+ENT:MaybePlayStep\(\)" "Zombie should override Base's timer-driven step placeholder"
Assert-Contains $zombie "OnBMBHurtSound[\s\S]*self:Health\(\)\s*<=\s*\(damageInfo:GetDamage\(\)" "Zombie should skip hurt sound on lethal hits so death does not stack with hurt"
Assert-NotContains $zombie "npc/zombie/" "Zombie should not use Source default zombie sounds after MC sound import"
Assert-NotContains $zombie "player/pl_pain" "Zombie should not use Source default player pain sounds after MC damage import"
Assert-Contains $autorun "sound/bmb/mob/zombie/say1\.ogg" "Autorun should register zombie say resources for clients"
Assert-Contains $autorun "sound/bmb/mob/zombie/step1\.ogg" "Autorun should register zombie step resources for clients"
Assert-Contains $autorun "sound/bmb/damage/hit1\.ogg" "Autorun should register player damage hit resources for clients"

Assert-Contains $behaviors "function\s+BMB\.Behaviors\.MeleeAttack\.ResolveHit" "Shared melee should keep damage/knockback/hit-sound in one hit resolver"
Assert-Contains $behaviors "AttackVerticalOverlapRange" "Shared melee should support narrow vertical-overlap hits without widening normal vertical range"
Assert-Contains $behaviors "AttackVerticalOverlapFlatRange" "Vertical-overlap melee should require tight horizontal overlap"
Assert-Contains $behaviors "hitDelay\s*<=\s*0" "Shared melee should support instant hit resolution"
Assert-Contains $behaviors "timer\.Simple\(hitDelay,\s*resolveHit\)" "Shared melee should still support delayed windup attacks for future mobs"
Assert-Contains $behaviors "AttackGroundedVerticalKnockback" "Melee knockback should support a separate grounded-player vertical launch threshold"
Assert-Contains $behaviors "target:SetGroundEntity\(NULL\)" "Melee knockback should detach grounded players before applying vertical lift"
Assert-Contains $behaviors "target:SetVelocity\(-velocityBefore\)" "Player melee knockback should cancel residual velocity because Player:SetVelocity is additive"
Assert-Contains $behaviors "target:SetVelocity\(desiredVelocity\)" "Player melee knockback should apply one deterministic desired launch velocity"
Assert-Contains $behaviors "desiredVelocity\s*=\s*direction\s*\*\s*horizontal\s*\+\s*Vector\(0,\s*0,\s*launchVertical\)" "Melee knockback should include horizontal and vertical launch velocity"
Assert-Contains $behaviors "BMBLastMeleeDirection" "Melee knockback should cache a stable chase/attack direction for point-blank overlap hits"
Assert-Contains $behaviors "function\s+BMB\.Behaviors\.MeleeAttack\.GetTargetKnockbackDirection" "Melee knockback should resolve direction through a shared stable helper"
Assert-Contains $behaviors "MIN_VALID_DIRECTION_SQR" "Melee knockback direction validation should use epsilon, not unit-vector length thresholds"
Assert-NotContains $behaviors "direction:LengthSqr\(\)\s*<=\s*1\s*then\s*return" "Melee knockback must not reject normalized unit directions"
Assert-NotContains $behaviors "direction:LengthSqr\(\)\s*>\s*1\s*then\s*[\s\S]*return direction" "Melee direction fallback must accept normalized cached/forward directions"
Assert-Contains $behaviors "bmb_debug_melee_knockback" "Melee knockback should expose an opt-in diagnostic log cvar"
Assert-Contains $behaviors "bmb_melee_knockback_debug" "Melee knockback should expose a user-friendly debug toggle command"
Assert-Contains $behaviors "function\s+logMeleeDebug" "Melee debug should log attack try/resolve stages, not only velocity application"
Assert-Contains $behaviors "range_blocked" "Melee debug should show when attack attempts are outside range"
Assert-Contains $behaviors "cooldown" "Melee debug should show when attack attempts are on cooldown"
Assert-Contains $behaviors 'logMeleeDebug\(mob,\s*target,\s*"resolve",\s*"hit"' "Melee debug should show when a hit actually resolves"
Assert-Contains $behaviors 'logMeleeDebug\(mob,\s*target,\s*"resolve",\s*"range_fail"' "Melee debug should show when a swing no longer resolves at hit time"
Assert-NotContains $behaviors "function\s+BMB\.Behaviors\.MeleeAttack\.NudgeTargetForKnockback" "Melee knockback should not use SetPos nudge for player launch"
Assert-NotContains $behaviors "target:SetPos\(targetPos\)" "Melee knockback should not teleport/nudge the player"
Assert-NotContains $behaviors "AttackKnockbackCorrectionTicks" "Melee knockback should not use stale multi-tick correction"
Assert-NotContains $behaviors "for\s+i\s*=\s*1,\s*correctionTicks" "Melee knockback should not retry velocity over several ticks"
Assert-NotContains $behaviors "missingHorizontal" "Melee knockback should not top up horizontal push through correction ticks"
Assert-NotContains $behaviors "missingLift" "Melee knockback should not top up vertical lift through correction ticks"
Assert-Contains $behaviors "mob:GetForward\(\)" "Melee knockback should still have a forward fallback when no cached direction exists"
Assert-Contains $behaviors "function\s+BMB\.Behaviors\.Chase\.ApplySafePressure" "Direct zombie pressure should share cliff-safe steering"
Assert-Contains $behaviors "function\s+BMB\.Behaviors\.Chase\.IsSteerTargetSafe" "Direct zombie pressure should check the actual steering target for cliffs"
Assert-Contains $behaviors "_cliff" "Unsafe direct pressure should expose a cliff-blocked HUD mode instead of walking off edges"
Assert-Contains $base "function\s+ENT:IsBMBGridMovementTargetSafe" "Direct safety should include BMB grid support checks for MC block cliffs"
Assert-Contains $base "function\s+ENT:HasBMBGridBlockSupportAt" "Grid cliff safety should only activate on/near MC block support, not pure prop support"
Assert-Contains $base "function\s+ENT:GetBMBGridFootSample" "Grid safety should sample a lifted foot point to avoid top-face WorldToBlock false cliffs"
Assert-Contains $base "IsBMBGridFootHullClear\(sample\)" "Grid safety hull checks should use the lifted foot sample, not the exact ground boundary"
Assert-Contains $base "IsBMBGridFootStandable\(sample" "Grid safety standable checks should use the lifted foot sample, not the exact ground boundary"
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
