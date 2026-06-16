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

Write-Host "Sequence animation adapter checks passed."
