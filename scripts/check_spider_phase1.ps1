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
$base = "gmod_addon\lua\entities\bmb_base_mob.lua"

Assert-Contains $spider 'SpiderClimbSpikeEnabled\s*=\s*true' "Spider Phase 1 climb spike should be enabled for isolated validation."
Assert-Contains $spider 'bmb_spider_climb_spike",\s*"1"' "Spider climb spike should expose an on/off convar."
Assert-Contains $spider 'bmb_spider_climb_speed",\s*"105"' "Spider climb spike should expose the faster climb speed tuning."
Assert-Contains $spider 'bmb_spider_climb_probe_distance",\s*"42"' "Spider climb spike should expose wall probe distance tuning."
Assert-Contains $spider 'bmb_spider_climb_wall_clearance",\s*"30"' "Spider climb spike should expose wall clearance tuning without leaving a large visible gap."
Assert-Contains $spider 'bmb_spider_climb_mantle_forward",\s*"46"' "Spider climb spike should expose mantle forward tuning."
Assert-Contains $spider 'bmb_spider_climb_mantle_start_below",\s*"3"' "Spider climb should expose ledge readiness tuning so mantling does not start too early."
Assert-Contains $spider 'bmb_spider_climb_mantle_speed",\s*"72"' "Spider climb should expose smooth mantle speed tuning."
Assert-Contains $spider 'bmb_spider_climb_timeout",\s*"7"' "Spider climb spike should have a bounded timeout."
Assert-Contains $spider 'bmb_spider_climb_blocked_hold_time",\s*"3"' "Spider climb should expose blocked hold duration before giving up."
Assert-Contains $spider 'bmb_spider_climb_descend_speed",\s*"88"' "Spider climb should expose descend speed after a blocked climb."
Assert-Contains $spider 'bmb_spider_climb_giveup_cooldown",\s*"4"' "Spider climb should expose a cooldown after giving up a blocked climb."
Assert-Contains $spider 'bmb_debug_spider_climb",\s*"0"' "Spider climb spike should expose debug logging."

Assert-Contains $spider 'function ENT:FindBMBSpiderClimbWall\(target\)' "Spider Phase 1 should find a vertical wall before entering climb."
Assert-Contains $spider 'addDirection\(forward\)(?s).*addDirection\(right\).*addDirection\(-forward\)' "Spider climb should scan nearby walls instead of only checking the current forward vector."
Assert-Contains $spider 'addDirection\(targetDirection\)' "Spider climb should prioritize the current movement target when scanning for walls."
Assert-Contains $spider 'scanDistance\s*=\s*self:GetBMBSpiderClimbProbeDistance\(\)\s*\+\s*self:GetBMBSpiderBodyRadius\(\)' "Spider wall scan should account for body radius, not only center-point distance."
Assert-Contains $spider 'function ENT:RunBMBSpiderClimbSpike\(target\)' "Spider Phase 1 should own an isolated climb-state locomotion spike."
Assert-Contains $spider 'function ENT:FindBMBSpiderClimbMantle\(normal,\s*climbPos\)' "Spider Phase 1 should find a top landing before starting mantle."
Assert-Contains $spider 'function ENT:RunBMBSpiderClimbMantle\(normal,\s*fromPos,\s*landing\)' "Spider Phase 1 should smooth mantle over multiple frames instead of teleporting to the landing."
Assert-Contains $spider 'function ENT:HoldBMBSpiderClimbWall\(pos,\s*normal,\s*reason\)' "Spider Phase 1 should hold the wall when the top is blocked."
Assert-Contains $spider 'function ENT:GetBMBSpiderClimbHoldKey\(reason\)' "Spider Phase 1 should group blocked ledge hold reasons so the give-up timer cannot reset forever."
Assert-Contains $spider 'function ENT:HandleBMBSpiderClimbHold\(pos,\s*normal,\s*reason\)' "Spider Phase 1 should give up blocked wall holds after a short delay."
Assert-Contains $spider 'function ENT:RunBMBSpiderClimbDescend\(normal,\s*startPos,\s*reason\)' "Spider Phase 1 should descend from blocked overhangs instead of hanging forever."
Assert-Contains $spider 'function ENT:GetBMBSpiderClimbPinnedPosition\(pos,\s*normal\)' "Spider climb should keep the hull pinned to the wall plane."
Assert-Contains $spider 'function ENT:IsBMBSpiderClimbWallHit\(trace,\s*wallNormal\)' "Spider climb should allow hull traces to keep touching the same wall while sliding upward."
Assert-Contains $spider 'util\.TraceLine\(\{(?s).*mask\s*=\s*MASK_SOLID' "Spider climb should probe solid wall faces with traces."
Assert-Contains $spider 'util\.TraceHull\(\{(?s).*mins\s*=\s*self\.CollisionMins.*maxs\s*=\s*self\.CollisionMaxs' "Spider climb should protect SetPos movement with hull traces."
Assert-Contains $spider 'CanBMBSpiderMoveHull\(planned,\s*pinned,\s*normal\)' "Spider climb movement should pass the active wall normal into hull checks."
Assert-Contains $spider 'self:SetPos\(pinned\)' "Spider Phase 1 should use the selected SetPos climb route instead of relying on loco gravity."
Assert-Contains $spider 'self:SetPos\(current\)' "Spider mantle should move through intermediate positions instead of snapping to the landing."
Assert-Contains $spider 'self:SetBMBState\("climb_spike"\)' "Spider climb should advertise a climb_spike state."
Assert-Contains $spider 'self:SetBMBMoveMode\("climb_spike"\)' "Spider climb should expose a climb_spike debug move mode."
Assert-Contains $spider 'self:SetBMBMoveMode\("climb_mantle"\)' "Spider smooth mantle should expose a climb_mantle debug move mode."
Assert-Contains $spider 'mantle start from=%s ledge=%s landing=%s dist=%\.1f deadline=%\.2f' "Spider smooth mantle should log its start, ledge, landing, and time budget."
Assert-Contains $spider 'mantle progress stage=%d pos=%s target=%s dist=%\.1f timeleft=%\.2f' "Spider smooth mantle should log stage progress while tuning."
Assert-Contains $spider 'mantle timeout stage=%d pos=%s landing=%s remain=%\.1f' "Spider smooth mantle should log where it timed out."
Assert-Contains $spider 'mantle blocked stage=%d pos=%s next=%s hit=%s startsolid=%s fraction=%\.2f' "Spider smooth mantle should log blocking hull trace details."
Assert-Contains $spider 'print\("\[BMB spider climb\] start normal="' "Spider climb should always print start diagnostics during Phase 1 tuning."
Assert-Contains $spider 'print\("\[BMB spider climb\] finish "' "Spider climb should always print finish diagnostics during Phase 1 tuning."
Assert-Contains $spider 'BMBSpiderClimbGoalZ' "Spider climb should accumulate planned height instead of depending on GetPos after NextBot correction."
Assert-Contains $spider 'z=%\.1f actual=%\.1f dz=%\.1f' "Spider climb should print planned and actual height progress during Phase 1 tuning."
Assert-Contains $spider 'climbPos\.z\s*<\s*mantle\.topZ\s*-\s*self:GetBMBSpiderClimbMantleStartBelow\(\)' "Spider mantle should wait until the body reaches the real ledge instead of the raised landing point."
Assert-Contains $spider 'plannedMantleReason\s*==\s*"not_ready"\s*and\s*plannedMantle' "Lost wall near the ledge should keep climbing to the mantle threshold instead of failing."
Assert-Contains $spider 'ledgeZ\s*=\s*math\.min\(desired\.z,\s*plannedMantle\.topZ\s*-\s*self:GetBMBSpiderClimbMantleStartBelow\(\)\)' "Spider should bridge the small no-wall zone at the top before mantle."
Assert-Contains $spider 'HandleBMBSpiderClimbHold\(climbPos,\s*normal,\s*mantleReason\)' "Blocked mantle should hold briefly, then give up instead of ending the climb immediately."
Assert-Contains $spider 'HandleBMBSpiderClimbHold\(planned,\s*normal,\s*"top_blocked"\)' "Ceiling/top obstruction should hold briefly, then descend and wander elsewhere."
Assert-Contains $spider 'FinishBMBSpiderClimbSpike\("giveup"\)' "Blocked climb give-up should finish the climb and restore normal locomotion."
Assert-Contains $spider 'self:SetBMBMoveMode\("climb_descend"\)' "Blocked climb give-up should expose a climb_descend debug move mode."
Assert-Contains $spider 'ClearBMBDebugMove' "Spider climb should clear debug movement when the climb spike takes over."
Assert-Contains $spider 'RunBMBSpiderClimbSpike\(\)(?s).*RunBMBDebugMove' "Spider climb spike should run before debug movement so wall-contact tests can hand off to climb."
Assert-Contains $spider 'BMBSpiderClimbCooldownUntil' "Spider climb should cooldown after fail/success instead of immediately re-entering."
Assert-Contains $spider 'if self\.BMBSpiderClimbing then return false end' "Spider climb should guard against re-entry from path override hooks."
Assert-Contains $spider 'function ENT:BeginBMBSpiderClimbMoveTypeOverride\(\)' "Spider climb should save and override movetype while SetPos drives vertical motion."
Assert-Contains $spider 'self:SetMoveType\(MOVETYPE_NONE\)' "Spider climb should disable NextBot movetype during the SetPos climb spike."
Assert-Contains $spider 'function ENT:RestoreBMBSpiderClimbMoveTypeOverride\(\)' "Spider climb should restore the saved movetype on every finish path."
Assert-Contains $spider 'RestoreBMBSpiderClimbMoveTypeOverride\(\)(?s).*RestoreBMBStepHeight' "Spider climb finish should restore movetype before leaving climb state."
Assert-Contains $spider 'function ENT:TryBMBMoveOverride\(reason,\s*target\)' "Spider should expose a base movement override hook for active climbing."

Assert-Contains $base 'function ENT:TryBMBMoveOverride\(reason,\s*target\)' "Base mob should expose a no-op movement override hook."
Assert-Contains $base 'function ENT:RunBMBMoveOverride\(reason,\s*target\)' "Base mob should wrap movement override calls safely."
Assert-Contains $base 'RunBMBMoveOverride\("move_to",\s*destination\)' "Move requests should give spider climb a proactive wall check."
Assert-Contains $base 'RunBMBMoveOverride\("source_path",\s*destination\)' "Source path movement should be interruptible by spider climb."
Assert-Contains $base 'RunBMBMoveOverride\("path",\s*final\)' "A* path movement should be interruptible by spider climb."
Assert-Contains $base 'RunBMBMoveOverride\("path_carrot",\s*carrot\)' "A* path carrots should give spider climb a target-direction wall check."
Assert-Contains $base 'RunBMBMoveOverride\("direct",\s*destination\)' "Direct fallback movement should be interruptible by spider climb."

Assert-NotContains $spider 'Pack\.Run|SeekTarget\.Find' "Spider should not pull in pack behavior or active target scanning."

Write-Host "Spider Phase 1 checks passed."
