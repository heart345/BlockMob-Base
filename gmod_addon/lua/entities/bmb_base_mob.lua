AddCSLuaFile()

if SERVER then
    BMB = BMB or {}
    include("bmb/sh_config.lua")
    include("bmb/sv_block_world_mock.lua")
    include("bmb/sv_pathfinder.lua")
    include("bmb/sv_behaviors.lua")

    if not GetConVar("bmb_use_source_path") then
        -- 默认关：寻路走自写方块 A*（CLAUDE.md：不用 navmesh），此开关仅留作普通地图实验
        CreateConVar("bmb_use_source_path", "0", FCVAR_ARCHIVE, "EXPERIMENTAL: use GMod Source PathFollower instead of BMB block-grid A*.")
    end

    if not GetConVar("bmb_debug_hop_log") then
        CreateConVar("bmb_debug_hop_log", "0", FCVAR_ARCHIVE, "Print BlockHop launch/apex/result diagnostics.")
    end
end

ENT.Base = "base_nextbot"
ENT.Type = "nextbot"
ENT.PrintName = "BMB Base Mob"
ENT.Author = "BMB"
ENT.Category = "BlockMob Base"
ENT.Spawnable = false
ENT.AdminOnly = true

ENT.Model = "models/kleiner.mdl"
ENT.IsBMBMob = true
ENT.StartHealth = 20
ENT.UseRagdollOnDeath = false
ENT.UsePhysicsCorpseOnDeath = false
ENT.DeathRemoveDelay = 1.0
ENT.DeathPoofEffect = "bmb_death_poof"
ENT.DeathKeepRed = true
ENT.DeathCorpseColor = Color(255, 110, 110, 255)
ENT.DeathCorpseCollisionGroup = COLLISION_GROUP_DEBRIS
ENT.DeathCorpseDamageForceScale = 0.01
ENT.DeathCorpseMaxImpactSpeed = 120
ENT.DeathCorpseRollVelocity = 45
ENT.DeathCorpseRightPushSpeed = 55
ENT.DeathCorpseUpPushSpeed = 0
ENT.DeathCorpseRightForce = 0
ENT.DeathCorpseTorqueHeight = 24
ENT.DeathCorpseRightRollVelocity = 75
ENT.DeathPoofParticleCountMin = 18    -- MC Java poof 约 20 个（所有 mob 通用默认）
ENT.DeathPoofParticleCountMax = 22
ENT.DeathPoofRadiusScale = 15         -- 基数，经 GetBMBDeathEffectScale 按体型缩放
ENT.WalkSpeed = 80
ENT.RunSpeed = 120
ENT.Acceleration = 420
ENT.Deceleration = 650
ENT.CollisionMins = Vector(-16, -16, 0)
ENT.CollisionMaxs = Vector(16, 16, 48)
ENT.WaypointTimeout = 2.0
ENT.GroundProbeHeight = 32
ENT.GroundProbeDepth = 96
ENT.ForwardSafetyDistance = 48
ENT.SafetyProbeSpeedScale = 0.45
ENT.SafetyHullScale = 0.65
ENT.WallStopDistance = 20
ENT.GridSafetyStepScale = 0.5
ENT.GridSafetyMinStep = 8
ENT.GridSafetyFootLiftScale = 0.12
ENT.GridSafetyMinFootLift = 4
-- Source locomotion step height, intentionally absolute: 28u stays above a 36.5u half slab (18.25u)
-- while remaining below a full MC block.
ENT.StepHeight = 28
ENT.BlockHopApexScale = 1.5
ENT.BlockHopJumpHeightScale = 1.5
ENT.BlockHopLandingLift = 2
ENT.BlockHopLaunchMinDistanceScale = 0.85
ENT.BlockHopLaunchIdealDistanceScale = 1.15
ENT.BlockHopLaunchMaxDistanceScale = 1.4
ENT.BlockHopLaunchMinFaceDistanceScale = 0.75
ENT.BlockHopLaunchIdealFaceDistanceScale = 0.85
ENT.BlockHopLaunchLateralToleranceScale = 0.35
ENT.BlockHopAllowBlockedCloseLaunch = true
ENT.BlockHopBlockedCloseMinFaceDistanceScale = 0.52
ENT.BlockHopCeilingBlockedCloseMinFaceDistanceScale = 0.48
ENT.BlockHopLaunchCeilingClearanceScale = 0.95
ENT.BlockHopVerticalOvershootToleranceScale = 1.25
ENT.BlockHopMinLaunchSpeedScale = 0.6
ENT.BlockHopRequireLaunchSpeed = false
ENT.BlockHopManualHorizontalMinSpeed = 32
ENT.BlockHopManualHorizontalMaxScale = 1.1
ENT.BlockHopManualControlTime = 0.7
ENT.BlockHopManualLiftTime = 0.16
ENT.BlockHopManualForwardStartHeightScale = 0.8
ENT.BlockHopManualPostLiftMinVzScale = 0.35
ENT.BlockHopStepHeightScale = 0.49
ENT.BlockHopAirSteerStrength = 0.08
-- 重试间隔必须 < MoveNoProgressGrace(0.35)：落地贴墙期间 watchdog 在计时，
-- 重跳要赶在它把路径判死之前
ENT.BlockHopRetryDelay = 0.25
ENT.BlockHopMaxAttempts = 3
ENT.MaxPathDropCells = 3
-- 必须 > 一格，且 < 两格：MC 生物下一格台阶是日常移动，太小会把"从方块地板走下来"判成悬崖。
ENT.MaxStepDownScale = 1.1
ENT.DropVerticalReachUpToleranceScale = 0.35
ENT.TurnRate = 400
ENT.TurnInPlaceAngle = 110
ENT.UseSourcePathFollower = true
ENT.SourcePathLookAhead = 120
ENT.SourcePathGoalToleranceScale = 0.5
ENT.PathNodeToleranceScale = 0.5
ENT.PathCarrotMinDistanceScale = 2
ENT.PathCarrotMaxDistanceScale = 25 / 6
ENT.PathCarrotSpeedScale = 1.1
ENT.PathCornerMinAngle = 35
ENT.PathCornerSlowDistanceScale = 2
ENT.PathCornerSpeedScale = 0.55
ENT.PathCornerMinSpeed = 32
ENT.PathCornerCarrotDistanceScale = 8 / 9
ENT.PathCornerDeceleration = 720
ENT.PathTimeoutPerNode = 0.8
ENT.PathTimeoutSpeedScale = 2.6
ENT.PathTimeoutBase = 2.0
ENT.PathTimeoutMax = 45
ENT.DebugPathTimeoutScale = 3.0
ENT.DebugPathTimeoutBase = 4.0
ENT.DebugPathTimeoutMax = 90
ENT.DebugPathSegmentMinTimeout = 3.0
ENT.DebugPathRepathDelay = 0.25
ENT.DebugPathCommandTimeout = 120
ENT.DebugPathProgressGrace = 8.0
ENT.DebugPathNoProgressTimeout = 3.5
ENT.MoveNoProgressGrace = 0.35
ENT.MoveNoProgressTimeout = 0.25
ENT.MoveNoProgressDistance = 8
ENT.MoveNoProgressSpeed = 16
ENT.PathGoalProgressTimeout = 1.2
ENT.PathGoalProgressDistance = 10
ENT.DropAirMaxHorizontalSpeedScale = 0.35
ENT.StrandedRecoveryRetryDelay = 0.35
ENT.StrandedRecoveryBlockedDirectionCooldown = 1.2
ENT.StrandedRecoveryLocalStepScale = 0.75
ENT.StrandedRecoveryBailDuration = 0.55
ENT.StrandedRecoveryFallTimeout = 2.0
ENT.PropSupportDirectTimeoutScale = 1.25
ENT.PropSupportDirectTimeoutBase = 0.15
ENT.PropSupportDirectTimeoutMax = 1.5
ENT.PhysicsImpactRadius = 44
ENT.PhysicsImpactInterval = 0.3
ENT.PhysicsImpactCooldown = 0.22
ENT.PhysicsImpactMinSpeed = 260
ENT.PhysicsImpactDamageScale = 0.035
ENT.PhysicsImpactMaxDamage = 80
ENT.PhysicsPropImpactDamping = 0.45
ENT.PhysicsPropKillDamping = 0.68
ENT.HurtFlashTime = 0.5
ENT.HurtFlashRedAmount = 0.65
ENT.DamageInvulnerabilityTime = 0.5
ENT.KnockbackDuration = 0.12
ENT.KnockbackMinSpeed = 150
ENT.KnockbackDamageSpeedScale = 8
ENT.KnockbackMaxSpeed = 320
ENT.KnockbackUseJump = true
ENT.KnockbackVerticalSpeedScale = 6
ENT.KnockbackVerticalMinSpeed = 170
ENT.KnockbackVerticalMaxSpeed = 240
ENT.IdleActivity = ACT_IDLE
ENT.WalkActivity = ACT_WALK
ENT.RunActivity = ACT_RUN
ENT.JumpActivity = ACT_JUMP
-- Optional model sequence adapter. Per mob, set e.g.
-- AnimationSequences = { idle = "idle", walk = "walk", run = "walk", attack = "attack", death = "death" }.
-- Missing aliases or missing model sequences fall back to idle, then to the legacy Activity layer.
ENT.AnimationSequences = nil
ENT.AnimationMovePlaybackRateMin = 0
ENT.AnimationMovePlaybackRateMax = 2.5
ENT.AnimationPlaybackRateMin = 0.05
ENT.AnimationPlaybackRateMax = 2.5
-- 并行头部注视控制：服务端低频决定偶尔看谁，客户端按骨骼轴映射平滑转头。
-- 默认对齐 MC LookAtPlayerGoal 的"偶尔看一眼"，不是玩家靠近就持续盯住。
ENT.LookAtEnabled = true
ENT.LookAtHeadBoneName = "head"
ENT.LookAtRangeCells = 8
ENT.LookAtPollInterval = 0.5
ENT.LookAtStartChance = 0.06
ENT.LookAtDurationMin = 2.0
ENT.LookAtDurationMax = 4.0
ENT.LookAtYawLimit = 70
ENT.LookAtPitchLimit = 24
ENT.LookAtLerpSpeed = 8
ENT.LookAroundEnabled = true
ENT.LookAroundIntervalMin = 1.0
ENT.LookAroundIntervalMax = 3.0
ENT.LookAroundYawLimit = 60
ENT.LookAroundPitchLimit = 15
ENT.LookAroundForwardChance = 0.35
ENT.LookAroundMaxSpeed = nil -- nil = WalkSpeed + 10; fast running looks straight ahead.
-- 程序化腿摆(非 sequence 动画路)的通用速度→相位/幅度驱动,牛猪羊可共用。
-- 幅度随速度连续缩放(取代走/跑二元开关),频率随速度推进(走慢跑快自然区分)。
ENT.LimbSwingMinSpeed = 8        -- 低于此速度视为静止,摆幅强度→0
ENT.LimbSwingFullSpeed = nil     -- 摆幅到满(强度 1)的参考速度;nil 时取 RunSpeed
ENT.LimbSwingMinAmount = 0       -- 起步(刚过 MinSpeed)时的最小摆幅强度;0=纯比例,>0 给走路一个下限
ENT.LimbSwingPhaseScale = 0.18   -- 相位推进系数:频率 ∝ speed
ENT.LimbSwingBlendSpeed = 10     -- 摆幅强度向目标平滑过渡的速度

local function flatDistance(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y

    return math.sqrt(dx * dx + dy * dy)
end

local function flatDistanceSqr(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y

    return dx * dx + dy * dy
end

local function copyVector(vec)
    return Vector(vec.x, vec.y, vec.z)
end

local function startsWith(text, prefix)
    return string.sub(text or "", 1, #prefix) == prefix
end

local strandedEscapeDirections = {
    Vector(1, 0, 0),
    Vector(-1, 0, 0),
    Vector(0, 1, 0),
    Vector(0, -1, 0),
    Vector(1, 1, 0),
    Vector(1, -1, 0),
    Vector(-1, 1, 0),
    Vector(-1, -1, 0)
}

local function getBlockSizeValue()
    if BMB and BMB.GetBlockSize then return BMB.GetBlockSize() end
    return (BMB and BMB.BS) or 36.5
end

local function scaledBlockDistance(value, scale, fallbackScale)
    if value then return value end
    return getBlockSizeValue() * (scale or fallbackScale or 1)
end

local function atan2(y, x)
    if x > 0 then return math.atan(y / x) end
    if x < 0 and y >= 0 then return math.atan(y / x) + math.pi end
    if x < 0 and y < 0 then return math.atan(y / x) - math.pi end
    if y > 0 then return math.pi * 0.5 end
    if y < 0 then return -math.pi * 0.5 end
    return 0
end

if CLIENT then
    function ENT:Draw()
        local deathUntil = self:GetNWFloat("BMBDeathUntil", 0)
        if self:GetNWBool("BMBDead", false) and deathUntil > CurTime() and self.DeathKeepRed ~= false then
            local gb = 1 - (self.HurtFlashRedAmount or 0.65)

            render.SetColorModulation(1, gb, gb)
            self:DrawModel()
            render.SetColorModulation(1, 1, 1)
            return
        end

        local flashUntil = self:GetNWFloat("BMBHurtFlashUntil", 0)

        if flashUntil > CurTime() then
            local gb = 1 - (self.HurtFlashRedAmount or 0.65)

            render.SetColorModulation(1, gb, gb)
            self:DrawModel()
            render.SetColorModulation(1, 1, 1)
            return
        end

        self:DrawModel()
    end
end

local function pathFlatLength(waypoints, startIndex)
    if not waypoints or #waypoints <= 1 then return 0 end

    local length = 0
    local fromIndex = math.max(1, startIndex or 1)

    for i = fromIndex, #waypoints - 1 do
        length = length + flatDistance(waypoints[i], waypoints[i + 1])
    end

    return length
end

function ENT:Initialize()
    if CLIENT then return end
    self:BaseInitialize()
end

function ENT:BaseInitialize()
    self:SetModel(self.Model)
    self:SetHealth(self.StartHealth)
    self:SetCollisionBounds(self.CollisionMins, self.CollisionMaxs)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionGroup(COLLISION_GROUP_NPC)

    self.loco:SetStepHeight(self.StepHeight)
    self.BMBCurrentStepHeight = self.StepHeight
    self.loco:SetJumpHeight(self:GetBMBBlockSize() * (self.BlockHopJumpHeightScale or 1.5))
    self.loco:SetMaxYawRate(self.TurnRate or 400)
    self.loco:SetAcceleration(self.Acceleration)
    self.loco:SetDeceleration(self.Deceleration)
    self.loco:SetDesiredSpeed(self.WalkSpeed)

    self.State = self.State or "idle"
    self.CurrentMoveActivity = nil
    self.NextStepSoundTime = 0
    self.BMBMoveInterrupt = false
    self.BMBDead = false
    self.BMBHeld = false
    self.BMBDamageInvulnerableUntil = 0
    self.BMBKnockbackUntil = 0
    self.BMBKnockbackVelocity = nil
    self.BMBLastLandTime = 0
    self.NextPhysicsImpactCheck = CurTime() + math.Rand(0, self.PhysicsImpactInterval or 0.3)
    self.PhysicsImpactTimes = {}

    -- mock/real 块世界的懒选择：MCSWEP 比 BMB 后加载，include 时选不到 real，
    -- 生成 mob 时再选一次（幂等，已选对则无操作）
    if BMB and BMB.SelectBlockWorld then
        BMB.SelectBlockWorld()
    end

    if BMB and BMB.BlockWorld then
        BMB.BlockWorld.EnsureInitialized(self:GetPos())
    end

    self:SetNWString("BMBState", self.State)
    self:SetNWFloat("BMBStateStartedAt", CurTime())
    self:SetNWInt("BMBHealth", self:Health())
    self:SetNWFloat("BMBDesiredSpeed", self.WalkSpeed)
    self:SetNWFloat("BMBActivitySpeed", self.WalkSpeed)
    self:SetNWString("BMBMoveMode", "idle")
    self:SetNWFloat("BMBDistToGoal", 0)
    self:SetNWInt("BMBPathNode", 0)
    self:SetNWInt("BMBPathAdvance", 0)
    self:SetNWInt("BMBHopAttempt", 0)
    self:SetNWInt("BMBHopResult", 0)
    self:SetNWBool("BMBHopNative", false)
    self:SetNWFloat("BMBHopDistance", 0)
    self:SetNWFloat("BMBHopFaceDistance", 0)
    self:SetNWFloat("BMBHopSpeed", 0)
    self:SetNWFloat("BMBHopApex", 0)
    self:SetNWFloat("BMBHopDebugUntil", 0)
    self:SetNWFloat("BMBHurtFlashUntil", 0)
    self:SetNWFloat("BMBHurtFlashDuration", self.HurtFlashTime or 0.5)
    self:SetNWBool("BMBDead", false)
    self:SetNWFloat("BMBDeathUntil", 0)
    self:SetNWFloat("BMBInvulnerableUntil", 0)
    self:SetNWFloat("BMBKnockbackUntil", 0)
    self:SetNWFloat("BMBKnockbackSpeed", 0)
    self:SetNWInt("BMBLookAtTarget", 0)
    self:SetNWFloat("BMBLookAtUntil", 0)
    self:SetNWFloat("BMBLookAroundYaw", 0)
    self:SetNWFloat("BMBLookAroundPitch", 0)
    self:SetNWFloat("BMBLookAroundUntil", 0)
end

function ENT:StartBMBActivity(activity)
    if not activity then return end
    if self.CurrentMoveActivity == activity then return end

    self:StartActivity(activity)
    self.CurrentMoveActivity = activity
end

function ENT:GetBMBIdleActivity()
    return self.IdleActivity or ACT_IDLE
end

function ENT:GetBMBWalkActivity()
    return self.WalkActivity or ACT_WALK
end

function ENT:GetBMBRunActivity()
    return self.RunActivity or ACT_RUN
end

function ENT:GetBMBJumpActivity()
    return self.JumpActivity or ACT_JUMP
end

function ENT:GetBMBRunActivityThreshold()
    return (self.WalkSpeed + self.RunSpeed) * 0.5
end

function ENT:GetBMBMoveActivityForSpeed(speed)
    return speed >= self:GetBMBRunActivityThreshold() and self:GetBMBRunActivity() or self:GetBMBWalkActivity()
end

-- 程序化腿摆的通用驱动。把当前水平速度映射为:
--   phase  —— 累积相位(频率随速度连续推进,走慢跑快)
--   amount —— [0,1] 摆幅强度(随速度从 LimbSwingMinAmount 连续缩放到 1,不再走/跑二元)
-- 各 mob 在自己的 UpdateBMBVisualBones 里用 phase/amount 摆自己的骨骼(腿数/轴/最大角度自定)。
-- 持久状态存 self.BMBLimbSwingPhase / self.BMBLimbSwingAmount,需逐帧调用。
function ENT:UpdateBMBLimbSwing(speed2D)
    speed2D = speed2D or self:GetVelocity():Length2D()

    local frameTime = FrameTime()
    local minSpeed = self.LimbSwingMinSpeed or 8
    local fullSpeed = math.max(minSpeed + 1, self.LimbSwingFullSpeed or self.RunSpeed or 100)
    local speedFrac = math.Clamp((speed2D - minSpeed) / (fullSpeed - minSpeed), 0, 1)

    local targetAmount = 0
    if speed2D > minSpeed then
        targetAmount = Lerp(speedFrac, self.LimbSwingMinAmount or 0, 1)
    end

    local blend = math.Clamp(frameTime * (self.LimbSwingBlendSpeed or 10), 0, 1)
    local amount = Lerp(blend, self.BMBLimbSwingAmount or 0, targetAmount)
    local phase = (self.BMBLimbSwingPhase or 0) + speed2D * frameTime * (self.LimbSwingPhaseScale or 0.18)

    self.BMBLimbSwingAmount = amount
    self.BMBLimbSwingPhase = phase % (math.pi * 2)

    return self.BMBLimbSwingPhase, amount
end

function ENT:GetBMBLookAtRange()
    return scaledBlockDistance(self.LookAtRange, self.LookAtRangeCells, 8)
end

function ENT:ClearBMBLookAtTarget()
    if self:GetNWInt("BMBLookAtTarget", 0) == 0 and self:GetNWFloat("BMBLookAtUntil", 0) == 0 then return end

    self:SetNWInt("BMBLookAtTarget", 0)
    self:SetNWFloat("BMBLookAtUntil", 0)
end

function ENT:ClearBMBLookAroundTarget()
    if self:GetNWFloat("BMBLookAroundUntil", 0) == 0
        and self:GetNWFloat("BMBLookAroundYaw", 0) == 0
        and self:GetNWFloat("BMBLookAroundPitch", 0) == 0 then
        return
    end

    self:SetNWFloat("BMBLookAroundYaw", 0)
    self:SetNWFloat("BMBLookAroundPitch", 0)
    self:SetNWFloat("BMBLookAroundUntil", 0)
end

function ENT:IsBMBLookAtSuppressed()
    local state = self:GetNWString("BMBState", self.State or "idle")
    return self.BMBDead or state == "dead" or state == "eat_grass"
end

function ENT:IsBMBLookAtCandidateValid(target, rangeSqr)
    if not IsValid(target) or not target:IsPlayer() then return false end
    if target.Alive and not target:Alive() then return false end

    return self:GetPos():DistToSqr(target:GetPos()) <= rangeSqr
end

function ENT:FindBMBLookAtPlayer(rangeSqr)
    local candidates = {}

    for _, ply in ipairs(player.GetAll()) do
        if self:IsBMBLookAtCandidateValid(ply, rangeSqr) then
            candidates[#candidates + 1] = ply
        end
    end

    if #candidates == 0 then return nil end
    return candidates[math.random(1, #candidates)]
end

function ENT:IsBMBLookAroundActiveForSpeed()
    local maxSpeed = self.LookAroundMaxSpeed or ((self.WalkSpeed or 80) + 10)
    return self:GetVelocity():Length2D() <= maxSpeed
end

function ENT:UpdateBMBLookAroundController(now)
    if self.LookAroundEnabled == false or not self:IsBMBLookAroundActiveForSpeed() then
        self:ClearBMBLookAroundTarget()
        self.BMBNextLookAroundAt = now + math.Rand(self.LookAroundIntervalMin or 1.0, self.LookAroundIntervalMax or 3.0)
        return
    end

    if now < (self.BMBNextLookAroundAt or 0) then return end

    local delay = math.Rand(self.LookAroundIntervalMin or 1.0, self.LookAroundIntervalMax or 3.0)
    self.BMBNextLookAroundAt = now + delay

    local yaw = 0
    local pitch = 0
    if math.Rand(0, 1) > (self.LookAroundForwardChance or 0.35) then
        yaw = math.Rand(-(self.LookAroundYawLimit or 60), self.LookAroundYawLimit or 60)
        pitch = math.Rand(-(self.LookAroundPitchLimit or 15), self.LookAroundPitchLimit or 15)
    end

    self:SetNWFloat("BMBLookAroundYaw", yaw)
    self:SetNWFloat("BMBLookAroundPitch", pitch)
    self:SetNWFloat("BMBLookAroundUntil", self.BMBNextLookAroundAt + 0.1)
end

function ENT:UpdateBMBLookAtController()
    if self.LookAtEnabled == false then
        self:ClearBMBLookAtTarget()
        self:ClearBMBLookAroundTarget()
        return
    end

    if self:IsBMBLookAtSuppressed() then
        self:ClearBMBLookAtTarget()
        self:ClearBMBLookAroundTarget()
        return
    end

    local now = CurTime()
    local range = self:GetBMBLookAtRange()
    local rangeSqr = range * range
    local targetIndex = self:GetNWInt("BMBLookAtTarget", 0)
    local lookUntil = self:GetNWFloat("BMBLookAtUntil", 0)

    if targetIndex > 0 and lookUntil > now then
        local target = Entity(targetIndex)
        if self:IsBMBLookAtCandidateValid(target, rangeSqr) then
            self:ClearBMBLookAroundTarget()
            return
        end

        self:ClearBMBLookAtTarget()
    end

    if targetIndex > 0 or lookUntil > 0 then
        self:ClearBMBLookAtTarget()
    end

    if now < (self.BMBNextLookAtCheck or 0) then
        self:UpdateBMBLookAroundController(now)
        return
    end
    self.BMBNextLookAtCheck = now + (self.LookAtPollInterval or 0.5)

    if math.Rand(0, 1) > (self.LookAtStartChance or 0.06) then
        self:UpdateBMBLookAroundController(now)
        return
    end

    local target = self:FindBMBLookAtPlayer(rangeSqr)
    if not IsValid(target) then
        self:UpdateBMBLookAroundController(now)
        return
    end

    self:ClearBMBLookAroundTarget()
    self:SetNWInt("BMBLookAtTarget", target:EntIndex())
    self:SetNWFloat("BMBLookAtUntil", now + math.Rand(self.LookAtDurationMin or 2.0, self.LookAtDurationMax or 4.0))
end

if CLIENT then
    function ENT:GetBMBLookAtHeadBoneName()
        return self.LookAtHeadBoneName or "head"
    end

    function ENT:GetBMBLookAtTarget()
        local lookUntil = self:GetNWFloat("BMBLookAtUntil", 0)
        if lookUntil <= CurTime() then return nil end

        local targetIndex = self:GetNWInt("BMBLookAtTarget", 0)
        if targetIndex <= 0 then return nil end

        local target = Entity(targetIndex)
        if not IsValid(target) then return nil end

        return target
    end

    function ENT:GetBMBLookAtTargetPosition(target)
        if target.EyePos then return target:EyePos() end
        return target:WorldSpaceCenter()
    end

    function ENT:ComputeBMBLookAtHeadAngle(target)
        local localTarget = self:WorldToLocal(self:GetBMBLookAtTargetPosition(target))
        local horizontal = math.max(0.001, math.sqrt(localTarget.x * localTarget.x + localTarget.y * localTarget.y))
        local yaw = math.deg(atan2(localTarget.y, localTarget.x))
        local pitch = math.deg(atan2(localTarget.z, horizontal))

        -- MC sheep model mapping from in-game pose preview:
        -- Head rot X: positive = look left, negative = look right.
        -- Head rot Z: positive = look up, negative = look down.
        return Angle(
            math.Clamp(yaw, -(self.LookAtYawLimit or 70), self.LookAtYawLimit or 70),
            0,
            math.Clamp(pitch, -(self.LookAtPitchLimit or 24), self.LookAtPitchLimit or 24)
        )
    end

    function ENT:GetBMBLookAroundHeadAngle()
        if self:GetNWFloat("BMBLookAroundUntil", 0) <= CurTime() then return nil end

        return Angle(
            math.Clamp(self:GetNWFloat("BMBLookAroundYaw", 0), -(self.LookAroundYawLimit or 60), self.LookAroundYawLimit or 60),
            0,
            math.Clamp(self:GetNWFloat("BMBLookAroundPitch", 0), -(self.LookAroundPitchLimit or 15), self.LookAroundPitchLimit or 15)
        )
    end

    function ENT:UpdateBMBLookAtHeadPose(headBone)
        if not headBone then return false end

        local target = self:GetBMBLookAtTarget()
        local lookAroundAngle = nil
        local targetAngle = Angle(0, 0, 0)
        if target then
            targetAngle = self:ComputeBMBLookAtHeadAngle(target)
        else
            lookAroundAngle = self:GetBMBLookAroundHeadAngle()
            if lookAroundAngle then
                targetAngle = lookAroundAngle
            end
        end

        local current = self.BMBLookAtHeadAngle or Angle(0, 0, 0)
        local fraction = math.Clamp(FrameTime() * (self.LookAtLerpSpeed or 8), 0, 1)
        local nextAngle = Angle(
            Lerp(fraction, current.p, targetAngle.p),
            0,
            Lerp(fraction, current.r, targetAngle.r)
        )

        self.BMBLookAtHeadAngle = nextAngle

        local active = target ~= nil or lookAroundAngle ~= nil or math.abs(nextAngle.p) > 0.05 or math.abs(nextAngle.r) > 0.05
        if active then
            self:ManipulateBoneAngles(headBone, nextAngle)
        end

        return active
    end
end

function ENT:UsesBMBSequenceAnimation()
    return type(self.AnimationSequences) == "table"
end

function ENT:GetBMBSequenceCache()
    local model = self:GetModel() or ""
    if self.BMBSequenceCache and self.BMBSequenceCache.model == model then
        return self.BMBSequenceCache
    end

    self.BMBSequenceCache = {
        model = model,
        sequences = {}
    }

    return self.BMBSequenceCache
end

function ENT:LookupBMBAnimationSequence(sequenceName)
    if not sequenceName or sequenceName == "" then return -1 end

    local cache = self:GetBMBSequenceCache()
    if cache.sequences[sequenceName] == nil then
        cache.sequences[sequenceName] = self:LookupSequence(sequenceName) or -1
    end

    return cache.sequences[sequenceName]
end

function ENT:GetBMBAnimationSequenceAlias(action)
    local sequences = self.AnimationSequences
    if type(sequences) ~= "table" then return nil end

    local alias = sequences[action]
    if (not alias or alias == "") and action == "run" then
        alias = sequences.walk
    end

    if (not alias or alias == "") and action ~= "idle" then
        alias = sequences.idle
    end

    if type(alias) ~= "string" then return nil end
    return alias
end

function ENT:ResolveBMBAnimationSequence(action)
    if not self:UsesBMBSequenceAnimation() then return nil end

    local sequenceName = self:GetBMBAnimationSequenceAlias(action)
    local sequenceId = self:LookupBMBAnimationSequence(sequenceName)
    if sequenceId and sequenceId >= 0 then
        return sequenceId, sequenceName, action
    end

    if action ~= "idle" then
        local idleName = self:GetBMBAnimationSequenceAlias("idle")
        local idleId = self:LookupBMBAnimationSequence(idleName)
        if idleId and idleId >= 0 then
            return idleId, idleName, "idle"
        end
    end

    return nil
end

function ENT:GetBMBAnimationAction()
    local state = self:GetNWString("BMBState", self.State or "idle")

    if self.BMBDead or state == "dead" then return "death" end
    if state == "eat_grass" then return "eat_grass" end
    if state == "attack" then return "attack" end
    if state == "knockback" then return "hurt" end
    if self.BMBHeld or state == "held" then return "idle" end

    local jumping = self.loco.IsClimbingOrJumping and self.loco:IsClimbingOrJumping() or false
    local onGround = self:IsBMBOnGround()

    if jumping or not onGround then return "jump" end

    local speed2D = self:GetVelocity():Length2D()
    local desiredSpeed = self:GetNWFloat("BMBDesiredSpeed", self.WalkSpeed)
    local activitySpeed = self:GetNWFloat("BMBActivitySpeed", desiredSpeed)
    local mode = self:GetNWString("BMBMoveMode", "idle")

    if mode == "idle" and speed2D < 8 then return "idle" end
    if desiredSpeed <= 1 and speed2D < 8 then return "idle" end

    return math.max(activitySpeed, speed2D) >= self:GetBMBRunActivityThreshold() and "run" or "walk"
end

function ENT:GetBMBAnimationPlaybackRate(action, sequenceName, speed2D)
    local rates = self.AnimationPlaybackRates
    if type(rates) == "table" then
        local rate = rates[action] or rates[sequenceName]
        if rate then
            return math.Clamp(rate, self.AnimationPlaybackRateMin or 0.05, self.AnimationPlaybackRateMax or 2.5)
        end
    end

    if action == "walk" or action == "run" then
        local referenceSpeeds = self.AnimationReferenceSpeeds
        local referenceSpeed

        if type(referenceSpeeds) == "table" then
            referenceSpeed = referenceSpeeds[action] or referenceSpeeds[sequenceName]
        end

        referenceSpeed = referenceSpeed or self.AnimationMoveReferenceSpeed or self.WalkSpeed or 1

        local rate = (speed2D or 0) / math.max(1, referenceSpeed)
        return math.Clamp(rate, self.AnimationMovePlaybackRateMin or 0, self.AnimationMovePlaybackRateMax or 2.5)
    end

    return 1
end

function ENT:UpdateBMBSequenceAnimation(action, speed2D)
    if not self:UsesBMBSequenceAnimation() then return false end

    action = action or self:GetBMBAnimationAction()
    speed2D = speed2D or self:GetVelocity():Length2D()

    local sequenceId, sequenceName, resolvedAction = self:ResolveBMBAnimationSequence(action)
    if not sequenceId then return false end

    if self.BMBCurrentSequenceId ~= sequenceId then
        self:ResetSequence(sequenceId)
        self:SetCycle(0)
        self.BMBCurrentSequenceId = sequenceId
        self.BMBCurrentSequenceName = sequenceName
    end

    self.BMBCurrentAnimationAction = resolvedAction
    self:SetPlaybackRate(self:GetBMBAnimationPlaybackRate(resolvedAction, sequenceName, speed2D))
    self:FrameAdvance(FrameTime())
    return true
end

function ENT:UpdateBMBSequenceAnimationFromState()
    if not self:UsesBMBSequenceAnimation() then return false end
    return self:UpdateBMBSequenceAnimation(self:GetBMBAnimationAction(), self:GetVelocity():Length2D())
end

function ENT:UpdateMoveActivity(speed, activitySpeed)
    local commandSpeed = speed or self.WalkSpeed
    local intentSpeed = activitySpeed or commandSpeed
    local activity = self:GetBMBMoveActivityForSpeed(intentSpeed)

    self:StartBMBActivity(activity)
    self:SetNWFloat("BMBDesiredSpeed", commandSpeed)
    self:SetNWFloat("BMBActivitySpeed", intentSpeed)
end

function ENT:GetBMBBlockSize()
    return getBlockSizeValue()
end

function ENT:GetBMBScaledDistance(value, scale, fallbackScale)
    return scaledBlockDistance(value, scale, fallbackScale)
end

function ENT:GetBMBDefaultGoalTolerance()
    if BMB and BMB.GetBlockSize then
        BMB.GetBlockSize()
    end

    if BMB and BMB.Config and BMB.Config.DefaultGoalTolerance then
        return BMB.Config.DefaultGoalTolerance
    end

    return self:GetBMBBlockSize() * 0.5
end

function ENT:GetBMBSourcePathGoalTolerance()
    return self:GetBMBScaledDistance(self.SourcePathGoalTolerance, self.SourcePathGoalToleranceScale, 0.5)
end

function ENT:GetBMBPathNodeTolerance()
    return self:GetBMBScaledDistance(self.PathNodeTolerance, self.PathNodeToleranceScale, 0.5)
end

function ENT:GetBMBPathCarrotMinDistance()
    return self:GetBMBScaledDistance(self.PathCarrotMinDistance, self.PathCarrotMinDistanceScale, 2)
end

function ENT:GetBMBPathCarrotMaxDistance()
    return self:GetBMBScaledDistance(self.PathCarrotMaxDistance, self.PathCarrotMaxDistanceScale, 25 / 6)
end

function ENT:GetBMBPathCornerSlowDistance()
    return self:GetBMBScaledDistance(self.PathCornerSlowDistance, self.PathCornerSlowDistanceScale, 2)
end

function ENT:GetBMBPathCornerCarrotDistance()
    return self:GetBMBScaledDistance(self.PathCornerCarrotDistance, self.PathCornerCarrotDistanceScale, 8 / 9)
end

function ENT:GetBMBHopStepHeight()
    return self:GetBMBScaledDistance(self.BlockHopStepHeight, self.BlockHopStepHeightScale, 0.49)
end

function ENT:GetBMBMaxStepDown()
    return self:GetBMBScaledDistance(self.MaxStepDown, self.MaxStepDownScale, 1.1)
end

function ENT:SetBMBLocoStepHeight(height)
    height = height or self.StepHeight

    if self.loco and self.loco.SetStepHeight then
        self.loco:SetStepHeight(height)
    end

    self.BMBCurrentStepHeight = height
end

function ENT:BeginBMBHopStepHeight()
    if self.BMBHopStepHeightActive then return end

    self.BMBHopSavedStepHeight = self.BMBCurrentStepHeight or self.StepHeight
    self.BMBHopStepHeightActive = true
    self:SetBMBLocoStepHeight(self:GetBMBHopStepHeight())
end

function ENT:RestoreBMBStepHeight()
    if not self.BMBHopStepHeightActive then return end

    self:SetBMBLocoStepHeight(self.BMBHopSavedStepHeight or self.StepHeight)
    self.BMBHopSavedStepHeight = nil
    self.BMBHopStepHeightActive = false
end

function ENT:ShouldUseSourcePath()
    local convar = GetConVar("bmb_use_source_path")
    return self.UseSourcePathFollower and (not convar or convar:GetBool())
end

function ENT:InterruptBMBMovement()
    self.BMBMoveInterrupt = true
    self.BMBPendingBlockHop = nil
    self.BMBActiveBlockHop = nil
    self.BMBBlockHopAirControlUntil = 0
    self:RestoreBMBStepHeight()
end

function ENT:ClearBMBMovementInterrupt()
    self.BMBMoveInterrupt = false
end

function ENT:SetBMBMoveMode(mode)
    mode = mode or "idle"
    if self.BMBDead and mode ~= "dead" then return end
    if self.BMBCurrentMoveMode == mode then return end

    self.BMBCurrentMoveMode = mode
    self:SetNWString("BMBMoveMode", mode)

    if mode == "idle" and self.StartBMBIdleActivity then
        self:StartBMBIdleActivity()
    end
end

function ENT:MaintainBMBMoveSpeed(speed, activitySpeed)
    if self.BMBDead then return end

    local desiredSpeed = speed or self.WalkSpeed

    self.loco:SetDesiredSpeed(desiredSpeed)
    self:SetNWFloat("BMBDesiredSpeed", desiredSpeed)
    self:SetNWFloat("BMBActivitySpeed", activitySpeed or desiredSpeed)
end

function ENT:UpdateBMBApproachDebug(target, nodeIndex)
    if target then
        self:SetNWFloat("BMBDistToGoal", flatDistance(self:GetPos(), target))
    else
        self:SetNWFloat("BMBDistToGoal", 0)
    end

    if nodeIndex then
        self:SetNWInt("BMBPathNode", nodeIndex)
    end
end

function ENT:MarkBMBPathAdvanced(nodeIndex)
    self.BMBPathAdvanceCount = (self.BMBPathAdvanceCount or 0) + 1
    self:SetNWInt("BMBPathAdvance", self.BMBPathAdvanceCount)

    if nodeIndex then
        self:SetNWInt("BMBPathNode", nodeIndex)
    end
end

function ENT:StartBMBIdleActivity()
    self:StartBMBActivity(self:GetBMBIdleActivity())
end

function ENT:UpdateBMBActivityFromLocomotion()
    if self:UpdateBMBSequenceAnimationFromState() then return end

    if self.BMBHeld then
        self:StartBMBIdleActivity()
        return
    end

    if self:IsBMBKnockbackActive() then
        self:StartBMBIdleActivity()
        return
    end

    local jumping = self.loco.IsClimbingOrJumping and self.loco:IsClimbingOrJumping() or false
    local onGround = self:IsBMBOnGround()

    if jumping or not onGround then
        self:StartBMBActivity(self:GetBMBJumpActivity())
        return
    end

    local speed2D = self:GetVelocity():Length2D()
    local desiredSpeed = self:GetNWFloat("BMBDesiredSpeed", self.WalkSpeed)
    local activitySpeed = self:GetNWFloat("BMBActivitySpeed", desiredSpeed)
    local mode = self:GetNWString("BMBMoveMode", "idle")

    if mode == "idle" and speed2D < 8 then
        self:StartBMBIdleActivity()
        return
    end

    if desiredSpeed <= 1 and speed2D < 8 then
        self:StartBMBIdleActivity()
        return
    end

    local activity = self:GetBMBMoveActivityForSpeed(math.max(activitySpeed, speed2D))

    self:StartBMBActivity(activity)
end

function ENT:StartBMBMoveProgressWatch()
    return {
        pos = copyVector(self:GetPos()),
        deadline = CurTime() + (self.MoveNoProgressGrace or 0.75)
    }
end

function ENT:CheckBMBMoveProgress(watch)
    if not watch then return true end

    local velocity = self:GetVelocity():Length2D()
    local moved = flatDistance(self:GetPos(), watch.pos)

    if velocity >= (self.MoveNoProgressSpeed or 8) or moved >= (self.MoveNoProgressDistance or 3) then
        watch.pos = copyVector(self:GetPos())
        watch.deadline = CurTime() + (self.MoveNoProgressTimeout or 0.45)
        return true
    end

    return CurTime() < watch.deadline
end

function ENT:StartBMBGoalProgressWatch(goal)
    return {
        distance = flatDistance(self:GetPos(), goal),
        deadline = CurTime() + (self.PathGoalProgressTimeout or 0.9)
    }
end

function ENT:GetBMBMoveTimeoutForDistance(distance, speed, options)
    options = options or {}
    if options.timeout then return options.timeout end

    local desiredSpeed = math.max(1, speed or self.WalkSpeed)
    local scale = options.timeoutScale or self.PathTimeoutSpeedScale or 2.6
    local base = options.timeoutBase or self.PathTimeoutBase or 2.0
    local timeout = base + (math.max(0, distance or 0) / desiredSpeed) * scale

    if options.minTimeout then
        timeout = math.max(timeout, options.minTimeout)
    end

    local maxTimeout = options.timeoutMax or self.PathTimeoutMax
    if maxTimeout then
        timeout = math.min(timeout, maxTimeout)
    end

    return math.max(self.WaypointTimeout or 0, timeout)
end

function ENT:GetBMBPathTimeout(waypoints, speed, options, startIndex)
    options = options or {}
    if options.timeout then return options.timeout end

    local length = pathFlatLength(waypoints, startIndex)
    local distanceBudget = self:GetBMBMoveTimeoutForDistance(length, speed, options)
    local nodeBudget = #waypoints * (self.PathTimeoutPerNode or 0.8) + 1.0

    return math.max(distanceBudget, nodeBudget)
end

function ENT:CheckBMBGoalProgress(watch, goal)
    if not watch or not goal then return true end

    local distance = flatDistance(self:GetPos(), goal)
    if distance <= watch.distance - (self.PathGoalProgressDistance or 10) then
        watch.distance = distance
        watch.deadline = CurTime() + (self.PathGoalProgressTimeout or 0.9)
        return true
    end

    if distance > watch.distance then
        watch.distance = distance
    end

    return CurTime() < watch.deadline
end

function ENT:FailBMBMove(mode, keepMomentum)
    self:RestoreBMBStepHeight()

    -- 安全层拦下移动时主动杀掉水平动量：高速冲向平台边缘时仅靠自然减速刹不住，
    -- 惯性会把 mob 顺势带下悬崖。撞墙类失败（keepMomentum）不急刹：墙本身挡得住，
    -- 急刹反而造成"离 prop 还有段距离就掉速、一点一点给油转向"的犹豫观感
    if not keepMomentum then
        local velocity = self:GetVelocity()
        self.loco:SetVelocity(Vector(velocity.x * 0.1, velocity.y * 0.1, velocity.z))
    end

    self:SetBMBMoveMode(mode or "blocked")
    self:StartBMBIdleActivity()
    self:UpdateBMBApproachDebug(nil, 0)
end

function ENT:InterruptibleWait(duration)
    self:StartBMBIdleActivity()
    self:SetBMBMoveMode("idle")
    self:UpdateBMBApproachDebug(nil, 0)

    local deadline = CurTime() + duration

    while CurTime() < deadline do
        if self.BMBMoveInterrupt then return false end
        coroutine.wait(math.min(0.05, deadline - CurTime()))
    end

    return true
end

function ENT:RunBMBInitialIdle()
    local idleUntil = self.BMBInitialIdleUntil
    if not idleUntil or CurTime() >= idleUntil then return false end

    self:SetBMBState("idle")
    self:InterruptibleWait(math.min(0.2, math.max(0, idleUntil - CurTime())))
    return true
end

function ENT:RunBehaviour()
    while true do
        coroutine.wait(0.2)
        coroutine.yield()
    end
end

function ENT:Think()
    if CLIENT then
        if self.UpdateBMBVisualBones then
            self:UpdateBMBVisualBones()
        end

        self:NextThink(CurTime())
        return true
    end

    if SERVER then
        if self.BMBDead then
            self:ClearBMBLookAtTarget()

            -- 死亡后每 tick 缴械 loco：否则 flee 的水平动量 / 跳跃中死亡的弹道速度残留会让尸体跟着跑或跳
            if self.loco then
                if self.loco.SetGravity then self.loco:SetGravity(0) end
                if self.loco.SetVelocity then self.loco:SetVelocity(vector_origin) end
                if self.loco.SetDesiredSpeed then self.loco:SetDesiredSpeed(0) end
            end

            self:UpdateBMBSequenceAnimationFromState()
            self:NextThink(CurTime())
            return true
        end

        self:UpdateBMBLookAtController()

        if self.BMBHeld then
            -- 物理枪持握中：loco 每 tick 缴械。否则 loco 醒着时重力下拽 + 出固体
            -- 解算上顶，和物理枪的持握点拉扯 = 上下抽搐/陷地循环；loco 恰好睡着的
            -- 个体则不抽——哪只抽哪只挂取决于被抓瞬间 loco 醒睡，看着随机
            if self.loco.SetGravity then
                self.loco:SetGravity(0)
            end

            if self.loco.SetDesiredSpeed then
                self.loco:SetDesiredSpeed(0)
                self:SetNWFloat("BMBDesiredSpeed", 0)
            end

            self.loco:SetVelocity(vector_origin)
        else
            self:CheckPhysicsImpacts()
        end

        if not self.BMBDead and self.MaybePlayIdleSound then
            self:MaybePlayIdleSound()
        end

        self:UpdateBMBActivityFromLocomotion()

        -- Keep entity Think per tick: NextBot locomotion/body interpolation becomes visibly
        -- choppy if the whole entity Think is throttled. Expensive maintenance is throttled
        -- inside its own helpers instead.
        self:NextThink(CurTime())
        return true
    end
end

function ENT:IsBMBHeld()
    return self.BMBHeld == true
end

-- hop 重跳延时的计时基准：物理引擎的落地回调，不靠 IsOnGround 轮询
-- （轮询间隔里"已落地又起跳"会抖动）
function ENT:OnLandOnGround(_)
    self.BMBLastLandTime = CurTime()
    self.CurrentMoveActivity = nil
    self:UpdateBMBActivityFromLocomotion()
end

function ENT:OnBMBPhysgunPickup(_)
    if self.BMBHeld then return end

    self.BMBHeld = true
    if self.loco.GetGravity and self.loco.SetGravity then
        self.BMBHeldGravity = self.loco:GetGravity()
        self.loco:SetGravity(0)
    end

    self:InterruptBMBMovement()
    self:MaintainBMBMoveSpeed(0)
    self:SetBMBMoveMode("held")
    self:StartBMBIdleActivity()
end

function ENT:OnBMBPhysgunDrop(_)
    if not self.BMBHeld then return end

    self.BMBHeld = false
    self:ClearBMBMovementInterrupt()

    if self.loco.SetGravity and self.BMBHeldGravity then
        self.loco:SetGravity(self.BMBHeldGravity)
    end

    self.BMBHeldGravity = nil
    -- 踹一脚向下速度：被抓瞬间 loco 若在睡眠（零速 + 自认在地面）物理更新被短路，
    -- 松手悬空也不掉；这脚把它踹醒，挂天上/半空松手的都正常受重力下落
    self.loco:SetVelocity(Vector(0, 0, -10))
    self:MaintainBMBMoveSpeed(self.WalkSpeed or 80)
    self.BMBInitialIdleUntil = 0
    self:SetBMBMoveMode("idle")
    self:StartBMBIdleActivity()
end

if SERVER then
    hook.Add("PhysgunPickup", "BMB_PhysgunHold", function(_, ent)
        if ent.IsBMBMob and ent.OnBMBPhysgunPickup then
            ent:OnBMBPhysgunPickup()
        end
    end)

    hook.Add("PhysgunDrop", "BMB_PhysgunHold", function(_, ent)
        if ent.IsBMBMob and ent.OnBMBPhysgunDrop then
            ent:OnBMBPhysgunDrop()
        end
    end)
end

function ENT:SetBMBState(state)
    if self.BMBDead and state ~= "dead" then return end
    if self.State == state then return end
    self.State = state
    self:SetNWString("BMBState", state)
    self:SetNWFloat("BMBStateStartedAt", CurTime())
end

function ENT:IsBMBFleeing()
    return self.State == "flee" or self:GetNWString("BMBState", "") == "flee"
end

function ENT:IsBMBInDamageInvulnerability()
    return CurTime() < (self.BMBDamageInvulnerableUntil or 0)
end

function ENT:StartBMBHurtFlash()
    local duration = self.HurtFlashTime or 0.5
    self:SetNWFloat("BMBHurtFlashDuration", duration)
    self:SetNWFloat("BMBHurtFlashUntil", CurTime() + duration)
end

function ENT:HasBMBDamageType(damageInfo, mask)
    if not damageInfo or not mask then return false end
    return bit.band(damageInfo:GetDamageType() or 0, mask) ~= 0
end

function ENT:IsBMBPhysicsDamage(damageInfo)
    return self:HasBMBDamageType(damageInfo, DMG_CRUSH)
end

function ENT:GetBMBKnockbackDirection(damageInfo)
    if not damageInfo then return nil end

    local origin = self:WorldSpaceCenter()
    local function awayFromPoint(point)
        if not point then return nil end
        if point:LengthSqr() <= 1 then return nil end

        local direction = origin - point
        direction.z = 0

        if direction:LengthSqr() <= 1 then return nil end

        direction:Normalize()
        return direction
    end

    if self:HasBMBDamageType(damageInfo, DMG_BLAST) then
        local blastDirection = awayFromPoint(damageInfo:GetDamagePosition())
        if blastDirection then return blastDirection end

        local inflictor = damageInfo:GetInflictor()
        if IsValid(inflictor) and inflictor ~= self then
            blastDirection = awayFromPoint(inflictor:WorldSpaceCenter())
            if blastDirection then return blastDirection end
        end
    end

    local attacker = damageInfo:GetAttacker()
    if IsValid(attacker) and attacker ~= self then
        local attackDirection = awayFromPoint(attacker:WorldSpaceCenter())
        if attackDirection then return attackDirection end
    end

    local hitDirection = awayFromPoint(damageInfo:GetDamagePosition())
    if hitDirection then return hitDirection end

    local force = damageInfo:GetDamageForce()
    if force and force:LengthSqr() > 1 then
        local forceDirection = Vector(force.x, force.y, 0)
        if forceDirection:LengthSqr() > 1 then
            forceDirection:Normalize()
            return forceDirection
        end
    end

    local fallback = -self:GetForward()
    fallback.z = 0
    if fallback:LengthSqr() <= 1 then return Vector(1, 0, 0) end

    fallback:Normalize()
    return fallback
end

function ENT:IsBMBKnockbackActive()
    return CurTime() < (self.BMBKnockbackUntil or 0) and self.BMBKnockbackVelocity ~= nil
end

function ENT:GetBMBKnockbackVerticalVelocity(currentVelocity)
    currentVelocity = currentVelocity or self:GetVelocity()
    if not self:IsBMBOnGround() then return currentVelocity.z end

    local blockSize = self:GetBMBBlockSize()
    local lift = math.Clamp(
        blockSize * (self.KnockbackVerticalSpeedScale or 6),
        self.KnockbackVerticalMinSpeed or 170,
        self.KnockbackVerticalMaxSpeed or 240
    )

    return math.max(currentVelocity.z, lift)
end

function ENT:StartBMBKnockback(damageInfo)
    if self.BMBHeld then return false end
    if self:IsBMBPhysicsDamage(damageInfo) then return false end

    local direction = self:GetBMBKnockbackDirection(damageInfo)
    if not direction then return false end

    local damage = math.max(0, damageInfo:GetDamage() or 0)
    local minSpeed = self.KnockbackMinSpeed or 150
    local maxSpeed = self.KnockbackMaxSpeed or 320
    local speed = math.Clamp(minSpeed + damage * (self.KnockbackDamageSpeedScale or 8), minSpeed, maxSpeed)
    local now = CurTime()
    local currentVelocity = self:GetVelocity()
    local verticalSpeed = self:GetBMBKnockbackVerticalVelocity(currentVelocity)

    self.BMBKnockbackStartedAt = now
    self.BMBKnockbackUntil = now + (self.KnockbackDuration or 0.12)
    self.BMBKnockbackVelocity = direction * speed
    self.BMBKnockbackVerticalSpeed = verticalSpeed
    self.BMBKnockbackDesiredSpeed = math.max(1, self:GetNWFloat("BMBDesiredSpeed", self.WalkSpeed), self.WalkSpeed or 1)
    self.BMBKnockbackActivitySpeed = math.max(
        self.BMBKnockbackDesiredSpeed,
        self:GetNWFloat("BMBActivitySpeed", self.BMBKnockbackDesiredSpeed)
    )
    self.BMBKnockbackLocoSpeed = math.max(speed, self.BMBKnockbackDesiredSpeed)
    self:SetNWFloat("BMBKnockbackUntil", self.BMBKnockbackUntil)
    self:SetNWFloat("BMBKnockbackSpeed", speed)

    self:InterruptBMBMovement()
    self:SetBMBState("knockback")
    self:SetBMBMoveMode("knockback")
    self:UpdateBMBApproachDebug(nil, 0)
    self:MaintainBMBKnockbackSpeedBudget()

    if self.KnockbackUseJump ~= false and verticalSpeed > currentVelocity.z and self.loco.Jump then
        self.loco:Jump()
    end

    self.loco:SetVelocity(Vector(self.BMBKnockbackVelocity.x, self.BMBKnockbackVelocity.y, verticalSpeed))

    return true
end

function ENT:MaintainBMBKnockbackSpeedBudget()
    local displayDesired = math.max(1, self.BMBKnockbackDesiredSpeed or self:GetNWFloat("BMBDesiredSpeed", self.WalkSpeed))
    local displayActivity = math.max(displayDesired, self.BMBKnockbackActivitySpeed or self:GetNWFloat("BMBActivitySpeed", displayDesired))
    local velocity = self.BMBKnockbackVelocity or vector_origin
    local locoBudget = math.max(displayDesired, self.BMBKnockbackLocoSpeed or 0, velocity:Length2D())

    self.loco:SetDesiredSpeed(locoBudget)
    self:SetNWFloat("BMBDesiredSpeed", displayDesired)
    self:SetNWFloat("BMBActivitySpeed", displayActivity)
end

function ENT:RunBMBKnockback()
    if not self:IsBMBKnockbackActive() then return false end

    self:ClearBMBMovementInterrupt()
    self:SetBMBState("knockback")
    self:SetBMBMoveMode("knockback")
    self:MaintainBMBKnockbackSpeedBudget()
    self:StartBMBIdleActivity()

    local duration = math.max(0.01, (self.BMBKnockbackUntil or CurTime()) - (self.BMBKnockbackStartedAt or CurTime()))

    while self:IsBMBKnockbackActive() do
        local baseVelocity = self.BMBKnockbackVelocity or vector_origin
        local remaining = math.Clamp(((self.BMBKnockbackUntil or 0) - CurTime()) / duration, 0, 1)
        local currentVelocity = self:GetVelocity()

        self:SetBMBState("knockback")
        self:SetBMBMoveMode("knockback")
        self:MaintainBMBKnockbackSpeedBudget()
        self.loco:SetVelocity(Vector(baseVelocity.x * remaining, baseVelocity.y * remaining, currentVelocity.z))
        self:UpdateBMBApproachDebug(nil, 0)

        coroutine.yield()
    end

    local restoreSpeed = self.BMBKnockbackDesiredSpeed or self.WalkSpeed
    self.BMBKnockbackVelocity = nil
    self.BMBKnockbackVerticalSpeed = nil
    self.BMBKnockbackDesiredSpeed = nil
    self.BMBKnockbackActivitySpeed = nil
    self.BMBKnockbackLocoSpeed = nil
    self:SetNWFloat("BMBKnockbackSpeed", 0)
    self.loco:SetDesiredSpeed(restoreSpeed)
    self:SetBMBMoveMode("idle")
    self:UpdateBMBApproachDebug(nil, 0)
    self:ClearBMBMovementInterrupt()

    return true
end

function ENT:HasBMBDebugMove()
    return self.BMBDebugMoveUntil and CurTime() < self.BMBDebugMoveUntil and (self.BMBDebugMoveDirection or self.BMBDebugMoveTarget)
end

function ENT:ClearBMBDebugMove()
    self.BMBDebugMoveUntil = 0
    self.BMBDebugMoveDirection = nil
    self.BMBDebugMoveTarget = nil
    self.BMBDebugMoveUsePath = nil
end

function ENT:IsBMBCurrentPositionStandable()
    if not BMB or not BMB.Pathfinder or not BMB.Pathfinder.IsStandablePosition then
        return true
    end

    return BMB.Pathfinder.IsStandablePosition(self:GetBMBGridFootSample(self:GetPos()), { mob = self })
end

function ENT:IsBMBPropSupportEntity(ent)
    if not IsValid(ent) then return false end
    if ent:IsWorld() or ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() then return false end

    local class = string.lower(ent:GetClass() or "")
    if startsWith(class, "mc_") or startsWith(class, "mcswep") or string.find(class, "minecraft", 1, true) then
        return false
    end

    if startsWith(class, "prop_") or class == "func_physbox" or class == "func_physbox_multiplayer" then
        return true
    end

    return ent.GetMoveType and ent:GetMoveType() == MOVETYPE_VPHYSICS
end

function ENT:IsBMBOnPropSupport()
    if not self:IsBMBOnGround() then return false end

    local hasGround, trace = self:HasBMBPhysicalGroundAt(self:GetPos())
    if not hasGround or not trace or trace.HitWorld then return false end

    return self:IsBMBPropSupportEntity(trace.Entity)
end

function ENT:ShouldRunBMBStrandedRecovery()
    if self.BMBHeld then return false end
    if self:IsBMBKnockbackActive() then return false end
    if not self:IsBMBOnGround() then return false end
    if self:IsBMBOnPropSupport() then
        self.BMBStrandedCell = nil
        return false
    end

    local standable, cell = self:IsBMBCurrentPositionStandable()
    if standable then
        self.BMBStrandedCell = nil
        return false
    end

    self.BMBStrandedCell = cell
    return true
end

function ENT:IsBMBStrandedEscapeDirectionBlocked(directionKey)
    if not directionKey or not self.BMBStrandedBlockedDirections then return false end

    local blockedUntil = self.BMBStrandedBlockedDirections[directionKey]
    if not blockedUntil then return false end

    if CurTime() < blockedUntil then return true end

    self.BMBStrandedBlockedDirections[directionKey] = nil
    return false
end

function ENT:RecordBMBStrandedEscapeFailure(directionKey)
    if not directionKey then return end

    self.BMBStrandedBlockedDirections = self.BMBStrandedBlockedDirections or {}
    self.BMBStrandedBlockedDirections[directionKey] = CurTime() + (self.StrandedRecoveryBlockedDirectionCooldown or 1.2)
    self.BMBStrandedEscapeCursor = directionKey % #strandedEscapeDirections + 1
end

function ENT:HasBMBPhysicalGroundAt(pos)
    local probeHalf = math.max(2, self:GetBMBBlockSize() * 0.08)
    local startHeight = math.max(6, (self.GroundProbeHeight or 32) * 0.25)
    local probeDepth = math.max(12, self:GetBMBBlockSize() * 0.75)

    local trace = util.TraceHull({
        start = Vector(pos.x, pos.y, pos.z + startHeight),
        endpos = Vector(pos.x, pos.y, pos.z - probeDepth),
        mins = Vector(-probeHalf, -probeHalf, 0),
        maxs = Vector(probeHalf, probeHalf, probeHalf),
        filter = self,
        mask = MASK_SOLID
    })

    return trace.Hit and not trace.StartSolid, trace
end

function ENT:FindBMBStrandedEscapePoint()
    local current = self:GetPos()
    local step = self:GetBMBScaledDistance(self.StrandedRecoveryLocalStep, self.StrandedRecoveryLocalStepScale, 0.75)
    local fallPoint
    local fallKey
    local standableOptions = { mob = self }
    local count = #strandedEscapeDirections
    local startIndex = ((self.BMBStrandedEscapeCursor or 1) - 1) % count + 1

    for offset = 0, count - 1 do
        local directionKey = ((startIndex + offset - 2) % count) + 1
        if self:IsBMBStrandedEscapeDirectionBlocked(directionKey) then continue end

        local direction = strandedEscapeDirections[directionKey]
        local normal = Vector(direction.x, direction.y, 0)
        normal:Normalize()

        local candidate = Vector(current.x + normal.x * step, current.y + normal.y * step, current.z)
        if self:IsBMBHullClearAtPosition(candidate) then
            local standable = false
            if BMB and BMB.Pathfinder and BMB.Pathfinder.IsStandablePosition then
                standable = BMB.Pathfinder.IsStandablePosition(candidate, standableOptions)
            end

            if standable then
                self.BMBStrandedEscapeCursor = directionKey % count + 1
                return candidate, "standable", directionKey
            end

            local hasGround = self:HasBMBPhysicalGroundAt(candidate)
            if not hasGround and not fallPoint then
                fallPoint = candidate
                fallKey = directionKey
            end
        end
    end

    if fallPoint then
        self.BMBStrandedEscapeCursor = fallKey % count + 1
        return fallPoint, "fall", fallKey
    end

    return nil
end

function ENT:MoveBMBStrandedBailOut(destination, speed, options)
    options = options or {}

    local desiredSpeed = speed or self.WalkSpeed
    local moveIntentSpeed = options.moveIntentSpeed or desiredSpeed
    local bailUntil = CurTime() + (options.duration or self.StrandedRecoveryBailDuration or 0.55)
    local fallUntil = bailUntil + (self.StrandedRecoveryFallTimeout or 2.0)
    local escapeKey = options.escapeKey
    self.BMBStrandedEscapeKey = escapeKey

    self:ClearBMBMovementInterrupt()
    self:MaintainBMBMoveSpeed(desiredSpeed, moveIntentSpeed)
    self:UpdateMoveActivity(desiredSpeed, moveIntentSpeed)
    self:SetBMBMoveMode("stranded_bail")

    local progressWatch = self:StartBMBMoveProgressWatch()

    while CurTime() < fallUntil do
        if self.BMBMoveInterrupt then return false end

        if self:IsBMBOnGround() and (self:IsBMBCurrentPositionStandable() or self:IsBMBOnPropSupport()) then
            self.BMBStrandedCell = nil
            self:SetBMBMoveMode("idle")
            self:UpdateBMBApproachDebug(nil, 0)
            return true
        end

        if not self:IsBMBOnGround() then
            self:SetBMBMoveMode("stranded_fall")
            if progressWatch then
                progressWatch.deadline = CurTime() + (self.MoveNoProgressGrace or 0.35)
            end
        elseif CurTime() < bailUntil then
            local target = Vector(destination.x, destination.y, self:GetPos().z)

            self:SetBMBMoveMode("stranded_bail")
            self:MaintainBMBMoveSpeed(desiredSpeed)
            self:UpdateBMBApproachDebug(target, 0)
            self:SteerTowards(target, progressWatch)
            self:BodyMoveXY()
            self:MaybePlayStep()

            if not self:CheckBMBMoveProgress(progressWatch) then
                self:RecordBMBStrandedEscapeFailure(escapeKey)
                self:SetBMBMoveMode("stranded_bail_retry")
                self:StartBMBIdleActivity()
                self:UpdateBMBApproachDebug(nil, 0)
                return false
            end

            if self.loco:IsStuck() then
                self:HandleStuck()
                self:RecordBMBStrandedEscapeFailure(escapeKey)
                self:SetBMBMoveMode("stranded_bail_retry")
                self:StartBMBIdleActivity()
                self:UpdateBMBApproachDebug(nil, 0)
                return false
            end
        else
            return false
        end

        coroutine.yield()
    end

    return self:IsBMBOnGround() and (self:IsBMBCurrentPositionStandable() or self:IsBMBOnPropSupport())
end

function ENT:RunBMBStrandedRecovery()
    if not self:ShouldRunBMBStrandedRecovery() then return false end

    self:SetBMBState("stranded")
    self:SetBMBMoveMode("stranded_recovery")

    local now = CurTime()
    if now < (self.BMBNextStrandedRecoveryAt or 0) then
        coroutine.wait(math.min(0.1, (self.BMBNextStrandedRecoveryAt or now) - now))
        return true
    end

    self.BMBNextStrandedRecoveryAt = now + (self.StrandedRecoveryRetryDelay or 0.35)

    local target, _, escapeKey = self:FindBMBStrandedEscapePoint()
    if not target then
        self:FailBMBMove("stranded_no_escape")
        coroutine.wait(self.StrandedRecoveryRetryDelay or 0.35)
        return true
    end

    self:MoveBMBStrandedBailOut(target, self.WalkSpeed, {
        duration = self.StrandedRecoveryBailDuration or 0.55,
        escapeKey = escapeKey
    })

    return true
end

function ENT:RunBMBDebugMove()
    if not self:HasBMBDebugMove() then return false end

    local desiredSpeed = self.BMBDebugMoveSpeed or self.RunSpeed

    if self.BMBDebugMoveTarget and self.BMBDebugMoveUsePath then
        self:SetBMBState("debug_move")
        self:SetBMBMoveMode("debug_path")
        self:MaintainBMBMoveSpeed(desiredSpeed)
        self:UpdateMoveActivity(desiredSpeed)

        local debugLastProgressAt = CurTime()
        local debugProgressTarget = self.BMBDebugMoveTarget
        local debugLastProgressDistance = debugProgressTarget and flatDistance(self:GetPos(), debugProgressTarget) or math.huge

        while self:HasBMBDebugMove() do
            local target = self.BMBDebugMoveTarget
            if not target then break end

            if target ~= debugProgressTarget then
                debugProgressTarget = target
                debugLastProgressAt = CurTime()
                debugLastProgressDistance = flatDistance(self:GetPos(), target)
            end

            local goalTolerance = self.BMBDebugMoveTolerance or BMB.Config.DefaultGoalTolerance
            if flatDistance(self:GetPos(), target) <= goalTolerance then
                self:ClearBMBDebugMove()
                self:SetBMBMoveMode("idle")
                self:UpdateBMBApproachDebug(nil, 0)
                return true
            end

            local remaining = math.max(0.1, (self.BMBDebugMoveUntil or CurTime()) - CurTime())
            local minTimeout = math.min(self.DebugPathSegmentMinTimeout or 3.0, remaining)
            local distanceBefore = flatDistance(self:GetPos(), target)
            local advanceBefore = self.BMBPathAdvanceCount or 0
            local moved = self:MoveToWorldPosition(target, desiredSpeed, {
                skipSourcePath = true,
                allowStrandedStart = true,
                allowPartial = true,
                acceptPartial = true,
                minTimeout = minTimeout,
                timeoutScale = self.DebugPathTimeoutScale or 3.0,
                timeoutBase = self.DebugPathTimeoutBase or 4.0,
                timeoutMax = self.DebugPathTimeoutMax or 90,
                goalTolerance = goalTolerance
            })

            if flatDistance(self:GetPos(), target) <= goalTolerance then
                self:ClearBMBDebugMove()
                self:SetBMBMoveMode("idle")
                self:UpdateBMBApproachDebug(nil, 0)
                return true
            end

            local distanceAfter = flatDistance(self:GetPos(), target)
            local advanceAfter = self.BMBPathAdvanceCount or 0
            local madeProgress = advanceAfter > advanceBefore
                or distanceAfter < distanceBefore - goalTolerance * 0.25
                or distanceAfter < debugLastProgressDistance - goalTolerance * 0.25

            if madeProgress then
                debugLastProgressAt = CurTime()
                debugLastProgressDistance = math.min(debugLastProgressDistance, distanceAfter)
                self.BMBDebugMoveUntil = math.max(
                    self.BMBDebugMoveUntil or 0,
                    CurTime() + (self.DebugPathProgressGrace or 8.0)
                )
            elseif CurTime() - debugLastProgressAt >= (self.DebugPathNoProgressTimeout or 3.5) then
                self:FailBMBMove("debug_no_progress")
                self:ClearBMBDebugMove()
                return true
            end

            if not self:HasBMBDebugMove() then return true end

            if not moved then
                self:SetBMBMoveMode("debug_repath")
                self:StartBMBIdleActivity()
                self:UpdateBMBApproachDebug(target, 0)
            end

            coroutine.wait(math.min(self.DebugPathRepathDelay or 0.25, remaining))
        end

        self:ClearBMBDebugMove()
        self:SetBMBMoveMode("idle")
        self:UpdateBMBApproachDebug(nil, 0)
        return true
    end

    self:SetBMBState("debug_move")
    self:SetBMBMoveMode("debug_direct")
    self:ClearBMBMovementInterrupt()
    self:MaintainBMBMoveSpeed(desiredSpeed)
    self:UpdateMoveActivity(desiredSpeed)

    local progressWatch = self:StartBMBMoveProgressWatch()

    while self:HasBMBDebugMove() do
        local target

        if self.BMBDebugMoveTarget then
            local delta = self.BMBDebugMoveTarget - self:GetPos()
            delta.z = 0

            if delta:Length2D() <= (self.BMBDebugMoveTolerance or 24) then
                self:ClearBMBDebugMove()
                self:SetBMBMoveMode("idle")
                self:UpdateBMBApproachDebug(nil, 0)
                return true
            end

            delta:Normalize()

            local lookAhead = math.min(math.max(self:GetPos():Distance(self.BMBDebugMoveTarget), 96), self.BMBDebugMoveLookAhead or 220)
            target = self:GetPos() + delta * lookAhead
        else
            local direction = self.BMBDebugMoveDirection
            if not direction then
                self:ClearBMBDebugMove()
                self:SetBMBMoveMode("idle")
                self:UpdateBMBApproachDebug(nil, 0)
                return true
            end

            target = self:GetPos() + direction * (self.BMBDebugMoveLookAhead or 180)
        end

        target.z = self:GetPos().z

        if not self.BMBDebugMoveIgnoreSafety and not self:IsMovementTargetSafe(target) then
            self:ClearBMBDebugMove()
            self:SetBMBMoveMode("idle")
            self:UpdateBMBApproachDebug(nil, 0)
            return true
        end

        self:MaintainBMBMoveSpeed(desiredSpeed)
        self:UpdateBMBApproachDebug(target, 0)
        self:SteerTowards(target, progressWatch)
        self:BodyMoveXY()
        self:MaybePlayStep()

        if not self:CheckBMBMoveProgress(progressWatch) then
            self:ClearBMBDebugMove()
            self:FailBMBMove("debug_blocked")
            return true
        end

        if self.loco:IsStuck() then
            self:HandleStuck()
            self:ClearBMBDebugMove()
            self:FailBMBMove("debug_stuck")
            return true
        end

        coroutine.yield()
    end

    self:SetBMBMoveMode("idle")
    self:UpdateBMBApproachDebug(nil, 0)
    return true
end

function ENT:MoveToWorldPosition(destination, speed, options)
    options = options or {}

    -- 物理枪持握中不接新移动（held 与 hop/path 状态握手：当前 move 协程已被
    -- InterruptBMBMovement 掐掉、hop 重跳计数随局部变量一起销毁，这里再挡新请求）
    if self.BMBHeld then return false end
    if self:IsBMBKnockbackActive() then return false end

    local desiredSpeed = speed or self.WalkSpeed
    self.loco:SetDesiredSpeed(desiredSpeed)
    self:UpdateMoveActivity(desiredSpeed)

    if not options.keepInterrupt then
        self:ClearBMBMovementInterrupt()
    end

    local propSupportFallback = options.allowPropSupportFallback

    local function shouldUsePropSupportFallback()
        if propSupportFallback ~= nil then return propSupportFallback end
        return self:IsBMBOnPropSupport()
    end

    local function runDirectFallback()
        if options.allowDirectFallback then
            return self:MoveDirectFallback(destination, speed, options)
        end

        if not shouldUsePropSupportFallback() then return false end

        local directOptions = {}
        for key, value in pairs(options) do
            directOptions[key] = value
        end

        local distance = flatDistance(self:GetPos(), destination)
        directOptions.moveMode = directOptions.moveMode or "prop_direct"
        directOptions.acceptPartial = true
        directOptions.duration = directOptions.duration or self:GetBMBMoveTimeoutForDistance(distance, desiredSpeed, {
            timeoutScale = self.PropSupportDirectTimeoutScale or 1.25,
            timeoutBase = self.PropSupportDirectTimeoutBase or 0.15,
            timeoutMax = self.PropSupportDirectTimeoutMax or 1.5
        })

        return self:MoveDirectFallback(destination, speed, directOptions)
    end

    if self:ShouldUseSourcePath() and not options.skipSourcePath then
        if self:MoveWithSourcePath(destination, desiredSpeed, options) then return true end
        if self.BMBMoveInterrupt then return false end
    end

    local waypoints = BMB.Pathfinder.FindPath(self:GetPos(), destination, {
        mob = self,
        allowPartial = options.allowPartial,
        allowUnsupportedWalk = options.allowUnsupportedWalk or options.allowStrandedStart
    })
    if not waypoints or #waypoints == 0 then
        return runDirectFallback()
    end

    if self:MoveAlongPath(waypoints, desiredSpeed, options) then return true end
    if self.BMBMoveInterrupt then return false end

    return runDirectFallback()
end

function ENT:MoveWithSourcePath(destination, speed, options)
    options = options or {}

    if self:IsBMBKnockbackActive() then return false end
    if not Path then return false end

    local path = Path("Follow")
    local goalTolerance = options.goalTolerance or self:GetBMBSourcePathGoalTolerance()

    path:SetMinLookAheadDistance(options.lookAhead or self.SourcePathLookAhead)
    path:SetGoalTolerance(goalTolerance)
    path:Compute(self, destination)

    if not path:IsValid() then return false end

    local distance = flatDistance(self:GetPos(), destination)
    local timeout = CurTime() + (options.duration or self:GetBMBMoveTimeoutForDistance(distance, speed or self.WalkSpeed, options))

    self:ClearBMBMovementInterrupt()
    self.loco:SetDesiredSpeed(speed or self.WalkSpeed)
    self:UpdateMoveActivity(speed or self.WalkSpeed)

    local progressWatch = self:StartBMBMoveProgressWatch()

    while path:IsValid() and CurTime() < timeout do
        if self.BMBMoveInterrupt then return false end
        if self:GetPos():DistToSqr(destination) <= goalTolerance * goalTolerance then return true end

        self:SetBMBMoveMode("source_path")
        self:MaintainBMBMoveSpeed(speed or self.WalkSpeed)
        self:UpdateBMBApproachDebug(destination, 0)
        path:Update(self)
        self:BodyMoveXY()
        self:MaybePlayStep()

        if not self:CheckBMBMoveProgress(progressWatch) then
            self:FailBMBMove("source_blocked")
            return false
        end

        if self.loco:IsStuck() then
            self:HandleStuck()
            self:FailBMBMove("source_stuck")
            return false
        end

        coroutine.yield()
    end

    if options.acceptPartial then return true end

    return self:GetPos():DistToSqr(destination) <= goalTolerance * goalTolerance
end

function ENT:GetClosestPathCursor(waypoints, startIndex)
    local current = self:GetPos()
    local segmentStart = math.max(1, (startIndex or 1) - 1)
    local segmentEnd = math.min(#waypoints - 1, segmentStart + 6)

    if #waypoints == 1 then
        return Vector(waypoints[1].x, waypoints[1].y, current.z), 1
    end

    if segmentStart > segmentEnd then
        segmentStart = segmentEnd
    end

    local bestPoint
    local bestIndex = segmentStart
    local bestDistance = math.huge

    for i = segmentStart, segmentEnd do
        local a = waypoints[i]
        local b = waypoints[i + 1]
        local dx = b.x - a.x
        local dy = b.y - a.y
        local lengthSqr = dx * dx + dy * dy

        if lengthSqr > 0.01 then
            local t = math.Clamp(((current.x - a.x) * dx + (current.y - a.y) * dy) / lengthSqr, 0, 1)
            local point = Vector(a.x + dx * t, a.y + dy * t, current.z)
            local distance = flatDistanceSqr(current, point)

            if distance < bestDistance then
                bestDistance = distance
                bestPoint = point
                bestIndex = i
            end
        end
    end

    if bestPoint then return bestPoint, bestIndex end

    local fallback = waypoints[math.min(startIndex or 1, #waypoints)]
    if not fallback then return nil end

    return Vector(fallback.x, fallback.y, current.z), math.min(startIndex or 1, #waypoints)
end

function ENT:GetPathPointAhead(waypoints, cursor, segmentIndex, distance)
    if not cursor or not segmentIndex then return nil end

    local current = self:GetPos()
    local remaining = math.max(distance or 0, 0)
    local point = Vector(cursor.x, cursor.y, current.z)

    for i = segmentIndex, #waypoints - 1 do
        local nextNode = waypoints[i + 1]
        local segment = Vector(nextNode.x - point.x, nextNode.y - point.y, 0)
        local length = segment:Length()

        if length > 0.1 then
            if length >= remaining then
                segment:Normalize()

                point = point + segment * remaining
                point.z = current.z
                return point
            end

            remaining = remaining - length
            point = Vector(nextNode.x, nextNode.y, current.z)
        end
    end

    local final = waypoints[#waypoints]
    if not final then return nil end

    point = Vector(final.x, final.y, current.z)

    if remaining > 0 then
        local previous = waypoints[#waypoints - 1]

        if previous then
            local overshoot = Vector(final.x - previous.x, final.y - previous.y, 0)

            if overshoot:LengthSqr() > 1 then
                overshoot:Normalize()
                point = point + overshoot * math.min(remaining, self:GetBMBDefaultGoalTolerance())
                point.z = current.z
                return point
            end
        end
    end

    return point
end

function ENT:GetBMBPathHullRadius()
    return math.max(
        math.abs(self.CollisionMins.x),
        math.abs(self.CollisionMaxs.x),
        math.abs(self.CollisionMins.y),
        math.abs(self.CollisionMaxs.y)
    )
end

function ENT:GetBMBPathHeightCells()
    local blockSize = self:GetBMBBlockSize()
    local height = math.max(1, self.CollisionMaxs.z - self.CollisionMins.z)

    return math.max(0, math.floor((height - 1) / blockSize))
end

function ENT:DoesBMBHullOverlapBlock(pos, blockCoord, radius)
    local blockCenter = BMB.BlockWorld.BlockToWorld(blockCoord)
    local half = self:GetBMBBlockSize() * 0.5
    local closestX = math.Clamp(pos.x, blockCenter.x - half, blockCenter.x + half)
    local closestY = math.Clamp(pos.y, blockCenter.y - half, blockCenter.y + half)
    local dx = pos.x - closestX
    local dy = pos.y - closestY

    return dx * dx + dy * dy < radius * radius
end

function ENT:IsBMBHullClearAtPosition(pos)
    if not BMB or not BMB.BlockWorld or not BMB.BlockWorld.IsSolid then return true end
    if not BMB.BlockWorld.WorldToBlock or not BMB.BlockWorld.BlockToWorld then return true end

    local centerCell = BMB.BlockWorld.WorldToBlock(pos)
    local radius = self:GetBMBPathHullRadius()
    local blockSize = self:GetBMBBlockSize()
    local range = math.ceil((radius + blockSize * 0.5) / blockSize)
    local maxZOffset = self:GetBMBPathHeightCells()

    for dz = 0, maxZOffset do
        for dx = -range, range do
            for dy = -range, range do
                local blockCoord = {
                    x = centerCell.x + dx,
                    y = centerCell.y + dy,
                    z = (centerCell.z or 0) + dz
                }

                if BMB.BlockWorld.IsSolid(blockCoord) and self:DoesBMBHullOverlapBlock(pos, blockCoord, radius) then
                    return false
                end
            end
        end
    end

    return true
end

function ENT:GetBMBGridSafetyFootLift()
    return math.max(
        self.GridSafetyMinFootLift or 4,
        self:GetBMBBlockSize() * (self.GridSafetyFootLiftScale or 0.12)
    )
end

function ENT:GetBMBGridFootSample(pos)
    return pos + Vector(0, 0, self:GetBMBGridSafetyFootLift())
end

function ENT:IsBMBGridFootHullClear(pos)
    return self:IsBMBHullClearAtPosition(self:GetBMBGridFootSample(pos))
end

function ENT:IsBMBGridFootStandable(pos, options)
    if not BMB or not BMB.Pathfinder or not BMB.Pathfinder.IsStandablePosition then return true end

    local standable = BMB.Pathfinder.IsStandablePosition(self:GetBMBGridFootSample(pos), options or { mob = self })
    return standable == true
end

function ENT:IsBMBPathCellPassable(blockCoord)
    if not BMB or not BMB.BlockWorld or not BMB.BlockWorld.BlockToWorld then return true end

    return self:IsBMBHullClearAtPosition(BMB.BlockWorld.BlockToWorld(blockCoord))
end

function ENT:IsBMBPathLineStandable(pos, options)
    return self:IsBMBGridFootStandable(pos, options)
end

function ENT:IsPathGridVisible(target, requireStandable)
    if not BMB or not BMB.BlockWorld or not BMB.BlockWorld.WorldToBlock then return true end
    if not BMB.BlockWorld.IsSolid then return true end

    local current = self:GetPos()
    local delta = target - current
    delta.z = 0

    local distance = delta:Length2D()
    if distance <= 1 then return true end
    if not self:IsBMBGridFootHullClear(current) then return false end

    delta:Normalize()

    local step = math.max(self:GetBMBBlockSize() * 0.25, 6)
    local samples = math.max(1, math.ceil(distance / step))
    local standableOptions = requireStandable ~= false and { mob = self } or nil
    for i = 1, samples do
        local sampleDistance = math.min(distance, i * step)
        local sample = current + delta * sampleDistance
        if not self:IsBMBGridFootHullClear(sample) then return false end
        if standableOptions and not self:IsBMBPathLineStandable(sample, standableOptions) then return false end
    end

    return true
end

function ENT:HasBMBGridBlockSupportAt(pos)
    if not BMB or not BMB.BlockWorld then return false end

    local blockWorld = BMB.BlockWorld
    if blockWorld.SupportsVerticalPath == false then return false end
    if not blockWorld.WorldToBlock or not blockWorld.IsSolid then return false end

    local radius = math.min(self:GetBMBPathHullRadius() * 0.55, self:GetBMBBlockSize() * 0.35)
    local samples = {
        Vector(0, 0, 0),
        Vector(radius, 0, 0),
        Vector(-radius, 0, 0),
        Vector(0, radius, 0),
        Vector(0, -radius, 0)
    }

    for _, offset in ipairs(samples) do
        local cell = blockWorld.WorldToBlock(pos + offset)
        local below = {
            x = cell.x,
            y = cell.y,
            z = (cell.z or 0) - 1
        }

        if blockWorld.IsSolid(cell) then return true end
        if blockWorld.IsSolid(below) then return true end
    end

    return false
end

function ENT:IsBMBGridMovementTargetSafe(target, probeDistance)
    if self:IsBMBOnPropSupport() then return true end
    if not BMB or not BMB.BlockWorld or not BMB.Pathfinder then return true end
    if BMB.BlockWorld.SupportsVerticalPath == false then return true end
    if not BMB.Pathfinder.IsStandablePosition then return true end

    local current = self:GetPos()
    local delta = target - current
    delta.z = 0

    local distance = delta:Length2D()
    if distance <= 1 then return true end

    delta:Normalize()

    local probe = math.min(distance, probeDistance or distance)
    local forwardTarget = current + delta * probe

    -- Only enable the grid layer when this movement is actually on/near MC blocks.
    -- Pure Source ground and prop support keep using the trace-based safety above.
    if not self:HasBMBGridBlockSupportAt(current) and not self:HasBMBGridBlockSupportAt(forwardTarget) then
        return true
    end

    local step = math.max(
        self:GetBMBBlockSize() * (self.GridSafetyStepScale or 0.5),
        self.GridSafetyMinStep or 8
    )
    local samples = math.max(1, math.ceil(probe / step))
    local standableOptions = { mob = self }

    for i = 1, samples do
        local sampleDistance = math.min(probe, i * step)
        local sample = current + delta * sampleDistance

        if not self:IsBMBGridFootHullClear(sample) then
            return false, "wall"
        end

        if not self:IsBMBGridFootStandable(sample, standableOptions) then
            return false, "cliff"
        end
    end

    return true
end

function ENT:GetPathCarrot(waypoints, startIndex, carrotDistance)
    local cursor, segmentIndex = self:GetClosestPathCursor(waypoints, startIndex)
    if not cursor then return nil end

    local rawCarrot = self:GetPathPointAhead(waypoints, cursor, segmentIndex, carrotDistance)
    if not rawCarrot then return nil end

    if self:IsPathGridVisible(rawCarrot) then return rawCarrot end

    -- carrot 必须落在路径折线上，但 loco 仍会直线追 carrot；直角走廊里若直线视线被方块挡住，
    -- 二分缩短前瞻距离，取当前能直视到的最远折线点，避免抄近路撞入口外壁
    local low = 0
    local high = carrotDistance
    local best = cursor

    for _ = 1, 7 do
        local mid = (low + high) * 0.5
        local candidate = self:GetPathPointAhead(waypoints, cursor, segmentIndex, mid)

        if candidate and self:IsPathGridVisible(candidate) then
            best = candidate
            low = mid
        else
            high = mid
        end
    end

    return best
end

function ENT:GetBMBPathCornerAngle(waypoints, cornerIndex)
    local previousNode = waypoints[cornerIndex - 1]
    local cornerNode = waypoints[cornerIndex]
    local nextNode = waypoints[cornerIndex + 1]

    if not previousNode or not cornerNode or not nextNode then return 0 end

    local incoming = Vector(cornerNode.x - previousNode.x, cornerNode.y - previousNode.y, 0)
    local outgoing = Vector(nextNode.x - cornerNode.x, nextNode.y - cornerNode.y, 0)

    if incoming:LengthSqr() <= 1 or outgoing:LengthSqr() <= 1 then return 0 end

    return math.abs(math.AngleDifference(incoming:Angle().y, outgoing:Angle().y))
end

function ENT:GetBMBPathDistanceToNode(waypoints, nodeIndex, cornerIndex, current)
    if cornerIndex < nodeIndex then
        return flatDistance(current, waypoints[cornerIndex])
    end

    local distance = flatDistance(current, waypoints[nodeIndex])

    for i = nodeIndex, cornerIndex - 1 do
        distance = distance + flatDistance(waypoints[i], waypoints[i + 1])
    end

    return distance
end

function ENT:GetBMBPathCornerControl(waypoints, nodeIndex, current, desiredSpeed, defaultCarrotDistance)
    local minAngle = self.PathCornerMinAngle or 35
    local startCorner = math.max(2, nodeIndex - 1)
    local endCorner = math.min(#waypoints - 1, nodeIndex + 4)
    local bestDistance
    local bestAngle = 0

    for cornerIndex = startCorner, endCorner do
        local angle = self:GetBMBPathCornerAngle(waypoints, cornerIndex)

        if angle >= minAngle then
            local distance = self:GetBMBPathDistanceToNode(waypoints, nodeIndex, cornerIndex, current)

            if not bestDistance or distance < bestDistance then
                bestDistance = distance
                bestAngle = angle
            end
        end
    end

    if not bestDistance then return desiredSpeed, defaultCarrotDistance, false end

    local slowDistance = self:GetBMBPathCornerSlowDistance()
    local proximity = 1 - math.Clamp(bestDistance / slowDistance, 0, 1)
    local angleFactor = math.Clamp((bestAngle - minAngle) / math.max(1, 90 - minAngle), 0, 1)
    local slowAmount = proximity * angleFactor

    if slowAmount <= 0 then return desiredSpeed, defaultCarrotDistance, false end

    local cornerSpeed = math.max(self.PathCornerMinSpeed or 32, desiredSpeed * (self.PathCornerSpeedScale or 0.55))
    local cornerCarrot = self:GetBMBPathCornerCarrotDistance()
    local speed = desiredSpeed - (desiredSpeed - cornerSpeed) * slowAmount
    local carrotDistance = defaultCarrotDistance - (defaultCarrotDistance - cornerCarrot) * slowAmount

    return speed, carrotDistance, true
end

function ENT:IsSourceHitBMBBlock(hitPos, hitNormal)
    if not hitPos then return false end
    if not BMB or not BMB.BlockWorld or not BMB.BlockWorld.WorldToBlock then return false end
    if not BMB.BlockWorld.IsSolid then return false end

    local samples = { hitPos }
    if hitNormal then
        samples[#samples + 1] = hitPos - hitNormal * 4
        samples[#samples + 1] = hitPos + hitNormal * 4
        samples[#samples + 1] = hitPos - hitNormal * (self:GetBMBBlockSize() * 0.5)
    end

    for _, sample in ipairs(samples) do
        local cell = BMB.BlockWorld.WorldToBlock(sample)

        for dz = 0, self:GetBMBPathHeightCells() do
            if BMB.BlockWorld.IsSolid({
                x = cell.x,
                y = cell.y,
                z = (cell.z or 0) + dz
            }) then
                return true
            end
        end
    end

    return false
end

function ENT:IsPathSourceTargetSafe(target, probeDistance)
    local current = self:GetPos()
    local delta = target - current
    delta.z = 0

    local distance = delta:Length2D()
    if distance <= 1 then return true end

    delta:Normalize()

    local probe = math.min(distance, probeDistance or self:GetBMBTickSafetyProbe())
    local forwardTarget = current + delta * probe
    local traceFilter = function(ent)
        return self:ShouldSafetyTraceHit(ent)
    end
    local hullScale = self.SafetyHullScale

    local wallTrace = util.TraceHull({
        start = current + Vector(0, 0, self.GroundProbeHeight),
        endpos = forwardTarget + Vector(0, 0, self.GroundProbeHeight),
        mins = Vector(self.CollisionMins.x * hullScale, self.CollisionMins.y * hullScale, -self.GroundProbeHeight * 0.35),
        maxs = Vector(self.CollisionMaxs.x * hullScale, self.CollisionMaxs.y * hullScale, self.GroundProbeHeight * 0.45),
        filter = traceFilter,
        mask = MASK_SOLID
    })

    if wallTrace.Hit and not wallTrace.StartSolid and not self:CanStepPastTrace(wallTrace, forwardTarget, traceFilter) then
        if not self:IsSourceHitBMBBlock(wallTrace.HitPos, wallTrace.HitNormal) then
            return false, "wall"
        end

        local hitDistance = wallTrace.Fraction * probe
        probe = math.max(4, hitDistance - 4)
        forwardTarget = current + delta * probe
    end

    local groundTrace = util.TraceHull({
        start = forwardTarget + Vector(0, 0, self.GroundProbeHeight),
        endpos = forwardTarget - Vector(0, 0, self.GroundProbeDepth),
        mins = Vector(self.CollisionMins.x * 0.75, self.CollisionMins.y * 0.75, 0),
        maxs = Vector(self.CollisionMaxs.x * 0.75, self.CollisionMaxs.y * 0.75, 4),
        filter = traceFilter,
        mask = MASK_SOLID
    })

    if not groundTrace.Hit then return false, "cliff" end
    if groundTrace.HitNormal.z < 0.65 then return false, "cliff" end
    if current.z - groundTrace.HitPos.z > self:GetBMBMaxStepDown() then return false, "cliff" end

    local gridSafe, gridReason = self:IsBMBGridMovementTargetSafe(forwardTarget, probe)
    if not gridSafe then return false, gridReason or "cliff" end

    return true
end

function ENT:GetBMBWaypointAction(waypoints, nodeIndex)
    local node = waypoints and waypoints[nodeIndex]
    if not node then return "walk" end
    if node.action then return node.action end

    local previous = waypoints[nodeIndex - 1]
    if node.coord and previous and previous.coord then
        local dz = (node.coord.z or 0) - (previous.coord.z or 0)
        if dz == 1 then return "hop" end
        if dz < 0 then return "drop" end
    end

    return "walk"
end

function ENT:IsBMBPathVerticalAction(action)
    return action == "hop" or action == "drop"
end

function ENT:IsBMBOnGround()
    if self.loco and self.loco.IsOnGround then
        return self.loco:IsOnGround()
    end

    local traceFilter = function(ent)
        return self:ShouldSafetyTraceHit(ent)
    end

    local groundTrace = util.TraceHull({
        start = self:GetPos() + Vector(0, 0, 4),
        endpos = self:GetPos() - Vector(0, 0, 8),
        mins = Vector(self.CollisionMins.x * 0.75, self.CollisionMins.y * 0.75, 0),
        maxs = Vector(self.CollisionMaxs.x * 0.75, self.CollisionMaxs.y * 0.75, 4),
        filter = traceFilter,
        mask = MASK_SOLID
    })

    return groundTrace.Hit
end

function ENT:IsBMBPathActionAtTargetLevel(node)
    if not node or not node.coord then return true end
    if not BMB or not BMB.BlockWorld or not BMB.BlockWorld.WorldToBlock then return true end

    local currentCell = BMB.BlockWorld.WorldToBlock(self:GetPos())
    return (currentCell.z or 0) == (node.coord.z or 0)
end

function ENT:IsBMBVerticalPathNodeReached(node)
    if not node then return false end
    if not self:IsBMBOnGround() then return false end
    if not node.z then return true end

    local targetFootZ = node.z - self:GetBMBBlockSize() * 0.5 + (self.BlockHopLandingLift or 2)
    local downTolerance = self.VerticalPathReachZTolerance or 8
    local upTolerance = downTolerance
    if node.action == "drop" then
        upTolerance = self.DropVerticalReachUpTolerance
            or self:GetBMBBlockSize() * (self.DropVerticalReachUpToleranceScale or 0.35)
    elseif node.action == "hop" then
        upTolerance = math.max(
            upTolerance,
            self.BlockHopVerticalOvershootTolerance
                or self:GetBMBBlockSize() * (self.BlockHopVerticalOvershootToleranceScale or 1.25)
        )
    end

    local deltaZ = self:GetPos().z - targetFootZ
    local reached = deltaZ >= -downTolerance and deltaZ <= upTolerance

    -- MC cell conversion floors at block boundaries; a bot standing exactly on a top face can
    -- quantize to the lower cell for a tick. Trust the actual settled foot height instead.
    self:LogBMBVerticalReach(node, targetFootZ, deltaZ, reached, downTolerance, upTolerance)

    return reached
end

function ENT:ShouldAdvanceBMBPathNode(node, action, nodeDistance, nodeTolerance)
    if nodeDistance > nodeTolerance then return false end
    if not self:IsBMBPathVerticalAction(action) then return true end

    return self:IsBMBVerticalPathNodeReached(node)
end

function ENT:IsBMBPathFinalReached(final, tolerance)
    if not final then return false end
    if flatDistance(self:GetPos(), final) > tolerance then return false end
    if not final.coord then return true end

    if self:IsBMBPathVerticalAction(final.action) then
        return self:IsBMBVerticalPathNodeReached(final)
    end

    return self:IsBMBPathActionAtTargetLevel(final)
end

function ENT:GetBMBBlockHopJumpHeight(blockSize, apex)
    local configured = self.BlockHopJumpHeight
    if configured then
        return math.max(apex or 0, configured)
    end

    return math.max(apex or 0, (blockSize or self:GetBMBBlockSize()) * (self.BlockHopJumpHeightScale or 1.5))
end

function ENT:GetBMBHopForward(current, target, previousNode)
    local forward

    if previousNode then
        forward = Vector(target.x - previousNode.x, target.y - previousNode.y, 0)
    else
        forward = Vector(target.x - current.x, target.y - current.y, 0)
    end

    if forward:LengthSqr() <= 1 then
        forward = Vector(target.x - current.x, target.y - current.y, 0)
    end

    if forward:LengthSqr() <= 1 then
        forward = self:GetForward()
        forward.z = 0
    end

    if forward:LengthSqr() <= 1 then
        forward = Vector(1, 0, 0)
    else
        forward:Normalize()
    end

    return forward
end

function ENT:GetBMBHopLaunchCeilingClearance()
    local blockSize = self:GetBMBBlockSize()
    local liftStart = blockSize * (self.BlockHopManualForwardStartHeightScale or 0.8)
    local configured = self.BlockHopLaunchCeilingClearance

    if configured then return configured end

    return math.max(liftStart + 6, blockSize * (self.BlockHopLaunchCeilingClearanceScale or 0.95))
end

function ENT:IsBMBHopLaunchCeilingClear(pos)
    if not pos then return true, "ok" end

    local clearance = self:GetBMBHopLaunchCeilingClearance()
    local traceFilter = function(ent)
        return self:ShouldSafetyTraceHit(ent)
    end

    local trace = util.TraceHull({
        start = pos + Vector(0, 0, 1),
        endpos = pos + Vector(0, 0, clearance),
        mins = self.CollisionMins,
        maxs = self.CollisionMaxs,
        filter = traceFilter,
        mask = MASK_SOLID
    })

    if trace.StartSolid then return false, "ceiling_startsolid" end
    if trace.Hit then return false, "ceiling_trace" end

    local step = math.max(self:GetBMBBlockSize() * 0.25, 6)
    local samples = math.max(1, math.ceil(clearance / step))
    for i = 0, samples do
        local sample = pos + Vector(0, 0, math.min(clearance, i * step))
        if not self:IsBMBHullClearAtPosition(sample) then
            return false, "ceiling_grid"
        end
    end

    return true, "ok"
end

function ENT:GetBMBHopLaunchControl(current, target, speed, previousNode)
    local blockSize = self:GetBMBBlockSize()
    local distance = flatDistance(current, target)
    local faceDistance = math.max(0, distance - blockSize * 0.5)
    local forward = self:GetBMBHopForward(current, target, previousNode)
    local velocity = self:GetVelocity()
    local horizontal = Vector(velocity.x, velocity.y, 0)
    local speed2D = horizontal:Length2D()
    local speedAlong = horizontal:Dot(forward)
    local minFaceDistance = self.BlockHopLaunchMinFaceDistance
        or blockSize * (self.BlockHopLaunchMinFaceDistanceScale or 0.75)
    local idealFaceDistance = self.BlockHopLaunchIdealFaceDistance
        or blockSize * (self.BlockHopLaunchIdealFaceDistanceScale or 0.85)
    local minDistance = math.max(
        self.BlockHopLaunchMinDistance or 0,
        blockSize * (self.BlockHopLaunchMinDistanceScale or 0.85),
        blockSize * 0.5 + minFaceDistance
    )
    local idealDistance = math.max(
        self.BlockHopLaunchIdealDistance or 0,
        blockSize * (self.BlockHopLaunchIdealDistanceScale or 1.15),
        blockSize * 0.5 + idealFaceDistance
    )
    local maxDistance = self.BlockHopLaunchMaxDistance or blockSize * (self.BlockHopLaunchMaxDistanceScale or 1.4)
    local lateralTolerance = self.BlockHopLaunchLateralTolerance or blockSize * (self.BlockHopLaunchLateralToleranceScale or 0.35)
    local right = Vector(-forward.y, forward.x, 0)
    local targetDelta = Vector(current.x - target.x, current.y - target.y, 0)
    local lateralOffset = math.abs(targetDelta:Dot(right))
    local minSpeed = (speed or self.WalkSpeed) * (self.BlockHopMinLaunchSpeedScale or 0.6)
    local backoff = Vector(target.x - forward.x * idealDistance, target.y - forward.y * idealDistance, current.z)
    local approach = Vector(target.x, target.y, current.z)
    local needsSpeed = self.BlockHopRequireLaunchSpeed == true
    local allowCloseLaunch = self.BlockHopAllowCloseLaunch == true
    local allowBlockedCloseLaunch = self.BlockHopAllowBlockedCloseLaunch ~= false
    local blockedCloseMinFaceDistance = self.BlockHopBlockedCloseMinFaceDistance
        or blockSize * (self.BlockHopBlockedCloseMinFaceDistanceScale or 0.52)
    local ceilingBlockedCloseMinFaceDistance = self.BlockHopCeilingBlockedCloseMinFaceDistance
        or blockSize * (self.BlockHopCeilingBlockedCloseMinFaceDistanceScale or 0.48)
    local blockedCloseDistance = blockSize * 0.5 + blockedCloseMinFaceDistance
    local blockedCloseBackoff = Vector(target.x - forward.x * blockedCloseDistance, target.y - forward.y * blockedCloseDistance, current.z)
    local backoffHullClear = true
    if self.IsBMBHullClearAtPosition then
        backoffHullClear = self:IsBMBHullClearAtPosition(backoff)
    end

    local currentLiftClear, currentLiftReason = self:IsBMBHopLaunchCeilingClear(current)
    local backoffLiftClear, backoffLiftReason = self:IsBMBHopLaunchCeilingClear(backoff)
    local blockedCloseBackoffLiftClear, blockedCloseBackoffLiftReason = self:IsBMBHopLaunchCeilingClear(blockedCloseBackoff)
    local backoffSafe, backoffSafeReason = true, "ok"
    if self.IsPathSourceTargetSafe then
        backoffSafe, backoffSafeReason = self:IsPathSourceTargetSafe(backoff)
    end

    local backoffBlocked = backoffHullClear ~= true or backoffSafe ~= true or backoffLiftClear ~= true
    local effectiveBlockedCloseMinFaceDistance = blockedCloseMinFaceDistance
    if backoffLiftClear ~= true then
        effectiveBlockedCloseMinFaceDistance = math.min(effectiveBlockedCloseMinFaceDistance, ceilingBlockedCloseMinFaceDistance)
    end

    local setupTarget = backoff
    if backoffLiftClear ~= true and blockedCloseBackoffLiftClear == true then
        setupTarget = blockedCloseBackoff
    end

    local canBlockedCloseLaunch = allowBlockedCloseLaunch
        and backoffBlocked
        and currentLiftClear == true
        and distance <= maxDistance
        and faceDistance >= effectiveBlockedCloseMinFaceDistance
        and faceDistance < minFaceDistance
        and lateralOffset <= lateralTolerance
        and (not needsSpeed or speedAlong >= minSpeed)
    local ready = distance >= minDistance and distance <= maxDistance
        and faceDistance >= minFaceDistance
        and lateralOffset <= lateralTolerance
        and currentLiftClear == true
        and (not needsSpeed or speedAlong >= minSpeed)
    local steerTarget = approach
    local reason = "approach"

    if allowCloseLaunch and distance <= maxDistance
        and faceDistance < minFaceDistance
        and lateralOffset <= lateralTolerance
        and currentLiftClear == true
        and (not needsSpeed or speedAlong >= minSpeed) then
        ready = true
        reason = "close_lift"
    elseif canBlockedCloseLaunch then
        ready = true
        reason = "blocked_close_lift"
    elseif currentLiftClear ~= true and distance <= maxDistance then
        steerTarget = setupTarget
        reason = "lift_blocked"
    elseif lateralOffset > lateralTolerance then
        steerTarget = setupTarget
        reason = "align"
    elseif faceDistance < minFaceDistance then
        steerTarget = setupTarget
        reason = "face_close"
    elseif distance < minDistance then
        steerTarget = setupTarget
        reason = "close"
    elseif needsSpeed and speedAlong < minSpeed then
        steerTarget = distance < idealDistance and setupTarget or approach
        reason = "slow"
    elseif distance > maxDistance then
        steerTarget = setupTarget
        reason = "far"
    else
        reason = "ready"
    end

    return {
        ready = ready,
        reason = reason,
        target = steerTarget,
        forward = forward,
        distance = distance,
        faceDistance = faceDistance,
        minFaceDistance = minFaceDistance,
        lateralOffset = lateralOffset,
        speed2D = speed2D,
        speedAlong = speedAlong,
        minSpeed = minSpeed,
        backoff = backoff,
        backoffBlocked = backoffBlocked,
        backoffHullClear = backoffHullClear,
        backoffSafe = backoffSafe,
        backoffSafeReason = backoffSafeReason,
        currentLiftClear = currentLiftClear,
        currentLiftReason = currentLiftReason,
        backoffLiftClear = backoffLiftClear,
        backoffLiftReason = backoffLiftReason,
        blockedCloseBackoffLiftClear = blockedCloseBackoffLiftClear,
        blockedCloseBackoffLiftReason = blockedCloseBackoffLiftReason,
        blockedCloseMinFaceDistance = blockedCloseMinFaceDistance,
        effectiveBlockedCloseMinFaceDistance = effectiveBlockedCloseMinFaceDistance
    }
end

function ENT:ShouldLogBMBHop()
    local convar = GetConVar("bmb_debug_hop_log")
    return convar and convar:GetBool()
end

function ENT:FormatBMBHopVector(pos)
    if not pos then return "nil" end

    return string.format("(%.1f,%.1f,%.1f)", pos.x or 0, pos.y or 0, pos.z or 0)
end

function ENT:LogBMBHopSetup(nodeIndex, launch, current, target)
    if not self:ShouldLogBMBHop() or not launch then return end

    local now = CurTime()
    local key = tostring(nodeIndex or 0) .. ":" .. tostring(launch.reason) .. ":" .. tostring(launch.ready)
    if self.BMBLastHopSetupLogKey == key and now < (self.BMBNextHopSetupLogAt or 0) then return end

    self.BMBLastHopSetupLogKey = key
    self.BMBNextHopSetupLogAt = now + (self.BlockHopSetupLogInterval or 0.25)

    local setupSafe, setupReason = true, "ok"
    if self.IsPathSourceTargetSafe and launch.target then
        setupSafe, setupReason = self:IsPathSourceTargetSafe(launch.target)
    end

    local hullClear = true
    if self.IsBMBHullClearAtPosition and launch.target then
        hullClear = self:IsBMBHullClearAtPosition(launch.target)
    end

    print(string.format(
        "[BMB] hop setup ent=%s node=%d ready=%s reason=%s dist=%.1f face=%.1f minFace=%.1f closeMin=%.1f effClose=%.1f lateral=%.1f speed=%.1f minSpeed=%.1f safe=%s safeReason=%s hull=%s currentLift=%s currentLiftReason=%s backoffBlocked=%s backoffHull=%s backoffSafe=%s backoffReason=%s backoffLift=%s backoffLiftReason=%s closeLift=%s closeLiftReason=%s pos=%s target=%s steer=%s",
        tostring(self), nodeIndex or 0, tostring(launch.ready == true), tostring(launch.reason),
        launch.distance or 0, launch.faceDistance or 0, launch.minFaceDistance or 0,
        launch.blockedCloseMinFaceDistance or 0, launch.effectiveBlockedCloseMinFaceDistance or launch.blockedCloseMinFaceDistance or 0,
        launch.lateralOffset or 0, launch.speedAlong or 0, launch.minSpeed or 0,
        tostring(setupSafe == true), tostring(setupReason or "ok"), tostring(hullClear == true),
        tostring(launch.currentLiftClear == true), tostring(launch.currentLiftReason or "ok"),
        tostring(launch.backoffBlocked == true), tostring(launch.backoffHullClear == true),
        tostring(launch.backoffSafe == true), tostring(launch.backoffSafeReason or "ok"),
        tostring(launch.backoffLiftClear == true), tostring(launch.backoffLiftReason or "ok"),
        tostring(launch.blockedCloseBackoffLiftClear == true), tostring(launch.blockedCloseBackoffLiftReason or "ok"),
        self:FormatBMBHopVector(current), self:FormatBMBHopVector(target), self:FormatBMBHopVector(launch.target)
    ))
end

function ENT:LogBMBVerticalReach(node, targetFootZ, deltaZ, reached, downTolerance, upTolerance)
    if not self:ShouldLogBMBHop() or not node then return end

    local now = CurTime()
    local key = tostring(node.action or "vertical") .. ":" .. tostring(node.coord and node.coord.z or node.z or 0) .. ":" .. tostring(reached)
    if self.BMBLastVerticalReachLogKey == key and now < (self.BMBNextVerticalReachLogAt or 0) then return end

    self.BMBLastVerticalReachLogKey = key
    self.BMBNextVerticalReachLogAt = now + (self.BlockHopReachLogInterval or 0.25)

    local cellZ = "nil"
    if BMB and BMB.BlockWorld and BMB.BlockWorld.WorldToBlock then
        local cell = BMB.BlockWorld.WorldToBlock(self:GetPos())
        cellZ = tostring(cell and cell.z)
    end

    downTolerance = downTolerance or self.VerticalPathReachZTolerance or 8
    upTolerance = upTolerance or downTolerance

    print(string.format(
        "[BMB] vertical reach ent=%s action=%s reached=%s posZ=%.2f targetFootZ=%.2f dz=%.2f tolDown=%.1f tolUp=%.1f cellZ=%s nodeZ=%s dist=%.1f onGround=%s",
        tostring(self), tostring(node.action or "vertical"), tostring(reached == true),
        self:GetPos().z, targetFootZ or 0, deltaZ or 0, downTolerance, upTolerance,
        cellZ, tostring(node.coord and node.coord.z or node.z), flatDistance(self:GetPos(), node),
        tostring(self:IsBMBOnGround())
    ))
end

function ENT:BeginBMBHopDebug(nodeIndex, target, launch, native)
    self.BMBHopAttemptCount = (self.BMBHopAttemptCount or 0) + 1
    self.BMBHopDebug = {
        attempt = self.BMBHopAttemptCount,
        nodeIndex = nodeIndex or 0,
        target = target,
        launchZ = self:GetPos().z,
        maxZ = self:GetPos().z,
        distance = launch and launch.distance or flatDistance(self:GetPos(), target),
        faceDistance = launch and launch.faceDistance or 0,
        speed = launch and launch.speedAlong or self:GetVelocity():Length2D(),
        native = native == true,
        startedAt = CurTime()
    }

    self:SetNWInt("BMBHopAttempt", self.BMBHopAttemptCount)
    self:SetNWInt("BMBHopResult", 0)
    self:SetNWBool("BMBHopNative", native == true)
    self:SetNWFloat("BMBHopDistance", self.BMBHopDebug.distance)
    self:SetNWFloat("BMBHopFaceDistance", self.BMBHopDebug.faceDistance)
    self:SetNWFloat("BMBHopSpeed", self.BMBHopDebug.speed)
    self:SetNWFloat("BMBHopApex", 0)
    self:SetNWFloat("BMBHopDebugUntil", CurTime() + 5)

    if self:ShouldLogBMBHop() then
        print(string.format("[BMB] hop start ent=%s attempt=%d node=%d native=%s dist=%.1f face=%.1f speed=%.1f target=%s pos=%s",
            tostring(self), self.BMBHopAttemptCount, nodeIndex or 0, tostring(native == true),
            self.BMBHopDebug.distance, self.BMBHopDebug.faceDistance, self.BMBHopDebug.speed,
            self:FormatBMBHopVector(target), self:FormatBMBHopVector(self:GetPos())))
    end
end

function ENT:UpdateBMBHopDebug()
    local debugData = self.BMBHopDebug
    if not debugData then return end

    debugData.maxZ = math.max(debugData.maxZ or self:GetPos().z, self:GetPos().z)
    self:SetNWFloat("BMBHopApex", math.max(0, (debugData.maxZ or self:GetPos().z) - (debugData.launchZ or self:GetPos().z)))
end

function ENT:FinishBMBHopDebug(result)
    local debugData = self.BMBHopDebug
    if not debugData then return end

    self:UpdateBMBHopDebug()
    self.BMBPendingBlockHop = nil
    self.BMBActiveBlockHop = nil
    self.BMBBlockHopAirControlUntil = 0
    self:RestoreBMBStepHeight()

    local resultCode = 2
    if result == "success" then
        resultCode = 1
    elseif result == "fail" then
        resultCode = 3
    end

    self:SetNWInt("BMBHopResult", resultCode)
    self:SetNWFloat("BMBHopDebugUntil", CurTime() + 5)

    if self:ShouldLogBMBHop() then
        local target = debugData.target
        local targetFootZ = target and (target.z - self:GetBMBBlockSize() * 0.5 + (self.BlockHopLandingLift or 2)) or 0

        print(string.format("[BMB] hop %s ent=%s attempt=%d node=%d native=%s dist=%.1f face=%.1f speed=%.1f apex=%.1f pos=%s target=%s targetFootZ=%.2f dz=%.2f onGround=%s",
            result or "retry", tostring(self), debugData.attempt or 0, debugData.nodeIndex or 0,
            tostring(debugData.native == true), debugData.distance or 0, debugData.faceDistance or 0,
            debugData.speed or 0, self:GetNWFloat("BMBHopApex", 0),
            self:FormatBMBHopVector(self:GetPos()), self:FormatBMBHopVector(target),
            targetFootZ, self:GetPos().z - targetFootZ, tostring(self:IsBMBOnGround())))
    end

    self.BMBHopDebug = nil
end

function ENT:GetBMBManualHopVelocity(target, speed, launch, gravity, apex)
    local blockSize = self:GetBMBBlockSize()
    local current = self:GetPos()
    local landingZ = target.z - blockSize * 0.5 + (self.BlockHopLandingLift or 2)
    local dz = landingZ - current.z
    local verticalSpeed = math.sqrt(2 * gravity * apex)
    local discriminant = math.max(1, verticalSpeed * verticalSpeed - 2 * gravity * dz)
    local flightTime = (verticalSpeed + math.sqrt(discriminant)) / gravity
    local distance = launch and launch.distance or flatDistance(current, target)
    local horizontalSpeed = distance / math.max(flightTime, 0.1)
    local minSpeed = self.BlockHopManualHorizontalMinSpeed or 32
    local maxSpeed = (speed or self.WalkSpeed) * (self.BlockHopManualHorizontalMaxScale or 1.1)
    local forward = launch and launch.forward or self:GetBMBHopForward(current, target)

    horizontalSpeed = math.Clamp(horizontalSpeed, minSpeed, maxSpeed)

    local horizontal = Vector(forward.x * horizontalSpeed, forward.y * horizontalSpeed, 0)

    return Vector(horizontal.x, horizontal.y, verticalSpeed), flightTime, horizontal, verticalSpeed
end

function ENT:QueueBMBManualBlockHop(target, speed, launch, gravity, apex)
    local velocity, flightTime, horizontal, verticalSpeed = self:GetBMBManualHopVelocity(target, speed, launch, gravity, apex)

    self.BMBPendingBlockHop = {
        createdAt = CurTime(),
        velocity = velocity,
        horizontal = horizontal,
        verticalSpeed = verticalSpeed,
        flightTime = flightTime,
        target = target
    }
end

function ENT:ApplyBMBPendingBlockHop()
    local pending = self.BMBPendingBlockHop
    if not pending then return end
    if CurTime() <= (pending.createdAt or 0) then return end

    local now = CurTime()
    local blockSize = self:GetBMBBlockSize()
    local controlTime = math.max(
        self.BlockHopManualControlTime or 0.7,
        (pending.flightTime or 0.55) + 0.12
    )

    self.BMBPendingBlockHop = nil
    self.BMBActiveBlockHop = {
        startedAt = now,
        launchZ = self:GetPos().z,
        target = pending.target,
        horizontal = pending.horizontal or Vector(pending.velocity.x, pending.velocity.y, 0),
        verticalSpeed = pending.verticalSpeed or pending.velocity.z,
        liftUntil = now + (self.BlockHopManualLiftTime or 0.16),
        forwardStartZ = self:GetPos().z + blockSize * (self.BlockHopManualForwardStartHeightScale or 0.8),
        controlUntil = now + controlTime
    }

    -- 再踢一次 Jump，防止上一 tick 的 Jump 状态已经被地面解算提前吃掉。
    self.loco:Jump()
    -- 第一段只向上抬，不立刻给水平速度；避免 hull 顶住方块侧面把 vz 磨没。
    self.loco:SetVelocity(Vector(0, 0, pending.velocity.z))
    self.BMBBlockHopAirControlUntil = now + controlTime

    if self:ShouldLogBMBHop() then
        local target = pending.target
        local targetFootZ = target and (target.z - blockSize * 0.5 + (self.BlockHopLandingLift or 2)) or 0

        print(string.format("[BMB] hop velocity ent=%s vx=%.1f vy=%.1f vz=%.1f flight=%.2f lift=%.2f target=%s targetFootZ=%.2f startZ=%.2f",
            tostring(self), pending.velocity.x, pending.velocity.y, pending.velocity.z,
            pending.flightTime or 0, self.BlockHopManualLiftTime or 0.16,
            self:FormatBMBHopVector(target), targetFootZ, self:GetPos().z))
    end
end

function ENT:MaintainBMBManualBlockHop(carrot, speed, progressWatch)
    local hop = self.BMBActiveBlockHop
    if not hop then return false end

    local now = CurTime()
    if now > (hop.controlUntil or 0) then
        self.BMBActiveBlockHop = nil
        return false
    end

    local current = self:GetPos()
    local velocity = self:GetVelocity()
    local lifted = current.z >= (hop.forwardStartZ or current.z) or now >= (hop.liftUntil or now)
    local target = hop.target or carrot

    if target then
        self.loco:FaceTowards(Vector(target.x, target.y, current.z))
    end

    if not lifted then
        if self:IsBMBOnGround() then
            self.loco:Jump()
        end

        self.loco:SetVelocity(Vector(0, 0, math.max(velocity.z, hop.verticalSpeed or 0)))
    else
        local horizontal = hop.horizontal or Vector(velocity.x, velocity.y, 0)
        local aim = carrot or target

        if aim then
            local direction = Vector(aim.x - current.x, aim.y - current.y, 0)

            if direction:LengthSqr() > 1 then
                direction:Normalize()

                local desired = direction * (speed or self.WalkSpeed)
                local strength = math.max(self.BlockHopAirSteerStrength or 0.08, 0.18)
                horizontal = Vector(
                    horizontal.x + (desired.x - horizontal.x) * strength,
                    horizontal.y + (desired.y - horizontal.y) * strength,
                    0
                )
            end
        end

        local minVz = 0
        if current.z < (hop.forwardStartZ or current.z) + 8 then
            minVz = (hop.verticalSpeed or 0) * (self.BlockHopManualPostLiftMinVzScale or 0.35)
        end

        self.loco:SetVelocity(Vector(horizontal.x, horizontal.y, math.max(velocity.z, minVz)))
    end

    if progressWatch then
        progressWatch.deadline = CurTime() + (self.MoveNoProgressGrace or 0.35)
    end

    return true
end

function ENT:StartBMBBlockHop(target, speed, launch)
    local blockSize = self:GetBMBBlockSize()
    local gravity = 600
    if self.loco and self.loco.GetGravity then
        gravity = math.abs(self.loco:GetGravity() or gravity)
    end

    if gravity <= 0 then gravity = 600 end

    local apex = self.BlockHopApex or blockSize * (self.BlockHopApexScale or 1.5)
    local jumpHeight = self:GetBMBBlockHopJumpHeight(blockSize, apex)

    if self.loco.SetJumpHeight then
        self.loco:SetJumpHeight(jumpHeight)
    end

    -- JumpAcrossGap 在一格爬升时会出现 apex=0 的低弧/不起弧；这里改成先用
    -- Jump 打开跳跃态，再下一 tick 覆盖手写弹道，避开同 tick 地面解算抢速度。
    self:BeginBMBHopStepHeight()
    self.loco:Jump()
    self:QueueBMBManualBlockHop(target, speed, launch, gravity, jumpHeight)
    self:FaceTarget(Vector(target.x, target.y, self:GetPos().z))
    self:BeginBMBHopDebug(launch and launch.nodeIndex, target, launch, false)

    return false
end

function ENT:SteerBMBInAir(target, speed, progressWatch)
    local current = self:GetPos()
    local aim = Vector(target.x, target.y, current.z)
    local direction = aim - current
    direction.z = 0

    if direction:LengthSqr() > 1 then
        direction:Normalize()
        self.loco:FaceTowards(aim)

        local velocity = self:GetVelocity()
        local targetVelocity = direction * (speed or self.WalkSpeed)
        local strength = self.BlockHopAirSteerStrength or 0.08

        self.loco:SetVelocity(Vector(
            velocity.x + (targetVelocity.x - velocity.x) * strength,
            velocity.y + (targetVelocity.y - velocity.y) * strength,
            velocity.z
        ))
    end

    if progressWatch then
        progressWatch.deadline = CurTime() + (self.MoveNoProgressGrace or 0.35)
    end
end

function ENT:MaintainBMBDropAir(progressWatch)
    -- Drop 是 A* 明确授权的下落边：离开边缘后不要再朝 carrot 转向。
    -- 否则 carrot 可能落到身后，实体会在空中回头给一脚反向速度，看起来很不 MC。
    -- 但 Source 空中几乎不吃地面摩擦；离边瞬间若保留完整行走速度，会被水平惯性甩很远。
    -- 这里只钳制当前水平速度大小，不改朝向、不 FaceTowards，避免回到"空中掉头刹车"。
    local velocity = self:GetVelocity()
    local horizontalSpeed = math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
    local desiredSpeed = self:GetNWFloat("BMBDesiredSpeed", self.WalkSpeed)
    local maxHorizontal = self.DropAirMaxHorizontalSpeed or desiredSpeed * (self.DropAirMaxHorizontalSpeedScale or 0.35)

    if horizontalSpeed > maxHorizontal and horizontalSpeed > 0 then
        local scale = maxHorizontal / horizontalSpeed
        self.loco:SetVelocity(Vector(velocity.x * scale, velocity.y * scale, velocity.z))
    end

    if progressWatch then
        progressWatch.deadline = CurTime() + (self.MoveNoProgressGrace or 0.35)
    end
end

function ENT:MaintainBMBNativeHop(target, progressWatch)
    local current = self:GetPos()
    local aim = Vector(target.x, target.y, current.z)

    if flatDistanceSqr(current, aim) > 1 then
        self.loco:FaceTowards(aim)
    end

    if progressWatch then
        progressWatch.deadline = CurTime() + (self.MoveNoProgressGrace or 0.35)
    end
end

function ENT:MoveAlongPath(waypoints, speed, options)
    options = options or {}

    if not waypoints or #waypoints == 0 then return false end
    if self:IsBMBKnockbackActive() then return false end

    local desiredSpeed = speed or self.WalkSpeed
    local moveIntentSpeed = options.moveIntentSpeed or desiredSpeed
    local blockSize = self:GetBMBBlockSize()
    local goalTolerance = options.goalTolerance or self:GetBMBDefaultGoalTolerance()
    local nodeTolerance = options.nodeTolerance or self:GetBMBPathNodeTolerance()
    local carrotDistance = options.carrotDistance or math.Clamp(
        desiredSpeed * (self.PathCarrotSpeedScale or 1.1),
        self:GetBMBPathCarrotMinDistance(),
        self:GetBMBPathCarrotMaxDistance()
    )
    local nodeIndex = 1
    local final = waypoints[#waypoints]

    -- 路径头部是出发格中心，可能落在身后：起步前先跳过脚下这一格，避免开局回头拐一下
    local startPos = self:GetPos()
    while nodeIndex < #waypoints
        and not self:IsBMBPathVerticalAction(self:GetBMBWaypointAction(waypoints, nodeIndex))
        and flatDistance(startPos, waypoints[nodeIndex]) <= blockSize * 0.75 do
        nodeIndex = nodeIndex + 1
    end

    local timeout = CurTime() + self:GetBMBPathTimeout(waypoints, desiredSpeed, options, nodeIndex)

    self:ClearBMBMovementInterrupt()
    self:MaintainBMBMoveSpeed(desiredSpeed, moveIntentSpeed)
    self:UpdateMoveActivity(desiredSpeed, moveIntentSpeed)
    self:SetBMBMoveMode("path_carrot")

    local progressWatch = self:StartBMBMoveProgressWatch()
    local goalProgressWatch = self:StartBMBGoalProgressWatch(final)
    local hopStartedAt = {}
    local hopAttempts = {}
    local hopNative = {}

    while CurTime() < timeout do
        if self.BMBMoveInterrupt then
            self:RestoreBMBStepHeight()
            return false
        end

        local current = self:GetPos()
        self:ApplyBMBPendingBlockHop()
        self:UpdateBMBHopDebug()

        if self:IsBMBPathFinalReached(final, goalTolerance) then
            if final.action == "hop" then
                self:FinishBMBHopDebug("success")
            end

            self:SetBMBMoveMode("idle")
            self:UpdateBMBApproachDebug(nil, 0)
            return true
        end

        local advanceStartIndex = nodeIndex

        while nodeIndex < #waypoints do
            local node = waypoints[nodeIndex]
            local nodeAction = self:GetBMBWaypointAction(waypoints, nodeIndex)
            local nodeDistance = flatDistance(current, node)

            if self:ShouldAdvanceBMBPathNode(node, nodeAction, nodeDistance, nodeTolerance) then
                if nodeAction == "hop" then
                    self:FinishBMBHopDebug("success")
                end

                nodeIndex = nodeIndex + 1
                self:MarkBMBPathAdvanced(nodeIndex)
            elseif not self:IsBMBPathVerticalAction(nodeAction) and nodeDistance <= blockSize * 1.5 then
                -- 切弯时会从节点旁边掠过（横向 > nodeTolerance），只按距离判定节点永远推进不了，
                -- carrot 会折回身后的漏过节点导致原地转圈。已越过该节点朝下一节点的垂面就视为通过
                local nextNode = waypoints[nodeIndex + 1]
                local passedX = (nextNode.x - node.x) * (current.x - node.x)
                local passedY = (nextNode.y - node.y) * (current.y - node.y)

                if passedX + passedY > 0 then
                    nodeIndex = nodeIndex + 1
                    self:MarkBMBPathAdvanced(nodeIndex)
                else
                    break
                end
            else
                break
            end
        end

        -- 沿路径推进节点 = 实打实的进展：绕墙的合法路径会有一段离终点直线距离越走越远，
        -- 不刷新 goal-progress watchdog 会把绕路误杀成 path_no_goal_progress；
        -- watchdog 保留原本"防原地绕圈"的用途（绕圈不会持续推进节点）
        if goalProgressWatch and nodeIndex > advanceStartIndex then
            goalProgressWatch.distance = flatDistance(current, final)
            goalProgressWatch.deadline = CurTime() + (self.PathGoalProgressTimeout or 0.9)
        end

        local activeAction = self:GetBMBWaypointAction(waypoints, nodeIndex)
        local actionNode = waypoints[nodeIndex]
        local verticalAction = self:IsBMBPathVerticalAction(activeAction)
        local pathSpeed, pathCarrotDistance, cornering
        local carrot

        if verticalAction and actionNode then
            pathSpeed = desiredSpeed
            pathCarrotDistance = math.min(carrotDistance, self:GetBMBPathCornerCarrotDistance())
            cornering = false
            carrot = Vector(actionNode.x, actionNode.y, current.z)
        else
            pathSpeed, pathCarrotDistance, cornering = self:GetBMBPathCornerControl(waypoints, nodeIndex, current, desiredSpeed, carrotDistance)
            carrot = self:GetPathCarrot(waypoints, nodeIndex, pathCarrotDistance)
        end

        if options.minPathSpeed then
            pathSpeed = math.max(pathSpeed, math.min(desiredSpeed, options.minPathSpeed))
        end

        if not carrot then
            self:RestoreBMBStepHeight()
            return false
        end

        if not verticalAction then
            local sourceSafe, sourceReason = self:IsPathSourceTargetSafe(carrot)
            if not sourceSafe then
                self:FailBMBMove(sourceReason == "cliff" and "path_cliff" or "path_wall", sourceReason == "wall")
                return false
            end
        end

        if activeAction == "hop" then
            self:SetBMBMoveMode("path_hop")
        elseif activeAction == "drop" then
            self:SetBMBMoveMode("path_drop")
        else
            self:SetBMBMoveMode(cornering and "path_corner" or "path_carrot")
        end

        self.loco:SetDeceleration(cornering and math.max(self.Deceleration, self.PathCornerDeceleration or 720) or self.Deceleration)
        self:MaintainBMBMoveSpeed(pathSpeed, moveIntentSpeed)
        self:UpdateBMBApproachDebug(carrot, nodeIndex)

        if activeAction == "hop" then
            local triggerDistance = self.BlockHopTriggerDistance or blockSize * (self.BlockHopLaunchMaxDistanceScale or 1.4)
            local onGround = self:IsBMBOnGround()
            -- loco:Jump() 会同步置跳跃态，用它代替时间猜的"起跳保护窗"：
            -- 跳跃态内不交回 Approach（地面驱动会和跳跃打架），状态和真实物理一致
            local jumping = self.loco.IsClimbingOrJumping and self.loco:IsClimbingOrJumping() or false
            local manualAirControl = CurTime() < (self.BMBBlockHopAirControlUntil or 0)
            local hopSetupSteered = false

            -- 跳过却落回地面且节点没推进 = 这一跳撞在方块面上掉回来了。
            -- 重跳延时从 OnLandOnGround 回调时刻起算（物理给的时序，不靠轮询猜抖动）；
            -- 连续 BlockHopMaxAttempts 次失败按路径失败交还行为层换目标
            local hopStart = hopStartedAt[nodeIndex]
            if hopStart and onGround and not jumping and not manualAirControl then
                local landedAt = self.BMBLastLandTime or 0

                if landedAt > hopStart and CurTime() - landedAt >= (self.BlockHopRetryDelay or 0.25) then
                    if (hopAttempts[nodeIndex] or 0) >= (self.BlockHopMaxAttempts or 3) then
                        self:FinishBMBHopDebug("fail")
                        self:FailBMBMove("path_hop_fail")
                        return false
                    end

                    self:FinishBMBHopDebug("retry")
                    hopStartedAt[nodeIndex] = nil
                end
            end

            if not hopStartedAt[nodeIndex] and onGround and not jumping
                and flatDistance(current, actionNode) <= triggerDistance then
                local launch = self:GetBMBHopLaunchControl(current, actionNode, pathSpeed, waypoints[nodeIndex - 1])
                launch.nodeIndex = nodeIndex
                self:LogBMBHopSetup(nodeIndex, launch, current, actionNode)

                if launch.ready then
                    hopNative[nodeIndex] = self:StartBMBBlockHop(actionNode, pathSpeed, launch)
                    hopStartedAt[nodeIndex] = CurTime()
                    hopAttempts[nodeIndex] = (hopAttempts[nodeIndex] or 0) + 1
                    -- 引擎标志若晚一帧翻转也不回 Approach：起跳当帧强制按跳跃态驱动
                    jumping = true
                else
                    self:UpdateBMBApproachDebug(launch.target, nodeIndex)
                    self:SteerTowards(launch.target, progressWatch)
                    hopSetupSteered = true
                end
            end

            -- 空中转向只在跳跃态/真离地时接管（它会刷新 no-progress watchdog，
            -- 落地贴墙阶段还用它等于把卡死兜底关掉）
            if not hopSetupSteered then
                local manualHopHandled = self:MaintainBMBManualBlockHop(carrot, pathSpeed, progressWatch)

                if not manualHopHandled and (jumping or manualAirControl or not onGround) then
                    if hopNative[nodeIndex] then
                        self:MaintainBMBNativeHop(carrot, progressWatch)
                    else
                        self:SteerBMBInAir(carrot, pathSpeed, progressWatch)
                    end
                elseif not manualHopHandled then
                    self:SteerTowards(carrot, progressWatch)
                end
            end
        elseif activeAction == "drop" and not self:IsBMBOnGround() then
            self:MaintainBMBDropAir(progressWatch)
        else
            self:SteerTowards(carrot, progressWatch)
        end

        self:BodyMoveXY()
        self:MaybePlayStep()

        if not self:CheckBMBMoveProgress(progressWatch) then
            -- 已经贴到终点附近的"无进度"按到达处理：到站减速被 watchdog 误杀会跳过行为层的停顿
            if self:IsBMBPathFinalReached(final, goalTolerance * 2) then
                self:SetBMBMoveMode("idle")
                self:UpdateBMBApproachDebug(nil, 0)
                return true
            end

            self:FailBMBMove("path_blocked")
            return false
        end

        if not self:CheckBMBGoalProgress(goalProgressWatch, final) then
            if self:IsBMBPathFinalReached(final, goalTolerance * 2) then
                self:SetBMBMoveMode("idle")
                self:UpdateBMBApproachDebug(nil, 0)
                return true
            end

            self:FailBMBMove("path_no_goal_progress")
            return false
        end

        if not verticalAction and self.loco:IsStuck() then
            self:HandleStuck()
            self:FailBMBMove("path_stuck")
            return false
        end

        coroutine.yield()
    end

    self:RestoreBMBStepHeight()

    if options.acceptPartial then return true end

    return flatDistance(self:GetPos(), final) <= goalTolerance
end

function ENT:MoveDirectFallback(destination, speed, options)
    options = options or {}

    if self:IsBMBKnockbackActive() then return false end

    local desiredSpeed = speed or self.RunSpeed
    local duration = options.duration or 0.55
    local timeout = CurTime() + duration
    local target = Vector(destination.x, destination.y, self:GetPos().z)
    local goalTolerance = options.goalTolerance or self:GetBMBDefaultGoalTolerance()

    self:ClearBMBMovementInterrupt()
    self:MaintainBMBMoveSpeed(desiredSpeed)
    self:UpdateMoveActivity(desiredSpeed)
    self:SetBMBMoveMode(options.moveMode or "direct")

    local progressWatch = self:StartBMBMoveProgressWatch()

    while CurTime() < timeout do
        if self.BMBMoveInterrupt then return false end

        target.z = self:GetPos().z
        if flatDistance(self:GetPos(), destination) <= goalTolerance then return true end

        local safe, blockReason = self:IsMovementTargetSafe(target, self:GetBMBTickSafetyProbe(options.safetyProbe))
        if not safe then
            self:FailBMBMove("direct_blocked", blockReason == "wall")
            return false
        end

        self:MaintainBMBMoveSpeed(desiredSpeed)
        self:UpdateBMBApproachDebug(target, 0)
        self:SteerTowards(target, progressWatch)
        self:BodyMoveXY()
        self:MaybePlayStep()

        if not self:CheckBMBMoveProgress(progressWatch) then
            self:FailBMBMove("direct_blocked")
            return false
        end

        coroutine.yield()
    end

    return options.acceptPartial or flatDistance(self:GetPos(), destination) <= goalTolerance
end

function ENT:MoveAlongDirection(direction, speed, options)
    options = options or {}

    if self.BMBHeld then return false end
    if self:IsBMBKnockbackActive() then return false end

    local moveDirection = Vector(direction.x, direction.y, 0)
    -- 只挡零向量：Flee 传进来的是归一化单位向量（LengthSqr ≈ 1.0），阈值用 1 会把它拒收
    if moveDirection:LengthSqr() < 0.01 then return false end

    moveDirection:Normalize()

    local desiredSpeed = speed or self.WalkSpeed
    local duration = options.duration or 1.0
    local lookAhead = options.lookAhead or 150
    local timeout = CurTime() + duration
    local pathDestination = self:GetPos() + moveDirection * lookAhead
    pathDestination.z = self:GetPos().z

    if options.useSourcePath and self:ShouldUseSourcePath() and not options.skipSourcePath then
        if self:MoveWithSourcePath(pathDestination, speed or self.WalkSpeed, {
            duration = duration,
            lookAhead = options.pathLookAhead or self.SourcePathLookAhead,
            goalTolerance = options.goalTolerance or self:GetBMBSourcePathGoalTolerance(),
            acceptPartial = true,
            skipSourcePath = true
        }) then
            return true
        end

        if self.BMBMoveInterrupt then return false end
    end

    self:ClearBMBMovementInterrupt()
    self:MaintainBMBMoveSpeed(desiredSpeed)
    self:UpdateMoveActivity(desiredSpeed)
    self:SetBMBMoveMode("direction_direct")

    local progressWatch = self:StartBMBMoveProgressWatch()

    while CurTime() < timeout do
        if self.BMBMoveInterrupt then return false end

        local target = self:GetPos() + moveDirection * lookAhead
        target.z = self:GetPos().z

        local safe, blockReason = self:IsMovementTargetSafe(target, self:GetBMBTickSafetyProbe(options.safetyProbe))
        if not safe then
            self:FailBMBMove("direction_blocked", blockReason == "wall")
            return false
        end

        self:MaintainBMBMoveSpeed(desiredSpeed)
        self:UpdateBMBApproachDebug(target, 0)
        self:SteerTowards(target, progressWatch)
        self:BodyMoveXY()
        self:MaybePlayStep()

        if not self:CheckBMBMoveProgress(progressWatch) then
            self:FailBMBMove("direction_blocked")
            return false
        end

        coroutine.yield()
    end

    return true
end

function ENT:MoveToWaypoint(waypoint)
    if self:IsBMBKnockbackActive() then return false end

    local target = Vector(waypoint.x, waypoint.y, self:GetPos().z)
    local timeout = CurTime() + self.WaypointTimeout

    self:SetBMBMoveMode("waypoint_legacy")

    local progressWatch = self:StartBMBMoveProgressWatch()

    while CurTime() < timeout do
        if self.BMBMoveInterrupt then return false end

        target.z = self:GetPos().z

        local delta = target - self:GetPos()
        delta.z = 0

        if delta:Length2D() <= BMB.Config.DefaultGoalTolerance then return true end

        local safe, blockReason = self:IsMovementTargetSafe(target)
        if not safe then
            self:FailBMBMove("waypoint_blocked", blockReason == "wall")
            return false
        end

        self:MaintainBMBMoveSpeed(self:GetNWFloat("BMBDesiredSpeed", self.WalkSpeed))
        self:UpdateBMBApproachDebug(target, 0)
        self:SteerTowards(target, progressWatch)
        self:BodyMoveXY()
        self:MaybePlayStep()

        if not self:CheckBMBMoveProgress(progressWatch) then
            self:FailBMBMove("waypoint_blocked")
            return false
        end

        if self.loco:IsStuck() then
            self:HandleStuck()
            self:FailBMBMove("waypoint_stuck")
            return false
        end

        coroutine.yield()
    end

    return false
end

-- 移动中每 tick 复查用的探测距离：悬崖前瞻随速度缩放（刹得住即可），
-- 但不超过选方向时验证过的档位——选向短档、复查长档会"选中即失败"，又回到冻住
function ENT:GetBMBTickSafetyProbe(selectionProbe)
    local dynamicProbe = math.max(
        self.ForwardSafetyDistance,
        self:GetVelocity():Length2D() * (self.SafetyProbeSpeedScale or 0.45)
    )

    if selectionProbe then return math.min(selectionProbe, dynamicProbe) end

    return dynamicProbe
end

function ENT:IsMovementTargetSafe(target, probeDistance)
    local current = self:GetPos()
    local probeHeight = self.GroundProbeHeight
    local delta = target - current
    delta.z = 0

    local distance = delta:Length2D()
    if distance <= 1 then return true end

    delta:Normalize()

    -- 探测距离随当前速度放大：固定 48u 在跑动速度（Flee 145u/s，刹车距离约 40u）下
    -- 等探到没地面时动量已经把 mob 带下悬崖
    local probe = math.min(distance, probeDistance or math.max(
        self.ForwardSafetyDistance,
        self:GetVelocity():Length2D() * (self.SafetyProbeSpeedScale or 0.45)
    ))
    local forwardTarget = current + delta * probe
    local startPos = current + Vector(0, 0, probeHeight)
    local endPos = forwardTarget + Vector(0, 0, probeHeight)
    local hullScale = self.SafetyHullScale
    local traceFilter = function(ent)
        return self:ShouldSafetyTraceHit(ent)
    end

    local wallTrace = util.TraceHull({
        start = startPos,
        endpos = endPos,
        mins = Vector(self.CollisionMins.x * hullScale, self.CollisionMins.y * hullScale, -probeHeight * 0.35),
        maxs = Vector(self.CollisionMaxs.x * hullScale, self.CollisionMaxs.y * hullScale, probeHeight * 0.45),
        filter = traceFilter,
        mask = MASK_SOLID
    })

    -- 起步就嵌在 prop 里（StartSolid）时不按墙处理：被 prop 挤住/贴住（尤其斜放的 prop）时
    -- 所有方向的 hull 都从重叠开始，按墙判会全方向被毙 → Flee 原地冻住。
    -- 放行后撞不动的方向由 loco 碰撞挡住、no-progress watchdog 换向，能走的方向自然脱困
    if wallTrace.Hit and not wallTrace.StartSolid and not self:CanStepPastTrace(wallTrace, forwardTarget, traceFilter) then
        -- 撞墙无害（loco 碰撞自己挡得住），不需要像悬崖那样在整个探测距离上提前避让：
        -- 远处的墙允许继续接近，贴脸（WallStopDistance）才算挡路。否则 mob 在离 prop
        -- 一个探测距离外就开始犹豫掉速，永远碰不到 prop（三面围起来时直接不敢进）
        local hitDistance = wallTrace.Fraction * probe
        if hitDistance <= (self.WallStopDistance or 20) then return false, "wall" end

        -- 墙还远：把地面探测截到墙跟前，否则探测点落进墙体/墙顶会误报
        probe = hitDistance - 4
        forwardTarget = current + delta * probe
    end

    local groundTrace = util.TraceHull({
        start = forwardTarget + Vector(0, 0, self.GroundProbeHeight),
        endpos = forwardTarget - Vector(0, 0, self.GroundProbeDepth),
        mins = Vector(self.CollisionMins.x * 0.75, self.CollisionMins.y * 0.75, 0),
        maxs = Vector(self.CollisionMaxs.x * 0.75, self.CollisionMaxs.y * 0.75, 4),
        filter = traceFilter,
        mask = MASK_SOLID
    })

    if not groundTrace.Hit then return false, "cliff" end
    if groundTrace.HitNormal.z < 0.65 then return false, "cliff" end
    if current.z - groundTrace.HitPos.z > self:GetBMBMaxStepDown() then return false, "cliff" end

    local gridSafe, gridReason = self:IsBMBGridMovementTargetSafe(forwardTarget, probe)
    if not gridSafe then return false, gridReason or "cliff" end

    return true
end

function ENT:CanStepPastTrace(wallTrace, forwardTarget, traceFilter)
    if not wallTrace.Hit then return true end

    local current = self:GetPos()
    local stepHeight = self.StepHeight

    if wallTrace.HitPos.z - current.z > stepHeight + 4 then return false end

    local raisedStart = current + Vector(0, 0, stepHeight + self.GroundProbeHeight)
    local raisedEnd = forwardTarget + Vector(0, 0, stepHeight + self.GroundProbeHeight)
    local hullScale = self.SafetyHullScale

    local raisedTrace = util.TraceHull({
        start = raisedStart,
        endpos = raisedEnd,
        mins = Vector(self.CollisionMins.x * hullScale, self.CollisionMins.y * hullScale, -self.GroundProbeHeight * 0.35),
        maxs = Vector(self.CollisionMaxs.x * hullScale, self.CollisionMaxs.y * hullScale, self.GroundProbeHeight * 0.45),
        filter = traceFilter,
        mask = MASK_SOLID
    })

    if raisedTrace.Hit then return false end

    local landingTrace = util.TraceHull({
        start = forwardTarget + Vector(0, 0, stepHeight + self.GroundProbeHeight),
        endpos = forwardTarget - Vector(0, 0, self.GroundProbeDepth),
        mins = Vector(self.CollisionMins.x * 0.6, self.CollisionMins.y * 0.6, 0),
        maxs = Vector(self.CollisionMaxs.x * 0.6, self.CollisionMaxs.y * 0.6, 4),
        filter = traceFilter,
        mask = MASK_SOLID
    })

    if not landingTrace.Hit then return false end
    if landingTrace.HitNormal.z < 0.65 then return false end
    if landingTrace.HitPos.z - current.z > stepHeight + 4 then return false end
    if current.z - landingTrace.HitPos.z > self:GetBMBMaxStepDown() then return false end

    return true
end

function ENT:ShouldSafetyTraceHit(ent)
    if ent == self then return false end
    if not IsValid(ent) then return true end
    if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() then return false end

    return true
end

function ENT:CheckPhysicsImpacts()
    if self.BMBDead then return end
    if CurTime() < (self.NextPhysicsImpactCheck or 0) then return end

    self.NextPhysicsImpactCheck = CurTime() + self.PhysicsImpactInterval

    local center = self:WorldSpaceCenter()
    for _, ent in ipairs(ents.FindInSphere(center, self.PhysicsImpactRadius)) do
        self:HandlePhysicsImpact(ent)
    end
end

function ENT:HandlePhysicsImpact(ent)
    if not self:IsPhysicsImpactEntity(ent) then return false end

    local now = CurTime()
    self.PhysicsImpactTimes = self.PhysicsImpactTimes or {}

    if now < (self.PhysicsImpactTimes[ent] or 0) then return false end

    local phys = ent:GetPhysicsObject()
    local velocity = phys:GetVelocity()
    local speed = velocity:Length()

    if speed < self.PhysicsImpactMinSpeed then return false end

    self.PhysicsImpactTimes[ent] = now + self.PhysicsImpactCooldown

    local massScale = math.Clamp(phys:GetMass() / 45, 0.75, 2.25)
    local damageAmount = math.Clamp((speed - self.PhysicsImpactMinSpeed) * self.PhysicsImpactDamageScale * massScale, 1, self.PhysicsImpactMaxDamage)

    local damage = DamageInfo()
    damage:SetAttacker(IsValid(ent:GetOwner()) and ent:GetOwner() or ent)
    damage:SetInflictor(ent)
    damage:SetDamage(damageAmount)
    damage:SetDamageType(DMG_CRUSH)
    damage:SetDamageForce(velocity * phys:GetMass())
    damage:SetDamagePosition(ent:WorldSpaceCenter())

    self:TakeDamageInfo(damage)
    self:ReactToPhysicsImpact(ent, phys, velocity, self.BMBDead)

    return true
end

function ENT:IsPhysicsImpactEntity(ent)
    if not IsValid(ent) then return false end
    if ent == self then return false end
    if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() then return false end

    local phys = ent:GetPhysicsObject()
    if not IsValid(phys) or not phys:IsMoveable() then return false end

    return ent:GetSolid() ~= SOLID_NONE
end

function ENT:ReactToPhysicsImpact(ent, phys, velocity, killed)
    local damping = killed and self.PhysicsPropKillDamping or self.PhysicsPropImpactDamping

    phys:SetVelocity(velocity * damping)
end

function ENT:OnContact(ent)
    self:HandlePhysicsImpact(ent)
end

function ENT:StartTouch(ent)
    self:HandlePhysicsImpact(ent)
end

function ENT:FaceTarget(position)
    local direction = position - self:GetPos()
    direction.z = 0

    if direction:LengthSqr() <= 1 then return end

    -- 转向只走 loco（CLAUDE.md：禁止 SetAngles 手动转向，会打断客户端插值）
    -- 转速由 BaseInitialize 里的 loco:SetMaxYawRate(TurnRate) 控制
    self.loco:FaceTowards(position)
end

-- 移动循环统一入口：目标在身后超过 TurnInPlaceAngle 时先原地转身再走，
-- 否则 Approach 会不顾朝向直接倒退（MC 生物不会面朝前倒着走）
function ENT:SteerTowards(target, progressWatch)
    local direction = target - self:GetPos()
    direction.z = 0

    if direction:LengthSqr() <= 1 then return end

    self.loco:FaceTowards(target)

    local yawDiff = math.abs(math.AngleDifference(direction:Angle().y, self:GetAngles().y))
    if yawDiff > (self.TurnInPlaceAngle or 110) then
        -- 原地转身阶段速度为 0 是预期行为，不让 no-progress watchdog 计时
        if progressWatch then
            progressWatch.deadline = CurTime() + (self.MoveNoProgressGrace or 0.35)
        end

        return
    end

    self.loco:Approach(target, 1)
end

function ENT:MaybePlayStep()
    if CurTime() < self.NextStepSoundTime then return end
    if self:GetVelocity():Length2D() < 18 then return end

    self:EmitSound("npc/zombie/foot1.wav", 58, math.random(96, 104), 0.25)
    self.NextStepSoundTime = CurTime() + 0.5
end

function ENT:PlayBMBAnimation(name)
    if name == "eat" then
        self:RestartGesture(ACT_GESTURE_RANGE_ATTACK1)
    elseif name == "hurt" then
        self:RestartGesture(ACT_FLINCH_PHYSICS)
    end
end

function ENT:OnInjured(damageInfo, context)
    if CLIENT then return end

    local wasFleeing = context and context.wasFleeing
    local startedKnockback = self:StartBMBKnockback(damageInfo)

    if not startedKnockback and not wasFleeing then
        self:InterruptBMBMovement()
    end

    self:PlayBMBAnimation("hurt")

    if self.OnBMBInjured then
        self:OnBMBInjured(damageInfo, wasFleeing)
    end
end

function ENT:GetBMBDeathRemoveDelay()
    if self.DeathRemoveDelay == false then return false end

    local delay = tonumber(self.DeathRemoveDelay)
    if delay == nil then delay = 1.0 end

    return math.max(0, delay)
end

function ENT:StopBMBMovementOnDeath()
    if CLIENT then return end

    self.BMBDead = true
    self.BMBHeld = false
    self.BMBMoveInterrupt = true
    self.BMBPendingBlockHop = nil
    self.BMBActiveBlockHop = nil
    self.BMBBlockHopAirControlUntil = 0
    self.BMBKnockbackUntil = 0
    self.BMBKnockbackVelocity = nil
    self.BMBKnockbackVerticalSpeed = nil
    self.BMBKnockbackDesiredSpeed = nil
    self.BMBKnockbackActivitySpeed = nil
    self.BMBKnockbackLocoSpeed = nil
    self.TargetEntity = nil

    self:SetNWBool("BMBDead", true)
    self:SetNWFloat("BMBDesiredSpeed", 0)
    self:SetNWFloat("BMBActivitySpeed", 0)
    self:SetNWFloat("BMBKnockbackUntil", 0)
    self:SetNWFloat("BMBKnockbackSpeed", 0)
    self:SetBMBState("dead")
    self:SetBMBMoveMode("dead")
    self:UpdateBMBApproachDebug(nil, 0)
    self:RestoreBMBStepHeight()

    if self.loco then
        if self.loco.SetDesiredSpeed then
            self.loco:SetDesiredSpeed(0)
        end

        if self.loco.SetVelocity then
            self.loco:SetVelocity(vector_origin)
        end
    end

    self:SetSolid(SOLID_NONE)
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
end

function ENT:GetBMBDeathEffectOrigin()
    if self.WorldSpaceCenter then
        return self:WorldSpaceCenter()
    end

    return self:GetPos() + self:OBBCenter()
end

function ENT:GetBMBDeathEffectScale()
    local mins = self:OBBMins()
    local maxs = self:OBBMaxs()
    local height = math.max(1, maxs.z - mins.z)
    local width = math.max(maxs.x - mins.x, maxs.y - mins.y, 1)

    return math.Clamp(math.max(height, width) / 48, 0.6, 2.4)
end

function ENT:GetBMBDeathPoofParticleCount()
    if self.DeathPoofParticleCountMin or self.DeathPoofParticleCountMax then
        local minCount = math.floor(tonumber(self.DeathPoofParticleCountMin) or 5)
        local maxCount = math.floor(tonumber(self.DeathPoofParticleCountMax) or minCount)

        if maxCount < minCount then
            minCount, maxCount = maxCount, minCount
        end

        return math.random(math.max(1, minCount), math.max(1, maxCount))
    end

    return math.max(1, math.floor(tonumber(self.DeathPoofParticleCount) or 6))
end

function ENT:EmitBMBDeathPoofAt(origin, scale)
    if CLIENT then return end
    if not self.DeathPoofEffect then return end

    local data = EffectData()
    local effectScale = scale or self:GetBMBDeathEffectScale()

    data:SetOrigin(origin or self:GetBMBDeathEffectOrigin())
    data:SetScale(effectScale)
    data:SetRadius((self.DeathPoofRadiusScale or 28) * effectScale)
    data:SetMagnitude(self:GetBMBDeathPoofParticleCount())
    util.Effect(self.DeathPoofEffect, data, true, true)
end

function ENT:EmitBMBDeathPoof()
    self:EmitBMBDeathPoofAt(self:GetBMBDeathEffectOrigin(), self:GetBMBDeathEffectScale())
end

function ENT:GetBMBDeathCorpseImpactVelocity(damageInfo)
    local velocity = self:GetVelocity() or vector_origin
    local rightPush = self:GetRight() * (self.DeathCorpseRightPushSpeed or 0)
    local upPush = Vector(0, 0, self.DeathCorpseUpPushSpeed or 0)
    local pushedVelocity = velocity + rightPush + upPush
    if not damageInfo then return pushedVelocity end

    local force = damageInfo:GetDamageForce()
    if not force or force:LengthSqr() <= 1 then return pushedVelocity end

    local speed = math.min(force:Length() * (self.DeathCorpseDamageForceScale or 0.02), self.DeathCorpseMaxImpactSpeed or 220)
    local direction = force:GetNormalized()

    return pushedVelocity + direction * speed
end

function ENT:ApplyBMBDeathCorpseTip(corpse, phys)
    if not IsValid(corpse) or not IsValid(phys) then return end

    local rightForce = self.DeathCorpseRightForce or 0
    if rightForce ~= 0 then
        local massScale = math.max(1, phys:GetMass())
        local force = self:GetRight() * rightForce * massScale
        local offset = Vector(0, 0, self.DeathCorpseTorqueHeight or 24)

        phys:ApplyForceOffset(force, corpse:WorldSpaceCenter() + offset)
    end

    local roll = self.DeathCorpseRightRollVelocity or 0
    if roll ~= 0 then
        phys:AddAngleVelocity(corpse:GetForward() * roll)
    end
end

function ENT:CopyBMBVisualStateToCorpse(corpse)
    corpse:SetSkin(self:GetSkin() or 0)
    corpse:SetColor(self.DeathKeepRed ~= false and (self.DeathCorpseColor or Color(255, 110, 110, 255)) or self:GetColor())
    corpse:SetRenderMode(RENDERMODE_TRANSALPHA)

    if self.GetBodyGroups then
        for _, bodyGroup in ipairs(self:GetBodyGroups()) do
            corpse:SetBodygroup(bodyGroup.id, self:GetBodygroup(bodyGroup.id))
        end
    end

    if self.GetMaterials then
        local materials = self:GetMaterials()
        for index = 0, #materials - 1 do
            local subMaterial = self:GetSubMaterial(index)
            if subMaterial and subMaterial ~= "" then
                corpse:SetSubMaterial(index, subMaterial)
            end
        end
    end
end

function ENT:CreateBMBPhysicsCorpse(damageInfo)
    if CLIENT then return nil end
    if not self.UsePhysicsCorpseOnDeath then return nil end

    local corpse = ents.Create(self.DeathCorpseClass or "prop_physics")
    if not IsValid(corpse) then return nil end

    corpse:SetModel(self:GetModel())
    corpse:SetPos(self:GetPos())
    corpse:SetAngles(self:GetAngles())
    self:CopyBMBVisualStateToCorpse(corpse)
    corpse:Spawn()
    corpse:Activate()
    corpse:SetCollisionGroup(self.DeathCorpseCollisionGroup or COLLISION_GROUP_DEBRIS)

    local phys = corpse:GetPhysicsObject()
    if not IsValid(phys) then
        corpse:Remove()
        return nil
    end

    phys:Wake()
    phys:SetVelocity(self:GetBMBDeathCorpseImpactVelocity(damageInfo))
    phys:AddAngleVelocity(Vector(
        math.Rand(-45, 45),
        math.Rand(-45, 45),
        math.Rand(-1, 1) >= 0 and (self.DeathCorpseRollVelocity or 180) or -(self.DeathCorpseRollVelocity or 180)
    ))
    self:ApplyBMBDeathCorpseTip(corpse, phys)

    return corpse
end

function ENT:ScheduleBMBDeathCleanup(delay, corpse)
    if CLIENT then return end
    if delay == false then return end

    timer.Simple(delay or 1.0, function()
        if IsValid(self) then
            local origin = IsValid(corpse) and corpse:WorldSpaceCenter() or self:GetBMBDeathEffectOrigin()
            self:EmitBMBDeathPoofAt(origin, self:GetBMBDeathEffectScale())
        end

        if IsValid(corpse) then
            corpse:Remove()
        end

        if IsValid(self) then
            self:Remove()
        end
    end)
end

function ENT:BeginBMBDeath(damageInfo)
    if CLIENT then return end
    if self.BMBDeathStarted then return end

    self.BMBDeathStarted = true

    local delay = self:GetBMBDeathRemoveDelay()
    local deathUntil = delay == false and 0 or CurTime() + delay

    self:StopBMBMovementOnDeath()

    if self.DeathKeepRed ~= false then
        self:SetNWFloat("BMBDeathUntil", deathUntil)
    else
        self:SetNWFloat("BMBDeathUntil", 0)
    end

    local attacker = damageInfo and damageInfo:GetAttacker() or self
    local inflictor = damageInfo and damageInfo:GetInflictor() or attacker
    hook.Run("OnNPCKilled", self, attacker, inflictor)

    if self.UseRagdollOnDeath then
        self:BecomeRagdoll(damageInfo)
        return
    end

    local corpse = self:CreateBMBPhysicsCorpse(damageInfo)
    if IsValid(corpse) then
        self:SetNoDraw(true)
        self:ScheduleBMBDeathCleanup(delay, corpse)
        return
    end

    self:ScheduleBMBDeathCleanup(delay)
end

function ENT:OnTakeDamage(damageInfo)
    if CLIENT or self.BMBDead then return end

    local damage = damageInfo:GetDamage()
    if damage <= 0 then return 0 end

    if self:IsBMBInDamageInvulnerability() then
        return 0 -- invulnerable
    end

    local now = CurTime()
    local wasFleeing = self:IsBMBFleeing()
    self.BMBDamageInvulnerableUntil = now + (self.DamageInvulnerabilityTime or 1.0)
    self:SetNWFloat("BMBInvulnerableUntil", self.BMBDamageInvulnerableUntil)
    self:StartBMBHurtFlash()
    if self.OnBMBHurtSound then
        self:OnBMBHurtSound(damageInfo)
    end

    self:SetHealth(self:Health() - damage)
    self:SetNWInt("BMBHealth", self:Health())

    if self:Health() <= 0 then
        self:OnKilled(damageInfo)
        return damage
    end

    self:OnInjured(damageInfo, { wasFleeing = wasFleeing })

    return damage
end

function ENT:OnKilled(damageInfo)
    if CLIENT then return end

    self:BeginBMBDeath(damageInfo)
end
