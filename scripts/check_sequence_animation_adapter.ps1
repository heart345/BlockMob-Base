$ErrorActionPreference = "Stop"

function Assert-Contains([string]$relativePath, [string]$pattern, [string]$message) {
    $path = Join-Path (Get-Location) $relativePath
    $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    if ($text -notmatch $pattern) {
        throw "ERROR: ${relativePath}: ${message}"
    }
}

$base = "gmod_addon\lua\entities\bmb_base_mob.lua"

Assert-Contains $base "AnimationSequences" "Base should expose per-mob logical action to model sequence mapping."
Assert-Contains $base "LookupBMBAnimationSequence" "Base should cache LookupSequence calls for exported model sequence names."
Assert-Contains $base "ResolveBMBAnimationSequence" "Base should resolve missing actions/sequences through idle fallback."
Assert-Contains $base "LookupSequence\(sequenceName\)" "Base should use model sequence names verbatim instead of ACT-only mapping."
Assert-Contains $base "ResetSequence\(sequenceId\)" "Base should reset to the chosen sequence when logical animation changes."
Assert-Contains $base "SetPlaybackRate" "Base should scale sequence playback rate from movement speed."
Assert-Contains $base "action == `"walk`" or action == `"run`"" "Movement actions should use speed-scaled playback."
Assert-Contains $base "sequenceId, sequenceName, resolvedAction" "Playback rate should use the resolved sequence/action after idle fallback."

Write-Host "Sequence animation adapter checks passed."
