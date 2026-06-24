$ErrorActionPreference = "Stop"

function Assert-Contains([string]$relativePath, [string]$pattern, [string]$message) {
    $path = Join-Path (Get-Location) $relativePath
    $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    if ($text -notmatch $pattern) {
        throw "ERROR: ${relativePath}: ${message}"
    }
}

$spider = "gmod_addon\lua\entities\bmb_spider.lua"

Assert-Contains $spider 'WalkSpeed\s*=\s*100' "Spider wander speed should use the tuned 100 default."
Assert-Contains $spider 'RunSpeed\s*=\s*140' "Spider chase speed should use the tuned 140 default."
Assert-Contains $spider 'AttackMoveSpeed\s*=\s*140' "Spider close attack pressure should keep pace with the tuned chase speed."

Assert-Contains $spider 'bmb_spider_climb_cancel_cooldown",\s*"1\.6"' "Spider Phase 3 should cooldown after target-aware climb cancellation."
Assert-Contains $spider 'bmb_spider_climb_chase_min_target_up",\s*"18"' "Spider Phase 3 should require a target height advantage before chase climb starts."
Assert-Contains $spider 'bmb_spider_climb_chase_wall_dot",\s*"0\.1"' "Spider Phase 3 should require chase targets to be roughly beyond the climbed wall."
Assert-Contains $spider 'bmb_spider_climb_chase_cancel_grace",\s*"0\.45"' "Spider Phase 3 should expose a grace window before cancelling an active climb."
Assert-Contains $spider 'bmb_spider_climb_chase_active",\s*"1"' "Spider Phase 3 should enable proactive chase climb routing by default."
Assert-Contains $spider 'bmb_spider_climb_chase_approach_distance",\s*"260"' "Spider Phase 3 should expose proactive climb wall scan distance."
Assert-Contains $spider 'bmb_spider_climb_chase_approach_timeout",\s*"0\.45"' "Spider Phase 3 should expose proactive climb approach segment time."
Assert-Contains $spider 'bmb_spider_climb_chase_start_distance",\s*"84"' "Spider Phase 3 should start climbing immediately when a proactive wall hit is close enough."

Assert-Contains $spider 'function ENT:GetBMBSpiderClimbCombatTarget\(\)' "Spider Phase 3 should resolve the current retaliation target for climb decisions."
Assert-Contains $spider 'function ENT:GetBMBSpiderClimbTargetPosition\(target\)' "Spider Phase 3 should bias wall scans toward the current combat or movement target."
Assert-Contains $spider 'function ENT:ShouldBMBSpiderStartClimb\(target,\s*normal,\s*reason\)' "Spider Phase 3 should gate climb startup instead of climbing every wall during chase."
Assert-Contains $spider 'targetUp\s*<\s*minTargetUp' "Spider chase climb should not start when the target is not meaningfully above the spider."
Assert-Contains $spider 'dot\s*<\s*minDot' "Spider chase climb should reject walls that are not between the spider and its target."

Assert-Contains $spider 'function ENT:ShouldCancelBMBSpiderChaseClimb\(normal\)' "Spider Phase 3 should re-check target state while already climbing."
Assert-Contains $spider 'BMBSpiderClimbCancelCheckAt' "Spider climb should wait a short grace period before target-aware cancellation."
Assert-Contains $spider 'targetPos\.z\s*-\s*startZ\s*<\s*minTargetUp\s*\*\s*0\.5' "Spider climb should cancel if the chase target drops back down."
Assert-Contains $spider 'targetDirection:Dot\(intoWall\)\s*<\s*-0\.35' "Spider climb should cancel if the chase target clearly moves away from the climbed wall."
Assert-Contains $spider 'FinishBMBSpiderClimbSpike\(cancelReason or "target_lost"\)' "Spider climb should restore normal locomotion when chase cancellation fires."
Assert-Contains $spider 'GetBMBSpiderClimbCancelCooldown\(\)' "Target-aware climb cancellation should have its own retry cooldown."

Assert-Contains $spider 'function ENT:ShouldRunBMBSpiderChaseClimb\(target\)' "Spider Phase 3 should decide when a high chase target deserves proactive climb routing."
Assert-Contains $spider 'function ENT:GetBMBSpiderChaseClimbDirections\(target\)' "Spider Phase 3 should use a fan of target/forward/side directions for high-target wall scans."
Assert-Contains $spider 'function ENT:TryBMBSpiderChaseClimbAtWall\(target,\s*normal,\s*reason\)' "Spider Phase 3 should be able to start climb from a wall normal found by proactive chase scan."
Assert-Contains $spider 'function ENT:FindBMBSpiderChaseClimbApproach\(target\)' "Spider Phase 3 should find a wall approach point before ordinary chase stalls below high targets."
Assert-Contains $spider 'function ENT:RunBMBSpiderChaseClimb\(target\)' "Spider Phase 3 should own a proactive chase climb entry point."
Assert-Contains $spider 'self:SetBMBMoveMode\("chase_climb_approach"\)' "Spider proactive climb should expose a chase_climb_approach debug move mode."
Assert-Contains $spider 'MoveToWorldPosition\(approach,\s*speed,\s*\{(?s).*allowDirectFallback\s*=\s*true' "Spider proactive climb should walk to the wall foot before the climb spike takes over."
Assert-Contains $spider 'RunBMBSpiderChaseClimb\(self\.TargetEntity\)' "Spider AI should try proactive climbing before falling back to shared chase."
Assert-Contains $spider 'BMBSpiderClimbForcedNormal' "Spider proactive climb should preserve a detected wall normal so direct blocked frontal cases can enter climb."
Assert-Contains $spider 'approachDistance\s*<=\s*startDistance' "Spider proactive climb should skip wall-foot movement and climb immediately when already close to the wall."
Assert-Contains $spider 'skip climb start: wall not pinned' "Spider climb should not enter climb_spike until the current position can actually pin to the wall."
Assert-Contains $spider 'BMBSpiderClimbLastPinnedPos\s*=\s*startPinned' "Spider climb should seed the spike from the first pinned wall position, not a too-far pre-wall position."

Assert-Contains $spider 'BMBSpiderClimbPendingReason\s*=\s*reason' "Movement override should pass its reason into the climb spike without changing the Phase 1 function signature."
Assert-Contains $spider 'reason\s*=\s*self\.BMBSpiderClimbPendingReason or "ambient"' "Ambient climb attempts should be distinguishable from movement override climb attempts."
Assert-Contains $spider 'scanTarget\s*=\s*targetPos or target' "Wall scanning should prefer the resolved combat target position when one exists."

Write-Host "Spider Phase 3 checks passed."
