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

Assert-Contains $base "function\s+ENT:RecordBMBStrandedEscapeFailure\s*\(" "stranded bail-out must remember blocked directions"
Assert-Contains $base "function\s+ENT:IsBMBStrandedEscapeDirectionBlocked\s*\(" "stranded escape search must skip recently blocked directions"
Assert-Contains $base "BMBStrandedEscapeKey" "stranded movement must carry a direction key into failure handling"
Assert-Contains $base "stranded_bail_retry" "HUD mode should expose stranded retry instead of freezing on blocked"

Assert-Contains $base "function\s+ENT:MaintainBMBDropAir\s*\(" "drop edges need an air handler that preserves facing/velocity"
Assert-Contains $base "activeAction\s*==\s*""drop""[\s\S]*MaintainBMBDropAir" "drop branch must not use generic air steering that can turn backward"

Assert-Contains $base "function\s+ENT:OnBMBPhysgunDrop\s*\(" "physgun drop should have an explicit recovery hook"
Assert-Contains $base "OnBMBPhysgunDrop[\s\S]*ClearBMBMovementInterrupt" "physgun drop must clear the pickup movement interrupt so wander can resume"
Assert-Contains $base "OnBMBPhysgunDrop[\s\S]*MaintainBMBMoveSpeed\(self\.WalkSpeed or 80\)" "physgun drop must restore a non-zero desired speed budget"
Assert-Contains $base "OnBMBPhysgunDrop[\s\S]*BMBInitialIdleUntil\s*=\s*0" "physgun drop should not leave sheep stuck behind the spawn idle gate"

Assert-Contains $base "BlockHopLaunchLateralToleranceScale" "hop launch must define a lateral alignment tolerance"
Assert-Contains $base "lateralOffset" "hop launch must measure lateral offset from the intended launch line"
Assert-Contains $base "reason\s*=\s*""align""" "hop launch must steer to alignment before jumping"
Assert-Contains $base "local\s+setupTarget\s*=\s*backoff" "hop setup target should default to the launch/backoff point"
Assert-Contains $base "distance\s*>\s*maxDistance[\s\S]*steerTarget\s*=\s*setupTarget" "far hop approach should aim at launch/setup point, not the block face"

Assert-Contains $base "NextThink\(CurTime\(\)\)" "entity Think must stay every tick for smooth nextbot movement"
Assert-NotContains $base "NextThink\(CurTime\(\)\s*\+\s*\(self\.ThinkInterval" "many-mob scaling must not throttle the whole entity Think"

Assert-Contains "docs\STATE.md" "stranded_bail_retry" "STATE.md must document blocked stranded retry behavior"
Assert-Contains "CLAUDE.md" "air steer/FaceTowards" "CLAUDE.md must record the no-backturn drop rule"

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Host "ERROR: $_" }
    exit 1
}

Write-Host "Movement recovery/scaling checks passed."
