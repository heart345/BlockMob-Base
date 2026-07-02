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
Assert-Contains $base "PhysicsImpactMinSpeed\s*=\s*90" "physics impact should use speed only as a low movement gate"
Assert-Contains $base "PhysicsImpactMinMomentum\s*=\s*18000" "physics impact damage threshold should be momentum-based but stronger now that physgun drag is filtered"
Assert-Contains $base "PhysicsImpactMomentumScale\s*=\s*0\.00026" "physics impact damage should scale by momentum with a stronger thrown-prop feel"
Assert-Contains $base "PhysicsImpactMaxDamage\s*=\s*30" "physics impact should stay capped while allowing thrown heavy props to hurt"
Assert-Contains $base "PhysicsPropHeldDamageScale\s*=\s*0" "physgun-held props should not grind mobs down while being dragged"
Assert-Contains $base "BMBPhysgunHeldBy" "physgun pickup/drop hooks should mark held props for physics impact filtering"
Assert-Contains $base "function\s+ENT:IsBMBPhysicsImpactClosing" "physics impact damage should require the prop to be moving into the mob"
Assert-Contains $base "velocity:Dot\(toMob\)\s*>\s*0" "physics impact should ignore outward or tangential prop motion"
Assert-Contains $base "function\s+ENT:ReactToPhysicsImpact[\s\S]*reflected" "physics impact feedback should visibly bounce props instead of only damping velocity"
Assert-Contains $base "createOrMigrateNumberConVar\(""bmb_physics_impact_min_momentum"",\s*18000[\s\S]*\{\s*10000,\s*22000\s*\}" "archived physics impact defaults should migrate to the stronger post-physgun-filter tuning"
Assert-Contains $base "bmb_physics_impact_min_momentum" "physics impact momentum threshold should be tunable in game"
Assert-Contains $base "local momentum\s*=\s*mass \* speed" "physics impact should compute damage from mass times speed"
Assert-Contains $base "\(momentum - minMomentum\) \* self:GetBMBPhysicsImpactMomentumScale\(\)" "physics impact damage should use momentum over threshold"
Assert-NotContains $base "PhysicsImpactDamageScale" "old speed-dominant physics impact damage scaling should stay removed"
Assert-Contains $base "function\s+ENT:CanBMBConsumeHopAsStep" "tall step-height mobs should be able to consume one-block hop nodes as normal steps"
Assert-Contains $base "action == ""hop"" and self:CanBMBConsumeHopAsStep\(\)" "effective waypoint action should remap hop to walk for mobs that can step one block"
Assert-Contains $base "local verticalNode\s*=\s*verticalAction or waypointVerticalAction" "hop-as-step should preserve vertical-node safety exemptions while using walk steering"

Assert-Contains $config "PathfinderYieldEvery" "pathfinder time slicing should be centrally configurable"
Assert-Contains $pathfinder "BMB\.Config\.PathfinderYieldEvery" "A* should use the global smaller yield budget for many mobs"
Assert-Contains $behaviors "WanderPathAttempts" "wander should not run many full A* attempts in one behavior tick"
Assert-Contains $behaviors "WanderFailurePause" "failed wander path attempts should back off instead of immediately retrying across many mobs"

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Host "ERROR: $_" }
    exit 1
}

Write-Host "Drop/debug/spawn/perf checks passed."
