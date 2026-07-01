BMB = BMB or {}
BMB.Status = BMB.Status or {}

local status = BMB.Status

status.Effects = status.Effects or {}
status.Tracked = status.Tracked or {}

local poisonDamageType = DMG_POISON or DMG_GENERIC or 0

status.Effects.poison = {
    kind = "dot",
    interval = 1.0,
    dps = 2,
    damageType = poisonDamageType,
    nonlethal = true,
    undeadImmune = true
}

status.Effects.slowness = {
    kind = "stat_mult",
    stat = "movespeed",
    mult = 0.6
}

status.Effects.weakness = {
    kind = "stat_add",
    stat = "attack_damage",
    delta = -4
}

local function isValidTarget(ent)
    return IsValid(ent) and (ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() or ent.IsBMBMob)
end

local function effectNow()
    return CurTime()
end

local function copyEffectDefaults(effectType)
    local defaults = status.Effects[effectType]
    if not defaults then return nil end

    local effect = {}
    for key, value in pairs(defaults) do
        effect[key] = value
    end

    return effect
end

local function hasActiveStat(ent, statName)
    local effects = ent.BMBStatusEffects
    if not effects then return false end

    for _, effect in pairs(effects) do
        if effect.stat == statName and (effect.kind == "stat_mult" or effect.kind == "stat_add") then
            return true
        end
    end

    return false
end

local function statTotals(ent, statName)
    local mult = 1
    local add = 0
    local active = false
    local effects = ent.BMBStatusEffects
    if not effects then return mult, add, active end

    for _, effect in pairs(effects) do
        if effect.stat == statName then
            if effect.kind == "stat_mult" then
                mult = mult * (tonumber(effect.mult) or 1)
                active = true
            elseif effect.kind == "stat_add" then
                add = add + (tonumber(effect.delta) or 0)
                active = true
            end
        end
    end

    return mult, add, active
end

local function ensureBaselines(ent)
    ent.BMBStatusStatBaselines = ent.BMBStatusStatBaselines or {}
    return ent.BMBStatusStatBaselines
end

local function capturePlayerMoveBaseline(ply)
    local baselines = ensureBaselines(ply)
    if baselines.movespeed then return baselines.movespeed end

    baselines.movespeed = {
        walk = ply:GetWalkSpeed(),
        run = ply:GetRunSpeed()
    }

    return baselines.movespeed
end

local mobMoveSpeedFields = {
    "WalkSpeed",
    "RunSpeed",
    "AttackMoveSpeed",
    "PackMoveSpeed",
    "StrafeSpeed"
}

local function captureMobMoveBaseline(ent)
    local baselines = ensureBaselines(ent)
    if baselines.movespeed then return baselines.movespeed end

    local baseline = {}
    for _, field in ipairs(mobMoveSpeedFields) do
        if isnumber(ent[field]) then
            baseline[field] = ent[field]
        end
    end

    baselines.movespeed = baseline
    return baseline
end

local attackDamageFields = {
    "AttackDamage",
    "MeleeDamage"
}

local function captureAttackDamageBaseline(ent)
    local baselines = ensureBaselines(ent)
    if baselines.attack_damage then return baselines.attack_damage end

    local baseline = {}
    for _, field in ipairs(attackDamageFields) do
        if isnumber(ent[field]) then
            baseline[field] = ent[field]
        end
    end

    baselines.attack_damage = baseline
    return baseline
end

local function restoreMoveSpeed(ent)
    local baselines = ent.BMBStatusStatBaselines
    local baseline = baselines and baselines.movespeed
    if not baseline then return end

    if ent:IsPlayer() then
        if baseline.walk then ent:SetWalkSpeed(baseline.walk) end
        if baseline.run then ent:SetRunSpeed(baseline.run) end
    else
        for field, value in pairs(baseline) do
            ent[field] = value
        end
    end

    baselines.movespeed = nil
end

local function restoreAttackDamage(ent)
    local baselines = ent.BMBStatusStatBaselines
    local baseline = baselines and baselines.attack_damage
    if not baseline then return end

    for field, value in pairs(baseline) do
        ent[field] = value
    end

    baselines.attack_damage = nil
end

local function applyMoveSpeed(ent)
    if not hasActiveStat(ent, "movespeed") then
        restoreMoveSpeed(ent)
        return
    end

    local mult, add = statTotals(ent, "movespeed")

    if ent:IsPlayer() then
        local baseline = capturePlayerMoveBaseline(ent)
        ent:SetWalkSpeed(math.max(1, baseline.walk * mult + add))
        ent:SetRunSpeed(math.max(1, baseline.run * mult + add))
        return
    end

    local baseline = captureMobMoveBaseline(ent)
    for field, value in pairs(baseline) do
        ent[field] = math.max(1, value * mult + add)
    end
end

local function applyAttackDamage(ent)
    if ent:IsPlayer() then return end

    if not hasActiveStat(ent, "attack_damage") then
        restoreAttackDamage(ent)
        return
    end

    local mult, add = statTotals(ent, "attack_damage")
    local baseline = captureAttackDamageBaseline(ent)
    for field, value in pairs(baseline) do
        ent[field] = math.max(0, value * mult + add)
    end
end

function status.RecomputeStat(ent, statName)
    if not isValidTarget(ent) then return end

    if statName == "movespeed" then
        applyMoveSpeed(ent)
    elseif statName == "attack_damage" then
        applyAttackDamage(ent)
    end
end

local function rememberTracked(ent)
    status.Tracked[ent] = true
end

local function mergeEffect(existing, incoming, now)
    local expireAt = incoming.expireAt or now + (incoming.duration or 0)

    if existing then
        incoming.expireAt = math.max(existing.expireAt or 0, expireAt)

        if incoming.kind == "dot" then
            incoming.dps = math.max(tonumber(existing.dps) or 0, tonumber(incoming.dps) or 0)
            incoming.interval = math.min(tonumber(existing.interval) or incoming.interval or 1, tonumber(incoming.interval) or 1)
            incoming.nextTickAt = math.min(existing.nextTickAt or now + incoming.interval, now + incoming.interval)
            incoming.source = incoming.source or existing.source
        elseif incoming.kind == "stat_mult" then
            incoming.mult = math.min(tonumber(existing.mult) or 1, tonumber(incoming.mult) or 1)
        elseif incoming.kind == "stat_add" then
            incoming.delta = math.min(tonumber(existing.delta) or 0, tonumber(incoming.delta) or 0)
        end
    else
        incoming.expireAt = expireAt
        if incoming.kind == "dot" then
            incoming.nextTickAt = now + (incoming.interval or 1)
        end
    end

    return incoming
end

function status.Apply(target, effectType, params)
    if not isValidTarget(target) then return false end

    params = params or {}
    local duration = tonumber(params.duration)
    if not duration or duration <= 0 then return false end

    local now = effectNow()
    local effect = copyEffectDefaults(effectType)
    if not effect then return false end
    if effect.undeadImmune and target.IsUndead then return false end

    for key, value in pairs(params) do
        effect[key] = value
    end

    effect.effectType = effectType
    effect.duration = duration
    effect.expireAt = now + duration

    target.BMBStatusEffects = target.BMBStatusEffects or {}
    local existing = target.BMBStatusEffects[effectType]
    target.BMBStatusEffects[effectType] = mergeEffect(existing, effect, now)

    rememberTracked(target)

    if effect.stat then
        status.RecomputeStat(target, effect.stat)
    end

    return true
end

function status.Get(ent, effectType)
    if not IsValid(ent) or not ent.BMBStatusEffects then return nil end
    return ent.BMBStatusEffects[effectType]
end

function status.Has(ent, effectType)
    return status.Get(ent, effectType) ~= nil
end

function status.Clear(ent, effectType)
    if not IsValid(ent) or not ent.BMBStatusEffects then return end

    local effect = ent.BMBStatusEffects[effectType]
    if not effect then return end

    ent.BMBStatusEffects[effectType] = nil
    if effect.stat then
        status.RecomputeStat(ent, effect.stat)
    end

    if not next(ent.BMBStatusEffects) then
        ent.BMBStatusEffects = nil
        status.Tracked[ent] = nil
    end
end

function status.ClearAll(ent)
    if not IsValid(ent) then return end

    local stats = {}
    local effects = ent.BMBStatusEffects
    if effects then
        for _, effect in pairs(effects) do
            if effect.stat then stats[effect.stat] = true end
        end
    end

    local baselines = ent.BMBStatusStatBaselines
    if baselines then
        if baselines.movespeed then stats.movespeed = true end
        if baselines.attack_damage then stats.attack_damage = true end
    end

    ent.BMBStatusEffects = nil
    status.Tracked[ent] = nil

    for statName in pairs(stats) do
        status.RecomputeStat(ent, statName)
    end
end

local function applyDot(target, effect)
    local damage = math.max(0, (tonumber(effect.dps) or 0) * (tonumber(effect.interval) or 1))
    if damage <= 0 then return end

    if effect.nonlethal ~= false and target.Health then
        local health = target:Health()
        if health <= 1 then return end
        damage = math.min(damage, health - 1)
    end

    if damage <= 0 then return end

    local source = IsValid(effect.source) and effect.source or target
    local damageInfo = DamageInfo()
    damageInfo:SetDamage(damage)
    damageInfo:SetDamageType(effect.damageType or DMG_GENERIC or 0)
    damageInfo:SetAttacker(source)
    damageInfo:SetInflictor(source)
    damageInfo:SetDamagePosition(target:WorldSpaceCenter())
    damageInfo:SetDamageForce(vector_origin)
    target:TakeDamageInfo(damageInfo)
end

function status.TickTarget(ent, now)
    if not isValidTarget(ent) then
        status.Tracked[ent] = nil
        return
    end

    if ent.BMBDead or (ent:IsPlayer() and not ent:Alive()) then
        status.ClearAll(ent)
        return
    end

    local effects = ent.BMBStatusEffects
    if not effects then
        status.Tracked[ent] = nil
        return
    end

    local statsToRecompute = {}

    for effectType, effect in pairs(effects) do
        if now >= (effect.expireAt or 0) then
            effects[effectType] = nil
            if effect.stat then statsToRecompute[effect.stat] = true end
        elseif effect.kind == "dot" and now >= (effect.nextTickAt or now) then
            applyDot(ent, effect)
            effect.nextTickAt = math.max((effect.nextTickAt or now) + (effect.interval or 1), now + 0.05)
        end
    end

    for statName in pairs(statsToRecompute) do
        status.RecomputeStat(ent, statName)
    end

    if not next(effects) then
        ent.BMBStatusEffects = nil
        status.Tracked[ent] = nil
    end
end

function status.TickAll()
    local now = effectNow()
    for ent in pairs(status.Tracked) do
        status.TickTarget(ent, now)
    end
end

function status.GetPlayerWeaknessDamageScale(attacker, damage)
    if not IsValid(attacker) or not attacker:IsPlayer() then return 1 end

    local _mult, add, active = statTotals(attacker, "attack_damage")
    if not active or add >= 0 then return 1 end

    damage = tonumber(damage) or 0
    if damage <= 0 then return 1 end

    return math.Clamp((damage + add) / damage, 0, 1)
end

hook.Add("Think", "BMB.Status.Tick", function()
    status.TickAll()
end)

hook.Add("EntityRemoved", "BMB.Status.EntityRemoved", function(ent)
    if ent and ent.BMBStatusEffects then
        status.ClearAll(ent)
    end
end)

hook.Add("PlayerDeath", "BMB.Status.PlayerDeath", function(ply)
    status.ClearAll(ply)
end)

hook.Add("EntityTakeDamage", "BMB.Status.WeaknessDamageScale", function(_target, damageInfo)
    local attacker = damageInfo:GetAttacker()
    local scale = status.GetPlayerWeaknessDamageScale(attacker, damageInfo:GetDamage())
    if scale < 1 then
        damageInfo:ScaleDamage(scale)
    end
end)
