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

function Assert-NotContains([string]$relativePath, [string]$pattern, [string]$message) {
    $text = Read-Text $relativePath
    if ($text -match $pattern) {
        Add-Failure("${relativePath}: $message")
    }
}

$real = "gmod_addon\lua\bmb\sv_block_world_real.lua"
$pathfinder = "gmod_addon\lua\bmb\sv_pathfinder.lua"
$baseMob = "gmod_addon\lua\entities\bmb_base_mob.lua"
$config = "gmod_addon\lua\bmb\sh_config.lua"
$zombie = "gmod_addon\lua\entities\bmb_zombie.lua"

# Part A: MCSWEP shape queries wired into the real adapter (pragmatic incremental).
Assert-Contains $real "function\s+cellProvidesStandableTop\s*\(" "Real adapter must derive a standable-top predicate from MCSWEP shape queries"
Assert-Contains $real "MC\.GetCellBlockExtent" "Real adapter must use MC.GetCellBlockExtent for the cell z-envelope (neighbors resolved)"
Assert-Contains $real "MC\.BlockIsFullCube" "Real adapter must keep the full-cube fast path"
Assert-Contains $real "narrowConnectionKinds" "Real adapter must exclude narrow connection blocks (glass pane / fence / wall) from standable tops"
Assert-Contains $real "\.connection" "Narrow-collision detection must read MC.Blocks[id].connection, not guess by block name"
Assert-Contains $real "cellProvidesStandableTop\s*\(\s*below" "HasSupport must use the standable-top predicate for the cell below (slab/stair/step support)"

# CLAUDE.md rule: all block/shape access goes through IBlockWorld. Pathfinder/base must not call MCSWEP shape APIs directly.
Assert-NotContains $pathfinder "MC\.(GetCell|GetBlockExtent|GetBlockShape|BlockBoxes|GetBlockCollisionBoxes|BlockIsFullCube)" "Pathfinder must not call MCSWEP shape APIs directly; go through IBlockWorld"
Assert-NotContains $baseMob "MC\.(GetCell|GetBlockExtent|GetBlockShape|BlockBoxes|GetBlockCollisionBoxes)" "BaseMob must not call MCSWEP shape APIs directly; go through IBlockWorld"

# Part B: ShouldRepath is a single-point TTL stub, with the per-chunk-version replacement marked.
Assert-Contains $pathfinder "function\s+pathfinder\.ShouldRepath\s*\(" "Pathfinder must expose a single ShouldRepath cache-invalidation entry point"
Assert-Contains $pathfinder "PathCacheTTL" "ShouldRepath must use the TTL config (temporary stub)"
Assert-Contains $pathfinder "GetChunkVersion" "ShouldRepath must mark the per-chunk-version replacement as the future plan (TTL is a stub)"
Assert-Contains $pathfinder "bornAt" "FindPath must stamp path birth time for the TTL stub"
Assert-Contains $config "PathCacheTTL" "Config must define PathCacheTTL"
Assert-Contains $baseMob "BMB\.Pathfinder\.ShouldRepath" "MoveAlongPath must consult ShouldRepath at a safe point to self-heal stale paths"

# Cliff churn fix: hysteresis (debounce transient cliff) + drop tolerance (a downhill step is not a cliff).
$behaviors = "gmod_addon\lua\bmb\sv_behaviors.lua"
Assert-Contains $behaviors "BMBCliffSince" "ApplySafePressure must debounce transient cliff (hysteresis) to stop chase path<->cliff churn"
Assert-Contains $behaviors "CliffHysteresisTime" "Cliff hysteresis must use a tunable window"
Assert-Contains $baseMob "CliffHysteresisTime" "BaseMob must expose the cliff hysteresis window"
Assert-NotContains $baseMob "IsBMBGridFootDroppable" "Drop tolerance was reverted: chase_direct must yield downhill steps to A*, not dive down them"
Assert-Contains $behaviors "BMBChaseDirectCliffBlock" "direct pressure must remember confirmed cliff shortcuts so it does not retry the same dead line every segment"
Assert-Contains $behaviors "both chase_direct shortcuts and chase_repath direct pressure" "direct cliff memory must document that it covers chase_direct and chase_repath"
Assert-Contains $behaviors "RememberDirectCliffBlock" "direct cliff memory must be written when direct pressure confirms a cliff"
Assert-Contains $behaviors "ShouldRememberCliffMode" "direct cliff memory must explicitly choose which pressure modes write memory"
Assert-Contains $behaviors 'mode == "chase_direct" or mode == "chase_repath"' "chase_repath cliff failures must write the same direct cliff memory as chase_direct"
Assert-Contains $behaviors "IsDirectCliffBlocked" "CanDirect must consult direct cliff memory before taking the shortcut"
Assert-Contains $behaviors "TryRepathPressure" "chase_repath fallback must consult direct cliff memory before applying direct pressure"
Assert-Contains $behaviors "chase_repath_blocked" "memory-suppressed chase_repath must publish a non-cliff blocked mode instead of flickering chase_repath_cliff"
Assert-Contains $behaviors "chase_repath_giveup" "memory-suppressed chase_repath must keep a give-up exit instead of pinning mobs forever"
Assert-Contains $behaviors "ChaseDirectMaxDistanceCells" "CanDirect must support a max-distance gate so long-range chase can stay on A*"
Assert-Contains $zombie "ChaseDirectMaxDistanceCells\s*=\s*6" "Zombie direct chase should only take over near the target; far chase stays on A*"
Assert-Contains $baseMob "ChaseDirectCliffMemoryCooldown" "BaseMob must expose direct cliff shortcut memory cooldown"
Assert-Contains $behaviors "bmb_chase_cliff_memory_cooldown" "Direct cliff memory cooldown must be tunable in-game"
Assert-Contains $behaviors "bmb_chase_cliff_memory_move_cells" "Direct cliff memory mob movement threshold must be tunable in-game"
Assert-Contains $baseMob "ChaseDirectCliffMemoryDuration\s*=\s*25\.0" "Direct cliff memory should keep a long fallback expiry for dynamic block edits"
Assert-Contains $baseMob "ChaseDirectCliffMemoryMoveCells\s*=\s*6\.0" "Direct cliff memory should require enough detour progress before retrying the same cliff line"
Assert-Contains $baseMob "ChaseRepathCliffBlockedGiveUpTime" "BaseMob must expose a give-up timer for permanently blocked chase_repath pressure"

# Debug tool: snap clicked target to a standable cell (else a fixed unreachable target loops at debug_repath).
Assert-Contains "gmod_addon\lua\weapons\gmod_tool\stools\bmb_debug.lua" "FindNearestStandable|IsStandablePosition" "Debug move target must snap to a standable cell so A* goal is reachable"
Assert-Contains $baseMob "carrot-stops-at-vertical-node" "Carrot must stop at the next hop/drop node so MoveAlongPath can climb/descend stairs instead of stalling in place"

# STATE doc must record this round.
Assert-Contains "docs\STATE.md" "ShouldRepath" "STATE.md must record the path-cache TTL stub"
Assert-Contains "docs\STATE.md" "GetCellBlockExtent" "STATE.md must record the MCSWEP shape-query integration"

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Host "ERROR: $_" }
    exit 1
}

Write-Host "Block-shape pathing checks passed."
