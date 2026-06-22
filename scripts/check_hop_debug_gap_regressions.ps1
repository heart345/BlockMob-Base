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

$base = "gmod_addon\lua\entities\bmb_base_mob.lua"
$tool = "gmod_addon\lua\weapons\gmod_tool\stools\bmb_debug.lua"

Assert-Contains $base "BlockHopLaunchGroundProbeDown" "block hop launch should use a short physical ground probe to prevent airborne false starts"
Assert-Contains $base "function\s+ENT:IsBMBBlockHopLaunchGrounded" "block hop launches need a strict shared grounded predicate"
Assert-Contains $base "BlockHopPostKnockbackSuppressDuration" "block hop should have a short post-knockback landing suppression window"
Assert-Contains $base "BMBKnockbackSuppressHopOnLand" "vertical knockback should mark the next landing so chase cannot immediately launch a stale path hop"
Assert-Contains $base "function\s+ENT:IsBMBBlockHopSuppressedAfterKnockback" "path hop launch should be gated after knockback landing on voxel terrain"
Assert-Contains $base "path_hop_suppressed" "debug HUD should expose when post-knockback hop suppression is active"
Assert-Contains $base "function\s+ENT:StartBMBBlockHop[\s\S]*IsBMBBlockHopLaunchGrounded\(\)[\s\S]*self\.loco:Jump\(\)" "StartBMBBlockHop must reject airborne launches before calling loco:Jump"
Assert-Contains $base "local\s+onGround\s*=\s*not\s+hopSuppressed\s+and\s+self:IsBMBBlockHopLaunchGrounded\(\)" "path hop setup should use the strict launch-ground check, not the broad movement ground check"
Assert-Contains $base "local\s+nativeHop,\s*hopStarted\s*=\s*self:StartBMBBlockHop" "path hop setup should know whether the launch actually started"
Assert-Contains $base "if\s+hopStarted\s+then[\s\S]*hopStartedAt\[nodeIndex\]\s*=\s*CurTime\(\)" "blocked airborne hop launches must not be recorded as started attempts"
Assert-Contains $base "BlockHopLaunchMinFaceDistanceScale" "BlockHop should gate launch by distance from the block face, not just center distance"
Assert-Contains $base "BlockHopLaunchIdealFaceDistanceScale" "BlockHop backoff should target a face-distance launch point"
Assert-Contains $base "faceDistance\s*>=\s*minFaceDistance" "hop ready condition must reject face-close launches"
Assert-Contains $base "reason\s*=\s*""face_close""" "HUD/debug should distinguish face-close hop setup from generic close distance"
Assert-Contains $base "BlockHopAllowCloseLaunch" "some hostile mobs need a close-lift hop fallback when cramped geometry makes backoff impossible"
Assert-Contains $base "reason\s*=\s*""close_lift""" "close-lift launches should be diagnosable in hop logs/HUD"
Assert-Contains $base "BlockHopAllowBlockedCloseLaunch" "base mobs should have a guarded close-lift fallback when the ideal hop backoff point is blocked"
Assert-Contains $base "reason\s*=\s*""blocked_close_lift""" "blocked-backoff hop launches should be diagnosable in hop logs/HUD"
Assert-Contains $base "backoffBlocked" "hop setup logs should expose whether the ideal launch backoff point is blocked"
Assert-Contains $base "function\s+ENT:IsBMBHopLaunchCeilingClear" "hop launch setup should reject backoff points that are standable but have too little overhead lift clearance"
Assert-Contains $base "currentLiftClear\s*==\s*true" "hop ready/close-lift launch should require overhead clearance at the actual launch point"
Assert-Contains $base "backoffLiftClear" "hop setup logs should expose when the ideal backoff point is blocked by launch ceiling clearance"
Assert-Contains $base "BlockHopCeilingBlockedCloseMinFaceDistanceScale" "low-ceiling blocked-backoff hops need a slightly wider close launch window to avoid oscillating around one face-distance value"
Assert-Contains $base "effectiveBlockedCloseMinFaceDistance" "hop setup logs should expose the effective close-lift face threshold"
Assert-Contains $base "function\s+ENT:IsBMBVerticalPathNodeReached" "vertical path nodes need a shared reached predicate"
Assert-Contains $base "targetFootZ" "vertical hop/drop completion must compare actual foot height, not only 2D distance"
Assert-Contains $base "local\s+deltaZ\s*=\s*self:GetPos\(\)\.z - targetFootZ" "vertical hop/drop completion should use settled foot height, not fragile WorldToBlock z equality at block boundaries"
Assert-Contains $base "deltaZ\s*>=\s*-downTolerance\s*and\s*deltaZ\s*<=\s*upTolerance" "vertical hop/drop completion should use explicit lower/upper foot-height tolerances"
Assert-Contains $base "DropVerticalReachUpToleranceScale" "drop completion should allow a slightly higher settled foot position without weakening hop completion"
Assert-Contains $base "BlockHopVerticalOvershootToleranceScale" "hop completion should treat a grounded one-cell upward overshoot near the node as path progress instead of forcing debug repath"
Assert-Contains $base "function\s+ENT:LogBMBHopSetup" "hop debug log should expose setup/backoff reasons for cramped one-block launch failures"
Assert-Contains $base "function\s+ENT:LogBMBVerticalReach" "hop debug log should expose foot-height reach decisions"
Assert-Contains $base "IsBMBVerticalPathNodeReached\(final\)" "final hop/drop nodes must not be accepted before the vertical move actually lands"
Assert-Contains $base "IsBMBVerticalPathNodeReached\(node\)" "hop/drop node advancement must wait for the entity to reach the target level"

Assert-Contains $base "DebugPathCommandTimeout" "debug target movement needs a long command lifetime for maze/hop paths"
Assert-Contains $tool "DebugPathCommandTimeout" "tool right-click target moves must use the debug path command timeout"
Assert-Contains $base "DebugPathProgressGrace" "debug path should extend while it is making progress"
Assert-Contains $base "BMBPathAdvanceCount" "debug path progress extension should consider node advancement"
Assert-Contains $base "BMBDebugMoveUntil\s*=\s*math\.max" "debug path progress should refresh the command expiry instead of dropping to wander"

Assert-Contains $base "IsBMBPathLineStandable" "carrot visibility must reject unsupported shortcuts over gaps"
Assert-Contains $base "Pathfinder\.IsStandablePosition" "gap check should use the same standable semantics as A*"
Assert-Contains $base "IsPathGridVisible\(rawCarrot" "carrot selection must run the grounded visibility check"
Assert-Contains $base "IsPathGridVisible\(candidate" "carrot bisection must also use the grounded visibility check"

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Host "ERROR: $_" }
    exit 1
}

Write-Host "Hop/debug/gap regression checks passed."
