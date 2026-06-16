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

function Assert-FunctionNotContains([string]$relativePath, [string]$functionName, [string]$pattern, [string]$message) {
    $path = Join-Path (Get-Location) $relativePath
    $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    $escapedName = [regex]::Escape($functionName)
    $match = [regex]::Match($text, "function\s+ENT:$escapedName\s*\([^)]*\)(?s:.*?)(?=\r?\n\s*function\s+ENT:|\r?\nend\r?\nend|\z)")

    if (-not $match.Success) {
        throw "ERROR: ${relativePath}: missing function ENT:$functionName"
    }

    if ($match.Value -match $pattern) {
        throw "ERROR: ${relativePath}: $message"
    }
}

$base = "gmod_addon\lua\entities\bmb_base_mob.lua"
$sheep = "gmod_addon\lua\entities\bmb_sheep.lua"

Assert-Contains $base "AnimationSequences" "Base should expose per-mob logical action to model sequence mapping."
Assert-Contains $base "LookupBMBAnimationSequence" "Base should cache LookupSequence calls for exported model sequence names."
Assert-Contains $base "ResolveBMBAnimationSequence" "Base should resolve missing actions/sequences through idle fallback."
Assert-Contains $base "LookupSequence\(sequenceName\)" "Base should use model sequence names verbatim instead of ACT-only mapping."
Assert-Contains $base "ResetSequence\(sequenceId\)" "Base should reset to the chosen sequence when logical animation changes."
Assert-Contains $base "SetPlaybackRate" "Base should scale sequence playback rate from movement speed."
Assert-Contains $base "action == `"walk`" or action == `"run`"" "Movement actions should use speed-scaled playback."
Assert-Contains $base "sequenceId, sequenceName, resolvedAction" "Playback rate should use the resolved sequence/action after idle fallback."

Assert-Contains $base "function ENT:UpdateBMBLimbSwing" "Base should expose a reusable continuous limb-swing driver for procedural mobs (cow/pig/sheep)."
Assert-Contains $base "Lerp\(blend,\s*self\.BMBLimbSwingAmount" "Base limb swing amount should smooth in/out with FrameTime."
Assert-Contains $base "BMBLimbSwingPhase.*speed2D\s*\*\s*frameTime" "Base limb swing phase should be speed driven."
Assert-FunctionNotContains $base "UpdateBMBLimbSwing" "and\s*1\s*or\s*0" "Base limb swing amount should scale continuously with speed, not a binary walk/run switch."

Assert-Contains $sheep "Sequence locomotion is parked" "Sheep sequence hookup should stay visibly parked until converter pivot/rate issues are fixed."
Assert-NotContains $sheep "(?m)^\s*ENT\.AnimationSequences\s*=" "Sheep should not actively opt into model sequence locomotion yet."
Assert-NotContains $sheep "(?m)^\s*ENT\.AnimationReferenceSpeeds\s*=" "Sheep sequence reference speeds should stay disabled with the parked hookup."
Assert-Contains $sheep "local phase, swingAmount = self:UpdateBMBLimbSwing" "Sheep head/leg overlay should drive swing through the shared base limb-swing helper instead of hard speed branches."
Assert-Contains $sheep "LimbSwingPhaseScale\s*=\s*0\.09" "Sheep should lower the shared limb-swing frequency for both walk and run."
Assert-Contains $sheep "legSwingMax\s*=\s*25\.0" "Sheep procedural leg swing currently uses a 25 degree cap with continuous speed-scaled amplitude."
Assert-Contains $sheep 'sheepBoneNames\s*=\s*\{\s*"head",\s*"leg0",\s*"leg1",\s*"leg2",\s*"leg3"\s*\}' "Sheep visual bone cache should include legs while sequence hookup is parked."
Assert-Contains $sheep "setBoneAngle\(self,\s*bones\.leg0,\s*Angle\(0,\s*0,\s*legSwing\)\)" "Sheep front/back leg pair should be driven by smoothed procedural swing."
Assert-Contains $sheep "setBoneAngle\(self,\s*bones\.leg1,\s*Angle\(0,\s*0,\s*-legSwing\)\)" "Sheep opposite leg pair should counter-swing procedurally."
Assert-Contains $sheep "clearSheepHeadPoseOnce" "Sheep should clear old head poses once without locking the head bone every frame."
Assert-FunctionNotContains $sheep "UpdateBMBVisualBones" "speed\s*>\s*8\s*then" "Sheep visual bones should not hard switch walk legs on speed > 8."
Assert-FunctionNotContains $sheep "UpdateBMBVisualBones" "local\s+rate\s*=" "Sheep visual bones should not use time-rate-driven procedural leg swing."
Assert-FunctionNotContains $sheep "UpdateBMBVisualBones" "walkHead|idleHead|headWalkSwing" "Sheep locomotion should not swing the head; later head systems should own that bone."
Assert-Contains $sheep "StepSoundDistance\s*=\s*35" "Sheep footsteps should be distance-driven to align with the visual gait half-wave."
Assert-Contains $sheep "function ENT:UpdateBMBSheepStepSound" "Sheep should own client-side distance-driven step timing."
Assert-Contains $sheep "speed \* FrameTime\(\)" "Sheep step timing should accumulate traveled distance, not elapsed time."
Assert-Contains $sheep "function ENT:MaybePlayStep\(\)" "Sheep should override Base's timer-driven step placeholder."
Assert-FunctionNotContains $sheep "MaybePlayStep" "NextStepSoundTime" "Sheep footsteps should not use a timer gate."
Assert-Contains $sheep "bmb/mob/sheep/say1\.ogg" "Sheep should use unpacked Minecraft sheep say sounds."
Assert-Contains $sheep "bmb/mob/sheep/step1\.ogg" "Sheep should use unpacked Minecraft sheep step sounds."
Assert-Contains $sheep "bmb/dig/grass1\.ogg" "Sheep eat-grass should use Minecraft grass dig sounds."
Assert-Contains "gmod_addon\lua\bmb\sv_behaviors.lua" "PlayBMBEatGrassSound" "EatGrass behavior should let mobs provide their own grass-eating sound."

Assert-Contains $base "LookAtStartChance\s*=\s*0\.06" "Base LookAt should default to occasional MC-style glances, not constant staring."
Assert-Contains $base "LookAtPollInterval\s*=\s*0\.5" "Base LookAt decision layer should poll at a low server frequency."
Assert-Contains $base "BMBLookAtTarget" "Base LookAt should synchronize the target EntIndex through NW variables."
Assert-Contains $base "BMBLookAtUntil" "Base LookAt should synchronize the look timeout through NW variables."
Assert-Contains $base "BMBLookAroundYaw" "Base random look-around should synchronize only low-frequency yaw targets."
Assert-Contains $base "BMBLookAroundPitch" "Base random look-around should synchronize only low-frequency pitch targets."
Assert-Contains $base "LookAroundIntervalMin\s*=\s*1\.0" "Base look-around should pick low-frequency random head targets."
Assert-Contains $base "LookAroundIntervalMax\s*=\s*3\.0" "Base look-around should pick low-frequency random head targets."
Assert-Contains $base "LookAroundForwardChance\s*=\s*0\.35" "Base look-around should sometimes return the head to straight ahead."
Assert-Contains $base "function ENT:UpdateBMBLookAtController" "Base should own the server-side parallel LookAt controller."
Assert-Contains $base "function ENT:UpdateBMBLookAroundController" "Base should own the server-side random look-around controller."
Assert-Contains $base "function ENT:UpdateBMBLookAtHeadPose" "Base should expose a reusable client-side LookAt bone renderer."
Assert-Contains $base "math\.Clamp\(yaw,\s*-\(self\.LookAtYawLimit or 70\)" "Client LookAt yaw should be clamped by per-mob/default limits."
Assert-Contains $base "math\.Clamp\(pitch,\s*-\(self\.LookAtPitchLimit or 24\)" "Client LookAt pitch should be clamped by per-mob/default limits."
Assert-Contains $base "self:GetBMBLookAroundHeadAngle\(\)" "Client LookAt renderer should reuse the same Lerp path for random look-around."
Assert-Contains $base "state == `"dead`" or state == `"eat_grass`"" "LookAt should be suppressed during death/eat-grass poses."
Assert-Contains $sheep "self:UpdateBMBLookAtHeadPose\(bones\.head\)" "Sheep should consume the shared Base LookAt renderer in its normal visual branch."

Write-Host "Sequence animation adapter checks passed."
