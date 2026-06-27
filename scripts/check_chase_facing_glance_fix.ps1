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

$behaviors = "gmod_addon\lua\bmb\sv_behaviors.lua"
$base = "gmod_addon\lua\entities\bmb_base_mob.lua"

Assert-Contains $behaviors 'bmb_chase_direct_resuppress_time' "Chase should expose a direct retry suppression convar."
Assert-Contains $behaviors 'BMBChaseDirectSuppressUntil' "Chase should remember a failed direct attempt briefly."
Assert-Contains $behaviors 'CurTime\(\) >= directSuppressUntil and BMB\.Behaviors\.Chase\.CanDirect' "Chase should skip direct retries while suppressed."
Assert-Contains $behaviors 'mob\.BMBChaseDirectSuppressUntil = nil' "A successful direct chase should clear suppression."
Assert-Contains $behaviors 'getConVarFloat\("bmb_chase_direct_resuppress_time", mob\.ChaseDirectReSuppressTime or 0\.6\)' "Direct retry suppression should be tunable per convar or mob."

Assert-Contains $base 'self:FaceTarget\(carrot\)' "Grounded path-follow facing should use the smoothed carrot point."
Assert-NotContains $base 'path_hop_wait[\s\S]{0,260}FaceTarget\(actionNode\)' "Hop wait should not turn back to the raw hop node."
Assert-NotContains $base 'self\.HopOnlyLocomotion[\s\S]{0,360}FaceTarget\(launch\.target\)' "Hop-only setup should not face the backoff/setup target."

Write-Host "Chase facing glance fix checks passed."
