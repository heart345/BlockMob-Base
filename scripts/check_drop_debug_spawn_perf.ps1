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

$base = "gmod_addon\lua\entities\bmb_base_mob.lua"
$sheep = "gmod_addon\lua\entities\bmb_sheep.lua"
$behaviors = "gmod_addon\lua\bmb\sv_behaviors.lua"
$config = "gmod_addon\lua\bmb\sh_config.lua"
$pathfinder = "gmod_addon\lua\bmb\sv_pathfinder.lua"

Assert-Contains $base "DropAirMaxHorizontalSpeedScale" "drop air should cap horizontal carry instead of keeping full walk/run speed"
Assert-Contains $base "function\s+ENT:MaintainBMBDropAir\s*\([\s\S]*SetVelocity" "drop air handler must apply the horizontal speed cap without steering backward"

Assert-Contains $base "DebugPathRepathDelay" "debug path should retry failed partial/dead-end routes with a short delay"
Assert-Contains $base "function\s+ENT:RunBMBDebugMove\s*\([\s\S]*while\s+self:HasBMBDebugMove\(\)\s+do[\s\S]*MoveToWorldPosition" "debug target movement must keep replanning until target reached or debug expires"
Assert-Contains $base "acceptPartial\s*=\s*true" "debug path should accept partial progress so it can replan from hop/drop dead ends"
Assert-Contains $base "debug_repath" "debug path failures should not clear the command immediately"

Assert-Contains $sheep "InitialIdleMin" "new sheep should have a spawn idle window before ordinary wander"
Assert-Contains $sheep "BMBInitialIdleUntil" "new sheep should record the end of its initial idle"
Assert-Contains $sheep "RunBMBInitialIdle" "sheep behavior should honor initial idle without blocking debug/flee"

Assert-Contains $base "function\s+ENT:RunBMBInitialIdle\s*\(" "base mob should provide reusable initial idle handling"
Assert-Contains $base "NextThink\(CurTime\(\)\)" "NextBot entity Think must stay every tick for smooth locomotion/interpolation"
Assert-NotContains $base "NextThink\(CurTime\(\)\s*\+\s*\(self\.ThinkInterval" "do not throttle the whole entity Think; throttle expensive maintenance internally"
Assert-Contains $base "PhysicsImpactInterval\s*=\s*0\.3" "periodic physics impact scans should be slower; contact hooks still catch immediate hits"
Assert-Contains $base "NextPhysicsImpactCheck\s*=\s*CurTime\(\)\s*\+\s*math\.Rand" "physics impact scans should be staggered across mobs"

Assert-Contains $config "PathfinderYieldEvery" "pathfinder time slicing should be centrally configurable"
Assert-Contains $pathfinder "BMB\.Config\.PathfinderYieldEvery" "A* should use the global smaller yield budget for many mobs"
Assert-Contains $behaviors "WanderPathAttempts" "wander should not run many full A* attempts in one behavior tick"
Assert-Contains $behaviors "WanderFailurePause" "failed wander path attempts should back off instead of immediately retrying across many mobs"

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Host "ERROR: $_" }
    exit 1
}

Write-Host "Drop/debug/spawn/perf checks passed."
