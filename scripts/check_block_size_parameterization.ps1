param(
    [string]$Root = (Resolve-Path -LiteralPath "$PSScriptRoot\..").Path
)

$ErrorActionPreference = "Stop"

$luaRoot = Join-Path $Root "gmod_addon\lua"
$failures = New-Object System.Collections.Generic.List[string]

function Get-RelativePath([string]$path) {
    $fullRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd('\')
    $fullPath = [System.IO.Path]::GetFullPath($path)

    if ($fullPath.StartsWith($fullRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $fullPath.Substring($fullRoot.Length + 1)
    }

    return $path
}

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

Assert-Contains "gmod_addon\lua\bmb\sh_config.lua" "BMB\.DefaultBlockSize\s*=\s*36\.5\b" "mock fallback must match MCSWEP 36.5"
Assert-Contains "gmod_addon\lua\bmb\sh_config.lua" "BMB\.BS\s*=" "BMB.BS must be the shared block-size cache"
Assert-Contains "gmod_addon\lua\bmb\sh_config.lua" "MC\s+and\s+MC\.BS" "BMB block size must prefer MC.BS at runtime"

Assert-Contains "gmod_addon\lua\entities\bmb_base_mob.lua" "BlockHopStepHeightScale\s*=\s*0\.49\b" "hop step height must be expressed as < half block"
Assert-Contains "gmod_addon\lua\entities\bmb_base_mob.lua" "MaxStepDownScale\s*=\s*1\.1\b" "one-block drop safety must be expressed as block scale"
Assert-Contains "gmod_addon\lua\entities\bmb_base_mob.lua" "PathNodeToleranceScale\s*=\s*0\.5\b" "waypoint tolerance must be expressed as block scale"
Assert-Contains "gmod_addon\lua\entities\bmb_sheep.lua" "WanderDistanceMinCells\s*=\s*3\b" "wander distance must be expressed in cells"
Assert-Contains "gmod_addon\lua\entities\bmb_sheep.lua" "FleePanicMinDistanceCells\s*=\s*1\b" "flee minimum distance must be expressed in cells"

Assert-NotContains "gmod_addon\lua\entities\bmb_base_mob.lua" "\b(BMB\.Config\.BlockSize|or\s+36(?!\.5)|BlockHopStepHeight\s*=\s*18|BlockHopApex\s*=\s*45|MaxStepDown\s*=\s*40|PathNodeTolerance\s*=\s*18|SourcePathGoalTolerance\s*=\s*18|PathCarrotMinDistance\s*=\s*72|PathCornerSlowDistance\s*=\s*72)\b" "size-derived constants must use BMB.BS scales"
Assert-NotContains "gmod_addon\lua\entities\bmb_sheep.lua" "\b(WanderDistanceMin\s*=\s*108|WanderDistanceMax\s*=\s*288|FleePanicRadius\s*=\s*180|FleePanicMinDistance\s*=\s*36)\b" "sheep distances must use cell counts"

$luaFiles = Get-ChildItem -LiteralPath $luaRoot -Recurse -File -Filter *.lua
foreach ($file in $luaFiles) {
    $relative = Get-RelativePath $file.FullName
    $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8

    if ($relative -ne "gmod_addon\lua\bmb\sh_config.lua" -and $text -match "BMB\.Config\.BlockSize") {
        Add-Failure("${relative}: use BMB.GetBlockSize()/BMB.BS instead of BMB.Config.BlockSize")
    }

    if ($text -match "or\s+36(?!\.5)") {
        Add-Failure("${relative}: found stale block-size fallback 'or 36'")
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Host "ERROR: $_" }
    exit 1
}

Write-Host "Block-size parameterization checks passed."
