$ErrorActionPreference = "Stop"

function Assert-Contains([string]$relativePath, [string]$pattern, [string]$message) {
    $path = Join-Path (Get-Location) $relativePath
    $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    if ($text -notmatch $pattern) {
        throw "ERROR: ${relativePath}: ${message}"
    }
}

function Assert-NotContains([string]$relativePath, [string]$pattern, [string]$message) {
    $path = Join-Path (Get-Location) $relativePath
    $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    if ($text -match $pattern) {
        throw "ERROR: ${relativePath}: ${message}"
    }
}

$spider = "gmod_addon\lua\entities\bmb_spider.lua"
$menu = "gmod_addon\lua\autorun\mcgm_autorun.lua"

Assert-Contains $spider 'ENT\.Base\s*=\s*"bmb_base_mob"' "Spider Phase 0 must be a real BMB NextBot."
Assert-Contains $spider 'ENT\.Type\s*=\s*"nextbot"' "Spider should spawn as a NextBot."
Assert-Contains $spider 'ENT\.Model\s*=\s*"models/mcgm/spider/spider\.mdl"' "Spider must reference the converted MC spider model path."
Assert-Contains $spider 'ENT\.Spawnable\s*=\s*true' "Spider should be spawnable for Phase 0 testing."
Assert-Contains $menu '"bmb_spider"' "Spider should be registered in the BlockMob Base spawnmenu category."

Assert-Contains $spider 'ENT\.CollisionMins\s*=\s*Vector\(-26,\s*-26,\s*0\)' "Spider collision mins should match the 1.4 block wide footprint."
Assert-Contains $spider 'ENT\.CollisionMaxs\s*=\s*Vector\(26,\s*26,\s*33\)' "Spider collision maxs should stay short enough for one-block-high gaps."
Assert-Contains $spider 'RetaliateOnDamage\s*=\s*false' "Spider Phase 0 should stay neutral ground wander only."

Assert-Contains $spider 'function ENT:RunBehaviour\(\)' "Spider should own a thin behavior scheduler."
Assert-Contains $spider 'MaintainBMBFreeze' "Spider should respect bmb_freeze for screenshots."
Assert-Contains $spider 'RunBMBDebugMove' "Spider should support the BMB debug movement tool."
Assert-Contains $spider 'RunBMBStrandedRecovery' "Spider should use base stranded recovery on invalid supports."
Assert-Contains $spider 'RunBMBInitialIdle' "Spider should idle briefly after spawn before wandering."
Assert-Contains $spider 'BMB\.Behaviors\.Wander\.Run\(self\)' "Spider Phase 0 should use shared Wander."

Assert-Contains $spider '(?s)"leg0".*"leg1".*"leg2".*"leg3".*"leg4".*"leg5".*"leg6".*"leg7"' "Spider visual cache should cover all eight legs."
Assert-Contains $spider 'AnimationSequences\s*=\s*\{(?s).*walk\s*=\s*"idle".*run\s*=\s*"idle"' "Spider should keep the baked walk sequence parked so Lua convars own leg motion."
Assert-Contains $spider 'bmb_spider_leg_animation",\s*"1"' "Spider procedural leg animation should default on after the MDL facing fix."
Assert-Contains $spider 'bmb_spider_leg_swing_max",\s*"10"' "Spider leg fore/aft swing should be tunable."
Assert-Contains $spider 'bmb_spider_leg_lift_max",\s*"3"' "Spider leg lift rotation should default to the user-requested small value and be tunable."
Assert-Contains $spider 'bmb_spider_leg_frequency",\s*"1"' "Spider gait frequency should be tunable and default to Minecraft-style base phase."
Assert-Contains $spider 'bmb_spider_leg_solo",\s*"0"' "Spider should expose a solo-leg debug convar for tuning one root bone at a time."
Assert-Contains $spider 'bmb_spider_leg_phase_a",\s*"0"' "Spider group A phase should default to 0 radians."
Assert-Contains $spider 'bmb_spider_leg_phase_b",\s*"3\.1416"' "Spider group B phase should default to PI radians."
Assert-Contains $spider 'bmb_spider_leg_phase_step",\s*"0\.7854"' "Spider should expose a front-to-back wave phase step convar defaulting to PI/4."
Assert-Contains $spider 'bmb_spider_leg_lift_phase",\s*"0"' "Spider lift should default to Minecraft's source phase."
Assert-Contains $spider 'bmb_spider_leg_swing_axis",\s*"2"' "Spider swing should default to the tested roll-axis control."
Assert-Contains $spider 'bmb_spider_leg_lift_axis",\s*"1"' "Spider lift should default to the tested yaw-axis control."
Assert-Contains $spider 'bmb_spider_leg_axis_test",\s*"0"' "Spider should expose a static axis probe for checking pitch/yaw/roll world motion."
Assert-Contains $spider 'bmb_spider_leg_axis_test_leg",\s*"8"' "Spider axis probe should default to the eighth solo-order leg for rear-leg debugging."
Assert-Contains $spider 'bmb_spider_leg_axis_test_angle",\s*"35"' "Spider axis probe angle should be tunable and large enough to read in game."
Assert-Contains $spider '(?s)spiderSoloLegNames\s*=\s*\{.*"leg[0-7]".*"leg[0-7]".*"leg[0-7]".*"leg[0-7]".*"leg[0-7]".*"leg[0-7]".*"leg[0-7]".*"leg[0-7]".*\}' "Spider solo-leg debug order should cover all eight leg root bones."
Assert-Contains $spider '(?s)spiderLegs\s*=\s*\{.*waveIndex\s*=\s*0.*waveIndex\s*=\s*1.*waveIndex\s*=\s*2.*waveIndex\s*=\s*3.*\}' "Spider gait should assign front-to-back wave indexes so legs do not open in two synchronized scissors."
Assert-Contains $spider 'local function updateAxisTest\(ent,\s*bones\)' "Spider should apply static axis probes before procedural animation."
Assert-Contains $spider 'bmb_spider_"\s*\.\.\s*legName\s*\.\.\s*"_group' "Spider should expose per-leg A/B group convars for in-game phase pairing tests."
Assert-Contains $spider '(?s)local legLiftOffsetDefaults\s*=\s*\{.*leg2\s*=\s*"20".*leg3\s*=\s*"20".*leg4\s*=\s*"-20".*leg5\s*=\s*"-20".*\}' "Spider should bake the latest tested lift offsets into the per-leg convar defaults."
Assert-Contains $spider 'local wavePhase\s*=\s*\(leg\.waveIndex or 0\) \* phaseStep' "Spider leg phase should add a tunable front-to-back wave phase."
Assert-Contains $spider 'local phaseOffset\s*=\s*\(group == 0 and phaseA or phaseB\) \+ wavePhase' "Spider leg phase should combine A/B diagonal phase with the front-to-back wave phase."
Assert-Contains $spider 'math\.cos\(gaitPhase \* 2 \+ phaseOffset\)' "Spider swing should use Minecraft's doubled swing phase on the leg-root rotation."
Assert-Contains $spider 'math\.abs\(math\.sin\(gaitPhase \+ phaseOffset \+ liftPhase\)\)' "Spider lift should use Minecraft's absolute sine formula as a small leg-root rotation."
Assert-Contains $spider 'bmb_spider_"\s*\.\.\s*legName\s*\.\.\s*"_swing_offset' "Spider should expose per-leg static swing angle offsets for foot placement."
Assert-Contains $spider 'bmb_spider_"\s*\.\.\s*legName\s*\.\.\s*"_lift_offset' "Spider should expose per-leg static lift angle offsets for feet that hover."
Assert-Contains $spider 'bmb_spider_"\s*\.\.\s*legName\s*\.\.\s*"_phase_offset' "Spider should expose per-leg phase offsets without copy-pasting eight animation blocks."
Assert-NotContains $spider 'bmb_spider_leg_pair_phase|bmb_spider_leg_right_phase' "Spider gait should no longer use the old four-phase tuning scheme."
Assert-NotContains $spider 'function ENT:Draw\(\)|SetAngles|SetRenderAngles|spiderForwardAngle|setBoneAngle\(self,\s*bones\.root,\s*Angle\(0,\s*180' "Spider facing should be baked into the MDL/QC, not flipped in Lua."
Assert-Contains $spider 'setBoneAngle\(self,\s*bones\[legName\],\s*angle\)' "Spider procedural gait should rotate each leg root bone."
Assert-Contains $spider 'setBonePosition\(self,\s*bones\[legName\],\s*zeroVector\)' "Spider procedural gait should not translate leg bones."
Assert-NotContains $spider 'SpiderLegRollMax|legRollConVar|rollMax|getLegOffset|offset_x|offset_y|offset_z|Vector\([^)]*lift' "Spider gait must not use leg translation offsets; animation belongs in ManipulateBoneAngles."

Assert-NotContains $spider 'MeleeAttack|Leap\.Try|Pack\.Run|Chase\.Run|SeekTarget\.Find' "Spider Phase 0 must not pull in Phase 2 combat or Phase 3 climb/chase behavior."

Write-Host "Spider Phase 0 checks passed."
