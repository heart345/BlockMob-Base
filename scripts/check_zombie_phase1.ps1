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

function Assert-Missing([string]$relativePath, [string]$message) {
    $path = Join-Path $Root $relativePath
    if (Test-Path -LiteralPath $path) {
        Add-Failure("${relativePath}: $message")
    }
}

$zombie = "gmod_addon\lua\entities\bmb_zombie.lua"
$base = "gmod_addon\lua\entities\bmb_base_mob.lua"
$behaviors = "gmod_addon\lua\bmb\sv_behaviors.lua"
$autorun = "gmod_addon\lua\autorun\mcgm_autorun.lua"
$state = "docs\STATE.md"
$claude = "CLAUDE.md"
$plan = ".planning\mcgm-main\task_plan.md"

Assert-Contains $zombie 'ENT\.Base\s*=\s*"bmb_base_mob"' "new zombie must inherit BMB base, not the legacy base_nextbot prototype"
Assert-Contains $zombie 'ENT\.PrintName\s*=\s*"BMB Zombie"' "new zombie should expose the release spawn name"
Assert-Contains $zombie "TargetRange" "zombie should define target acquisition range"
Assert-Contains $zombie "AttackRange" "zombie should define melee range"
Assert-Contains $zombie "AttackRange\s*=\s*60" "zombie melee range should be slightly longer than the legacy贴脸 38u value"
Assert-Contains $zombie "AttackVerticalRange\s*=\s*28" "zombie melee should have a separate vertical range so one-block height differences keep chasing instead of attack_ready"
Assert-Contains $zombie "AttackDamage" "zombie should define melee damage"
Assert-Contains $zombie "AttackCooldown\s*=\s*1\.0" "zombie melee cooldown should match the Phase 2 1.0s attack interval"
Assert-Contains $zombie "AttackHitDelay\s*=\s*0" "zombie should hit immediately on entering attack range"
Assert-Contains $zombie "AttackMoveSpeed" "zombie should keep forward pressure while attacking instead of freezing at 0 speed"
Assert-Contains $zombie "AttackKnockback\s*=\s*150" "zombie melee should knock the player backward without over-pulling horizontally"
Assert-Contains $zombie "AttackVerticalKnockback\s*=\s*155" "zombie melee should give the player a small lift"
Assert-Contains $zombie "AmbientSoundIntervalTicks\s*=\s*80" "zombie ambient sound should use MC Mob#getAmbientSoundInterval"
Assert-Contains $zombie "AmbientSoundChanceDenominator\s*=\s*1000" "zombie ambient sound should use MC's random.nextInt(1000) gate"
Assert-Contains $zombie "ResetBMBAmbientSoundTime" "zombie ambient sound should reset to -interval like MC Mob"
Assert-Contains $zombie "ChaseSegmentTimeout\s*=\s*2\.0" "zombie chase should have enough time to advance before replanning"
Assert-Contains $zombie "ChaseFailureRepathDelay\s*=\s*0\.05" "failed chase replans should not look like idle pauses"
Assert-Contains $zombie "ChasePreferDirect\s*=\s*true" "zombie should prefer MC-style direct line-of-sight chase before A*"
Assert-Contains $zombie "ChaseDirectDuration\s*=\s*0\.28" "direct chase should run in short refreshed segments instead of long stale paths"
Assert-Contains $zombie "ChaseDirectProbeCells\s*=\s*4" "direct chase should still use forward safety probing"
Assert-Contains $zombie "ChaseHighTargetHoldCells\s*=\s*1\.65" "high unreachable targets should be held under instead of clearing the chase"
Assert-Contains $zombie "ChaseHighTargetStalkDelay\s*=\s*0\.12" "high target stalking should repoll quickly without visible idle gaps"
Assert-Contains $zombie 'ENT\.Model\s*=\s*"models/mcgm/zombie/zombie\.mdl"' "zombie should use the converted MC model, not Valve Classic.mdl"
Assert-Contains $zombie "function ENT:UpdateBMBVisualBones" "zombie locomotion/death/attack should be procedural client bone animation like sheep"
Assert-Contains $zombie "ApplyBMBBipedLocomotion" "zombie walk should be procedural biped (legs counter-swing + arm forward swing), not a model sequence"
Assert-Contains $zombie "BMBAttackStartedAt" "zombie attack should be a procedural arm-swing keyframe driven by a networked attack timestamp"
Assert-NotContains $zombie "RunActivity\s*=\s*ACT_WALK" "zombie no longer uses ACT_WALK; locomotion is procedural via UpdateBMBVisualBones"
Assert-NotContains $zombie "Classic\.mdl" "zombie should not fall back to Valve Classic.mdl"
Assert-NotContains $zombie "RestartGesture" "zombie attack should be procedural keyframes, not a model gesture"
Assert-Contains $zombie "TurnInPlaceAngle\s*=\s*170" "zombie chase should not stop for ordinary path-carrot heading changes"
Assert-Contains $zombie "BlockHopAllowCloseLaunch\s*=\s*true" "zombie should use close-lift hop fallback in cramped stair/ledge approaches"
Assert-Contains $zombie "BMB\.Behaviors\.SeekTarget" "zombie state machine should use the shared target selector"
Assert-Contains $zombie "BMB\.Behaviors\.Chase" "zombie state machine should use the shared chase behavior"
Assert-Contains $zombie "BMB\.Behaviors\.MeleeAttack" "zombie state machine should use the shared melee behavior"
Assert-Contains $zombie "RunBMBKnockback" "zombie should respect base knockback priority before normal hostile steering"
Assert-Contains $zombie "RunBMBDebugMove" "debug movement should still override hostile AI for testing"
Assert-Contains $zombie "RunBMBStrandedRecovery" "stranded recovery should still override hostile AI"
Assert-Contains $base "function\s+ENT:TryBMBRetaliate" "retaliation should live in BaseMob instead of zombie-only injury code"
Assert-Contains $base "TryBMBRetaliate\(damageInfo\)" "accepted damage should ask BaseMob to retarget valid attackers"
Assert-Contains $zombie "TargetEntity" "zombie should keep target state in the entity state machine"
Assert-Contains $zombie "MeleeAttack\.Try" "zombie attack should go through the reusable melee module"
Assert-Contains $zombie "chase_repath" "failed chase segments should keep target and replan shortly instead of dropping to idle/wander"
Assert-Contains $zombie "StalkHighTarget" "failed high-target chase should keep stalking beneath the player instead of steering into a zero vector"
Assert-Contains $zombie "ApplySafePressure" "chase_repath should keep pressure through shared cliff-safe steering instead of standing still or walking off edges"

Assert-NotContains $zombie 'Path\("Follow"\)' "new zombie should use BMB block A*, not the old Source PathFollower loop"
Assert-NotContains $zombie "navmesh" "new zombie should not depend on GMod navmesh"
Assert-NotContains $zombie "SetAngles" "new zombie should not hand-drive angles; BaseMob FaceTarget uses loco"
Assert-NotContains $zombie "BMBMeleeLockUntil" "zombie should not hard-stop during attack windup; MC-style mobs keep pressure while swinging"

Assert-Contains $behaviors "BMB\.Behaviors\.SeekTarget" "shared hostile target selector should exist"
Assert-Contains $behaviors "BMB\.Behaviors\.Chase" "shared hostile chase behavior should exist"
Assert-Contains $behaviors "BMB\.Behaviors\.MeleeAttack" "shared melee attack behavior should exist"
Assert-Contains $behaviors "function\s+BMB\.Behaviors\.SeekTarget\.Find" "target selector should expose Find"
Assert-Contains $behaviors "function\s+BMB\.Behaviors\.Chase\.Run" "chase behavior should expose Run"
Assert-Contains $behaviors "function\s+BMB\.Behaviors\.Chase\.CanDirect" "chase should expose a line-of-sight direct pressure gate"
Assert-Contains $behaviors "function\s+BMB\.Behaviors\.Chase\.RunDirect" "chase should run direct pursuit on visible open ground"
Assert-Contains $behaviors "function\s+BMB\.Behaviors\.Chase\.ApplySafePressure" "direct chase/attack pressure should share cliff-safe steering"
Assert-Contains $behaviors "function\s+BMB\.Behaviors\.Chase\.IsSteerTargetSafe" "direct pressure should re-check movement safety on the actual steering target"
Assert-Contains $behaviors "function\s+BMB\.Behaviors\.Chase\.StalkHighTarget" "chase should keep high unreachable targets instead of dropping them"
Assert-Contains $behaviors "function\s+BMB\.Behaviors\.MeleeAttack\.Try" "melee behavior should expose Try"
Assert-Contains $behaviors "function\s+BMB\.Behaviors\.MeleeAttack\.ResolveHit" "melee behavior should allow immediate hit resolution without duplicating damage code"
Assert-Contains $behaviors "AttackVerticalRange" "melee behavior should check vertical attack range separately from horizontal range"
Assert-Contains $behaviors "MeleeAttack\.IsInRange\(mob,\s*target\)" "chase should use melee range semantics for attack_ready, including vertical range"
Assert-Contains $behaviors "ChaseSegmentTimeout" "chase should have a segment timeout separate from the scan/repath interval"
Assert-Contains $behaviors "AttackMoveSpeed" "melee behavior should preserve movement budget while attacking"
Assert-Contains $behaviors "MaintainBMBMoveSpeed\(attackMoveSpeed" "melee attack should keep forward pressure with attackMoveSpeed"
Assert-Contains $behaviors 'ApplySafePressure\(mob,\s*target,\s*attackMoveSpeed,\s*"attack_ready"' "attack_ready should keep pressure through cliff-safe steering instead of direct target steering"
Assert-Contains $behaviors "chase_direct" "open line-of-sight chase should publish chase_direct mode"
Assert-Contains $behaviors "chase_stalk" "unreachable high targets should publish chase_stalk mode"
Assert-Contains $behaviors "Visible\(target\)" "direct chase should require line of sight so mazes still use BMB A*"
Assert-Contains $behaviors "IsMovementTargetSafe\(probeTarget,\s*probe\)" "direct chase should keep wall/cliff safety before bypassing A*"
Assert-Contains $behaviors "MoveToWorldPosition" "chase should use BMB movement/pathing"
Assert-Contains $behaviors "skipSourcePath\s*=\s*true" "chase should prefer BMB block-grid A*"
Assert-Contains $behaviors "DamageInfo" "melee attack should apply real GMod damage"
Assert-Contains $behaviors "SetAttacker\(mob\)" "melee damage should attribute the mob as attacker"
Assert-Contains $behaviors "SetInflictor\(mob\)" "melee damage should attribute the mob as inflictor"
Assert-Contains $behaviors "SetDamageType" "melee attack should set a damage type"
Assert-Contains $behaviors "timer\.Simple" "melee attack should support a windup/hit delay"
Assert-Contains $behaviors "hitDelay\s*<=\s*0" "melee attack should support instant hits for Phase 2 zombie"
Assert-Contains $behaviors "NextMeleeAttackTime" "melee attack should enforce cooldown"
Assert-NotContains $behaviors "BMBMeleeLockUntil" "melee attack should not install a hard movement lock"

Assert-Contains $autorun 'list\.Set\("NPC",\s*"bmb_zombie"' "spawn menu should register the new BMB zombie"
Assert-Contains $autorun 'Class\s*=\s*"bmb_zombie"' "spawn menu should point at bmb_zombie"
Assert-NotContains $autorun "mcgm_zombie" "legacy mcgm_zombie must not be registered for release"
Assert-NotContains $autorun "Minecraft in GMod" "legacy Minecraft in GMod category must not be registered for release"

Assert-Missing "gmod_addon\lua\entities\mcgm_zombie.lua" "legacy navmesh prototype should be removed for release"
Assert-Contains $state "Zombie" "STATE.md should record the zombie migration status"
Assert-Contains $claude "SeekTarget / Chase" "CLAUDE.md should continue documenting hostile shared behavior modules"
Assert-Contains $plan "Phase 3: Zombie" "task plan should track the zombie migration phase"

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Host "ERROR: $_" }
    exit 1
}

Write-Host "Zombie phase 1 architecture checks passed."
