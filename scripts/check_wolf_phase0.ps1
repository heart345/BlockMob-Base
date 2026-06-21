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

$wolf = "gmod_addon\lua\entities\bmb_wolf.lua"
$menu = "gmod_addon\lua\autorun\mcgm_autorun.lua"

Assert-Contains $wolf 'ENT\.Base\s*=\s*"bmb_base_mob"' "Wolf Phase 0 must be a real BMB NextBot, not the old base_anim stub."
Assert-Contains $wolf 'ENT\.Type\s*=\s*"nextbot"' "Wolf Phase 0 must spawn as a NextBot."
Assert-Contains $wolf 'ENT\.Model\s*=\s*"models/mcgm/wolf/wolf\.mdl"' "Wolf must reference the converted MC wolf model path."
Assert-Contains $wolf 'ENT\.Spawnable\s*=\s*true' "Wolf should be spawnable for Phase 0 testing."
Assert-NotContains $wolf 'base_anim|cube025x025x025|Stub Wolf' "The old flee-test box stub must not come back."

Assert-Contains $wolf 'function ENT:RunBehaviour\(\)' "Wolf should own a thin behavior scheduler."
Assert-Contains $wolf 'MaintainBMBFreeze' "Wolf should respect bmb_freeze for screenshots."
Assert-Contains $wolf 'RunBMBDebugMove' "Wolf should support the BMB debug movement tool."
Assert-Contains $wolf 'RunBMBStrandedRecovery' "Wolf should use base stranded recovery on invalid supports."
Assert-Contains $wolf 'RunBMBInitialIdle' "Wolf should idle briefly after spawn before wandering."
Assert-Contains $wolf 'BMB\.Behaviors\.Wander\.Run\(self\)' "Wolf Phase 0 should only wander; prey chase is Phase 1."
Assert-NotContains $wolf 'MeleeAttack|RangedAttack|Pack|Leap|FindPrey|TargetEntity' "Wolf Phase 0 must not mix in Phase 1+ combat/pack/leap behavior."

Assert-Contains $wolf 'function ENT:CacheBMBWolfBones\(\)' "Wolf should cache MC model bones for visual overlays."
Assert-Contains $wolf '"head",\s*"leg0",\s*"leg1",\s*"leg2",\s*"leg3",\s*"tail"' "Wolf bone cache should cover head, four legs, and tail."
Assert-Contains $wolf 'function ENT:UpdateBMBVisualBones\(\)' "Wolf should update visual bones client-side."
Assert-Contains $wolf 'UpdateBMBLookAtHeadPose\(bones\.head\)' "Wolf should reuse Base LookAt head rendering."
Assert-Contains $wolf 'UpdateBMBLimbSwing\(speed\)' "Wolf should reuse Base continuous limb swing."
Assert-Contains $wolf 'createWolfPoseConVars\("bmb_wolf_tail",\s*Angle\(0,\s*0,\s*-45\)' "Wolf tail should idle at the tested vanilla-like droop."
Assert-Contains $wolf 'tailAngle\.p\s*=\s*tailAngle\.p\s*\+\s*math\.sin\(phase\).*WolfTailSwingXDegrees' "Wolf tail walk/run swing should use rot_x, not the droop rot_z axis."
Assert-Contains $wolf 'WolfTailSwingXDegrees\s*=\s*40' "Wolf tail rot_x should swing naturally between about -40 and 40 while moving."
Assert-Contains $wolf 'createWolfPoseConVars\("bmb_wolf_body"' "Wolf body pose should stay tunable client-side while Phase 0 axes are being verified."
Assert-Contains $wolf 'createWolfPoseConVars\("bmb_wolf_upper_body"' "Wolf upperBody pose should stay tunable client-side while Phase 0 axes are being verified."
Assert-Contains $wolf 'createWolfPoseConVars\("bmb_wolf_upper_body",\s*zeroAngle,\s*Vector\(0,\s*0,\s*-10\)' "Wolf upperBody should use the tested -10 z offset."
Assert-Contains $wolf 'leg0.*legSwing' "Wolf should drive one diagonal leg pair."
Assert-Contains $wolf 'leg1.*-legSwing' "Wolf should counter-swing the opposite diagonal leg pair."
Assert-Contains $wolf 'function ENT:MaybePlayStep\(\)' "Wolf Phase 0 should silence Base's placeholder zombie footstep until the sound pass."

Assert-Contains $menu '"bmb_wolf"' "Spawn menu should register BMB Wolf as an NPC."
Assert-Contains $menu 'Name\s*=\s*"BMB Wolf"' "Spawn menu should show the published BMB Wolf name."

Write-Host "Wolf phase 0 checks passed."
