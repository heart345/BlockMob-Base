AddCSLuaFile()

ENT.Base = "bmb_base_mob"
ENT.Type = "nextbot"
ENT.PrintName = "BMB Spider"
ENT.Author = "Heart#"
ENT.Category = "BlockMob Base"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Model = "models/mcgm/spider/spider.mdl"
ENT.StartHealth = 60
ENT.RetaliateOnDamage = false
ENT.DeathRemoveDelay = 1.5
ENT.DeathTipDuration = 0.5
ENT.DeathTipDegrees = 90

ENT.WalkSpeed = 80
ENT.RunSpeed = 105
ENT.Acceleration = 360
ENT.Deceleration = 460
ENT.CollisionMins = Vector(-26, -26, 0)
ENT.CollisionMaxs = Vector(26, 26, 33)
ENT.MobSeparationRadiusScale = 1.1
ENT.MobSeparationApproachDistance = 28
ENT.MobSeparationMaxSpeed = 110

ENT.WanderDistanceMinCells = 3
ENT.WanderDistanceMaxCells = 9
ENT.WanderPauseMin = 2.5
ENT.WanderPauseMax = 6.5
ENT.WanderPathAttempts = 2
ENT.WanderFailurePauseMin = 0.5
ENT.WanderFailurePauseMax = 1.4
ENT.InitialIdleMin = 1.0
ENT.InitialIdleMax = 3.0

ENT.LookAtEyeHeight = 18
ENT.LookAtPitchLimit = 18
ENT.LookAroundPitchLimit = 10
ENT.LimbSwingMinAmount = 0.25
ENT.LimbSwingPhaseScale = 0.08
ENT.AnimationSequences = {
    idle = "idle",
    walk = "idle",
    run = "idle",
    jump = "idle"
}
ENT.SpiderLegSwingMax = 10
ENT.SpiderLegLiftMax = 3

if CLIENT then
    local zeroAngle = Angle(0, 0, 0)
    local zeroVector = Vector(0, 0, 0)
    local spiderBoneNames = {
        "root",
        "body0",
        "head",
        "body1",
        "leg0",
        "leg1",
        "leg2",
        "leg3",
        "leg4",
        "leg5",
        "leg6",
        "leg7"
    }
    local spiderLegNames = { "leg0", "leg1", "leg2", "leg3", "leg4", "leg5", "leg6", "leg7" }
    local spiderLegs = {
        { name = "leg0", side = 1, group = 0, waveIndex = 0 },
        { name = "leg1", side = -1, group = 1, waveIndex = 0 },
        { name = "leg2", side = 1, group = 1, waveIndex = 1 },
        { name = "leg3", side = -1, group = 0, waveIndex = 1 },
        { name = "leg4", side = 1, group = 0, waveIndex = 2 },
        { name = "leg5", side = -1, group = 1, waveIndex = 2 },
        { name = "leg6", side = 1, group = 1, waveIndex = 3 },
        { name = "leg7", side = -1, group = 0, waveIndex = 3 }
    }
    local spiderSoloLegNames = { "leg1", "leg0", "leg3", "leg2", "leg5", "leg4", "leg7", "leg6" }
    local legLiftOffsetDefaults = {
        leg2 = "20",
        leg3 = "20",
        leg4 = "-20",
        leg5 = "-20"
    }
    local legAnimationConVar = CreateClientConVar("bmb_spider_leg_animation", "1", true, false, "Enable procedural spider leg animation.")
    local legSoloConVar = CreateClientConVar("bmb_spider_leg_solo", "0", true, false, "Only animate one spider leg while debugging; 0 animates all, 1-8 use right/left pair order.")
    local legSwingConVar = CreateClientConVar("bmb_spider_leg_swing_max", "10", true, false, "Spider leg fore/aft swing amplitude.")
    local legLiftConVar = CreateClientConVar("bmb_spider_leg_lift_max", "3", true, false, "Spider leg lift rotation amplitude.")
    local legFrequencyConVar = CreateClientConVar("bmb_spider_leg_frequency", "1", true, false, "Spider leg gait frequency multiplier.")
    local legPhaseAConVar = CreateClientConVar("bmb_spider_leg_phase_a", "0", true, false, "Spider leg group A phase in radians.")
    local legPhaseBConVar = CreateClientConVar("bmb_spider_leg_phase_b", "3.1416", true, false, "Spider leg group B phase in radians.")
    local legPhaseStepConVar = CreateClientConVar("bmb_spider_leg_phase_step", "0.7854", true, false, "Spider front-to-back leg wave phase step in radians.")
    local legLiftPhaseConVar = CreateClientConVar("bmb_spider_leg_lift_phase", "0", true, false, "Spider lift phase offset relative to Minecraft's base formula.")
    local legSwingAxisConVar = CreateClientConVar("bmb_spider_leg_swing_axis", "2", true, false, "Spider swing axis: 0 pitch, 1 yaw, 2 roll.")
    local legLiftAxisConVar = CreateClientConVar("bmb_spider_leg_lift_axis", "1", true, false, "Spider lift axis: 0 pitch, 1 yaw, 2 roll.")
    local legAxisTestConVar = CreateClientConVar("bmb_spider_leg_axis_test", "0", true, false, "Static spider leg axis probe: 0 off, 1 pitch, 2 yaw, 3 roll.")
    local legAxisTestLegConVar = CreateClientConVar("bmb_spider_leg_axis_test_leg", "8", true, false, "Spider leg axis probe target in solo order, 1-8.")
    local legAxisTestAngleConVar = CreateClientConVar("bmb_spider_leg_axis_test_angle", "35", true, false, "Static spider leg axis probe angle.")
    local legPoseConVars = {}

    for _, leg in ipairs(spiderLegs) do
        local legName = leg.name
        legPoseConVars[legName] = {
            group = CreateClientConVar("bmb_spider_" .. legName .. "_group", tostring(leg.group), true, false, "Spider " .. legName .. " gait group: 0=A, 1=B."),
            swingOffset = CreateClientConVar("bmb_spider_" .. legName .. "_swing_offset", "0", true, false, "Spider " .. legName .. " static swing angle offset."),
            liftOffset = CreateClientConVar("bmb_spider_" .. legName .. "_lift_offset", legLiftOffsetDefaults[legName] or "0", true, false, "Spider " .. legName .. " static lift angle offset."),
            phaseOffset = CreateClientConVar("bmb_spider_" .. legName .. "_phase_offset", "0", true, false, "Spider " .. legName .. " gait phase offset in radians.")
        }
    end

    local function setBoneAngle(ent, boneId, angle)
        if not boneId then return end
        ent:ManipulateBoneAngles(boneId, angle or zeroAngle)
    end

    local function setBonePosition(ent, boneId, pos)
        if not boneId then return end
        ent:ManipulateBonePosition(boneId, pos or zeroVector)
    end

    local function resetSpiderBones(ent, bones)
        for _, boneName in ipairs(spiderBoneNames) do
            setBoneAngle(ent, bones[boneName], zeroAngle)
            setBonePosition(ent, bones[boneName], zeroVector)
        end
    end

    local function addAxisAngle(angle, axis, amount)
        axis = math.floor(tonumber(axis) or 1)

        if axis == 0 then
            angle.p = angle.p + amount
        elseif axis == 2 then
            angle.r = angle.r + amount
        else
            angle.y = angle.y + amount
        end

        return angle
    end

    local function updateAxisTest(ent, bones)
        local testAxis = legAxisTestConVar:GetInt()
        if testAxis <= 0 then return false end

        local soloIndex = math.Clamp(legAxisTestLegConVar:GetInt(), 1, #spiderSoloLegNames)
        local testLegName = spiderSoloLegNames[soloIndex]
        local angle = Angle(0, 0, 0)
        addAxisAngle(angle, testAxis - 1, legAxisTestAngleConVar:GetFloat())

        for _, legName in ipairs(spiderLegNames) do
            setBoneAngle(ent, bones[legName], legName == testLegName and angle or zeroAngle)
            setBonePosition(ent, bones[legName], zeroVector)
        end

        return true
    end

    function ENT:CacheBMBSpiderBones()
        local model = self:GetModel()
        if self.BMBSpiderBoneCache and self.BMBSpiderBoneCache.model == model then
            return self.BMBSpiderBoneCache
        end

        self.BMBSpiderBoneCache = {
            model = model,
            root = self:LookupBone("root"),
            body0 = self:LookupBone("body0"),
            head = self:LookupBone("head"),
            body1 = self:LookupBone("body1"),
            leg0 = self:LookupBone("leg0"),
            leg1 = self:LookupBone("leg1"),
            leg2 = self:LookupBone("leg2"),
            leg3 = self:LookupBone("leg3"),
            leg4 = self:LookupBone("leg4"),
            leg5 = self:LookupBone("leg5"),
            leg6 = self:LookupBone("leg6"),
            leg7 = self:LookupBone("leg7")
        }

        return self.BMBSpiderBoneCache
    end

    function ENT:UpdateBMBSpiderLegs(bones, speed)
        if updateAxisTest(self, bones) then return end

        if not legAnimationConVar:GetBool() then
            for _, legName in ipairs(spiderLegNames) do
                setBoneAngle(self, bones[legName], zeroAngle)
                setBonePosition(self, bones[legName], zeroVector)
            end

            return
        end

        local phase, swingAmount = self:UpdateBMBLimbSwing(speed)
        local gaitPhase = phase * legFrequencyConVar:GetFloat()
        local swingMax = legSwingConVar:GetFloat()
        local liftMax = legLiftConVar:GetFloat()
        local phaseA = legPhaseAConVar:GetFloat()
        local phaseB = legPhaseBConVar:GetFloat()
        local phaseStep = legPhaseStepConVar:GetFloat()
        local liftPhase = legLiftPhaseConVar:GetFloat()
        local swingAxis = legSwingAxisConVar:GetInt()
        local liftAxis = legLiftAxisConVar:GetInt()
        local soloLegName = spiderSoloLegNames[legSoloConVar:GetInt()]

        for _, leg in ipairs(spiderLegs) do
            local legName = leg.name
            if soloLegName and legName ~= soloLegName then
                setBoneAngle(self, bones[legName], zeroAngle)
                setBonePosition(self, bones[legName], zeroVector)
                continue
            end

            local convars = legPoseConVars[legName]
            local group = convars and convars.group:GetInt() or leg.group
            local wavePhase = (leg.waveIndex or 0) * phaseStep
            local phaseOffset = (group == 0 and phaseA or phaseB) + wavePhase + (convars and convars.phaseOffset:GetFloat() or 0)

            local swing = -math.cos(gaitPhase * 2 + phaseOffset) * swingMax * swingAmount * leg.side
            local lift = math.abs(math.sin(gaitPhase + phaseOffset + liftPhase)) * liftMax * swingAmount * leg.side
            if convars then
                swing = swing + convars.swingOffset:GetFloat()
                lift = lift + convars.liftOffset:GetFloat()
            end

            local angle = Angle(0, 0, 0)
            addAxisAngle(angle, swingAxis, swing)
            addAxisAngle(angle, liftAxis, lift)
            setBoneAngle(self, bones[legName], angle)
            setBonePosition(self, bones[legName], zeroVector)
        end
    end

    function ENT:UpdateBMBVisualBones()
        local bones = self:CacheBMBSpiderBones()
        if not bones then return end

        local state = self:GetNWString("BMBState", "idle")
        if state == "dead" or self:GetNWBool("BMBDead", false) then
            resetSpiderBones(self, bones)

            if bones.root then
                local startedAt = self:GetNWFloat("BMBStateStartedAt", CurTime())
                local duration = self.DeathTipDuration or 0.5
                local t = duration > 0 and math.Clamp((CurTime() - startedAt) / duration, 0, 1) or 1
                local tip = t * (self.DeathTipDegrees or 90)
                local tipSign = (self:EntIndex() % 2 == 0) and 1 or -1
                setBoneAngle(self, bones.root, Angle(0, tip * tipSign, 0))
            end

            return
        end

        setBoneAngle(self, bones.root, zeroAngle)
        setBonePosition(self, bones.root, zeroVector)
        setBoneAngle(self, bones.body0, zeroAngle)
        setBonePosition(self, bones.body0, zeroVector)
        setBoneAngle(self, bones.body1, zeroAngle)
        setBonePosition(self, bones.body1, zeroVector)

        if not self:UpdateBMBLookAtHeadPose(bones.head) then
            setBoneAngle(self, bones.head, zeroAngle)
            setBonePosition(self, bones.head, zeroVector)
        end

        self:UpdateBMBSpiderLegs(bones, self:GetVelocity():Length2D())
    end
end

function ENT:Initialize()
    if CLIENT then return end

    self:BaseInitialize()
    self:SetBMBState("idle")
    self.TargetEntity = nil
    self.BMBInitialIdleUntil = CurTime() + math.Rand(self.InitialIdleMin or 1.0, self.InitialIdleMax or 3.0)
end

function ENT:MaybePlayStep()
    -- Spider Phase 0 parks footsteps until spider-specific audio is packaged.
end

function ENT:RunBMBSpiderAI()
    self.TargetEntity = nil
    self:SetBMBState("wander")
    BMB.Behaviors.Wander.Run(self)
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
        else
            self.BMBDebugMoveActive = false
            self:RunBMBSpiderAI()
        end

        coroutine.yield()
    end
end
