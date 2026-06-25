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

$status = "gmod_addon\lua\bmb\sv_status_effects.lua"
$base = "gmod_addon\lua\entities\bmb_base_mob.lua"
$autorun = "gmod_addon\lua\autorun\bmb_autorun.lua"
$menu = "gmod_addon\lua\autorun\mcgm_autorun.lua"
$caveSpider = "gmod_addon\lua\entities\bmb_cave_spider.lua"

Assert-Contains $autorun 'addServerFile\("bmb/sv_status_effects\.lua"\)' "autorun should include the server status-effect framework."
Assert-Contains $base 'include\("bmb/sv_status_effects\.lua"\)' "base mob should include status effects for entity-load ordering."
Assert-Contains $base 'BMB\.Status\.ClearAll\(self\)' "base death should clear active status effects."

Assert-Contains $status 'BMB\.Status\s*=\s*BMB\.Status\s*or\s*\{\}' "status framework should live under BMB.Status."
Assert-Contains $status 'function status\.Apply\(target,\s*effectType,\s*params\)' "status framework should expose BMB.Status.Apply."
Assert-Contains $status 'hook\.Add\("Think",\s*"BMB\.Status\.Tick"' "status effects should use one centralized Think hook, not per-effect timers."
Assert-NotContains $status 'timer\.Create|timer\.Simple' "status effects should not open one timer per effect."
Assert-Contains $status 'status\.Effects\.poison' "poison DoT should be a built-in status effect."
Assert-Contains $status 'status\.Effects\.slowness' "slowness movespeed multiplier should be built in."
Assert-Contains $status 'status\.Effects\.weakness' "weakness attack damage debuff should be built in."
Assert-Contains $status 'capturePlayerMoveBaseline' "player speed debuffs should store a baseline speed."
Assert-Contains $status 'captureMobMoveBaseline' "mob speed debuffs should store baseline movement fields."
Assert-Contains $status 'baseline\.walk \* mult \+ add' "player movespeed should be recomputed from baseline, not repeatedly multiplied from current speed."
Assert-Contains $status 'value \* mult \+ add' "mob stat values should be recomputed from baseline values."
Assert-Contains $status 'hook\.Add\("EntityTakeDamage",\s*"BMB\.Status\.WeaknessDamageScale"' "player weakness should be applied through the global damage hook."
Assert-Contains $status 'attacker:IsPlayer\(\)' "weakness damage hook should only compensate player attackers; BMB mobs use AttackDamage field recompute."
Assert-Contains $status 'damageInfo:ScaleDamage\(scale\)' "player weakness should scale damage during damage resolution."
Assert-NotContains $status 'SetWalkSpeed[^\r\n]+weakness|SetRunSpeed[^\r\n]+weakness' "weakness should not try to mutate player movement or weapon fields."

Assert-Contains $caveSpider 'ENT\.Base\s*=\s*"bmb_spider"' "cave spider should inherit spider behavior."
Assert-Contains $caveSpider 'ENT\.Model\s*=\s*"models/mcgm/cave_spider/cave_spider\.mdl"' "cave spider should use the converted cave spider model."
Assert-Contains $caveSpider 'ENT\.CollisionMins\s*=\s*Vector\(-13,\s*-13,\s*0\)' "cave spider should override X/Y collision width for narrow pathing."
Assert-Contains $caveSpider 'ENT\.CollisionMaxs\s*=\s*Vector\(13,\s*13,\s*22\)' "cave spider should override collision height for its smaller body."
Assert-Contains $caveSpider 'BMB\.Status\.Apply\(target,\s*"poison"' "cave spider melee should apply poison through the status framework."
Assert-Contains $caveSpider 'source\s*=\s*self' "cave spider poison should attribute damage to the spider."
Assert-Contains $menu '"bmb_cave_spider"' "spawn menu should register BMB Cave Spider."

Write-Host "Status effect framework checks passed."
