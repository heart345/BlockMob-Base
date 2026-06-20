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

$baseMob = "gmod_addon\lua\entities\bmb_base_mob.lua"
$skeleton = "gmod_addon\lua\entities\bmb_skeleton.lua"

Assert-Contains $baseMob "function\s+ENT:GetBMBMCLightBrightness\s*\(" "BaseMob must sample Minecraft lighting for model rendering"
Assert-Contains $baseMob "MC\.WorldToCell" "BMB model lighting must use MC.WorldToCell for sample coordinates"
Assert-Contains $baseMob "MC\.SampleLighting" "BMB model lighting must use MC.SampleLighting so mc_light_enable controls it"
Assert-Contains $baseMob "function\s+ENT:DrawBMBModelWithMCLight\s*\(" "BaseMob must centralize lit model drawing"
Assert-Contains $baseMob "DrawBMBModelWithMCLight\(self,\s*1,\s*gb,\s*gb\)" "Hurt/death red flash must be multiplied by MC lighting"
Assert-Contains $baseMob "DrawBMBModelWithMCLight\(self\)" "Normal model drawing must be multiplied by MC lighting"
Assert-Contains $skeleton "DrawBMBModelWithMCLight\(bow\)" "Skeleton-family held bow must use the same MC lighting as the mob model"

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Host "ERROR: $_" }
    exit 1
}

Write-Host "MC lighting compatibility checks passed."
