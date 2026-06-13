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

Assert-Contains "gmod_addon\lua\bmb\sv_pathfinder.lua" "function\s+pathfinder\.IsStandablePosition\s*\(" "Pathfinder must expose standable-position checks for stranded detection"
Assert-Contains "gmod_addon\lua\bmb\sv_pathfinder.lua" "function\s+pathfinder\.FindNearestStandable\s*\(" "Pathfinder must expose nearest standable-cell search for recovery targets"
Assert-Contains "gmod_addon\lua\bmb\sv_pathfinder.lua" "allowUnsupportedWalk" "Recovery paths must be able to leave an unsupported but passable start"
Assert-Contains "gmod_addon\lua\entities\bmb_base_mob.lua" "function\s+ENT:ShouldRunBMBStrandedRecovery\s*\(" "BaseMob must detect illegal current support"
Assert-Contains "gmod_addon\lua\entities\bmb_base_mob.lua" "function\s+ENT:HasBMBPhysicalGroundAt\s*\(" "Recovery must be able to distinguish narrow physical support from open fall space"
Assert-Contains "gmod_addon\lua\entities\bmb_base_mob.lua" "function\s+ENT:FindBMBStrandedEscapePoint\s*\(" "Recovery must use local bail-out sampling instead of a wide grid search on panes"
Assert-Contains "gmod_addon\lua\entities\bmb_base_mob.lua" "function\s+ENT:MoveBMBStrandedBailOut\s*\(" "BaseMob must provide short bail-out steering for illegal-grid recovery"
Assert-Contains "gmod_addon\lua\entities\bmb_base_mob.lua" "function\s+ENT:RunBMBStrandedRecovery\s*\(" "BaseMob must run a recovery move to legal ground"
Assert-Contains "gmod_addon\lua\entities\bmb_base_mob.lua" "MoveBMBStrandedBailOut\s*\(" "Recovery must nudge off illegal narrow support instead of pathing along it"
Assert-Contains "gmod_addon\lua\entities\bmb_base_mob.lua" "stranded_bail" "HUD mode must expose bail-out recovery"
Assert-Contains "gmod_addon\lua\entities\bmb_sheep.lua" "RunBMBStrandedRecovery" "Sheep state machine must try stranded recovery before normal goals"
Assert-Contains "docs\STATE.md" "StrandedRecovery" "STATE.md must record the stranded recovery behavior"
Assert-Contains "CLAUDE.md" "StrandedRecovery" "CLAUDE.md must document the stranded recovery rule"
Assert-NotContains "gmod_addon\lua\entities\bmb_base_mob.lua" "ENT\.StrandedRecoveryRadiusCells\s*=\s*16" "Default stranded recovery must not run wide grid searches every retry"

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Host "ERROR: $_" }
    exit 1
}

Write-Host "Stranded recovery checks passed."
