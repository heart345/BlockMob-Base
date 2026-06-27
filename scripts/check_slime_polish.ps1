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
$effect = "gmod_addon\lua\effects\bmb_slime_land\init.lua"
$autorun = "gmod_addon\lua\autorun\bmb_autorun.lua"
$slimeBallVmt = "gmod_addon\materials\bmb\particles\slime_ball.vmt"
$slimeBallVtf = "gmod_addon\materials\bmb\particles\slime_ball.vtf"

Assert-Contains $slime 'ENT\.SlimeLandEffect\s*=\s*"bmb_slime_land"' "Slime should name its landing particle effect."
Assert-Contains $slime 'function ENT:EmitBMBSlimeLandEffect\(\)' "Slime should emit landing particles from the entity."
Assert-Contains $slime 'util\.Effect\(self\.SlimeLandEffect,\s*data,\s*true,\s*true\)' "Landing particles should use GMod effect dispatch."
Assert-Contains $slime 'data:SetMagnitude\(self:GetBMBSlimeLandParticleCount\(config\)\)' "Particle count should be size-driven."
Assert-Contains $slime 'data:SetRadius\(\(config\.radius or 9\) \* 2\)' "Landing particles should spawn around the slime footprint."
Assert-Contains $slime 'data:SetScale\(math\.Clamp' "Landing effect should receive a visual size scale."
Assert-Contains $slime 'SetNWFloat\("BMBSlimeLastLandAt",\s*now\)' "Landing squash should be networked to clients."
Assert-Contains $slime 'function ENT:StartBMBBlockHop\(target,\s*speed,\s*launch\)' "Hop start should be hooked for stretch animation."
Assert-Contains $slime 'SetNWFloat\("BMBSlimeLastHopAt",\s*CurTime\(\)\)' "Hop stretch should be networked to clients."
Assert-Contains $slime 'function ENT:GetBMBSlimeSquishAmount\(\)' "Client should compute cosmetic squash/stretch."
Assert-Contains $slime 'function ENT:Draw\(\)' "Slime should override Draw only for visual matrix scaling."
Assert-Contains $slime 'EnableMatrix\("RenderMultiply",\s*matrix\)' "Squash/stretch should use a render matrix, not server scale."
Assert-Contains $slime 'DisableMatrix\("RenderMultiply"\)' "Render matrix should be cleared after drawing."
Assert-Contains $slime 'callBaseMob\(self,\s*"Draw"\)' "Slime draw should preserve base MC lighting and hurt/death flash."
Assert-NotContains $slime 'SetModelScale\(.*BMBSlimeLastHopAt|SetCollisionBounds\(.*BMBSlimeLastLandAt' "Polish should not change collision or runtime model scale from animation timestamps."
Assert-Contains $base 'self\.OnBMBDeathCleanup' "Base death cleanup should expose a delayed cleanup hook for entities such as slime."
Assert-Contains $base 'self\.MobSeparationUseSafety ~= false' "Base mob separation should allow opt-out for overlap escape cases."
Assert-Contains $base 'launch\.reason == "lift_blocked"' "Hop-only mobs should detect ceiling-blocked hop launches."
Assert-Contains $base 'function ENT:RunBMBHopOnlyLiftBlockedSlide\(actionNode,\s*speed\)' "Base should keep the low-ceiling hop-only slide in a small helper."
Assert-Contains $base 'self:SetBMBMoveMode\("path_hop_slide"\)' "Hop-only mobs should expose low-ceiling slide mode for debugging."
Assert-Contains $base 'self\.loco:Approach\(Vector\(slideTarget\.x,\s*slideTarget\.y,\s*pos\.z\),\s*slideSpeed\)' "Low-ceiling hop-only mobs should slide along the ground instead of freezing."
Assert-Contains $slime 'function ENT:OnBMBDeathCleanup\(_corpse\)' "Slime should split at death cleanup, after the death animation window."
Assert-Contains $slime 'function ENT:SnapBMBSlimeDeathToGround\(\)' "Slime should settle to nearby ground before its death freeze."
Assert-Contains $slime 'BMBSlimeSplitInheritedTarget' "Slime should capture target inheritance before Base clears combat state on death."
Assert-Contains $slime 'function ENT:GetBMBSlimeDeathVisualScale\(\)' "Slime should have a visible death squash/collapse animation."
Assert-Contains $slime 'ENT\.UsePhysicsCorpseOnDeath\s*=\s*true' "Slime should use Base's physics corpse path for visible death tumble."
Assert-Contains $slime 'ENT\.DeathCorpseRollVelocity\s*=\s*220' "Slime corpse should have enough roll velocity to visibly tip."
Assert-Contains $slime 'ENT\.DeathCorpseRightRollVelocity\s*=\s*140' "Slime corpse should use tuned right-roll angular velocity."
Assert-Contains $slime 'function ENT:CopyBMBVisualStateToCorpse\(corpse\)' "Slime should copy its size-specific visual state onto physics corpses."
Assert-Contains $slime 'corpse:SetModelScale\(config\.modelScale or 1,\s*0\)' "Slime physics corpses should inherit the live slime model scale."
Assert-NotContains $slime 'DeathTipDuration|DeathTipDegrees|SetRenderOrigin|SetRenderAngles|GetBMBSlimeDeathTipLift' "Slime should not keep dead render-angle tip code when using physics corpses."
Assert-Contains $slime 'GetNWBool\("BMBDead",\s*false\)' "Slime draw should switch to death visual scale while dead."
Assert-Contains $slime 'ENT\.MobSeparationUseSafety\s*=\s*false' "Slime should be allowed to nudge out of mob overlap without path safety veto."
Assert-Contains $slime 'ENT\.MobSeparationPositionNudgeMax\s*=\s*9' "Slime overlap nudge should be strong enough to escape body-to-body stalls."
Assert-Contains $slime 'ENT\.MobSeparationMaxSpeed\s*=\s*155' "Slime separation speed should be stronger than the base default."
Assert-Contains $slime 'Hit = \{' "Slime should keep a player damage-hit sound set."
Assert-Contains $slime 'bmb/damage/hit1\.ogg' "Slime player hits should use Minecraft damage hit sounds."
Assert-Contains $slime 'function ENT:PlayBMBSlimePlayerHitSound\(target\)' "Slime should play player hit feedback after confirmed melee hits."
Assert-Contains $slime 'self:PlayBMBSlimePlayerHitSound\(target\)' "Slime melee hit callback should retain attack sound and add player hit sound."
Assert-Contains $slime 'speed\s*=\s*140' "Large slime chase hops should be faster and farther than the first pass."
Assert-Contains $slime 'hopDistanceScale\s*=\s*1\.48' "Large slime hop distance scale should be increased."
Assert-Contains $slime 'config\.hopDistanceScale' "Slime hop distance scale should feed the launch-distance tuning, not sit unused in the size table."
Assert-Contains $slime 'hopInterval\s*=\s*0\.26' "Large slime hop interval should be shorter."
Assert-Contains $slime 'hopHeightScale\s*=\s*0\.85' "Small slime hop height should stay at the normal pushed value; low ceilings should slide, not use a degenerate low apex."
Assert-NotContains $slime 'hopCeilingClearanceScale|hopForwardStartHeightScale|hopManualLiftTime|hopPostLiftMinVzScale|BlockHopLaunchCeilingClearance' "Low-ceiling slime fixes should live in Base's lift_blocked slide path, not per-size low-hop tuning."
Assert-NotContains $slime 'self:SplitBMBSlime\(\)\s*self:BeginBMBDeath' "Slime should not split immediately before BeginBMBDeath."

Assert-Contains $effect 'Material\("bmb/particles/slime_ball"\)' "Slime landing particles should use the MC slime_ball item texture."
Assert-Contains $effect 'local PARTICLE_TICK\s*=\s*0\.05' "Effect should simulate MC particle ticks at 20Hz."
Assert-Contains $effect 'local GRAVITY_PER_TICK\s*=\s*0\.04 \* MC_BLOCK_UNITS' "Item slime chunks should fall with BreakingItemParticle gravity."
Assert-Contains $effect 'particle\.vel:Mul\(0\.98\)' "Item slime chunks should apply MC friction."
Assert-Contains $effect 'particle\.vel\.x = particle\.vel\.x \* 0\.7' "Grounded particles should damp horizontal speed."
Assert-Contains $effect 'math\.floor\(4 / \(math\.Rand\(0,\s*1\) \* 0\.9 \+ 0\.1\)\)' "Particle lifetime should match BreakingItemParticle's short random lifetime."
Assert-Contains $effect 'math\.Rand\(0\.05,\s*0\.1\) \* MC_BLOCK_UNITS \* scale' "Particle quad size should match item_slime scale."
Assert-Contains $effect 'math\.Rand\(0\.5,\s*1\.0\)' "Particles should spawn in an outer footprint ring."
Assert-Contains $effect 'local uo = math\.Rand\(0,\s*3\)' "Each particle should pick a random sliding 4x4 U window from the 16x16 item texture."
Assert-Contains $effect 'u0 = \(uo \+ 1\) / 4' "Particle U coordinates should match MC's reversed getU0/getU1 convention."
Assert-Contains $effect 'u1 = uo / 4' "Particle U coordinates should preserve MC's random crop start."
Assert-Contains $effect 'v0 = vo / 4' "Particle V coordinates should preserve MC's random crop start."
Assert-Contains $effect 'v1 = \(vo \+ 1\) / 4' "Particle V coordinates should select a 4x4 crop."
Assert-Contains $effect 'mesh\.Begin\(MATERIAL_QUADS,\s*liveCount\)' "Effect should render UV-cropped quad particles."
Assert-Contains $effect 'mesh\.TexCoord\(0,\s*u,\s*v\)' "Effect should pass per-particle UVs to the mesh."
Assert-Contains $autorun 'materials/bmb/particles/slime_ball\.vmt' "Slime particle material should be sent to clients."
Assert-Contains $autorun 'materials/bmb/particles/slime_ball\.vtf' "Slime particle texture should be sent to clients."
Assert-Contains $slimeBallVmt '"\$basetexture"\s*"bmb/particles/slime_ball"' "VMT should point at the slime_ball VTF."

if (-not (Test-Path -LiteralPath (Join-Path (Get-Location) $slimeBallVtf))) {
    throw "ERROR: ${slimeBallVtf}: slime_ball VTF should exist."
}

Write-Host "Slime polish checks passed."
