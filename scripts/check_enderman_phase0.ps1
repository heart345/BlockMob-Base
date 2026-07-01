Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-Contains([string]$relativePath, [string]$pattern, [string]$message) {
    $repoRoot = Join-Path -Path $PSScriptRoot -ChildPath ".."
    $path = Join-Path -Path $repoRoot -ChildPath $relativePath
    $text = Get-Content -Raw -LiteralPath $path
    if ($text -notmatch $pattern) {
        throw "$message ($relativePath)"
    }
}

$enderman = "gmod_addon\lua\entities\bmb_enderman.lua"
$menu = "gmod_addon\lua\autorun\mcgm_autorun.lua"
$autorun = "gmod_addon\lua\autorun\bmb_autorun.lua"
$effect = "gmod_addon\lua\effects\bmb_enderman_warp\init.lua"

Assert-Contains $enderman 'ENT\.Base\s*=\s*"bmb_base_mob"' "Enderman should own neutral/provoked behavior from the base mob, not inherit zombie aggro."
Assert-Contains $enderman 'ENT\.Model\s*=\s*"models/mcgm/enderman/enderman\.mdl"' "Enderman should use the converted Enderman model."
Assert-Contains $enderman 'CollisionMins\s*=\s*Vector\(-11,\s*-11,\s*0\)' "Enderman should use a narrow MC-style hull."
Assert-Contains $enderman 'CollisionMaxs\s*=\s*Vector\(11,\s*11,\s*106\)' "Enderman height should force three-block path clearance."
Assert-Contains $enderman 'function\s+ENT:TryBMBTeleport\(reason,\s*context\)' "Enderman teleport should have one central entry point."
Assert-Contains $enderman 'GetBMBGroundSurfaceZ\(candidate\)' "Enderman teleport should reuse the base ground-surface probe."
Assert-Contains $enderman 'IsBMBHullClearAtPosition\(foot\)' "Enderman teleport should reuse tall-hull path clearance validation."
Assert-Contains $enderman 'util\.PointContents' "Enderman teleport should reject liquid destinations."
Assert-Contains $enderman 'function\s+ENT:EmitBMBEndermanAmbientPortalParticles' "Enderman should emit constant clientside MC portal particles."
Assert-Contains $enderman 'data:SetFlags\(ENDERMAN_PORTAL_AMBIENT_FLAGS\)' "Enderman ambient particles should mark the effect as ambient mode."
Assert-Contains $enderman 'data:SetStart\(startPos or origin\)' "Enderman teleport particles should receive the old position for path interpolation."
Assert-Contains $enderman 'data:SetMagnitude\(128\)' "Enderman teleport burst should use MC event 46 particle count."
Assert-Contains $enderman 'function\s+ENT:CheckBMBEndermanStare' "Enderman should implement player stare provocation."
Assert-Contains $enderman 'function\s+ENT:IsBMBEndermanBeingStaredAtByPlayer\(ply\)' "Enderman stare detection should be reusable for freeze/chase behavior."
Assert-Contains $enderman 'ply:GetAimVector\(\):Dot\(toHead\)' "Enderman stare should use aim dot against its head."
Assert-Contains $enderman 'minDot\s*=\s*1\s*-\s*math\.max\(0\.0001,\s*dotBias\)\s*/\s*distanceCells' "Enderman stare should use the MC distance-scaled dot threshold."
Assert-Contains $enderman 'TraceLine\(\{[\s\S]*ply:EyePos\(\)[\s\S]*headPos' "Enderman stare should require line of sight to the head."
Assert-Contains $enderman 'function\s+ENT:RunBMBEndermanPendingStare' "Enderman should keep the short MC pre-aggro stare pause."
Assert-Contains $enderman 'function\s+ENT:RunBMBEndermanFreezeWhenLookedAt' "Enderman should freeze when its player target stares at it nearby."
Assert-Contains $enderman 'EndermanFarTeleportMinCells\s*=\s*16' "Enderman far chase teleport should start at the MC 16-block threshold."
Assert-Contains $enderman 'function\s+ENT:IsBMBEndermanProjectileDamage' "Enderman should classify projectile damage before base damage handling."
Assert-Contains $enderman 'class\s*==\s*"bmb_arrow"' "Enderman should dodge and swallow BMB arrows."
Assert-Contains $enderman 'return\s+0' "Enderman projectile dodge should swallow projectile damage."
Assert-Contains $enderman 'BMBEndermanProvoked' "Enderman should network its provoked state for client pose."
Assert-Contains $enderman 'ENT\.EndermanAngryArmForwardAngle\s*=\s*0' "Enderman chase/provoked pose should keep arms hanging instead of raised."
Assert-Contains $enderman 'time\s*=\s*0\.14[\s\S]*rightArm\s*=\s*\{\s*angle\s*=\s*Angle\(0,\s*0,\s*-42\)[\s\S]*leftArm\s*=\s*\{\s*angle\s*=\s*Angle\(0,\s*0,\s*0\)' "Enderman melee gesture should swing only the right arm."
Assert-Contains $enderman 'bmb/mob/endermen/portal\.ogg' "Enderman should play MC teleport sounds."

Assert-Contains $effect 'Material\("bmb/particles/mc_portal"\)' "Enderman portal effect should use the dedicated MC generic_0..7 portal material."
Assert-Contains $effect 'local AMBIENT_FLAGS = 1' "Enderman portal effect should support ambient and teleport modes."
Assert-Contains $effect 'math\.random\(40,\s*49\)' "Portal particles should live 40-49 MC ticks."
Assert-Contains $effect 'math\.Rand\(0\.5,\s*0\.7\)' "Portal particles should use the MC 0.05-0.07 block base size."
Assert-Contains $effect 'curve = 1 \+ rawT - 2 \* rawT \* rawT' "Portal particles should use the MC return-to-start curve."
Assert-Contains $effect 'renderT \* renderT \* renderT \* renderT' "Portal particles should emulate MC late-life brightness."

Assert-Contains $menu '"bmb_enderman"' "Spawn menu should register BMB Enderman."
Assert-Contains $autorun 'sound/bmb/mob/endermen/stare\.ogg' "Autorun resource list should include Enderman stare sound."
Assert-Contains $autorun 'materials/bmb/particles/mc_portal\.vmt' "Autorun resource list should include the portal particle material."
Assert-Contains $autorun 'materials/bmb/particles/mc_portal\.vtf' "Autorun resource list should include the portal particle texture."

Write-Host "Enderman phase0 checks passed."
