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

$baseMob = "gmod_addon\lua\entities\bmb_base_mob.lua"
$zombie = "gmod_addon\lua\entities\bmb_zombie.lua"
$skeleton = "gmod_addon\lua\entities\bmb_skeleton.lua"
$husk = "gmod_addon\lua\entities\bmb_husk.lua"
$stray = "gmod_addon\lua\entities\bmb_stray.lua"
$arrow = "gmod_addon\lua\entities\bmb_arrow.lua"

Assert-Contains $arrow "dmg:SetAttacker\(IsValid\(self\.BMBArrowOwner\) and self\.BMBArrowOwner or self\)" "Arrow damage attacker must be the shooter, not the arrow entity"
Assert-Contains $arrow "filter\s*=\s*\{\s*self,\s*self\.BMBArrowOwner\s*\}" "Arrow trace should ignore its shooter but still credit shooter as attacker"

Assert-Contains $baseMob "function\s+ENT:IsBMBCombatTarget\s*\(" "BaseMob must define the common combat-target validity gate"
Assert-Contains $baseMob "function\s+ENT:TryBMBRetaliate\s*\(" "BaseMob must own the damage-retaliation target override"
Assert-Contains $baseMob "self\.TargetEntity\s*=\s*attacker" "Retaliation must write the shared TargetEntity slot"
Assert-Contains $baseMob "self:TryBMBRetaliate\(damageInfo\)" "OnInjured must invoke the common retaliation hook"
Assert-Contains $baseMob "RetaliateSameClass" "Retaliation must expose a same-class friendly-fire toggle"

Assert-Contains $zombie "function\s+ENT:CanBMBTarget\(target\)\s*[\r\n]+\s*return self:IsBMBCombatTarget\(target\)" "Zombie targeting must accept generic combat targets, not only players"
Assert-Contains $skeleton "function\s+ENT:CanBMBTarget\(target\)\s*[\r\n]+\s*return self:IsBMBCombatTarget\(target\)" "Skeleton targeting must accept generic combat targets, not only players"
Assert-Contains $zombie "self:CanBMBTarget\(self\.TargetEntity\)" "Zombie forced look should follow any current combat target"
Assert-Contains $skeleton "self:CanBMBTarget\(self\.TargetEntity\)" "Skeleton forced look should follow any current combat target"

Assert-NotContains $zombie "function\s+ENT:OnBMBInjured\(damageInfo,\s*_\)[\s\S]*self\.TargetEntity\s*=\s*attacker" "Zombie must not keep per-mob retaliation target logic"
Assert-NotContains $skeleton "function\s+ENT:OnBMBInjured\(damageInfo,\s*_\)[\s\S]*self\.TargetEntity\s*=\s*attacker" "Skeleton must not keep per-mob retaliation target logic"
Assert-NotContains $husk "self\.TargetEntity\s*=\s*attacker" "Husk must use base retaliation, not a player-only duplicate"
Assert-NotContains $stray "self\.TargetEntity\s*=\s*attacker" "Stray must use base retaliation, not a player-only duplicate"

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Host "ERROR: $_" }
    exit 1
}

Write-Host "Retaliation target checks passed."
