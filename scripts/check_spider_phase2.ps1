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

$spider = "gmod_addon\lua\entities\bmb_spider.lua"

Assert-Contains $spider 'RetaliateOnDamage\s*=\s*true' "Spider Phase 2 should enable base damage retaliation."
Assert-Contains $spider 'TargetRange\s*=\s*820' "Spider Phase 2 should define a bounded target range for retaliation validation."
Assert-Contains $spider 'TargetLoseRange\s*=\s*1050' "Spider Phase 2 should define a bounded lose range for retaliation validation."
Assert-Contains $spider 'function ENT:CanBMBTarget\(target\)\s*[\r\n]+\s*return self:IsBMBCombatTarget\(target\)' "Spider should allow base retaliation to accept the attacker as a combat target."
Assert-Contains $spider 'function ENT:GetBMBSpiderRetaliationTarget\(\)' "Spider Phase 2 should resolve targets only from existing retaliation state."
Assert-Contains $spider 'BMB\.Behaviors\.SeekTarget\.IsValid\(self,\s*self\.BMBRetaliationTarget' "Spider should validate the base retaliation target before chasing."
Assert-Contains $spider 'function ENT:OnBMBInjured\(_damageInfo,\s*_wasFleeing\)' "Spider should wake out of initial idle when attacked."
Assert-Contains $spider 'self\.BMBInitialIdleUntil\s*=\s*0' "Spider retaliation should cancel spawn idle."

Assert-Contains $spider 'function ENT:RunBMBSpiderAI\(\)(?s).*self\.TargetEntity\s*=\s*self:GetBMBSpiderRetaliationTarget\(\)' "Spider AI should use the retaliation target, not active scanning."
Assert-Contains $spider 'BMB\.Behaviors\.MeleeAttack\.Try\(self,\s*self\.TargetEntity\)' "Spider Phase 2 should reuse shared melee attack."
Assert-Contains $spider 'BMB\.Behaviors\.Leap\.Try\(self,\s*self\.TargetEntity\)' "Spider Phase 2 should reuse shared leap pounce."
Assert-Contains $spider 'BMB\.Behaviors\.Chase\.Run\(self,\s*self\.TargetEntity\)' "Spider Phase 2 should reuse shared chase."
Assert-Contains $spider 'BMB\.Behaviors\.Chase\.TryRepathPressure' "Spider Phase 2 should use shared chase pressure fallback when a path segment fails."

Assert-Contains $spider 'LeapEnabled\s*=\s*true' "Spider leap should be opt-in through shared leap parameters."
Assert-Contains $spider 'LeapMinDistanceCells\s*=\s*1\.35' "Spider leap should have a tuned minimum distance."
Assert-Contains $spider 'LeapMaxDistanceCells\s*=\s*4\.0' "Spider leap should have a tuned maximum distance."
Assert-Contains $spider 'LeapChance\s*=\s*0\.65' "Spider leap should use the faster Phase 2 pounce frequency."
Assert-Contains $spider 'LeapAttemptInterval\s*=\s*0\.3' "Spider leap should retry eligibility checks more often after the frequency tuning."
Assert-Contains $spider 'LeapCooldownMin\s*=\s*1\.2' "Spider leap should use the faster Phase 2 minimum cooldown."
Assert-Contains $spider 'LeapCooldownMax\s*=\s*2\.4' "Spider leap should use the faster Phase 2 maximum cooldown."
Assert-Contains $spider 'AttackRange\s*=\s*54' "Spider melee should have a tuned attack range."
Assert-Contains $spider 'AttackDamage\s*=\s*6' "Spider melee should define its own damage."

Assert-NotContains $spider 'SeekTarget\.Find' "Spider must remain neutral and never actively scan for players."
Assert-NotContains $spider 'Pack\.Run' "Spider Phase 2 should not add pack/flank behavior."

Write-Host "Spider Phase 2 checks passed."
