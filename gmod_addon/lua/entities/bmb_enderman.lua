AddCSLuaFile()

ENT.Base = "bmb_base_mob"
ENT.Type = "nextbot"
ENT.PrintName = "BMB Enderman"
ENT.Author = "Heart#"
ENT.Category = "BlockMob Base"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Model = "models/mcgm/enderman/enderman.mdl"
ENT.StartHealth = 140
ENT.WalkSpeed = 92
ENT.RunSpeed = 145
ENT.Acceleration = 520
ENT.Deceleration = 700
ENT.TargetRange = 2350
ENT.TargetLoseRange = 2900
ENT.TargetScanInterval = 0.35
ENT.TargetRequireLineOfSight = false
ENT.ChaseRepathInterval = 0.42
ENT.ChaseSegmentTimeout = 1.6
ENT.ChaseFailureRepathDelay = 0.05
ENT.ChasePreferDirect = true
ENT.ChaseDirectDuration = 0.24
ENT.ChaseDirectMaxDistanceCells = 7
ENT.ChaseDirectProbeCells = 5
ENT.ChaseHighTargetHoldCells = 1.8
ENT.WanderDistanceMinCells = 2
ENT.WanderDistanceMaxCells = 7
ENT.WanderPauseMin = 1.0
ENT.WanderPauseMax = 3.2
ENT.WanderPathAttempts = 2
ENT.WanderFailurePauseMin = 0.45
ENT.WanderFailurePauseMax = 1.1
ENT.InitialIdleMin = 0.3
ENT.InitialIdleMax = 0.9
ENT.AttackRange = 76
ENT.AttackVerticalRange = 44
ENT.AttackVerticalOverlapRange = 120
ENT.AttackVerticalOverlapFlatRange = 32
ENT.AttackDamage = 14
ENT.AttackCooldown = 0.9
ENT.AttackHitDelay = 0
ENT.AttackMoveSpeed = 145
ENT.AttackHitSlop = 18
ENT.AttackKnockback = 190
ENT.AttackVerticalKnockback = 160
ENT.AttackGroundedVerticalKnockback = 205
ENT.HitViewPunchPitch = -1.05
ENT.HitViewPunchYaw = 0.45
ENT.HitScreenShakeAmplitude = 1.0
ENT.HitScreenShakeFrequency = 13
ENT.HitScreenShakeDuration = 0.12
ENT.HitScreenShakeRadius = 110
ENT.AmbientSoundIntervalTicks = 80
ENT.AmbientSoundChanceDenominator = 950
ENT.AmbientSoundTickRate = 20
ENT.AmbientSoundMaxCatchupTicks = 4
ENT.CollisionMins = Vector(-11, -11, 0)
ENT.CollisionMaxs = Vector(11, 11, 106)
ENT.StepHeight = 40
ENT.LookAtPitchSign = -1
ENT.LookAtPitchLimit = 38
ENT.LookAtEyeHeight = 94
ENT.LookAroundPitchLimit = 12
ENT.BipedLegSwingMax = 28
ENT.BipedArmSwingMax = 10
ENT.BipedArmForwardAngle = 0
ENT.EndermanAngryArmForwardAngle = 0
ENT.AttackKeyframeDuration = 0.42
ENT.DeathTipDuration = 0.62
ENT.DeathTipDegrees = 90
ENT.LimbSwingMinAmount = 0.18
ENT.LimbSwingPhaseScale = 0.085
ENT.KnockbackUseJump = true
ENT.KnockbackVerticalSpeedScale = 6
ENT.KnockbackVerticalMinSpeed = 170
ENT.KnockbackVerticalMaxSpeed = 245
ENT.EndermanStareCheckInterval = 0.15
ENT.EndermanStareDotBias = 0.025
ENT.EndermanStareAggroDelay = 0.25
ENT.EndermanStareRangeCells = 64
ENT.EndermanFreezeRangeCells = 16
ENT.EndermanCloseStareTeleportCells = 4
ENT.EndermanTeleportCooldown = 0.6
ENT.EndermanTeleportAmbientInterval = 9
ENT.EndermanTeleportAmbientRangeCells = 12
ENT.EndermanTeleportReachRangeCells = 6
ENT.EndermanTeleportFleeRangeCells = 12
ENT.EndermanTeleportAttempts = 12
ENT.EndermanProjectileTeleportAttempts = 64
ENT.EndermanFarTeleportMinCells = 16
ENT.EndermanFarTeleportDelay = 1.5
ENT.EndermanReachTeleportRetryDelay = 0.25
ENT.EndermanAttackRequireLineOfSight = true
ENT.EndermanScaryFaceHeadOffset = Vector(0, 11.4, 0)
ENT.EndermanScaryFaceHatOffset = Vector(0, -11.4, 0)
ENT.EndermanCreepyJitterScale = 0.012
ENT.EndermanCreepyAngleJitter = 0.2

ENT.Sounds = {
    Say = {
        "bmb/mob/endermen/idle1.ogg",
        "bmb/mob/endermen/idle2.ogg",
        "bmb/mob/endermen/idle3.ogg",
        "bmb/mob/endermen/idle4.ogg",
        "bmb/mob/endermen/idle5.ogg"
    },
    Hurt = {
        "bmb/mob/endermen/hit1.ogg",
        "bmb/mob/endermen/hit2.ogg",
        "bmb/mob/endermen/hit3.ogg",
        "bmb/mob/endermen/hit4.ogg"
    },
    Death = {
        "bmb/mob/endermen/death.ogg"
    },
    Portal = {
        "bmb/mob/endermen/portal.ogg",
        "bmb/mob/endermen/portal2.ogg"
    },
    Scream = {
        "bmb/mob/endermen/scream1.ogg",
        "bmb/mob/endermen/scream2.ogg",
        "bmb/mob/endermen/scream3.ogg",
        "bmb/mob/endermen/scream4.ogg"
    },
    Stare = {
        "bmb/mob/endermen/stare.ogg"
    },
    Hit = {
        "bmb/damage/hit1.ogg",
        "bmb/damage/hit2.ogg",
        "bmb/damage/hit3.ogg"
    }
}

if SERVER then
    local function createEndermanConVar(name, default, description)
        if not GetConVar(name) then
            CreateConVar(name, default, FCVAR_ARCHIVE, description)
        end
    end

    createEndermanConVar("bmb_enderman_teleport_ambient_interval", "9", "Average seconds between neutral Enderman ambient teleports.")
    createEndermanConVar("bmb_enderman_teleport_cooldown", "0.6", "Minimum seconds between Enderman teleports.")
    createEndermanConVar("bmb_enderman_teleport_range", "12", "Neutral Enderman teleport search radius in MC blocks.")
    createEndermanConVar("bmb_enderman_teleport_reach_range", "6", "Provoked Enderman teleport radius around its target in MC blocks.")
    createEndermanConVar("bmb_enderman_teleport_flee_range", "12", "Enderman projectile dodge/flee teleport radius in MC blocks.")
    createEndermanConVar("bmb_enderman_stare_dot_bias", "0.025", "MC-style Enderman stare strictness; smaller means stricter.")
    createEndermanConVar("bmb_enderman_stare_range", "64", "Enderman stare detection range in MC blocks.")
end

local function randomSound(list)
    if not list or #list == 0 then return nil end
    return list[math.random(1, #list)]
end

local function endermanConVarFloat(name, fallback)
    local convar = GetConVar and GetConVar(name)
    if not convar then return fallback end
    return convar:GetFloat()
end

local function callBaseMethod(ent, methodName, ...)
    local base = ent.BaseClass
    if base and base[methodName] then
        return base[methodName](ent, ...)
    end

    local stored = scripted_ents and scripted_ents.GetStored and scripted_ents.GetStored("bmb_base_mob")
    local storedTable = stored and stored.t
    if storedTable and storedTable[methodName] then
        return storedTable[methodName](ent, ...)
    end

    return nil
end

local function flatDistanceSqr(a, b)
    local dx = (a.x or 0) - (b.x or 0)
    local dy = (a.y or 0) - (b.y or 0)
    return dx * dx + dy * dy
end

local function normalizedFlatDirection(fromPos, toPos)
    if not fromPos or not toPos then return nil end

    local direction = toPos - fromPos
    direction.z = 0
    if direction:LengthSqr() <= 0.0001 then return nil end

    direction:Normalize()
    return direction
end

function ENT:Initialize()
    if CLIENT then return end

    self:BaseInitialize()
    self:SetBMBState("idle")
    self.TargetEntity = nil
    self.NextTargetScanTime = 0
    self.NextMeleeAttackTime = 0
    self.BMBEndermanProvoked = false
    self:SetNWBool("BMBEndermanProvoked", false)
    self:SetNWBool("BMBEndermanStaredAt", false)
    self:ResetBMBAmbientSoundTime()
    self.BMBNextAmbientSoundTickAt = CurTime() + math.Rand(0, 1 / (self.AmbientSoundTickRate or 20))
    self.BMBInitialIdleUntil = CurTime() + math.Rand(self.InitialIdleMin or 0.3, self.InitialIdleMax or 0.9)
    self:ScheduleBMBEndermanAmbientTeleport()
end

function ENT:IsBMBEndermanProvoked()
    return self.BMBEndermanProvoked == true or self:GetNWBool("BMBEndermanProvoked", false)
end

function ENT:SetBMBEndermanProvoked(provoked)
    self.BMBEndermanProvoked = provoked == true
    self:SetNWBool("BMBEndermanProvoked", self.BMBEndermanProvoked)
end

function ENT:SetBMBEndermanStaredAt(staredAt)
    self.BMBEndermanStaredAt = staredAt == true
    self:SetNWBool("BMBEndermanStaredAt", self.BMBEndermanStaredAt)
end

function ENT:CanBMBRetaliateAgainst(attacker)
    return self:IsBMBCombatTarget(attacker)
end

function ENT:CanBMBTarget(target)
    if not self:IsBMBCombatTarget(target) then return false end
    if not self:IsBMBEndermanProvoked() then return false end

    return target == self.TargetEntity
        or target == self.BMBRetaliationTarget
        or target == self.BMBEndermanTarget
end

function ENT:GetBMBForcedLookTarget()
    if self:CanBMBTarget(self.TargetEntity) then
        return self.TargetEntity
    end

    return nil
end

function ENT:ClearBMBEndermanProvoked()
    self:SetBMBEndermanProvoked(false)
    self:SetBMBEndermanStaredAt(false)
    self.TargetEntity = nil
    self.BMBRetaliationTarget = nil
    self.BMBEndermanTarget = nil
    self.BMBEndermanPendingTarget = nil
    self.BMBEndermanAggroAt = 0
    self.BMBEndermanFarTeleportStartedAt = nil
end

function ENT:ProvokeBMBEnderman(target, reason)
    if not self:IsBMBCombatTarget(target) then return false end

    local wasProvoked = self:IsBMBEndermanProvoked()
    self.BMBEndermanPendingTarget = nil
    self.BMBEndermanAggroAt = 0
    self:SetBMBEndermanStaredAt(false)
    self.TargetEntity = target
    self.BMBRetaliationTarget = target
    self.BMBEndermanTarget = target
    self.BMBEndermanFarTeleportStartedAt = nil
    self.NextTargetScanTime = 0
    self.BMBInitialIdleUntil = 0
    self:SetBMBEndermanProvoked(true)

    if not wasProvoked then
        self:InterruptBMBMovement()
        self:PlayBMBEndermanProvokeSound(reason)
    end

    return true
end

function ENT:GetBMBEndermanCombatTarget()
    local loseRange = self.TargetLoseRange or self.TargetRange
    if BMB.Behaviors.SeekTarget.IsValid(self, self.TargetEntity, loseRange) then
        return self.TargetEntity
    end

    if BMB.Behaviors.SeekTarget.IsValid(self, self.BMBRetaliationTarget, loseRange) then
        return self.BMBRetaliationTarget
    end

    if BMB.Behaviors.SeekTarget.IsValid(self, self.BMBEndermanTarget, loseRange) then
        return self.BMBEndermanTarget
    end

    return nil
end

function ENT:GetBMBEndermanHeadWorldPos()
    return self:GetPos() + Vector(0, 0, self.LookAtEyeHeight or 94)
end

function ENT:CanBMBEndermanSeeHeadFromPlayer(ply, headPos)
    local trace = util.TraceLine({
        start = ply:EyePos(),
        endpos = headPos,
        filter = { ply, self },
        mask = MASK_SHOT
    })

    return not trace.Hit
end

function ENT:IsBMBEndermanBeingStaredAtByPlayer(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end

    local blockSize = self:GetBMBBlockSize()
    local range = endermanConVarFloat("bmb_enderman_stare_range", self.EndermanStareRangeCells or 64) * blockSize
    local headPos = self:GetBMBEndermanHeadWorldPos()
    local toHead = headPos - ply:EyePos()
    local distance = toHead:Length()
    if distance <= 1 or distance > range then return false end

    local distanceCells = math.max(distance / blockSize, 0.001)
    local dotBias = endermanConVarFloat("bmb_enderman_stare_dot_bias", self.EndermanStareDotBias or 0.025)
    local minDot = 1 - math.max(0.0001, dotBias) / distanceCells
    toHead:Normalize()

    return ply:GetAimVector():Dot(toHead) > minDot and self:CanBMBEndermanSeeHeadFromPlayer(ply, headPos)
end

function ENT:ClearBMBEndermanPendingStare()
    self.BMBEndermanPendingTarget = nil
    self.BMBEndermanAggroAt = 0
    self:SetBMBEndermanStaredAt(false)
end

function ENT:StartBMBEndermanPendingStare(ply)
    if not self:IsBMBCombatTarget(ply) then return false end

    self.BMBEndermanPendingTarget = ply
    self.BMBEndermanAggroAt = CurTime() + (self.EndermanStareAggroDelay or 0.25)
    self.BMBInitialIdleUntil = 0
    self:SetBMBEndermanStaredAt(true)
    self:InterruptBMBMovement()
    self:SetBMBState("stared_at")
    self:SetBMBMoveMode("stared_at")
    self:FaceTarget(ply:EyePos())
    return true
end

function ENT:UpdateBMBEndermanPendingStare()
    local pendingTarget = self.BMBEndermanPendingTarget
    if not IsValid(pendingTarget) then
        self:ClearBMBEndermanPendingStare()
        return false
    end

    if not self:IsBMBEndermanBeingStaredAtByPlayer(pendingTarget) then
        self:ClearBMBEndermanPendingStare()
        return false
    end

    self:SetBMBEndermanStaredAt(true)
    self:FaceTarget(pendingTarget:EyePos())

    if CurTime() >= (self.BMBEndermanAggroAt or 0) then
        return self:ProvokeBMBEnderman(pendingTarget, "stare")
    end

    return true
end

function ENT:CheckBMBEndermanStare()
    if self.BMBDead or self.BMBHeld then return false end
    if self:UpdateBMBEndermanPendingStare() then return true end
    if self:IsBMBEndermanProvoked() then return false end

    local now = CurTime()
    if now < (self.BMBNextStareCheckAt or 0) then return false end
    self.BMBNextStareCheckAt = now + (self.EndermanStareCheckInterval or 0.15)

    for _, ply in ipairs(player.GetAll()) do
        if self:IsBMBEndermanBeingStaredAtByPlayer(ply) then
            return self:StartBMBEndermanPendingStare(ply)
        end
    end

    return false
end

function ENT:RunBMBEndermanPendingStare()
    if not self:UpdateBMBEndermanPendingStare() then return false end
    if self:IsBMBEndermanProvoked() then return false end

    self:InterruptBMBMovement()
    self:SetBMBState("stared_at")
    self:SetBMBMoveMode("stared_at")
    if self.loco and self.loco.SetVelocity then
        self.loco:SetVelocity(vector_origin)
    end
    coroutine.wait(0.05)
    return true
end

function ENT:IsBMBEndermanProjectileDamage(damageInfo)
    if not damageInfo then return false end

    local inflictor = damageInfo:GetInflictor()
    if IsValid(inflictor) then
        local class = inflictor:GetClass()
        if class == "bmb_arrow" then return true end
        if inflictor.IsBMBProjectile then return true end
    end

    local damageType = damageInfo:GetDamageType() or 0
    local projectileMask = bit.bor(DMG_BULLET or 0, DMG_BUCKSHOT or 0, DMG_AIRBOAT or 0)
    return projectileMask ~= 0 and bit.band(damageType, projectileMask) ~= 0
end

function ENT:OnTakeDamage(damageInfo)
    if CLIENT or self.BMBDead then return end

    if self:IsBMBEndermanProjectileDamage(damageInfo) then
        local attacker = damageInfo:GetAttacker()
        if not self:IsBMBCombatTarget(attacker) then
            attacker = damageInfo:GetInflictor()
        end

        if self:IsBMBCombatTarget(attacker) then
            self:ProvokeBMBEnderman(attacker, "projectile")
        end

        self:TryBMBTeleport("dodge", { threat = attacker })
        return 0
    end

    return callBaseMethod(self, "OnTakeDamage", damageInfo)
end

function ENT:GetBMBEndermanTeleportCooldown()
    return endermanConVarFloat("bmb_enderman_teleport_cooldown", self.EndermanTeleportCooldown or 0.6)
end

function ENT:GetBMBEndermanTeleportRangeCells(reason)
    if reason == "reach" then
        return endermanConVarFloat("bmb_enderman_teleport_reach_range", self.EndermanTeleportReachRangeCells or 6)
    end

    if reason == "flee" or reason == "dodge" then
        return endermanConVarFloat("bmb_enderman_teleport_flee_range", self.EndermanTeleportFleeRangeCells or 12)
    end

    return endermanConVarFloat("bmb_enderman_teleport_range", self.EndermanTeleportAmbientRangeCells or 12)
end

function ENT:GetBMBEndermanTeleportAttempts(reason)
    if reason == "dodge" or reason == "projectile" then
        return self.EndermanProjectileTeleportAttempts or 64
    end

    return self.EndermanTeleportAttempts or 12
end

function ENT:GetBMBEndermanTeleportOrigin(reason, context)
    if reason == "reach" and context and IsValid(context.target) then
        return context.target:GetPos()
    end

    return self:GetPos()
end

function ENT:GetBMBEndermanThreatPosition(context)
    if not context then return nil end

    local threat = context.threat or context.target
    if IsValid(threat) and threat.GetPos then
        return threat:GetPos()
    end

    return nil
end

function ENT:MakeBMBEndermanTeleportCandidate(reason, context)
    local blockSize = self:GetBMBBlockSize()

    if reason == "reach" and context and IsValid(context.target) then
        local target = context.target
        local targetEye = target.EyePos and target:EyePos() or (target:GetPos() + Vector(0, 0, blockSize))
        local direction = self:GetPos() - targetEye
        if direction:LengthSqr() <= 1 then
            direction = VectorRand()
        end
        direction:Normalize()

        return self:GetPos()
            + Vector(math.Rand(-4, 4) * blockSize, math.Rand(-4, 4) * blockSize, math.random(-8, 7) * blockSize)
            - direction * (16 * blockSize)
    end

    local origin = self:GetBMBEndermanTeleportOrigin(reason, context)
    local maxRadius = math.max(blockSize, self:GetBMBEndermanTeleportRangeCells(reason) * blockSize)
    local minRadius = blockSize * (reason == "reach" and 2.1 or 1.5)
    local threatPos = self:GetBMBEndermanThreatPosition(context)
    local direction

    if (reason == "flee" or reason == "dodge") and threatPos then
        direction = normalizedFlatDirection(threatPos, self:GetPos())
    end

    if not direction then
        local angle = math.Rand(0, math.pi * 2)
        direction = Vector(math.cos(angle), math.sin(angle), 0)
    else
        local yaw = math.rad(math.Rand(-55, 55))
        local cosYaw = math.cos(yaw)
        local sinYaw = math.sin(yaw)
        direction = Vector(
            direction.x * cosYaw - direction.y * sinYaw,
            direction.x * sinYaw + direction.y * cosYaw,
            0
        )
        direction:Normalize()
    end

    local distance = math.Rand(minRadius, maxRadius)
    local candidate = origin + direction * distance
    candidate.z = origin.z + blockSize * 1.25
    return candidate
end

function ENT:IsBMBEndermanBadTeleportContents(foot)
    if not util or not util.PointContents then return false end

    local contentsMask = bit.bor(CONTENTS_WATER or 0, CONTENTS_SLIME or 0, CONTENTS_LAVA or 0)
    if contentsMask == 0 then return false end

    local low = util.PointContents(foot + Vector(0, 0, 20))
    if bit.band(low or 0, contentsMask) ~= 0 then return true end

    local high = util.PointContents(foot + Vector(0, 0, 76))
    return bit.band(high or 0, contentsMask) ~= 0
end

function ENT:IsBMBEndermanSourceHullClear(foot)
    local trace = util.TraceHull({
        start = foot + Vector(0, 0, 1),
        endpos = foot + Vector(0, 0, 1),
        mins = self.CollisionMins,
        maxs = self.CollisionMaxs,
        filter = self,
        mask = MASK_PLAYERSOLID
    })

    return not trace.Hit
end

function ENT:IsBMBEndermanTeleportDestinationSafe(foot, reason, context)
    if not foot then return false end
    if not self:IsBMBHullClearAtPosition(foot) then return false end
    if not self:IsBMBEndermanSourceHullClear(foot) then return false end
    if self:IsBMBEndermanBadTeleportContents(foot) then return false end

    if (reason == "flee" or reason == "dodge") and context then
        local threatPos = self:GetBMBEndermanThreatPosition(context)
        if threatPos then
            local blockSize = self:GetBMBBlockSize()
            local currentDistance = flatDistanceSqr(self:GetPos(), threatPos)
            local nextDistance = flatDistanceSqr(foot, threatPos)
            if nextDistance <= currentDistance + blockSize * blockSize then return false end
        end
    end

    return true
end

function ENT:FindBMBEndermanTeleportDestination(reason, context)
    local attempts = self:GetBMBEndermanTeleportAttempts(reason)

    for _ = 1, attempts do
        local candidate = self:MakeBMBEndermanTeleportCandidate(reason, context)
        local surfaceZ = self:GetBMBGroundSurfaceZ(candidate)
        if surfaceZ then
            local foot = Vector(candidate.x, candidate.y, surfaceZ)
            if self:IsBMBEndermanTeleportDestinationSafe(foot, reason, context) then
                return foot
            end
        end
    end

    return nil
end

function ENT:EmitBMBEndermanWarpEffect(startPos, endPos)
    if not util or not util.Effect then return end

    local origin = endPos or startPos
    if not origin then return end

    local data = EffectData()
    data:SetOrigin(origin)
    data:SetStart(startPos or origin)
    data:SetScale(1)
    data:SetRadius(math.max(math.abs(self.CollisionMaxs.x or 11), math.abs(self.CollisionMaxs.y or 11)))
    data:SetMagnitude(128)
    util.Effect("bmb_enderman_warp", data, true, true)
end

function ENT:TryBMBTeleport(reason, context)
    if CLIENT or self.BMBDead or self.BMBHeld then return false end

    local now = CurTime()
    if now < (self.BMBNextTeleportAt or 0) then return false end

    local foot = self:FindBMBEndermanTeleportDestination(reason or "ambient", context or {})
    if not foot then
        self.BMBNextTeleportAt = now + math.min(0.25, self:GetBMBEndermanTeleportCooldown())
        return false
    end

    local oldFoot = self:GetPos()
    self:InterruptBMBMovement()
    self:SetPos(foot)
    if self.loco and self.loco.SetVelocity then
        self.loco:SetVelocity(vector_origin)
    end
    self:TryBMBGroundUnsink("teleport")
    self:EmitBMBEndermanWarpEffect(oldFoot, self:GetPos())
    self:PlayBMBEndermanTeleportSound()
    self.BMBNextTeleportAt = CurTime() + self:GetBMBEndermanTeleportCooldown()

    return true
end

function ENT:ScheduleBMBEndermanAmbientTeleport()
    local interval = endermanConVarFloat("bmb_enderman_teleport_ambient_interval", self.EndermanTeleportAmbientInterval or 9)
    self.BMBNextAmbientTeleportAt = CurTime() + math.max(1, interval * math.Rand(0.75, 1.35))
end

function ENT:MaybeBMBEndermanAmbientTeleport()
    if self.BMBDead or self.BMBHeld or self:IsBMBEndermanProvoked() or self.BMBDebugMoveActive then return false end
    if CurTime() < (self.BMBNextAmbientTeleportAt or 0) then return false end

    self:TryBMBTeleport("ambient", {})
    self:ScheduleBMBEndermanAmbientTeleport()
    return true
end

function ENT:MaybeBMBEndermanReachTeleport(target, isStaredAt)
    if not IsValid(target) then return false end
    if isStaredAt then
        self.BMBEndermanFarTeleportStartedAt = nil
        return false
    end

    local blockSize = self:GetBMBBlockSize()
    local minDistance = (self.EndermanFarTeleportMinCells or 16) * blockSize
    if flatDistanceSqr(self:GetPos(), target:GetPos()) <= minDistance * minDistance then
        self.BMBEndermanFarTeleportStartedAt = nil
        return false
    end

    local now = CurTime()
    self.BMBEndermanFarTeleportStartedAt = self.BMBEndermanFarTeleportStartedAt or now
    if now - self.BMBEndermanFarTeleportStartedAt < (self.EndermanFarTeleportDelay or 1.5) then return false end

    if now < (self.BMBNextReachTeleportAt or 0) then return false end
    self.BMBNextReachTeleportAt = now + (self.EndermanReachTeleportRetryDelay or 0.8)

    if self:TryBMBTeleport("reach", { target = target }) then
        self.BMBEndermanFarTeleportStartedAt = nil
        return true
    end

    return false
end

function ENT:RunBMBEndermanFreezeWhenLookedAt(target, isStaredAt)
    if not IsValid(target) or not target:IsPlayer() or not isStaredAt then return false end

    local blockSize = self:GetBMBBlockSize()
    local freezeDistance = (self.EndermanFreezeRangeCells or 16) * blockSize
    if flatDistanceSqr(self:GetPos(), target:GetPos()) > freezeDistance * freezeDistance then return false end

    self.BMBEndermanFarTeleportStartedAt = nil
    self:InterruptBMBMovement()
    self:SetBMBState("stare_freeze")
    self:SetBMBMoveMode("stare_freeze")
    self:FaceTarget(target:EyePos())
    if self.loco and self.loco.SetVelocity then
        self.loco:SetVelocity(vector_origin)
    end

    local closeDistance = (self.EndermanCloseStareTeleportCells or 4) * blockSize
    if flatDistanceSqr(self:GetPos(), target:GetPos()) < closeDistance * closeDistance then
        self:TryBMBTeleport("ambient", {})
    end

    coroutine.wait(0.05)
    return true
end

function ENT:CanBMBEndermanMeleeTarget(target)
    if not IsValid(target) then return false end
    if not self.EndermanAttackRequireLineOfSight then return true end
    return not self.Visible or self:Visible(target)
end

function ENT:RunBMBEndermanAI()
    local target = self:GetBMBEndermanCombatTarget()

    if not IsValid(target) then
        self:ClearBMBEndermanProvoked()
        self:SetBMBState("wander")
        BMB.Behaviors.Wander.Run(self)
        return
    end

    self.TargetEntity = target
    local isStaredAt = target:IsPlayer() and self:IsBMBEndermanBeingStaredAtByPlayer(target)

    if self:RunBMBEndermanFreezeWhenLookedAt(target, isStaredAt) then
        return
    end

    if self:CanBMBEndermanMeleeTarget(target) and BMB.Behaviors.MeleeAttack.Try(self, target) then
        coroutine.wait(0.05)
        return
    end

    self:MaybeBMBEndermanReachTeleport(target, isStaredAt)

    self:SetBMBState("chase")
    if not BMB.Behaviors.Chase.Run(self, target) then
        if BMB.Behaviors.SeekTarget.IsValid(self, target, self.TargetLoseRange or self.TargetRange) then
            if self:MaybeBMBEndermanReachTeleport(target, isStaredAt) then return end
            if BMB.Behaviors.Chase.StalkHighTarget(self, target) then return end

            self:SetBMBState("chase")
            self:SetBMBMoveMode("chase_repath")
            if BMB.Behaviors.Chase.TryRepathPressure then
                BMB.Behaviors.Chase.TryRepathPressure(
                    self,
                    target,
                    self.RunSpeed,
                    self.ChaseRepathProbeDistance or self:GetBMBBlockSize() * 1.5
                )
            elseif BMB.Behaviors.Chase.ApplySafePressure then
                BMB.Behaviors.Chase.ApplySafePressure(
                    self,
                    target,
                    self.RunSpeed,
                    "chase_repath",
                    self.ChaseRepathProbeDistance or self:GetBMBBlockSize() * 1.5
                )
            end
            coroutine.wait(self.ChaseFailureRepathDelay or 0.05)
        else
            self:ClearBMBEndermanProvoked()
            self:InterruptibleWait(math.Rand(0.25, 0.55))
        end
    end
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
        elseif self.RunBMBInitialIdle and self:RunBMBInitialIdle() then
            self.BMBDebugMoveActive = false
        elseif self.RunBMBEndermanPendingStare and self:RunBMBEndermanPendingStare() then
            self.BMBDebugMoveActive = false
        else
            self.BMBDebugMoveActive = false
            self:RunBMBEndermanAI()
        end

        coroutine.yield()
    end
end

function ENT:Think()
    if CLIENT then
        self:EmitBMBEndermanAmbientPortalParticles()
    elseif SERVER and not self.BMBDead then
        self:CheckBMBEndermanStare()
        self:MaybeBMBEndermanAmbientTeleport()
    end

    local result = callBaseMethod(self, "Think")
    if result ~= nil then return result end
end

function ENT:ApplyBMBPlayerHitFeedback(target)
    if not IsValid(target) or not target:IsPlayer() then return end

    if target.ViewPunch then
        target:ViewPunch(Angle(self.HitViewPunchPitch or -0.55, math.Rand(-(self.HitViewPunchYaw or 0.28), self.HitViewPunchYaw or 0.28), 0))
    end

    local shakeAmplitude = self.HitScreenShakeAmplitude or 0
    if shakeAmplitude > 0 and util and util.ScreenShake then
        util.ScreenShake(
            target:GetPos(),
            shakeAmplitude,
            self.HitScreenShakeFrequency or 10,
            self.HitScreenShakeDuration or 0.08,
            self.HitScreenShakeRadius or 96,
            true
        )
    end
end

function ENT:OnBMBMeleeHit(target, _damageInfo)
    if not IsValid(target) then return end

    local soundName = randomSound(self.Sounds and self.Sounds.Hit)
    if soundName and target:IsPlayer() then
        target:EmitSound(soundName, 74, math.random(96, 104), 0.82)
    end

    self:ApplyBMBPlayerHitFeedback(target)
end

function ENT:PlayBMBMeleeGesture(_target)
    self:SetNWFloat("BMBAttackStartedAt", CurTime())
end

function ENT:PlayBMBEndermanTeleportSound()
    local soundName = randomSound(self.Sounds and self.Sounds.Portal)
    if not soundName then return end

    self:EmitSound(soundName, 82, math.random(95, 105), 0.92)
end

function ENT:PlayBMBEndermanProvokeSound(reason)
    local soundName
    if reason == "stare" then
        soundName = randomSound(self.Sounds and self.Sounds.Stare)
    end
    soundName = soundName or randomSound(self.Sounds and self.Sounds.Scream)
    if not soundName then return end

    self:EmitSound(soundName, 86, math.random(96, 104), reason == "stare" and 0.7 or 0.9)
end

function ENT:PlayBMBEndermanHurt(volume)
    local soundName = randomSound(self.Sounds and self.Sounds.Hurt)
    if not soundName then return end

    self:EmitSound(soundName, 74, math.random(95, 105), volume or 0.88)
end

function ENT:OnBMBHurtSound(damageInfo)
    if damageInfo and self:Health() <= (damageInfo:GetDamage() or 0) then return end
    self:PlayBMBEndermanHurt(0.88)
end

function ENT:OnBMBInjured(damageInfo, _wasFleeing)
    if not damageInfo then return end

    local attacker = damageInfo:GetAttacker()
    if self:IsBMBCombatTarget(attacker) then
        self:ProvokeBMBEnderman(attacker, "damage")
    end
end

function ENT:OnKilled(damageInfo)
    if CLIENT then return end

    local soundName = randomSound(self.Sounds and self.Sounds.Death)
    if soundName then
        self:EmitSound(soundName, 78, math.random(95, 105), 0.96)
    end

    self:BeginBMBDeath(damageInfo)
end

function ENT:ResetBMBAmbientSoundTime()
    self.BMBAmbientSoundTime = -(self.AmbientSoundIntervalTicks or 80)
end

function ENT:MaybePlayStep()
    -- Enderman footsteps are intentionally silent for now; MC audio pack provides no step bank here.
end

function ENT:MaybePlayIdleSound()
    local sounds = self.Sounds
    if not sounds then return end

    local now = CurTime()
    local tickRate = self.AmbientSoundTickRate or 20
    local tickInterval = 1 / tickRate
    local nextTick = self.BMBNextAmbientSoundTickAt or now

    if now < nextTick then return end

    local ticks = math.floor((now - nextTick) / tickInterval) + 1
    ticks = math.Clamp(ticks, 1, self.AmbientSoundMaxCatchupTicks or 4)

    for _ = 1, ticks do
        local soundTime = self.BMBAmbientSoundTime
        if soundTime == nil then
            soundTime = -(self.AmbientSoundIntervalTicks or 80)
        end

        if math.random(0, (self.AmbientSoundChanceDenominator or 1000) - 1) < soundTime then
            local bank = self:IsBMBEndermanProvoked() and sounds.Scream or sounds.Say
            local soundName = randomSound(bank)
            if soundName then
                self:EmitSound(soundName, self:IsBMBEndermanProvoked() and 84 or 72, math.random(92, 108), self:IsBMBEndermanProvoked() and 0.72 or 0.58)
            end
            self:ResetBMBAmbientSoundTime()
            break
        end

        self.BMBAmbientSoundTime = soundTime + 1
    end

    self.BMBNextAmbientSoundTickAt = nextTick + ticks * tickInterval
    if self.BMBNextAmbientSoundTickAt < now - tickInterval then
        self.BMBNextAmbientSoundTickAt = now + tickInterval
    end
end

if CLIENT then
    local ENDERMAN_PORTAL_PARTICLE_TICK = 0.05
    local ENDERMAN_PORTAL_AMBIENT_FLAGS = 1
    local function shouldMigrateClientNumber(value, oldDefaults)
        if not oldDefaults then return false end

        for _, oldDefault in ipairs(oldDefaults) do
            if math.abs(value - oldDefault) <= 0.00001 then return true end
        end

        return false
    end

    local function createOrMigrateClientNumberConVar(name, defaultValue, helpText, oldDefaults)
        local convar = GetConVar(name)
        if not convar then
            return CreateClientConVar(name, tostring(defaultValue), true, false, helpText)
        end

        if shouldMigrateClientNumber(convar:GetFloat(), oldDefaults) then
            convar:SetFloat(defaultValue)
        end

        return convar
    end

    local endermanScaryHeadOffset = {
        x = createOrMigrateClientNumberConVar("bmb_enderman_scary_head_x", 0, "Enderman scary face head offset X."),
        y = createOrMigrateClientNumberConVar("bmb_enderman_scary_head_y", 11.4, "Enderman scary face head offset Y.", { 0 }),
        z = createOrMigrateClientNumberConVar("bmb_enderman_scary_head_z", 0, "Enderman scary face head offset Z.", { 11.4 })
    }
    local endermanScaryHatOffset = {
        x = createOrMigrateClientNumberConVar("bmb_enderman_scary_hat_x", 0, "Enderman scary face hat offset X."),
        y = createOrMigrateClientNumberConVar("bmb_enderman_scary_hat_y", -11.4, "Enderman scary face hat offset Y.", { 0 }),
        z = createOrMigrateClientNumberConVar("bmb_enderman_scary_hat_z", 0, "Enderman scary face hat offset Z.", { -11.4 })
    }
    local endermanJitterScale = createOrMigrateClientNumberConVar(
        "bmb_enderman_creepy_jitter_scale",
        0.012,
        "Enderman provoked render jitter in MC blocks.",
        { 0.02, 0.045 }
    )
    local endermanAngleJitter = createOrMigrateClientNumberConVar(
        "bmb_enderman_creepy_angle_jitter",
        0.2,
        "Enderman provoked silhouette jitter in degrees.",
        { 0, 1.1 }
    )

    local function vectorFromConVars(convars)
        return Vector(convars.x:GetFloat(), convars.y:GetFloat(), convars.z:GetFloat())
    end

    local function randomGaussian()
        local u1 = math.max(0.000001, math.Rand(0, 1))
        local u2 = math.Rand(0, 1)

        return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
    end

    local endermanAnimations = {
        attack = {
            duration = 0.42,
            frames = {
                { time = 0.00, bones = { rightArm = { angle = Angle(0, 0, 0) }, leftArm = { angle = Angle(0, 0, 0) } } },
                { time = 0.14, bones = { rightArm = { angle = Angle(0, 0, -42) }, leftArm = { angle = Angle(0, 0, 0) } } },
                { time = 0.42, bones = { rightArm = { angle = Angle(0, 0, 0) }, leftArm = { angle = Angle(0, 0, 0) } } }
            }
        }
    }

    function ENT:CacheBMBEndermanBones()
        local model = self:GetModel()
        if self.BMBEndermanBoneCache and self.BMBEndermanBoneCache.model == model then
            return self.BMBEndermanBoneCache
        end

        self.BMBEndermanBoneCache = {
            model = model,
            root = self:LookupBone("root"),
            head = self:LookupBone("head"),
            hat = self:LookupBone("hat"),
            rightArm = self:LookupBone("rightArm"),
            leftArm = self:LookupBone("leftArm"),
            rightLeg = self:LookupBone("rightLeg"),
            leftLeg = self:LookupBone("leftLeg")
        }

        return self.BMBEndermanBoneCache
    end

    function ENT:EmitBMBEndermanAmbientPortalParticles()
        if self:GetNWBool("BMBDead", false) or self:GetNoDraw() then return end
        if not util or not util.Effect then return end

        local now = CurTime()
        local nextAt = self.BMBNextEndermanPortalParticleAt or now
        if now < nextAt then return end

        local steps = 0
        while now + 0.0001 >= nextAt and steps < 4 do
            local data = EffectData()
            data:SetOrigin(self:GetPos())
            data:SetScale(1)
            data:SetMagnitude(2)
            data:SetFlags(ENDERMAN_PORTAL_AMBIENT_FLAGS)
            util.Effect("bmb_enderman_warp", data, true, true)

            nextAt = nextAt + ENDERMAN_PORTAL_PARTICLE_TICK
            steps = steps + 1
        end

        self.BMBNextEndermanPortalParticleAt = nextAt
    end

    function ENT:ApplyBMBEndermanLocomotion(bones, phase, amount)
        local legSwing = math.sin(phase) * (self.BipedLegSwingMax or 28) * amount
        local armSwing = math.sin(phase) * (self.BipedArmSwingMax or 10) * amount
        local armForward = self.BipedArmForwardAngle or 0

        self:SetBMBVisualBoneAngle(bones.rightLeg, Angle(0, 0, legSwing))
        self:SetBMBVisualBoneAngle(bones.leftLeg, Angle(0, 0, -legSwing))
        self:SetBMBVisualBoneAngle(bones.rightArm, Angle(0, 0, armForward - armSwing))
        self:SetBMBVisualBoneAngle(bones.leftArm, Angle(0, 0, armForward + armSwing))
    end

    function ENT:ApplyBMBEndermanScaryFace(bones)
        local provoked = self:GetNWBool("BMBEndermanProvoked", false)
        self:SetBMBVisualBonePosition(bones.head, provoked and vectorFromConVars(endermanScaryHeadOffset) or vector_origin)
        self:SetBMBVisualBonePosition(bones.hat, provoked and vectorFromConVars(endermanScaryHatOffset) or vector_origin)
    end

    function ENT:IsBMBEndermanCreepyVisualActive()
        if self:GetNWBool("BMBDead", false) then return false end

        return self:GetNWBool("BMBEndermanProvoked", false)
            or self:GetNWBool("BMBEndermanStaredAt", false)
            or self:GetNWString("BMBState", "") == "stare_freeze"
    end

    function ENT:GetBMBEndermanCreepyRootJitter()
        if not self:IsBMBEndermanCreepyVisualActive() then
            return vector_origin, angle_zero
        end

        local moveAmount = math.max(0, endermanJitterScale:GetFloat()) * self:GetBMBBlockSize()
        local position = vector_origin
        if moveAmount > 0 then
            position = Vector(randomGaussian() * moveAmount, randomGaussian() * moveAmount * 0.45, 0)
        end

        local amount = math.max(0, endermanAngleJitter:GetFloat())
        local angle = angle_zero
        if amount > 0 then
            angle = Angle(0, randomGaussian() * amount, randomGaussian() * amount * 0.35)
        end

        return position, angle
    end

    function ENT:Draw()
        callBaseMethod(self, "Draw")
    end

    function ENT:UpdateBMBVisualBones()
        local bones = self:CacheBMBEndermanBones()
        if not bones then return end

        local state = self:GetNWString("BMBState", "idle")

        if state == "dead" or self:GetNWBool("BMBDead", false) then
            self:SetBMBVisualBoneAngle(bones.head, angle_zero)
            self:SetBMBVisualBoneAngle(bones.rightArm, angle_zero)
            self:SetBMBVisualBoneAngle(bones.leftArm, angle_zero)
            self:SetBMBVisualBoneAngle(bones.rightLeg, angle_zero)
            self:SetBMBVisualBoneAngle(bones.leftLeg, angle_zero)
            self:SetBMBVisualBonePosition(bones.head, vector_origin)
            self:SetBMBVisualBonePosition(bones.hat, vector_origin)
            self:SetBMBVisualBonePosition(bones.root, vector_origin)

            if bones.root then
                local startedAt = self:GetNWFloat("BMBStateStartedAt", CurTime())
                local duration = self.DeathTipDuration or 0.62
                local t = duration > 0 and math.Clamp((CurTime() - startedAt) / duration, 0, 1) or 1
                local tip = t * (self.DeathTipDegrees or 90)
                local tipSign = (self:EntIndex() % 2 == 0) and 1 or -1
                self:SetBMBVisualBoneAngle(bones.root, Angle(0, tip * tipSign, 0))
            end

            return
        end

        local rootJitterPosition, rootJitterAngle = self:GetBMBEndermanCreepyRootJitter()
        self:SetBMBVisualBoneAngle(bones.root, rootJitterAngle)
        self:SetBMBVisualBonePosition(bones.root, rootJitterPosition)
        self:UpdateBMBLookAtHeadPose(bones.head)
        self:ApplyBMBEndermanScaryFace(bones)

        local speed = self:GetVelocity():Length2D()
        local phase, amount = self:UpdateBMBLimbSwing(speed)
        self:ApplyBMBEndermanLocomotion(bones, phase, amount)

        local attackStart = self:GetNWFloat("BMBAttackStartedAt", 0)
        if attackStart > 0 then
            local elapsed = CurTime() - attackStart
            local duration = self.AttackKeyframeDuration or 0.48
            if elapsed >= 0 and elapsed <= duration then
                local pose = BMB.SampleKeyframeAnimation(endermanAnimations.attack, elapsed)
                if pose then
                    local armForward = self.BipedArmForwardAngle or 0
                    local ra = (pose.rightArm and pose.rightArm.angle) or angle_zero
                    local la = (pose.leftArm and pose.leftArm.angle) or angle_zero
                    self:SetBMBVisualBoneAngle(bones.rightArm, Angle(0, 0, armForward + ra.r))
                    self:SetBMBVisualBoneAngle(bones.leftArm, Angle(0, 0, armForward + la.r))
                end
            end
        end
    end
end
