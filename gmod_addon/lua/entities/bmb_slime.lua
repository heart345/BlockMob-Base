AddCSLuaFile()

ENT.Base = "bmb_base_mob"
ENT.Type = "nextbot"
ENT.PrintName = "BMB Slime"
ENT.Author = "Heart#"
ENT.Category = "BlockMob Base"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Model = "models/mcgm/slime/slime.mdl"
ENT.HopOnlyLocomotion = true
ENT.UseSourcePathFollower = false
ENT.ChasePreferDirect = false
ENT.StartHealth = 32
ENT.TargetRange = 584
ENT.TargetLoseRange = 876
ENT.WanderPauseMin = 1.2
ENT.WanderPauseMax = 3.2
ENT.WanderDistanceMinCells = 1
ENT.WanderDistanceMaxCells = 4
ENT.AttackCooldown = 0.75
ENT.AttackHitDelay = 0
ENT.AttackHitSlop = 10
ENT.AttackKnockback = 80
ENT.AttackVerticalKnockback = 70
ENT.AttackGroundedVerticalKnockback = 95
ENT.AttackDamageType = DMG_SLASH
ENT.DeathRemoveDelay = 0.7
ENT.DeathKnockbackEnabled = false
ENT.MobSeparationRadiusScale = 1.0
ENT.MobSeparationSearchScale = 1.7
ENT.MobSeparationPositionNudgeMax = 3
ENT.BlockHopAllowCloseLaunch = true
ENT.BlockHopAllowBlockedCloseLaunch = true
ENT.BlockHopUsePreviousNodeForward = false
ENT.BlockHopManualHorizontalMaxScale = 1.22
ENT.BlockHopAirSteerStrength = 0.06
ENT.BlockHopMaxAttempts = 4
ENT.BlockHopRetryDelay = 0.18
ENT.PathCarrotMaxDistanceScale = 1.2
ENT.PathCarrotMinDistanceScale = 0.75
ENT.PathCornerMinAngle = 80
ENT.PathGoalProgressTimeout = 1.6
ENT.MoveNoProgressTimeout = 0.45
ENT.LookAtEyeHeight = 20

if SERVER then
    if not GetConVar("bmb_slime_split_count") then
        CreateConVar("bmb_slime_split_count", "2", FCVAR_ARCHIVE, "Number of child slimes spawned when a size > 1 BMB slime dies.")
    end

    if not GetConVar("bmb_slime_hop_dist_scale") then
        CreateConVar("bmb_slime_hop_dist_scale", "1", FCVAR_ARCHIVE, "Scale BMB slime hop horizontal launch speed.")
    end

    if not GetConVar("bmb_slime_hop_height_scale") then
        CreateConVar("bmb_slime_hop_height_scale", "1", FCVAR_ARCHIVE, "Scale BMB slime hop height.")
    end

    if not GetConVar("bmb_slime_hop_interval_scale") then
        CreateConVar("bmb_slime_hop_interval_scale", "1", FCVAR_ARCHIVE, "Scale BMB slime delay between landed hops.")
    end

    if not GetConVar("bmb_slime_contact_damage_scale") then
        CreateConVar("bmb_slime_contact_damage_scale", "1", FCVAR_ARCHIVE, "Scale BMB slime contact damage.")
    end

    if not GetConVar("bmb_slime_min_size_damage") then
        CreateConVar("bmb_slime_min_size_damage", "0", FCVAR_ARCHIVE, "Contact damage dealt by size 1 BMB slimes before global damage scale.")
    end
end

local slimeSizeData = {
    [1] = {
        modelScale = 1.0,
        radius = 9,
        height = 18,
        health = 4,
        damage = 0,
        attackRange = 24,
        verticalRange = 18,
        speed = 78,
        hopHeightScale = 0.85,
        hopDistanceScale = 0.92,
        hopInterval = 0.18,
        soundLevel = 64,
        soundVolume = 0.58,
        lookAtEyeHeight = 8
    },
    [2] = {
        modelScale = 2.0,
        radius = 18,
        height = 36,
        health = 16,
        damage = 4,
        attackRange = 38,
        verticalRange = 26,
        speed = 92,
        hopHeightScale = 1.15,
        hopDistanceScale = 1.04,
        hopInterval = 0.28,
        soundLevel = 68,
        soundVolume = 0.72,
        lookAtEyeHeight = 16
    },
    [3] = {
        modelScale = 4.0,
        radius = 36.5,
        height = 72,
        health = 32,
        damage = 8,
        attackRange = 70,
        verticalRange = 46,
        speed = 108,
        hopHeightScale = 1.55,
        hopDistanceScale = 1.18,
        hopInterval = 0.42,
        soundLevel = 74,
        soundVolume = 0.9,
        lookAtEyeHeight = 32
    }
}

local splitDirections = {
    Vector(1, 0, 0),
    Vector(-1, 0, 0),
    Vector(0, 1, 0),
    Vector(0, -1, 0),
    Vector(0.707, 0.707, 0),
    Vector(-0.707, 0.707, 0),
    Vector(0.707, -0.707, 0),
    Vector(-0.707, -0.707, 0)
}

local function randomSound(sounds)
    if not sounds or #sounds == 0 then return nil end
    return sounds[math.random(1, #sounds)]
end

local function conVarFloat(name, fallback)
    local convar = GetConVar and GetConVar(name)
    if not convar then return fallback end

    return convar:GetFloat()
end

local function conVarInt(name, fallback)
    local convar = GetConVar and GetConVar(name)
    if not convar then return fallback end

    return convar:GetInt()
end

local function clampSlimeSize(size)
    return math.Clamp(math.floor(tonumber(size) or 3), 1, 3)
end

local function slimeConfig(size)
    return slimeSizeData[clampSlimeSize(size)] or slimeSizeData[3]
end

local function callBaseMob(self, methodName, ...)
    local stored = scripted_ents.GetStored("bmb_base_mob")
    local baseTable = stored and stored.t
    local method = baseTable and baseTable[methodName]
    if not method then return nil end

    return method(self, ...)
end

ENT.Sounds = {
    Attack = {
        "bmb/mob/slime/attack1.ogg",
        "bmb/mob/slime/attack2.ogg"
    },
    Big = {
        "bmb/mob/slime/big1.ogg",
        "bmb/mob/slime/big2.ogg",
        "bmb/mob/slime/big3.ogg",
        "bmb/mob/slime/big4.ogg"
    },
    Small = {
        "bmb/mob/slime/small1.ogg",
        "bmb/mob/slime/small2.ogg",
        "bmb/mob/slime/small3.ogg",
        "bmb/mob/slime/small4.ogg",
        "bmb/mob/slime/small5.ogg"
    }
}

function ENT:GetBMBSlimeConfig(size)
    return slimeConfig(size or self.SlimeSize or 3)
end

function ENT:GetBMBSlimeEngineCollisionBounds(config)
    local modelScale = math.max(config.modelScale or 1, 0.01)
    local radius = config.radius / modelScale
    local height = config.height / modelScale

    return Vector(-radius, -radius, 0), Vector(radius, radius, height)
end

function ENT:GetBMBSlimeSounds()
    if (self.SlimeSize or 3) <= 1 then
        return self.Sounds and self.Sounds.Small
    end

    return self.Sounds and self.Sounds.Big
end

function ENT:SetSlimeSize(size)
    self.SlimeSize = clampSlimeSize(size)
    if SERVER and self.BMBSlimeInitialized then
        self:ApplySlimeSize(self.SlimeSize, false)
    end
end

function ENT:ApplySlimeSize(size, keepHealth)
    if CLIENT then return end

    size = clampSlimeSize(size)
    self.SlimeSize = size

    local config = self:GetBMBSlimeConfig(size)
    local damageScale = math.max(0, conVarFloat("bmb_slime_contact_damage_scale", 1))
    local minDamage = conVarFloat("bmb_slime_min_size_damage", 0)
    local hopDistanceScale = math.max(0.1, conVarFloat("bmb_slime_hop_dist_scale", 1))
    local hopHeightScale = math.max(0.1, conVarFloat("bmb_slime_hop_height_scale", 1))
    local hopIntervalScale = math.max(0, conVarFloat("bmb_slime_hop_interval_scale", 1))
    local radius = config.radius

    self:SetModelScale(config.modelScale, 0)
    self.CollisionMins = Vector(-radius, -radius, 0)
    self.CollisionMaxs = Vector(radius, radius, config.height)
    local engineMins, engineMaxs = self:GetBMBSlimeEngineCollisionBounds(config)
    self:SetCollisionBounds(engineMins, engineMaxs)

    self.StartHealth = config.health
    if self.SetMaxHealth then
        self:SetMaxHealth(config.health)
    end

    if keepHealth then
        self:SetHealth(math.Clamp(self:Health(), 1, config.health))
    else
        self:SetHealth(config.health)
    end
    self:SetNWInt("BMBHealth", self:Health())
    self:SetNWInt("BMBSlimeSize", size)

    self.AttackDamage = math.max(0, (size == 1 and minDamage or config.damage) * damageScale)
    self.AttackRange = config.attackRange
    self.AttackVerticalRange = config.verticalRange
    self.AttackVerticalOverlapRange = math.max(config.verticalRange, config.height + 10)
    self.AttackVerticalOverlapFlatRange = math.min(config.attackRange, radius + 8)
    self.WalkSpeed = config.speed * hopDistanceScale
    self.RunSpeed = self.WalkSpeed
    self.AttackMoveSpeed = self.WalkSpeed
    self.BlockHopApexScale = config.hopHeightScale * hopHeightScale
    self.BlockHopJumpHeightScale = config.hopHeightScale * hopHeightScale
    self.BlockHopInterval = math.max(0, config.hopInterval * hopIntervalScale)
    self.BlockHopManualHorizontalMaxScale = 1.08 + (0.14 * hopDistanceScale)
    self.BlockHopLaunchMaxDistanceScale = 1.35 + (0.18 * hopDistanceScale)
    self.BlockHopLaunchIdealDistanceScale = 0.95 + (0.16 * hopDistanceScale)
    self.BlockHopLaunchMinFaceDistanceScale = 0.42
    self.BlockHopLaunchIdealFaceDistanceScale = 0.58
    self.MobSeparationApproachDistance = math.max(12, radius * 1.2)
    self.LookAtEyeHeight = config.lookAtEyeHeight

    if self.loco then
        if self.loco.SetStepHeight then self.loco:SetStepHeight(self.StepHeight or 28) end
        if self.loco.SetJumpHeight then
            self.loco:SetJumpHeight(self:GetBMBBlockSize() * (self.BlockHopJumpHeightScale or 1.5))
        end
        if self.loco.SetDesiredSpeed then self.loco:SetDesiredSpeed(self.WalkSpeed) end
    end
end

function ENT:RefreshBMBSlimeRuntime()
    if CLIENT or self.BMBDead then return end

    local now = CurTime()
    if now < (self.BMBNextSlimeRuntimeRefresh or 0) then return end

    self.BMBNextSlimeRuntimeRefresh = now + 0.5
    self:ApplySlimeSize(self.SlimeSize or 3, true)
end

function ENT:Initialize()
    if CLIENT then return end

    self.SlimeSize = clampSlimeSize(self.SlimeSize or self.BMBInitialSlimeSize or 3)
    self:BaseInitialize()
    self.BMBSlimeInitialized = true
    self:ApplySlimeSize(self.SlimeSize, false)
    self:SetBMBState("idle")
    self.TargetEntity = nil
    self.NextTargetScanTime = 0
    self.NextMeleeAttackTime = 0
end

function ENT:RunBehaviour()
    while true do
        if self.BMBDead then
            return
        elseif self.MaintainBMBFreeze and self:MaintainBMBFreeze() then
            coroutine.wait(0.05)
        elseif self.BMBHeld then
            self:SetBMBState("held")
            coroutine.wait(0.2)
        elseif self.RunBMBKnockback and self:RunBMBKnockback() then
            self.BMBDebugMoveActive = false
        elseif self.RunBMBDebugMove and self:RunBMBDebugMove() then
            self.BMBDebugMoveActive = true
        elseif self.RunBMBStrandedRecovery and self:RunBMBStrandedRecovery() then
            self.BMBDebugMoveActive = false
        else
            self.BMBDebugMoveActive = false
            self:RefreshBMBSlimeRuntime()
            self:RunBMBSlimeAI()
        end

        coroutine.yield()
    end
end

function ENT:RunBMBSlimeAI()
    self.TargetEntity = BMB.Behaviors.SeekTarget.Find(self, self.TargetEntity)

    if not IsValid(self.TargetEntity) then
        self:SetBMBState("wander")
        BMB.Behaviors.Wander.Run(self)
        return
    end

    if BMB.Behaviors.MeleeAttack.IsInRange(self, self.TargetEntity) then
        if BMB.Behaviors.MeleeAttack.Try(self, self.TargetEntity) then
            coroutine.wait(0.05)
            return
        end

        self:SetBMBState("attack")
        self:SetBMBMoveMode("attack_cooldown")
        self:MaintainBMBMoveSpeed(0, 0)
        self:FaceTarget(self.TargetEntity:GetPos())
        coroutine.wait(0.05)
        return
    end

    self:SetBMBState("chase")
    if not BMB.Behaviors.Chase.Run(self, self.TargetEntity) then
        if BMB.Behaviors.SeekTarget.IsValid(self, self.TargetEntity, self.TargetLoseRange or self.TargetRange) then
            self:SetBMBMoveMode("chase_repath_wait")
            self:MaintainBMBMoveSpeed(0, 0)
            self:FaceTarget(self.TargetEntity:GetPos())
            coroutine.wait(self.ChaseFailureRepathDelay or 0.12)
        else
            self.TargetEntity = nil
            self:InterruptibleWait(math.Rand(0.25, 0.55))
        end
    end
end

function ENT:CanBMBTarget(target)
    return self:IsBMBCombatTarget(target)
end

function ENT:GetBMBForcedLookTarget()
    if self:CanBMBTarget(self.TargetEntity) then
        return self.TargetEntity
    end

    return nil
end

function ENT:PlayBMBMeleeGesture(_target)
    self:SetNWFloat("BMBAttackStartedAt", CurTime())
end

function ENT:PlayBMBAnimation(_name)
    -- Slime has no baked Source gestures; hurt/death feedback is sound, flash, and split/poof.
end

function ENT:PlayBMBSlimeSound(volumeScale)
    local soundName = randomSound(self:GetBMBSlimeSounds())
    if not soundName then return end

    local config = self:GetBMBSlimeConfig()
    self:EmitSound(
        soundName,
        config.soundLevel or 70,
        math.random(92, 108),
        math.Clamp((config.soundVolume or 0.75) * (volumeScale or 1), 0, 1)
    )
end

function ENT:PlayBMBSlimeAttackSound(target)
    local soundName = randomSound(self.Sounds and self.Sounds.Attack)
    if not soundName then return end

    local emitter = IsValid(target) and target or self
    emitter:EmitSound(soundName, 70, math.random(96, 104), 0.72)
end

function ENT:OnBMBMeleeHit(target, _damageInfo)
    self:PlayBMBSlimeAttackSound(target)
end

function ENT:OnBMBHurtSound(damageInfo)
    if damageInfo and self:Health() <= (damageInfo:GetDamage() or 0) then return end

    self:PlayBMBSlimeSound(0.9)
end

function ENT:OnLandOnGround(ent)
    callBaseMob(self, "OnLandOnGround", ent)
    if self.BMBDead then return end

    local now = CurTime()
    if now < (self.BMBNextSlimeLandSoundAt or 0) then return end

    self.BMBNextSlimeLandSoundAt = now + 0.12
    self:PlayBMBSlimeSound(0.78)
end

function ENT:MaybePlayStep()
    -- Slime movement sound is landing-driven from OnLandOnGround.
end

function ENT:IsBMBSlimeCandidateStandable(pos)
    if not BMB or not BMB.Pathfinder or not BMB.Pathfinder.IsStandablePosition then
        return true
    end

    if BMB.Pathfinder.IsStandablePosition(pos, { mob = self }) then return true end
    if self.HasBMBPhysicalGroundAt then
        local hasGround = self:HasBMBPhysicalGroundAt(pos)
        if hasGround then return true end
    end

    return false
end

function ENT:WithBMBSlimeCollisionSize(size, callback)
    local oldMins = self.CollisionMins
    local oldMaxs = self.CollisionMaxs
    local config = self:GetBMBSlimeConfig(size)

    self.CollisionMins = Vector(-config.radius, -config.radius, 0)
    self.CollisionMaxs = Vector(config.radius, config.radius, config.height)

    local ok, result = pcall(callback)

    self.CollisionMins = oldMins
    self.CollisionMaxs = oldMaxs

    if not ok then error(result) end
    return result
end

function ENT:FindBMBSlimeSplitPositions(childSize, count)
    local positions = {}
    local parentConfig = self:GetBMBSlimeConfig()
    local childConfig = self:GetBMBSlimeConfig(childSize)
    local ringRadius = math.max(
        parentConfig.radius + childConfig.radius + 5,
        self:GetBMBBlockSize() * 0.65
    )
    local directions = {}

    for index, direction in ipairs(splitDirections) do
        directions[index] = Vector(direction.x, direction.y, 0)
    end

    for index = #directions, 2, -1 do
        local swap = math.random(1, index)
        directions[index], directions[swap] = directions[swap], directions[index]
    end

    self:WithBMBSlimeCollisionSize(childSize, function()
        for _, direction in ipairs(directions) do
            if #positions >= count then break end

            direction:Normalize()
            local candidate = self:GetPos() + direction * ringRadius
            local surfaceZ = self:GetBMBGroundSurfaceZ(candidate)
            if surfaceZ then
                candidate.z = surfaceZ
            end

            if self:IsBMBHullClearAtPosition(candidate) and self:IsBMBSlimeCandidateStandable(candidate) then
                positions[#positions + 1] = { pos = candidate, direction = direction }
            end
        end
    end)

    return positions
end

function ENT:SpawnBMBSlimeChild(childSize, spawnData, inheritedTarget)
    local child = ents.Create("bmb_slime")
    if not IsValid(child) then return nil end

    child.SlimeSize = childSize
    child.BMBInitialSlimeSize = childSize
    child:SetPos(spawnData.pos)
    child:SetAngles(Angle(0, spawnData.direction:Angle().y, 0))
    child:Spawn()
    child:Activate()
    child:SetSlimeSize(childSize)

    if self:CanBMBTarget(inheritedTarget) then
        child.TargetEntity = inheritedTarget
        child.BMBRetaliationTarget = inheritedTarget
        child.BMBRetaliationStartedAt = CurTime()
    end

    if child.TryBMBGroundUnsink then
        child:TryBMBGroundUnsink("slime_split")
    end

    if child.loco and child.loco.SetVelocity then
        local config = child:GetBMBSlimeConfig(childSize)
        child.loco:SetVelocity(spawnData.direction * math.max(90, config.speed * 1.15) + Vector(0, 0, 115))
    end

    return child
end

function ENT:SplitBMBSlime()
    if self.BMBSlimeSplitDone then return end
    self.BMBSlimeSplitDone = true

    local size = clampSlimeSize(self.SlimeSize or 3)
    if size <= 1 then return end

    local childSize = size - 1
    local count = math.Clamp(conVarInt("bmb_slime_split_count", 2), 0, 4)
    if count <= 0 then return end

    local inheritedTarget = IsValid(self.TargetEntity) and self.TargetEntity or self.BMBRetaliationTarget
    local positions = self:FindBMBSlimeSplitPositions(childSize, count)

    for _, spawnData in ipairs(positions) do
        self:SpawnBMBSlimeChild(childSize, spawnData, inheritedTarget)
    end
end

function ENT:OnKilled(damageInfo)
    if CLIENT then return end

    self:PlayBMBSlimeSound(1.05)
    self:SplitBMBSlime()
    self:BeginBMBDeath(damageInfo)
end
