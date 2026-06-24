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
ENT.RetaliateOnDamage = true
ENT.DeathRemoveDelay = 1.5
ENT.DeathTipDuration = 0.5
ENT.DeathTipDegrees = 90

ENT.WalkSpeed = 80
ENT.RunSpeed = 105
ENT.Acceleration = 360
ENT.Deceleration = 460
ENT.TargetRange = 820
ENT.TargetLoseRange = 1050
ENT.ChaseRepathInterval = 0.45
ENT.ChaseSegmentTimeout = 1.2
ENT.ChaseFailureRepathDelay = 0.06
ENT.ChasePreferDirect = true
ENT.ChaseDirectDuration = 0.24
ENT.ChaseDirectMaxDistanceCells = 5
ENT.ChaseDirectProbeCells = 4
ENT.AttackRange = 54
ENT.AttackVerticalRange = 26
ENT.AttackVerticalOverlapRange = 58
ENT.AttackVerticalOverlapFlatRange = 22
ENT.AttackDamage = 6
ENT.AttackCooldown = 0.9
ENT.AttackHitDelay = 0
ENT.AttackMoveSpeed = 105
ENT.AttackHitSlop = 14
ENT.AttackKnockback = 120
ENT.AttackVerticalKnockback = 95
ENT.AttackGroundedVerticalKnockback = 130
ENT.LeapEnabled = true
ENT.LeapIgnoreCliff = true
ENT.LeapMinDistanceCells = 1.35
ENT.LeapMaxDistanceCells = 4.0
ENT.LeapMaxUpCells = 0.35
ENT.LeapMaxDownCells = 1.4
ENT.LeapTargetStopDistance = 18
ENT.LeapHorizontalSpeed = 290
ENT.LeapVerticalSpeed = 210
ENT.LeapChance = 0.65
ENT.LeapAttemptInterval = 0.3
ENT.LeapCooldownMin = 1.2
ENT.LeapCooldownMax = 2.4
ENT.LeapCommitTime = 0.28
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
ENT.SpiderClimbSpikeEnabled = true
ENT.SpiderClimbSpeed = 82
ENT.SpiderClimbProbeDistance = 42
ENT.SpiderClimbWallClearance = 30
ENT.SpiderClimbMantleForward = 46
ENT.SpiderClimbMantleUp = 44
ENT.SpiderClimbMantleDown = 90
ENT.SpiderClimbMantleStartBelow = 3
ENT.SpiderClimbMantleSpeed = 58
ENT.SpiderClimbTimeout = 7
ENT.SpiderClimbBlockedHoldTime = 3
ENT.SpiderClimbDescendSpeed = 78
ENT.SpiderClimbDescendTimeout = 6
ENT.SpiderClimbGiveUpCooldown = 4
ENT.SpiderClimbMaxWallNormalZ = 0.25

if SERVER then
    local function createSpiderConVar(name, default, description)
        if not GetConVar(name) then
            CreateConVar(name, default, FCVAR_ARCHIVE, description)
        end
    end

    createSpiderConVar("bmb_spider_climb_spike", "1", "Enable the Phase 1 spider SetPos wall-climb spike.")
    createSpiderConVar("bmb_spider_climb_speed", "82", "Spider climb spike upward speed.")
    createSpiderConVar("bmb_spider_climb_probe_distance", "42", "Spider climb spike forward wall probe distance.")
    createSpiderConVar("bmb_spider_climb_wall_clearance", "30", "Spider climb spike origin clearance from the wall plane.")
    createSpiderConVar("bmb_spider_climb_mantle_forward", "46", "Spider climb spike forward distance used when stepping onto the top.")
    createSpiderConVar("bmb_spider_climb_mantle_up", "44", "Spider climb spike upward top-search distance.")
    createSpiderConVar("bmb_spider_climb_mantle_down", "90", "Spider climb spike downward top-search distance.")
    createSpiderConVar("bmb_spider_climb_mantle_start_below", "3", "How close to the top ledge the spider must climb before mantling.")
    createSpiderConVar("bmb_spider_climb_mantle_speed", "58", "Spider smooth mantle speed after it reaches the ledge.")
    createSpiderConVar("bmb_spider_climb_timeout", "7", "Spider climb spike timeout in seconds.")
    createSpiderConVar("bmb_spider_climb_blocked_hold_time", "3", "How long the spider clings to a blocked ledge before giving up.")
    createSpiderConVar("bmb_spider_climb_descend_speed", "78", "Spider downward speed when giving up a blocked climb.")
    createSpiderConVar("bmb_spider_climb_descend_timeout", "6", "Maximum time spent descending after a blocked climb.")
    createSpiderConVar("bmb_spider_climb_giveup_cooldown", "4", "Cooldown after a blocked climb gives up so the spider wanders elsewhere.")
    createSpiderConVar("bmb_debug_spider_climb", "0", "Print spider climb spike diagnostics.")
end

local function spiderConVarBool(name, fallback)
    local convar = GetConVar and GetConVar(name)
    if not convar then return fallback end
    return convar:GetBool()
end

local function spiderConVarFloat(name, fallback)
    local convar = GetConVar and GetConVar(name)
    if not convar then return fallback end
    return convar:GetFloat()
end

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

function ENT:IsBMBSpiderClimbSpikeEnabled()
    return self.SpiderClimbSpikeEnabled ~= false
        and spiderConVarBool("bmb_spider_climb_spike", true)
end

function ENT:GetBMBSpiderClimbSpeed()
    return spiderConVarFloat("bmb_spider_climb_speed", self.SpiderClimbSpeed or 82)
end

function ENT:GetBMBSpiderClimbProbeDistance()
    return spiderConVarFloat("bmb_spider_climb_probe_distance", self.SpiderClimbProbeDistance or 42)
end

function ENT:GetBMBSpiderBodyRadius()
    return math.max(
        math.abs(self.CollisionMins.x or 0),
        math.abs(self.CollisionMaxs.x or 0),
        math.abs(self.CollisionMins.y or 0),
        math.abs(self.CollisionMaxs.y or 0)
    )
end

function ENT:GetBMBSpiderClimbWallClearance()
    local radius = self:GetBMBSpiderBodyRadius()

    return math.max(radius + 3, spiderConVarFloat("bmb_spider_climb_wall_clearance", self.SpiderClimbWallClearance or 30))
end

function ENT:GetBMBSpiderClimbMantleForward()
    return spiderConVarFloat("bmb_spider_climb_mantle_forward", self.SpiderClimbMantleForward or 46)
end

function ENT:GetBMBSpiderClimbMantleUp()
    return spiderConVarFloat("bmb_spider_climb_mantle_up", self.SpiderClimbMantleUp or 44)
end

function ENT:GetBMBSpiderClimbMantleDown()
    return spiderConVarFloat("bmb_spider_climb_mantle_down", self.SpiderClimbMantleDown or 90)
end

function ENT:GetBMBSpiderClimbMantleStartBelow()
    return spiderConVarFloat("bmb_spider_climb_mantle_start_below", self.SpiderClimbMantleStartBelow or 3)
end

function ENT:GetBMBSpiderClimbMantleSpeed()
    return spiderConVarFloat("bmb_spider_climb_mantle_speed", self.SpiderClimbMantleSpeed or 58)
end

function ENT:GetBMBSpiderClimbTimeout()
    return spiderConVarFloat("bmb_spider_climb_timeout", self.SpiderClimbTimeout or 7)
end

function ENT:GetBMBSpiderClimbBlockedHoldTime()
    return spiderConVarFloat("bmb_spider_climb_blocked_hold_time", self.SpiderClimbBlockedHoldTime or 3)
end

function ENT:GetBMBSpiderClimbDescendSpeed()
    return spiderConVarFloat("bmb_spider_climb_descend_speed", self.SpiderClimbDescendSpeed or 78)
end

function ENT:GetBMBSpiderClimbDescendTimeout()
    return spiderConVarFloat("bmb_spider_climb_descend_timeout", self.SpiderClimbDescendTimeout or 6)
end

function ENT:GetBMBSpiderClimbGiveUpCooldown()
    return spiderConVarFloat("bmb_spider_climb_giveup_cooldown", self.SpiderClimbGiveUpCooldown or 4)
end

function ENT:DebugBMBSpiderClimb(message)
    if not spiderConVarBool("bmb_debug_spider_climb", false) then return end
    print("[BMB spider climb] " .. tostring(message))
end

function ENT:BeginBMBSpiderClimbMoveTypeOverride()
    if not self.GetMoveType or not self.SetMoveType or MOVETYPE_NONE == nil then return end

    if self.BMBSpiderSavedMoveType == nil then
        self.BMBSpiderSavedMoveType = self:GetMoveType()
    end

    if self.loco and self.loco.GetGravity and self.loco.SetGravity and self.BMBSpiderSavedGravity == nil then
        self.BMBSpiderSavedGravity = self.loco:GetGravity()
        self.loco:SetGravity(0)
    end

    self:SetMoveType(MOVETYPE_NONE)
end

function ENT:RestoreBMBSpiderClimbMoveTypeOverride()
    if self.BMBSpiderSavedGravity ~= nil and self.loco and self.loco.SetGravity then
        self.loco:SetGravity(self.BMBSpiderSavedGravity)
    end

    self.BMBSpiderSavedGravity = nil

    if self.BMBSpiderSavedMoveType == nil then return end

    if self.SetMoveType then
        self:SetMoveType(self.BMBSpiderSavedMoveType)
    end

    self.BMBSpiderSavedMoveType = nil
end

function ENT:GetBMBSpiderClimbTraceFilter()
    return function(ent)
        return self:ShouldSafetyTraceHit(ent)
    end
end

function ENT:GetBMBSpiderFlatWallNormal(trace)
    if not trace or not trace.Hit then return nil end
    if math.abs(trace.HitNormal.z or 0) > (self.SpiderClimbMaxWallNormalZ or 0.25) then return nil end

    local normal = Vector(trace.HitNormal.x, trace.HitNormal.y, 0)
    if normal:LengthSqr() <= 0.0001 then return nil end
    normal:Normalize()

    return normal
end

function ENT:IsBMBSpiderClimbWallHit(trace, wallNormal)
    if not trace or not trace.Hit or not wallNormal then return false end

    local hitNormal = self:GetBMBSpiderFlatWallNormal(trace)
    if not hitNormal then return false end

    return hitNormal:Dot(wallNormal) > 0.9
end

function ENT:TraceBMBSpiderClimbWall(pos, normal)
    local sampleHeight = math.Clamp((self.CollisionMaxs.z or 33) * 0.5, 10, math.max(10, (self.CollisionMaxs.z or 33) - 2))
    local sample = pos + Vector(0, 0, sampleHeight)
    local probe = self:GetBMBSpiderClimbProbeDistance()

    return util.TraceLine({
        start = sample + normal * 8,
        endpos = sample - normal * (probe + 8),
        filter = self:GetBMBSpiderClimbTraceFilter(),
        mask = MASK_SOLID
    })
end

function ENT:FindBMBSpiderClimbWall(target)
    if not self:IsBMBSpiderClimbSpikeEnabled() then return nil end
    if CurTime() < (self.BMBSpiderClimbCooldownUntil or 0) then return nil end

    local current = self:GetPos()
    local targetDirection
    if target then
        targetDirection = Vector(target.x - current.x, target.y - current.y, 0)
        if targetDirection:LengthSqr() > 0.0001 then
            targetDirection:Normalize()
        else
            targetDirection = nil
        end
    end

    local forward = self:GetForward()
    forward.z = 0
    if forward:LengthSqr() <= 0.0001 then return nil end
    forward:Normalize()

    local right = self:GetRight()
    right.z = 0
    if right:LengthSqr() <= 0.0001 then
        right = Vector(-forward.y, forward.x, 0)
    else
        right:Normalize()
    end

    local directions = {}
    local function addDirection(direction)
        if not direction or direction:LengthSqr() <= 0.0001 then return end

        local flat = Vector(direction.x, direction.y, 0)
        if flat:LengthSqr() <= 0.0001 then return end
        flat:Normalize()

        for _, existing in ipairs(directions) do
            if existing:Dot(flat) > 0.98 then return end
        end

        table.insert(directions, flat)
    end

    addDirection(targetDirection)
    addDirection(self:GetVelocity())
    addDirection(forward)
    addDirection(forward + right)
    addDirection(forward - right)
    addDirection(right)
    addDirection(-right)
    addDirection(-forward)
    addDirection(-forward + right)
    addDirection(-forward - right)

    local sampleHeight = math.Clamp((self.CollisionMaxs.z or 33) * 0.45, 10, math.max(10, (self.CollisionMaxs.z or 33) - 2))
    local start = current + Vector(0, 0, sampleHeight)
    local scanDistance = self:GetBMBSpiderClimbProbeDistance() + self:GetBMBSpiderBodyRadius()
    local bestNormal
    local bestTrace
    local bestScore = -math.huge

    for _, direction in ipairs(directions) do
        if direction:LengthSqr() > 0.0001 then
            local trace = util.TraceLine({
                start = start,
                endpos = start + direction * scanDistance,
                filter = self:GetBMBSpiderClimbTraceFilter(),
                mask = MASK_SOLID
            })

            local normal = self:GetBMBSpiderFlatWallNormal(trace)
            if normal then
                local targetScore = targetDirection and math.max(0, direction:Dot(targetDirection)) or 0
                local score = targetScore * 2 + (1 - trace.Fraction)

                if score > bestScore then
                    bestScore = score
                    bestNormal = normal
                    bestTrace = trace
                end
            end
        end
    end

    if not bestNormal then
        local clearanceScanDistance = self:GetBMBSpiderClimbProbeDistance() + self:GetBMBSpiderClimbWallClearance()

        for _, direction in ipairs(directions) do
            if direction:LengthSqr() > 0.0001 then
                local trace = util.TraceLine({
                    start = start,
                    endpos = start + direction * clearanceScanDistance,
                    filter = self:GetBMBSpiderClimbTraceFilter(),
                    mask = MASK_SOLID
                })

                local normal = self:GetBMBSpiderFlatWallNormal(trace)
                if normal then
                    local targetScore = targetDirection and math.max(0, direction:Dot(targetDirection)) or 0
                    local score = targetScore * 2 + (1 - trace.Fraction)

                    if score > bestScore then
                        bestScore = score
                        bestNormal = normal
                        bestTrace = trace
                    end
                end
            end
        end
    end

    if bestNormal and spiderConVarBool("bmb_debug_spider_climb", false) then
        print(string.format(
            "[BMB spider climb] wall scan reason hit fraction=%.2f normal=%s",
            bestTrace and bestTrace.Fraction or -1,
            tostring(bestNormal)
        ))
    end

    return bestNormal, bestTrace
end

function ENT:GetBMBSpiderClimbPinnedPosition(pos, normal)
    local trace = self:TraceBMBSpiderClimbWall(pos, normal)
    local wallNormal = self:GetBMBSpiderFlatWallNormal(trace)
    if not wallNormal then return nil end

    local surface = trace.HitPos
    local clearance = self:GetBMBSpiderClimbWallClearance()

    return Vector(
        surface.x + wallNormal.x * clearance,
        surface.y + wallNormal.y * clearance,
        pos.z
    ), wallNormal
end

function ENT:CanBMBSpiderMoveHull(fromPos, toPos, wallNormal)
    local trace = util.TraceHull({
        start = fromPos,
        endpos = toPos,
        mins = self.CollisionMins,
        maxs = self.CollisionMaxs,
        filter = self:GetBMBSpiderClimbTraceFilter(),
        mask = MASK_SOLID
    })

    if trace.StartSolid then
        local endTrace = util.TraceHull({
            start = toPos,
            endpos = toPos,
            mins = self.CollisionMins,
            maxs = self.CollisionMaxs,
            filter = self:GetBMBSpiderClimbTraceFilter(),
            mask = MASK_SOLID
        })

        return not endTrace.StartSolid, endTrace
    end

    if trace.Hit and trace.Fraction < 0.98 and not self:IsBMBSpiderClimbWallHit(trace, wallNormal) then
        return false, trace
    end

    return true, trace
end

function ENT:IsBMBSpiderLandingClear(pos)
    if self.IsBMBHullClearAtPosition and not self:IsBMBHullClearAtPosition(pos) then
        return false
    end

    local trace = util.TraceHull({
        start = pos,
        endpos = pos,
        mins = self.CollisionMins,
        maxs = self.CollisionMaxs,
        filter = self:GetBMBSpiderClimbTraceFilter(),
        mask = MASK_SOLID
    })

    return not trace.StartSolid
end

function ENT:FindBMBSpiderClimbMantle(normal, climbPos)
    local intoWall = Vector(-normal.x, -normal.y, 0)
    if intoWall:LengthSqr() <= 0.0001 then return nil end
    intoWall:Normalize()

    local current = climbPos or self:GetPos()
    local probeCenter = current + intoWall * self:GetBMBSpiderClimbMantleForward()
    local groundTrace = util.TraceHull({
        start = probeCenter + Vector(0, 0, self:GetBMBSpiderClimbMantleUp()),
        endpos = probeCenter - Vector(0, 0, self:GetBMBSpiderClimbMantleDown()),
        mins = Vector(self.CollisionMins.x * 0.65, self.CollisionMins.y * 0.65, 0),
        maxs = Vector(self.CollisionMaxs.x * 0.65, self.CollisionMaxs.y * 0.65, 4),
        filter = self:GetBMBSpiderClimbTraceFilter(),
        mask = MASK_SOLID
    })

    if not groundTrace.Hit or groundTrace.HitNormal.z < 0.65 then return nil end

    local minTopZ = (self.BMBSpiderClimbStartZ or current.z) + self:GetBMBBlockSize() * 0.45
    if groundTrace.HitPos.z < minTopZ then return nil end

    local landing = Vector(probeCenter.x, probeCenter.y, groundTrace.HitPos.z + 2)

    return {
        landing = landing,
        topZ = groundTrace.HitPos.z,
        clear = self:IsBMBSpiderLandingClear(landing)
    }
end

function ENT:CanBMBSpiderMantleMoveHull(fromPos, toPos)
    local trace = util.TraceHull({
        start = fromPos,
        endpos = toPos,
        mins = self.CollisionMins,
        maxs = self.CollisionMaxs,
        filter = self:GetBMBSpiderClimbTraceFilter(),
        mask = MASK_SOLID
    })

    if trace.StartSolid then return false, trace end
    if trace.Hit and trace.Fraction < 0.98 then return false, trace end

    return true, trace
end

function ENT:GetBMBSpiderGroundTraceAt(pos, depth)
    return util.TraceHull({
        start = pos + Vector(0, 0, 4),
        endpos = pos - Vector(0, 0, depth or 10),
        mins = Vector(self.CollisionMins.x * 0.75, self.CollisionMins.y * 0.75, 0),
        maxs = Vector(self.CollisionMaxs.x * 0.75, self.CollisionMaxs.y * 0.75, 4),
        filter = self:GetBMBSpiderClimbTraceFilter(),
        mask = MASK_SOLID
    })
end

function ENT:TryFinishBMBSpiderDescendOnGround(pos)
    local groundTrace = self:GetBMBSpiderGroundTraceAt(pos, 12)
    if not groundTrace.Hit or groundTrace.HitNormal.z < 0.65 then return false end

    local landing = Vector(pos.x, pos.y, groundTrace.HitPos.z + 2)
    if not self:IsBMBSpiderLandingClear(landing) then return false end

    self:SetPos(landing)
    self.BMBSpiderClimbLastPinnedPos = landing
    self.BMBSpiderClimbGoalZ = landing.z
    return true
end

function ENT:RunBMBSpiderClimbDescend(normal, startPos, reason)
    local current = startPos or self:GetPos()
    local speed = math.max(12, self:GetBMBSpiderClimbDescendSpeed())
    local deadline = CurTime() + math.max(0.5, self:GetBMBSpiderClimbDescendTimeout())
    local lastTime = CurTime()
    local nextDescendLog = CurTime() + 0.5

    self:DebugBMBSpiderClimb("descend start reason=" .. tostring(reason))
    self:SetBMBState("climb_spike")
    self:SetBMBMoveMode("climb_descend")

    while CurTime() < deadline do
        if self.BMBDead or self.BMBHeld or self.BMBMoveInterrupt then return false, "interrupted" end
        if self.IsBMBKnockbackActive and self:IsBMBKnockbackActive() then return false, "knockback" end
        if self.IsBMBFreezeEnabled and self:IsBMBFreezeEnabled() then return false, "frozen" end

        if self:TryFinishBMBSpiderDescendOnGround(current) then
            self:DebugBMBSpiderClimb("descend ground")
            return true
        end

        local now = CurTime()
        local dt = math.Clamp(now - lastTime, 0.015, 0.08)
        lastTime = now

        local desired = current - Vector(0, 0, speed * dt)
        local pinned, updatedNormal = self:GetBMBSpiderClimbPinnedPosition(desired, normal)
        if not pinned then
            self:SetPos(current)
            self:DebugBMBSpiderClimb("descend lost_wall")
            return true
        end

        normal = updatedNormal or normal
        local clear, trace = self:CanBMBSpiderMoveHull(current, pinned, normal)
        if not clear then
            self:DebugBMBSpiderClimb("descend blocked normal=" .. tostring(trace and trace.HitNormal or "nil"))
            return false, "descend_blocked"
        end

        current = pinned
        self.BMBSpiderClimbLastPinnedPos = current
        self.BMBSpiderClimbGoalZ = current.z
        self:SetPos(current)
        self:SetBMBState("climb_spike")
        self:SetBMBMoveMode("climb_descend")
        self:UpdateBMBApproachDebug(current - Vector(0, 0, self:GetBMBBlockSize()), 0)

        if self.loco then
            if self.loco.SetDesiredSpeed then self.loco:SetDesiredSpeed(0) end
            if self.loco.SetVelocity then self.loco:SetVelocity(Vector(0, 0, 0)) end
            if self.loco.FaceTowards then self.loco:FaceTowards(current - normal * 64) end
        end

        if CurTime() >= nextDescendLog then
            self:DebugBMBSpiderClimb("descend z=" .. tostring(math.Round(current.z, 1)))
            nextDescendLog = CurTime() + 0.5
        end

        coroutine.wait(0.02)
    end

    self:SetPos(current)
    self:DebugBMBSpiderClimb("descend timeout")
    return true
end

function ENT:GetBMBSpiderClimbHoldKey(reason)
    if reason == "mantle_blocked" or reason == "mantle_timeout" or reason == "top_blocked" then
        return "blocked_ledge"
    end

    return tostring(reason)
end

function ENT:HoldBMBSpiderClimbWall(pos, normal, reason)
    local now = CurTime()
    local holdKey = self:GetBMBSpiderClimbHoldKey(reason)
    if self.BMBSpiderClimbHoldReason ~= holdKey then
        self.BMBSpiderClimbHoldReason = holdKey
        self.BMBSpiderClimbHoldStartedAt = now
    end

    self.BMBSpiderClimbGoalZ = pos.z
    self.BMBSpiderClimbLastPinnedPos = pos
    self:SetPos(pos)
    self:SetBMBState("climb_spike")
    self:SetBMBMoveMode("climb_spike")
    self:UpdateBMBApproachDebug(pos + Vector(0, 0, self:GetBMBBlockSize()), 0)

    if self.loco then
        if self.loco.SetDesiredSpeed then self.loco:SetDesiredSpeed(0) end
        if self.loco.SetVelocity then self.loco:SetVelocity(Vector(0, 0, 0)) end
        if self.loco.FaceTowards and normal then self.loco:FaceTowards(pos - normal * 64) end
    end

    if CurTime() >= (self.BMBSpiderClimbNextHoldLog or 0) then
        print(string.format(
            "[BMB spider climb] hold %s %.1f/%.1f",
            tostring(reason),
            now - (self.BMBSpiderClimbHoldStartedAt or now),
            self:GetBMBSpiderClimbBlockedHoldTime()
        ))
        self.BMBSpiderClimbNextHoldLog = CurTime() + 1.0
    end
end

function ENT:ShouldGiveUpBMBSpiderClimbHold(reason)
    if self.BMBSpiderClimbHoldReason ~= self:GetBMBSpiderClimbHoldKey(reason) then return false end
    return CurTime() - (self.BMBSpiderClimbHoldStartedAt or CurTime()) >= math.max(0.1, self:GetBMBSpiderClimbBlockedHoldTime())
end

function ENT:HandleBMBSpiderClimbHold(pos, normal, reason)
    self:HoldBMBSpiderClimbWall(pos, normal, reason)
    if not self:ShouldGiveUpBMBSpiderClimbHold(reason) then return false end

    local descended, descendReason = self:RunBMBSpiderClimbDescend(normal, pos, reason)
    if not descended and (descendReason == "interrupted" or descendReason == "knockback" or descendReason == "frozen") then
        self:FinishBMBSpiderClimbSpike(descendReason)
        return true
    end

    self:FinishBMBSpiderClimbSpike("giveup")
    return true
end

function ENT:RunBMBSpiderClimbMantle(normal, fromPos, landing)
    local speed = math.max(12, self:GetBMBSpiderClimbMantleSpeed())
    local current = fromPos or self:GetPos()
    local stage = 1
    local ledge = Vector(current.x, current.y, landing.z)
    local pathDistance = current:Distance(ledge) + ledge:Distance(landing)
    local deadline = CurTime() + math.max(0.35, pathDistance / speed + 0.8)
    local lastTime = CurTime()
    local nextMantleLog = CurTime() + 0.25

    self:SetBMBMoveMode("climb_mantle")
    self:SetBMBState("climb_spike")
    self:DebugBMBSpiderClimb(string.format(
        "mantle start from=%s ledge=%s landing=%s dist=%.1f deadline=%.2f",
        tostring(current),
        tostring(ledge),
        tostring(landing),
        current:Distance(landing),
        deadline - CurTime()
    ))

    while CurTime() < deadline do
        if self.BMBDead or self.BMBHeld or self.BMBMoveInterrupt then return false, "interrupted" end
        if self.IsBMBKnockbackActive and self:IsBMBKnockbackActive() then return false, "knockback" end
        if self.IsBMBFreezeEnabled and self:IsBMBFreezeEnabled() then return false, "frozen" end

        local now = CurTime()
        local dt = math.Clamp(now - lastTime, 0.015, 0.08)
        lastTime = now

        local target = stage == 1 and ledge or landing
        local delta = target - current
        local distance = delta:Length()
        if CurTime() >= nextMantleLog then
            self:DebugBMBSpiderClimb(string.format(
                "mantle progress stage=%d pos=%s target=%s dist=%.1f timeleft=%.2f",
                stage,
                tostring(current),
                tostring(target),
                distance,
                deadline - CurTime()
            ))
            nextMantleLog = CurTime() + 0.35
        end

        if distance <= 1.5 then
            if stage == 1 then
                current = ledge
                stage = 2
                self:SetPos(current)
                self.BMBSpiderClimbLastPinnedPos = current
                self.BMBSpiderClimbGoalZ = current.z
                coroutine.wait(0.02)
                continue
            else
                self:SetPos(landing)
                self.BMBSpiderClimbLastPinnedPos = landing
                self.BMBSpiderClimbGoalZ = landing.z
                self:DebugBMBSpiderClimb("mantle success")
                return true
            end
        end

        local step = math.min(distance, speed * dt)
        local nextPos = current + delta:GetNormalized() * step
        local clear
        local trace
        if stage == 1 then
            clear, trace = self:CanBMBSpiderMoveHull(current, nextPos, normal)
        else
            clear, trace = self:CanBMBSpiderMantleMoveHull(current, nextPos)
        end

        if not clear then
            self:DebugBMBSpiderClimb(string.format(
                "mantle blocked stage=%d pos=%s next=%s hit=%s startsolid=%s fraction=%.2f",
                stage,
                tostring(current),
                tostring(nextPos),
                tostring(trace and trace.HitNormal or "nil"),
                tostring(trace and trace.StartSolid or false),
                trace and trace.Fraction or -1
            ))

            return false, "mantle_blocked"
        end

        current = nextPos
        self.BMBSpiderClimbLastPinnedPos = current
        self.BMBSpiderClimbGoalZ = current.z
        self:SetPos(current)
        self:SetBMBState("climb_spike")
        self:SetBMBMoveMode("climb_mantle")
        self:UpdateBMBApproachDebug(target, 0)

        if current:Distance(target) <= 1.5 then
            if stage == 1 then
                current = ledge
                stage = 2
                self:SetPos(current)
                self.BMBSpiderClimbLastPinnedPos = current
                self.BMBSpiderClimbGoalZ = current.z
                coroutine.wait(0.02)
                continue
            else
                self:SetPos(landing)
                self.BMBSpiderClimbLastPinnedPos = landing
                self.BMBSpiderClimbGoalZ = landing.z
                self:DebugBMBSpiderClimb("mantle success after move")
                return true
            end
        end

        if self.loco then
            if self.loco.SetDesiredSpeed then self.loco:SetDesiredSpeed(0) end
            if self.loco.SetVelocity then self.loco:SetVelocity(Vector(0, 0, 0)) end
            if self.loco.FaceTowards then self.loco:FaceTowards(current - normal * 64) end
        end

        coroutine.wait(0.02)
    end

    local finalTarget = stage == 1 and ledge or landing
    if current:Distance(finalTarget) <= 1.5 then
        if stage == 1 then
            current = ledge
            stage = 2
        else
            self:SetPos(landing)
            self.BMBSpiderClimbLastPinnedPos = landing
            self.BMBSpiderClimbGoalZ = landing.z
            self:DebugBMBSpiderClimb("mantle success after deadline")
            return true
        end
    end

    self:DebugBMBSpiderClimb(string.format(
        "mantle timeout stage=%d pos=%s landing=%s remain=%.1f",
        stage,
        tostring(current),
        tostring(landing),
        current:Distance(stage == 1 and ledge or landing)
    ))
    return false, "mantle_timeout"
end

function ENT:FinishBMBSpiderClimbSpike(result)
    self.BMBSpiderClimbing = false
    self.BMBSpiderClimbStartZ = nil
    self.BMBSpiderClimbGoalZ = nil
    self.BMBSpiderClimbLastPinnedPos = nil
    self.BMBSpiderClimbNextHoldLog = nil
    self.BMBSpiderClimbNextMantleCandidateLog = nil
    self.BMBSpiderClimbHoldReason = nil
    self.BMBSpiderClimbHoldStartedAt = nil

    local cooldown = 0.8
    if result == "success" then
        cooldown = 0.2
    elseif result == "giveup" then
        cooldown = math.max(0.8, self:GetBMBSpiderClimbGiveUpCooldown())
    end

    self.BMBSpiderClimbCooldownUntil = CurTime() + cooldown
    self:RestoreBMBSpiderClimbMoveTypeOverride()
    self:RestoreBMBStepHeight()
    self:SetBMBMoveMode("idle")
    self:UpdateBMBApproachDebug(nil, 0)
    print("[BMB spider climb] finish " .. tostring(result))
    self:DebugBMBSpiderClimb(result)
end

function ENT:RunBMBSpiderClimbSpike(target)
    if self.BMBSpiderClimbing then return false end

    local normal = self:FindBMBSpiderClimbWall(target)
    if not normal then return false end

    local startPos = self:GetPos()
    self.BMBSpiderClimbing = true
    self.BMBSpiderClimbStartZ = startPos.z
    self.BMBSpiderClimbGoalZ = startPos.z
    self.BMBSpiderClimbLastPinnedPos = startPos
    self:ClearBMBMovementInterrupt()
    if self.ClearBMBDebugMove then
        self:ClearBMBDebugMove()
    end
    print("[BMB spider climb] start normal=" .. tostring(normal))
    self:SetBMBState("climb_spike")
    self:SetBMBMoveMode("climb_spike")
    self:MaintainBMBMoveSpeed(0, 0)
    self:BeginBMBSpiderClimbMoveTypeOverride()

    local deadline = CurTime() + math.max(0.5, self:GetBMBSpiderClimbTimeout())
    local lastTime = CurTime()
    local nextProgressLog = CurTime() + 0.5
    local function tryStartMantle(climbPos)
        local mantle = self:FindBMBSpiderClimbMantle(normal, climbPos)
        if not mantle then return false, "none" end
        if climbPos.z < mantle.topZ - self:GetBMBSpiderClimbMantleStartBelow() then
            return false, "not_ready", mantle
        end

        if not mantle.clear then return false, "mantle_blocked", mantle end

        return self:RunBMBSpiderClimbMantle(normal, climbPos, mantle.landing)
    end

    while CurTime() < deadline do
        if self.BMBDead or self.BMBHeld or self.BMBMoveInterrupt then
            self:FinishBMBSpiderClimbSpike("interrupted")
            return true
        end

        if self.IsBMBKnockbackActive and self:IsBMBKnockbackActive() then
            self:FinishBMBSpiderClimbSpike("knockback")
            return true
        end

        if self.IsBMBFreezeEnabled and self:IsBMBFreezeEnabled() then
            self:FinishBMBSpiderClimbSpike("frozen")
            return true
        end

        local climbPos = self.BMBSpiderClimbLastPinnedPos or self:GetPos()
        local mantled, mantleReason = tryStartMantle(climbPos)
        if mantled then
            self:FinishBMBSpiderClimbSpike("success")
            return true
        elseif mantleReason == "interrupted" or mantleReason == "knockback" or mantleReason == "frozen" then
            self:FinishBMBSpiderClimbSpike(mantleReason)
            return true
        elseif mantleReason == "mantle_blocked" or mantleReason == "mantle_timeout" then
            if self:HandleBMBSpiderClimbHold(climbPos, normal, mantleReason) then return true end
            deadline = CurTime() + math.max(0.5, self:GetBMBSpiderClimbTimeout())
            coroutine.wait(0.05)
            continue
        end

        local now = CurTime()
        local dt = math.Clamp(now - lastTime, 0.015, 0.08)
        lastTime = now

        self.BMBSpiderClimbGoalZ = (self.BMBSpiderClimbGoalZ or climbPos.z) + self:GetBMBSpiderClimbSpeed() * dt

        local current = self:GetPos()
        local planned = self.BMBSpiderClimbLastPinnedPos or current
        local desired = Vector(planned.x, planned.y, self.BMBSpiderClimbGoalZ)
        local pinned, updatedNormal = self:GetBMBSpiderClimbPinnedPosition(desired, normal)

        if not pinned then
            local plannedMantled, plannedMantleReason, plannedMantle = tryStartMantle(planned)
            if plannedMantled then
                self:FinishBMBSpiderClimbSpike("success")
                return true
            elseif plannedMantleReason == "interrupted" or plannedMantleReason == "knockback" or plannedMantleReason == "frozen" then
                self:FinishBMBSpiderClimbSpike(plannedMantleReason)
                return true
            elseif plannedMantleReason == "mantle_blocked" or plannedMantleReason == "mantle_timeout" then
                if self:HandleBMBSpiderClimbHold(planned, normal, plannedMantleReason) then return true end
                deadline = CurTime() + math.max(0.5, self:GetBMBSpiderClimbTimeout())
                coroutine.wait(0.05)
                continue
            elseif plannedMantleReason == "not_ready" and plannedMantle then
                local ledgeZ = math.min(desired.z, plannedMantle.topZ - self:GetBMBSpiderClimbMantleStartBelow())
                local ledgePos = Vector(planned.x, planned.y, math.max(planned.z, ledgeZ))
                self.BMBSpiderClimbGoalZ = ledgePos.z
                self.BMBSpiderClimbLastPinnedPos = ledgePos
                self:SetPos(ledgePos)
                self:SetBMBState("climb_spike")
                self:SetBMBMoveMode("climb_spike")
                self:UpdateBMBApproachDebug(plannedMantle.landing, 0)
                coroutine.wait(0.02)
                continue
            end

            self:FinishBMBSpiderClimbSpike("lost_wall")
            return true
        end

        normal = updatedNormal or normal
        if self.loco then
            if self.loco.SetDesiredSpeed then self.loco:SetDesiredSpeed(0) end
            if self.loco.SetVelocity then self.loco:SetVelocity(Vector(0, 0, 0)) end
            if self.loco.FaceTowards then self.loco:FaceTowards(self:GetPos() - normal * 64) end
        end

        local clear, trace = self:CanBMBSpiderMoveHull(planned, pinned, normal)
        if not clear then
            local hitNormal = trace and trace.HitNormal
            if hitNormal and math.abs(hitNormal.z or 0) > 0.35 then
                if self:HandleBMBSpiderClimbHold(planned, normal, "top_blocked") then return true end
                deadline = CurTime() + math.max(0.5, self:GetBMBSpiderClimbTimeout())
                coroutine.wait(0.05)
                continue
            end

            self:DebugBMBSpiderClimb("blocked normal=" .. tostring(trace and trace.HitNormal or "nil"))
            self:FinishBMBSpiderClimbSpike("blocked")
            return true
        end

        self.BMBSpiderClimbLastPinnedPos = pinned
        self:SetPos(pinned)
        self:SetBMBState("climb_spike")
        self:SetBMBMoveMode("climb_spike")
        self:UpdateBMBApproachDebug(pinned + Vector(0, 0, self:GetBMBBlockSize()), 0)

        if now >= nextProgressLog then
            print(string.format(
                "[BMB spider climb] z=%.1f actual=%.1f dz=%.1f",
                pinned.z,
                self:GetPos().z,
                pinned.z - (self.BMBSpiderClimbStartZ or pinned.z)
            ))
            nextProgressLog = now + 0.75
        end

        coroutine.wait(0.02)
    end

    self:FinishBMBSpiderClimbSpike("timeout")
    return true
end

function ENT:TryBMBMoveOverride(reason, target)
    return self:RunBMBSpiderClimbSpike(target)
end

function ENT:CanBMBTarget(target)
    return self:IsBMBCombatTarget(target)
end

function ENT:GetBMBSpiderRetaliationTarget()
    local loseRange = self.TargetLoseRange or self.TargetRange

    if BMB.Behaviors.SeekTarget.IsValid(self, self.TargetEntity, loseRange) then
        return self.TargetEntity
    end

    if BMB.Behaviors.SeekTarget.IsValid(self, self.BMBRetaliationTarget, loseRange) then
        return self.BMBRetaliationTarget
    end

    return nil
end

function ENT:GetBMBForcedLookTarget()
    if self:CanBMBTarget(self.TargetEntity) then
        return self.TargetEntity
    end

    return nil
end

function ENT:OnBMBInjured(_damageInfo, _wasFleeing)
    self.BMBInitialIdleUntil = 0

    if BMB.Behaviors.SeekTarget.IsValid(self, self.BMBRetaliationTarget, self.TargetLoseRange or self.TargetRange) then
        self.TargetEntity = self.BMBRetaliationTarget
    end
end

function ENT:PlayBMBMeleeGesture(_target)
    self:SetNWFloat("BMBAttackStartedAt", CurTime())
end

function ENT:RunBMBSpiderAI()
    self.TargetEntity = self:GetBMBSpiderRetaliationTarget()

    if not IsValid(self.TargetEntity) then
        self.TargetEntity = nil
        self.BMBRetaliationTarget = nil
        self:SetBMBState("wander")
        BMB.Behaviors.Wander.Run(self)
        return
    end

    if BMB.Behaviors.MeleeAttack.Try(self, self.TargetEntity) then
        coroutine.wait(0.05)
        return
    end

    if BMB.Behaviors.Leap.Try(self, self.TargetEntity) then
        return
    end

    self:SetBMBState("chase")
    if not BMB.Behaviors.Chase.Run(self, self.TargetEntity) then
        if BMB.Behaviors.SeekTarget.IsValid(self, self.TargetEntity, self.TargetLoseRange or self.TargetRange) then
            if BMB.Behaviors.Chase.StalkHighTarget(self, self.TargetEntity) then return end

            self:SetBMBState("chase")
            self:SetBMBMoveMode("chase_repath")
            if BMB.Behaviors.Chase.TryRepathPressure then
                BMB.Behaviors.Chase.TryRepathPressure(
                    self,
                    self.TargetEntity,
                    self.RunSpeed,
                    self.ChaseRepathProbeDistance or self:GetBMBBlockSize() * 1.5
                )
            elseif BMB.Behaviors.Chase.ApplySafePressure then
                BMB.Behaviors.Chase.ApplySafePressure(
                    self,
                    self.TargetEntity,
                    self.RunSpeed,
                    "chase_repath",
                    self.ChaseRepathProbeDistance or self:GetBMBBlockSize() * 1.5
                )
            end
            coroutine.wait(self.ChaseFailureRepathDelay or 0.08)
        else
            self.TargetEntity = nil
            self.BMBRetaliationTarget = nil
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
        elseif self.RunBMBSpiderClimbSpike and self:RunBMBSpiderClimbSpike() then
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
