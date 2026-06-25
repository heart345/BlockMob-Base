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
$stray = "gmod_addon\lua\entities\bmb_stray.lua"
$parched = "gmod_addon\lua\entities\bmb_parched.lua"
$bogged = "gmod_addon\lua\entities\bmb_bogged.lua"
$skeleton = "gmod_addon\lua\entities\bmb_skeleton.lua"
$arrow = "gmod_addon\lua\entities\bmb_arrow.lua"

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

Assert-Contains $arrow 'function\s+ENT:NotifyBMBArrowHit' "arrow should expose a confirmed-hit owner callback for skeleton-family special arrows."
Assert-Contains $arrow 'owner:OnBMBArrowHit\(target,\s*damageInfo,\s*trace,\s*self\)' "arrow callback should pass target, damage info, trace, and arrow to the shooter."
Assert-Contains $arrow 'PlayBMBArrowPlayerHitSound\(hitEnt\)' "arrow hits on players should play the MC damage hit sound."
Assert-Contains $skeleton 'bmb_bogged\s*=\s*\{' "bogged should have an explicit skeleton-family sound set."
Assert-Contains $skeleton 'bmb/mob/bogged/ambient1\.ogg' "bogged ambient sounds should be selected by skeleton-family sound lookup."
Assert-Contains $skeleton 'bmb/mob/bogged/death\.ogg' "bogged death sound should be selected by skeleton-family sound lookup."
Assert-Contains $stray 'function\s+ENT:OnBMBArrowHit' "stray should hook confirmed arrow hits."
Assert-Contains $stray 'StraySlownessDuration\s*=\s*5' "stray slowness arrows should last 5 seconds."
Assert-Contains $stray 'BMB\.Status\.Apply\(target,\s*"slowness"' "stray arrows should apply slowness through the status framework."
Assert-Contains $stray 'source\s*=\s*self' "stray slowness should attribute the effect to the stray shooter."
Assert-Contains $parched 'function\s+ENT:OnBMBArrowHit' "parched should hook confirmed arrow hits."
Assert-Contains $parched 'ParchedWeaknessDuration\s*=\s*5' "parched weakness arrows should last 5 seconds."
Assert-Contains $parched 'BMB\.Status\.Apply\(target,\s*"weakness"' "parched arrows should apply weakness through the status framework."
Assert-Contains $parched 'source\s*=\s*self' "parched weakness should attribute the effect to the parched shooter."
Assert-Contains $bogged 'ENT\.Base\s*=\s*"bmb_skeleton"' "bogged should inherit skeleton ranged behavior."
Assert-Contains $bogged 'ENT\.Model\s*=\s*"models/mcgm/bogged/bogged\.mdl"' "bogged should use the converted bogged model."
Assert-Contains $bogged 'function\s+ENT:OnBMBArrowHit' "bogged should hook confirmed arrow hits."
Assert-Contains $bogged 'BMB\.Status\.Apply\(target,\s*"poison"' "bogged arrows should apply poison through the status framework."
Assert-Contains $bogged 'source\s*=\s*self' "bogged poison should attribute damage to the bogged shooter."
Assert-Contains $menu '"bmb_bogged"' "spawn menu should register BMB Bogged."

Write-Host "Status effect framework checks passed."
