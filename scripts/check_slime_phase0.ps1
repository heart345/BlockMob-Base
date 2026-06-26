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

$slime = "gmod_addon\lua\entities\bmb_slime.lua"
$base = "gmod_addon\lua\entities\bmb_base_mob.lua"
$autorun = "gmod_addon\lua\autorun\bmb_autorun.lua"
$menu = "gmod_addon\lua\autorun\mcgm_autorun.lua"

Assert-Contains $slime 'ENT\.Base\s*=\s*"bmb_base_mob"' "Slime should be a real BMB NextBot."
Assert-Contains $slime 'ENT\.Type\s*=\s*"nextbot"' "Slime should spawn as a NextBot."
Assert-Contains $slime 'ENT\.Model\s*=\s*"models/mcgm/slime/slime\.mdl"' "Slime should use the converted slime model."
Assert-Contains $slime 'ENT\.HopOnlyLocomotion\s*=\s*true' "Slime should opt into pure hop locomotion."
Assert-Contains $slime 'ENT\.BlockHopUsePreviousNodeForward\s*=\s*false' "Slime should jump directly toward its current waypoint instead of waiting to align to the previous path segment."
Assert-Contains $slime 'ENT\.UseSourcePathFollower\s*=\s*false' "Slime should not fall back to Source path walking."
Assert-Contains $slime 'ENT\.ChasePreferDirect\s*=\s*false' "Slime should not use direct chase walking."
Assert-Contains $base 'function ENT:GetBMBEffectiveWaypointAction' "Base movement should expose an effective waypoint action hook."
Assert-Contains $base 'self\.HopOnlyLocomotion and action == "walk"' "HopOnly mobs should consume walk nodes as hop nodes."
Assert-Contains $base 'path_hop_wait' "HopOnly mobs should be able to wait between landed hops without walking."
Assert-Contains $base 'self\.BlockHopUsePreviousNodeForward ~= false' "Base hop direction should allow hop-only mobs to ignore previous path segment alignment."
Assert-Contains $base 'function ENT:GetBMBVectorPosition\(position\)' "Base should convert waypoint tables to Vectors before steering."
Assert-Contains $base 'position = self:GetBMBVectorPosition\(position\)' "FaceTarget should accept waypoint tables without vector subtraction errors."
Assert-Contains $base 'target = self:GetBMBVectorPosition\(target\)' "SteerTowards should accept waypoint tables without vector subtraction errors."

Assert-Contains $slime 'self\.SlimeSize' "Slime should keep runtime size on one entity."
Assert-Contains $slime 'function ENT:SetSlimeSize\(size\)' "Slime should expose SetSlimeSize for split children and debugging."
Assert-Contains $slime 'function ENT:ApplySlimeSize\(size,\s*keepHealth\)' "Slime should derive scale, collision, health, damage, and hop params from size."
Assert-Contains $slime 'SetModelScale\(config\.modelScale' "Slime size should drive model scale at runtime."
Assert-Contains $slime 'modelScale\s*=\s*1\.0' "Size 1 slime should use the small outer-shell scale."
Assert-Contains $slime 'modelScale\s*=\s*2\.0' "Size 2 slime should use the medium outer-shell scale."
Assert-Contains $slime 'modelScale\s*=\s*4\.0' "Size 3 slime should use the large outer-shell scale."
Assert-Contains $slime 'function ENT:GetBMBSlimeEngineCollisionBounds\(config\)' "Slime should keep engine bbox matched to scaled visuals."
Assert-Contains $slime 'config\.radius / modelScale' "Slime engine bbox should be inverse-scaled from the BMB world hull."
Assert-Contains $slime 'SetCollisionBounds\(engineMins,\s*engineMaxs\)' "Slime size should refresh engine collision bounds."
Assert-Contains $slime 'SetNWInt\("BMBSlimeSize",\s*size\)' "Slime size should be networked for debugging/future polish."
Assert-Contains $slime 'bmb_slime_hop_dist_scale' "Slime should expose hop distance tuning."
Assert-Contains $slime 'bmb_slime_hop_height_scale' "Slime should expose hop height tuning."
Assert-Contains $slime 'bmb_slime_hop_interval_scale' "Slime should expose hop interval tuning."
Assert-Contains $slime 'bmb_slime_contact_damage_scale' "Slime should expose contact damage tuning."
Assert-Contains $slime 'bmb_slime_min_size_damage' "Slime should expose size 1 damage tuning."

Assert-Contains $slime 'BMB\.Behaviors\.MeleeAttack\.IsInRange\(self,\s*self\.TargetEntity\)' "Slime should use contact range before chasing."
Assert-Contains $slime 'BMB\.Behaviors\.MeleeAttack\.Try\(self,\s*self\.TargetEntity\)' "Slime should reuse shared melee/contact damage."
Assert-Contains $slime 'attack_cooldown' "Slime should wait in range during attack cooldown instead of walking."
Assert-Contains $slime 'BMB\.Behaviors\.Chase\.Run\(self,\s*self\.TargetEntity\)' "Slime should reuse shared chase pathing outside contact range."
Assert-NotContains $slime 'RangedAttack|bmb_slime_small|bmb_slime_medium|bmb_slime_large' "Slime should not add ranged behavior or separate size classes."

Assert-Contains $slime 'function ENT:SplitBMBSlime\(\)' "Slime should split on death."
Assert-Contains $slime 'if size <= 1 then return end' "Size 1 slimes should never split."
Assert-Contains $slime 'bmb_slime_split_count' "Slime split count should be convar-driven."
Assert-Contains $slime 'FindBMBSlimeSplitPositions' "Slime split should search candidate positions."
Assert-Contains $slime 'WithBMBSlimeCollisionSize\(childSize' "Slime split should hull-check using child size."
Assert-Contains $slime 'IsBMBHullClearAtPosition\(candidate\)' "Slime split should reject blocked child positions."
Assert-Contains $slime 'GetBMBGroundSurfaceZ\(candidate\)' "Slime split should snap child spawn z to ground surface."
Assert-Contains $slime 'ents\.Create\("bmb_slime"\)' "Slime split should spawn the same entity class."
Assert-Contains $slime 'child:SetSlimeSize\(childSize\)' "Split children should receive the next smaller size."

Assert-Contains $slime 'function ENT:OnLandOnGround\(ent\)' "Slime should hook landing for movement sounds while keeping base unsink."
Assert-Contains $slime 'callBaseMob\(self,\s*"OnLandOnGround"' "Slime landing should preserve base landing/unsink behavior."
Assert-Contains $slime 'function ENT:MaybePlayStep\(\)' "Slime should silence Base's placeholder zombie footstep."
Assert-Contains $slime 'function ENT:PlayBMBAnimation\(_name\)' "Slime should suppress Base Source gestures it does not have."
Assert-Contains $autorun 'sound/bmb/mob/slime/attack1\.ogg' "Slime attack sound should be registered for clients."
Assert-Contains $autorun 'sound/bmb/mob/slime/big1\.ogg' "Slime big movement sound should be registered."
Assert-Contains $autorun 'sound/bmb/mob/slime/small5\.ogg' "Slime small movement sound set should be registered."
Assert-Contains $menu '"bmb_slime"' "Spawn menu should register BMB Slime."

Write-Host "Slime Phase 0 checks passed."
