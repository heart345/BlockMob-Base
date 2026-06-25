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

ENT.WalkSpeed = 100
ENT.RunSpeed = 140
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
ENT.AttackRange = 72
ENT.AttackVerticalRange = 34
ENT.AttackVerticalOverlapRange = 58
ENT.AttackVerticalOverlapFlatRange = 32
ENT.AttackDamage = 6
ENT.AttackCooldown = 0.9
ENT.AttackHitDelay = 0
ENT.AttackMoveSpeed = 140
ENT.AttackHitSlop = 18
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
ENT.AmbientSoundIntervalTicks = 80
ENT.AmbientSoundChanceDenominator = 1000
ENT.AmbientSoundTickRate = 20
ENT.AmbientSoundMaxCatchupTicks = 4
ENT.StepSoundDistance = 18
ENT.StepSoundMinSpeed = 8
ENT.StepSoundLevel = 58
ENT.StepSoundVolumeMin = 0.40
ENT.StepSoundVolumeMax = 0.76
ENT.StepSoundPitchMin = 88
ENT.StepSoundPitchMax = 112
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
ENT.SpiderClimbSpeed = 105
ENT.SpiderClimbProbeDistance = 42
ENT.SpiderClimbWallClearance = 30
ENT.SpiderClimbMantleForward = 46
ENT.SpiderClimbMantleUp = 44
ENT.SpiderClimbMantleDown = 90
ENT.SpiderClimbMantleStartBelow = 3
ENT.SpiderClimbMantleSpeed = 72
ENT.SpiderClimbTimeout = 7
ENT.SpiderClimbBlockedHoldTime = 3
ENT.SpiderClimbDescendSpeed = 88
ENT.SpiderClimbDescendTimeout = 6
ENT.SpiderClimbGiveUpCooldown = 4
ENT.SpiderClimbCancelCooldown = 1.6
ENT.SpiderClimbChaseMinTargetUp = 18
ENT.SpiderClimbChaseWallDot = 0.1
ENT.SpiderClimbChaseCancelGrace = 0.45
ENT.SpiderClimbChaseActive = true
ENT.SpiderClimbChaseApproachDistance = 260
ENT.SpiderClimbChaseApproachTimeout = 0.45
ENT.SpiderClimbChaseStartDistance = 84
ENT.SpiderClimbMaxCells = 6
ENT.SpiderClimbEdgeCost = 2.5
ENT.SpiderClimbHorizontalCells = 2
ENT.SpiderClimbMaxWallNormalZ = 0.25
ENT.BMBAllowClimbPath = true

ENT.Sounds = {
    Say = {
        "bmb/mob/spider/say1.ogg",
        "bmb/mob/spider/say2.ogg",
        "bmb/mob/spider/say3.ogg",
        "bmb/mob/spider/say4.ogg"
    },
    Hurt = {
        "bmb/mob/spider/say1.ogg",
        "bmb/mob/spider/say2.ogg",
        "bmb/mob/spider/say3.ogg",
        "bmb/mob/spider/say4.ogg"
    },
    Death = {
        "bmb/mob/spider/death.ogg"
    },
    Step = {
        "bmb/mob/spider/step1.ogg",
        "bmb/mob/spider/step2.ogg",
        "bmb/mob/spider/step3.ogg",
        "bmb/mob/spider/step4.ogg"
    },
    Hit = {
        "bmb/damage/hit1.ogg",
        "bmb/damage/hit2.ogg",
        "bmb/damage/hit3.ogg"
    }
}

if SERVER then
    local function createSpiderConVar(name, default, description)
        if not GetConVar(name) then
            CreateConVar(name, default, FCVAR_ARCHIVE, description)
        end
    end

    local function migrateSpiderConVarDefault(name, oldDefault, newDefault)
        local convar = GetConVar(name)
        if not convar then return end
        if convar:GetString() ~= oldDefault then return end

        RunConsoleCommand(name, newDefault)
    end

    createSpiderConVar("bmb_spider_climb_spike", "1", "Enable the Phase 1 spider SetPos wall-climb spike.")
    createSpiderConVar("bmb_spider_climb_speed", "105", "Spider climb spike upward speed.")
    createSpiderConVar("bmb_spider_climb_probe_distance", "42", "Spider climb spike forward wall probe distance.")
    createSpiderConVar("bmb_spider_climb_wall_clearance", "30", "Spider climb spike origin clearance from the wall plane.")
    createSpiderConVar("bmb_spider_climb_mantle_forward", "46", "Spider climb spike forward distance used when stepping onto the top.")
    createSpiderConVar("bmb_spider_climb_mantle_up", "44", "Spider climb spike upward top-search distance.")
    createSpiderConVar("bmb_spider_climb_mantle_down", "90", "Spider climb spike downward top-search distance.")
    createSpiderConVar("bmb_spider_climb_mantle_start_below", "3", "How close to the top ledge the spider must climb before mantling.")
    createSpiderConVar("bmb_spider_climb_mantle_speed", "72", "Spider smooth mantle speed after it reaches the ledge.")
    createSpiderConVar("bmb_spider_climb_timeout", "7", "Spider climb spike timeout in seconds.")
    createSpiderConVar("bmb_spider_climb_blocked_hold_time", "3", "How long the spider clings to a blocked ledge before giving up.")
    createSpiderConVar("bmb_spider_climb_descend_speed", "88", "Spider downward speed when giving up a blocked climb.")
    createSpiderConVar("bmb_spider_climb_descend_timeout", "6", "Maximum time spent descending after a blocked climb.")
    createSpiderConVar("bmb_spider_climb_giveup_cooldown", "4", "Cooldown after a blocked climb gives up so the spider wanders elsewhere.")
    createSpiderConVar("bmb_spider_climb_cancel_cooldown", "1.6", "Cooldown after chase-aware climb cancels so the spider can resume ground chase.")
    createSpiderConVar("bmb_spider_climb_chase_min_target_up", "18", "Minimum target height advantage before chase movement can trigger spider wall climb.")
    createSpiderConVar("bmb_spider_climb_chase_wall_dot", "0.1", "Minimum target-to-wall direction dot before chase movement can trigger spider wall climb.")
    createSpiderConVar("bmb_spider_climb_chase_cancel_grace", "0.45", "Grace period before chase-aware climb can cancel because the target changed.")
    createSpiderConVar("bmb_spider_climb_chase_active", "1", "Let spider chase proactively approach climbable walls below high targets.")
    createSpiderConVar("bmb_spider_climb_chase_approach_distance", "260", "How far spider chase scans ahead for a wall to climb toward a high target.")
    createSpiderConVar("bmb_spider_climb_chase_approach_timeout", "0.45", "How long one active spider chase-climb approach segment may run.")
    createSpiderConVar("bmb_spider_climb_chase_start_distance", "84", "How close a proactive chase wall hit can be before spider starts climbing immediately.")
    createSpiderConVar("bmb_spider_climb_max_cells", "6", "Maximum vertical A* cells a spider climb edge may cover.")
    createSpiderConVar("bmb_spider_climb_edge_cost", "2.5", "Per-cell A* cost for spider climb edges.")
    createSpiderConVar("bmb_spider_climb_horizontal_cells", "2", "Horizontal A* cells from which a wide spider may start a climb edge.")
    createSpiderConVar("bmb_debug_spider_climb", "0", "Print spider climb spike diagnostics.")

    migrateSpiderConVarDefault("bmb_spider_climb_speed", "82", "105")
    migrateSpiderConVarDefault("bmb_spider_climb_mantle_speed", "58", "72")
    migrateSpiderConVarDefault("bmb_spider_climb_descend_speed", "78", "88")
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

local function spiderFlatDistance(a, b)
    if not a or not b then return math.huge end

    local dx = (a.x or 0) - (b.x or 0)
    local dy = (a.y or 0) - (b.y or 0)

    return math.sqrt(dx * dx + dy * dy)
end

local function randomSound(list)
    if not list or #list == 0 then return nil end
    return list[math.random(1, #list)]
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

    function ENT:UpdateBMBSpiderStepSound(speed)
        speed = speed or self:GetVelocity():Length2D()

        if speed <= (self.StepSoundMinSpeed or 8) then
            self.BMBSpiderStepDistance = 0
            return
        end

        local stepDistance = self.StepSoundDistance or 18
        self.BMBSpiderStepDistance = (self.BMBSpiderStepDistance or 0) + speed * FrameTime()
        if self.BMBSpiderStepDistance < stepDistance then return end

        self.BMBSpiderStepDistance = self.BMBSpiderStepDistance - stepDistance

        local soundName = randomSound(self.Sounds and self.Sounds.Step)
        if not soundName then return end

        local fullSpeed = math.max((self.StepSoundMinSpeed or 8) + 1, self.RunSpeed or 140)
        local speedFrac = math.Clamp((speed - (self.StepSoundMinSpeed or 8)) / (fullSpeed - (self.StepSoundMinSpeed or 8)), 0, 1)
        local volume = Lerp(speedFrac, self.StepSoundVolumeMin or 0.40, self.StepSoundVolumeMax or 0.76)
        self:EmitSound(soundName, self.StepSoundLevel or 58, math.random(self.StepSoundPitchMin or 88, self.StepSoundPitchMax or 112), volume)
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

            self.BMBSpiderStepDistance = 0
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

        local speed = self:GetVelocity():Length2D()
        self:UpdateBMBSpiderLegs(bones, speed)
        self:UpdateBMBSpiderStepSound(speed)
    end
end

function ENT:Initialize()
    if CLIENT then return end

    self:BaseInitialize()
    self:SetBMBState("idle")
    self.TargetEntity = nil
    self:ResetBMBAmbientSoundTime()
    self.BMBNextAmbientSoundTickAt = CurTime() + math.Rand(0, 1 / (self.AmbientSoundTickRate or 20))
    self.BMBInitialIdleUntil = CurTime() + math.Rand(self.InitialIdleMin or 1.0, self.InitialIdleMax or 3.0)
end

function ENT:MaybePlayStep()
    -- Spider footsteps are client-side and distance-driven from the procedural leg phase.
end

function ENT:IsBMBSpiderClimbSpikeEnabled()
    return self.SpiderClimbSpikeEnabled ~= false
        and spiderConVarBool("bmb_spider_climb_spike", true)
end

function ENT:GetBMBSpiderClimbSpeed()
    return spiderConVarFloat("bmb_spider_climb_speed", self.SpiderClimbSpeed or 105)
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
    return spiderConVarFloat("bmb_spider_climb_mantle_speed", self.SpiderClimbMantleSpeed or 72)
end

function ENT:GetBMBSpiderClimbTimeout()
    return spiderConVarFloat("bmb_spider_climb_timeout", self.SpiderClimbTimeout or 7)
end

function ENT:GetBMBSpiderClimbBlockedHoldTime()
    return spiderConVarFloat("bmb_spider_climb_blocked_hold_time", self.SpiderClimbBlockedHoldTime or 3)
end

function ENT:GetBMBSpiderClimbDescendSpeed()
    return spiderConVarFloat("bmb_spider_climb_descend_speed", self.SpiderClimbDescendSpeed or 88)
end

function ENT:GetBMBSpiderClimbDescendTimeout()
    return spiderConVarFloat("bmb_spider_climb_descend_timeout", self.SpiderClimbDescendTimeout or 6)
end

function ENT:GetBMBSpiderClimbGiveUpCooldown()
    return spiderConVarFloat("bmb_spider_climb_giveup_cooldown", self.SpiderClimbGiveUpCooldown or 4)
end

function ENT:GetBMBSpiderClimbCancelCooldown()
    return spiderConVarFloat("bmb_spider_climb_cancel_cooldown", self.SpiderClimbCancelCooldown or 1.6)
end

function ENT:GetBMBSpiderClimbChaseMinTargetUp()
    return spiderConVarFloat("bmb_spider_climb_chase_min_target_up", self.SpiderClimbChaseMinTargetUp or 18)
end

function ENT:GetBMBSpiderClimbChaseWallDot()
    return spiderConVarFloat("bmb_spider_climb_chase_wall_dot", self.SpiderClimbChaseWallDot or 0.1)
end

function ENT:GetBMBSpiderClimbChaseCancelGrace()
    return spiderConVarFloat("bmb_spider_climb_chase_cancel_grace", self.SpiderClimbChaseCancelGrace or 0.45)
end

function ENT:IsBMBSpiderChaseClimbEnabled()
    return self.SpiderClimbChaseActive ~= false
        and spiderConVarBool("bmb_spider_climb_chase_active", true)
end

function ENT:GetBMBSpiderClimbChaseApproachDistance()
    return spiderConVarFloat("bmb_spider_climb_chase_approach_distance", self.SpiderClimbChaseApproachDistance or 260)
end

function ENT:GetBMBSpiderClimbChaseApproachTimeout()
    return spiderConVarFloat("bmb_spider_climb_chase_approach_timeout", self.SpiderClimbChaseApproachTimeout or 0.45)
end

function ENT:GetBMBSpiderClimbChaseStartDistance()
    return spiderConVarFloat("bmb_spider_climb_chase_start_distance", self.SpiderClimbChaseStartDistance or 84)
end

function ENT:GetBMBSpiderClimbMaxCells()
    return math.max(0, math.floor(spiderConVarFloat("bmb_spider_climb_max_cells", self.SpiderClimbMaxCells or 6)))
end

function ENT:GetBMBSpiderClimbEdgeCost()
    return math.max(1, spiderConVarFloat("bmb_spider_climb_edge_cost", self.SpiderClimbEdgeCost or 2.5))
end

function ENT:GetBMBSpiderClimbHorizontalCells()
    return math.max(1, math.floor(spiderConVarFloat("bmb_spider_climb_horizontal_cells", self.SpiderClimbHorizontalCells or 2)))
end

function ENT:ShouldBMBUseClimbPath(_target)
    return self:IsBMBSpiderClimbSpikeEnabled()
end

function ENT:ConfigureBMBPathfinderOptions(pathOptions, _destination, moveOptions)
    if moveOptions and moveOptions.allowClimb == false then return end
    if not self:ShouldBMBUseClimbPath() then return end

    pathOptions.allowClimb = true
    pathOptions.maxClimbCells = self:GetBMBSpiderClimbMaxCells()
    pathOptions.climbEdgeCost = self:GetBMBSpiderClimbEdgeCost()
    pathOptions.climbHorizontalCells = self:GetBMBSpiderClimbHorizontalCells()
end

function ENT:DebugBMBSpiderClimb(message)
    if not spiderConVarBool("bmb_debug_spider_climb", false) then return end
    print("[BMB spider climb] " .. tostring(message))
end

function ENT:GetBMBSpiderClimbCombatTarget()
    local seekTarget = BMB and BMB.Behaviors and BMB.Behaviors.SeekTarget
    local isValidTarget = seekTarget and seekTarget.IsValid
    local loseRange = self.TargetLoseRange or self.TargetRange

    if isValidTarget then
        if isValidTarget(self, self.TargetEntity, loseRange) then return self.TargetEntity end
        if isValidTarget(self, self.BMBRetaliationTarget, loseRange) then return self.BMBRetaliationTarget end
    else
        if IsValid(self.TargetEntity) then return self.TargetEntity end
        if IsValid(self.BMBRetaliationTarget) then return self.BMBRetaliationTarget end
    end

    return nil
end

function ENT:GetBMBSpiderClimbTargetPosition(target)
    local combatTarget = self:GetBMBSpiderClimbCombatTarget()
    if IsValid(combatTarget) and combatTarget.GetPos then
        return combatTarget:GetPos(), combatTarget
    end

    if IsValid(target) and target.GetPos then
        return target:GetPos(), target
    end

    if target and target.x and target.y and target.z then
        return Vector(target.x, target.y, target.z), nil
    end

    return nil, nil
end

function ENT:GetBMBSpiderFlatDirection(fromPos, toPos)
    if not fromPos or not toPos then return nil end

    local direction = Vector(toPos.x - fromPos.x, toPos.y - fromPos.y, 0)
    if direction:LengthSqr() <= 1 then return nil end

    direction:Normalize()
    return direction
end

function ENT:GetBMBSpiderIntoWallDirection(normal)
    if not normal then return nil end

    local intoWall = Vector(-normal.x, -normal.y, 0)
    if intoWall:LengthSqr() <= 0.0001 then return nil end

    intoWall:Normalize()
    return intoWall
end

function ENT:ShouldBMBSpiderStartClimb(target, normal, reason)
    if reason == "path_climb" then return true, nil end

    local combatTarget = self:GetBMBSpiderClimbCombatTarget()
    if not IsValid(combatTarget) then return true, nil end

    local targetPos = self:GetBMBSpiderClimbTargetPosition(target)
    if not targetPos then
        self:DebugBMBSpiderClimb("skip chase climb: no target pos reason=" .. tostring(reason))
        return false, combatTarget
    end

    local current = self:GetPos()
    local minTargetUp = math.max(0, self:GetBMBSpiderClimbChaseMinTargetUp())
    local targetUp = targetPos.z - current.z

    if targetUp < minTargetUp then
        self:DebugBMBSpiderClimb(string.format(
            "skip chase climb: target_up=%.1f min=%.1f reason=%s",
            targetUp,
            minTargetUp,
            tostring(reason)
        ))
        return false, combatTarget
    end

    local targetDirection = self:GetBMBSpiderFlatDirection(current, targetPos)
    local intoWall = self:GetBMBSpiderIntoWallDirection(normal)
    if targetDirection and intoWall then
        local dot = targetDirection:Dot(intoWall)
        local minDot = self:GetBMBSpiderClimbChaseWallDot()

        if dot < minDot then
            self:DebugBMBSpiderClimb(string.format(
                "skip chase climb: wall_dot=%.2f min=%.2f reason=%s",
                dot,
                minDot,
                tostring(reason)
            ))
            return false, combatTarget
        end
    end

    return true, combatTarget
end

function ENT:ShouldCancelBMBSpiderChaseClimb(normal)
    if not self.BMBSpiderClimbHadCombatTarget then return false end
    if CurTime() < (self.BMBSpiderClimbCancelCheckAt or 0) then return false end

    local combatTarget = self:GetBMBSpiderClimbCombatTarget()
    if not IsValid(combatTarget) then return true, "target_lost" end

    local targetPos = combatTarget:GetPos()
    local startZ = self.BMBSpiderClimbStartZ or self:GetPos().z
    local minTargetUp = math.max(0, self:GetBMBSpiderClimbChaseMinTargetUp())

    if targetPos.z - startZ < minTargetUp * 0.5 then
        return true, "target_dropped"
    end

    local targetDirection = self:GetBMBSpiderFlatDirection(self:GetPos(), targetPos)
    local intoWall = self:GetBMBSpiderIntoWallDirection(normal)
    if targetDirection and intoWall and targetDirection:Dot(intoWall) < -0.35 then
        return true, "target_moved_away"
    end

    return false
end

function ENT:ShouldRunBMBSpiderChaseClimb(target)
    if not self:IsBMBSpiderChaseClimbEnabled() then return false end
    if self.BMBSpiderClimbing then return false end
    if CurTime() < (self.BMBSpiderClimbCooldownUntil or 0) then return false end
    if not IsValid(target) then return false end

    local targetPos = target:GetPos()
    local targetUp = targetPos.z - self:GetPos().z

    return targetUp >= math.max(0, self:GetBMBSpiderClimbChaseMinTargetUp())
end

function ENT:AddBMBSpiderChaseClimbDirection(directions, direction, bias)
    if not direction or direction:LengthSqr() <= 0.0001 then return end

    local flat = Vector(direction.x, direction.y, 0)
    if flat:LengthSqr() <= 0.0001 then return end
    flat:Normalize()

    for _, existing in ipairs(directions) do
        if existing.direction:Dot(flat) > 0.96 then
            existing.bias = math.max(existing.bias or 0, bias or 0)
            return
        end
    end

    table.insert(directions, {
        direction = flat,
        bias = bias or 0
    })
end

function ENT:GetBMBSpiderChaseClimbDirections(target)
    local directions = {}
    local current = self:GetPos()
    local targetPos = IsValid(target) and target:GetPos() or nil
    local targetDirection = self:GetBMBSpiderFlatDirection(current, targetPos)

    local forward = self:GetForward()
    forward.z = 0
    if forward:LengthSqr() > 0.0001 then
        forward:Normalize()
    else
        forward = nil
    end

    local right = self:GetRight()
    right.z = 0
    if right:LengthSqr() > 0.0001 then
        right:Normalize()
    elseif forward then
        right = Vector(-forward.y, forward.x, 0)
    else
        right = nil
    end

    self:AddBMBSpiderChaseClimbDirection(directions, targetDirection, 4)
    self:AddBMBSpiderChaseClimbDirection(directions, forward, 3)

    if targetDirection and right then
        self:AddBMBSpiderChaseClimbDirection(directions, targetDirection + right * 0.45, 2.4)
        self:AddBMBSpiderChaseClimbDirection(directions, targetDirection - right * 0.45, 2.4)
    end

    if forward and right then
        self:AddBMBSpiderChaseClimbDirection(directions, forward + right * 0.55, 1.6)
        self:AddBMBSpiderChaseClimbDirection(directions, forward - right * 0.55, 1.6)
    end

    self:AddBMBSpiderChaseClimbDirection(directions, right, 0.4)
    self:AddBMBSpiderChaseClimbDirection(directions, right and -right or nil, 0.4)
    self:AddBMBSpiderChaseClimbDirection(directions, forward and -forward or nil, 0.1)

    return directions, targetDirection
end

function ENT:TryBMBSpiderChaseClimbAtWall(target, normal, reason)
    if not normal then return false end
    if not self:GetBMBSpiderClimbPinnedPosition(self:GetPos(), normal) then return false end

    self.BMBSpiderClimbForcedNormal = normal
    self.BMBSpiderClimbPendingReason = reason or "chase_active_wall"

    return self:RunBMBSpiderClimbSpike(IsValid(target) and target:GetPos() or nil)
end

function ENT:FindBMBSpiderChaseClimbApproach(target)
    if not IsValid(target) then return nil end

    local current = self:GetPos()
    local targetPos = target:GetPos()
    local directions, targetDirection = self:GetBMBSpiderChaseClimbDirections(target)
    if #directions == 0 then return nil end

    local flatDistance = spiderFlatDistance(current, targetPos)
    local traceDistance = math.min(
        math.max(self:GetBMBSpiderClimbProbeDistance(), flatDistance + self:GetBMBBlockSize()),
        math.max(self:GetBMBSpiderClimbProbeDistance(), self:GetBMBSpiderClimbChaseApproachDistance())
    )
    local sampleHeight = math.Clamp((self.CollisionMaxs.z or 33) * 0.45, 10, math.max(10, (self.CollisionMaxs.z or 33) - 2))
    local start = current + Vector(0, 0, sampleHeight)
    local best

    for _, entry in ipairs(directions) do
        local direction = entry.direction
        local trace = util.TraceLine({
            start = start,
            endpos = start + direction * traceDistance,
            filter = self:GetBMBSpiderClimbTraceFilter(),
            mask = MASK_SOLID
        })
        local normal = self:GetBMBSpiderFlatWallNormal(trace)

        if normal then
            local intoWall = self:GetBMBSpiderIntoWallDirection(normal)
            local wallDot = (targetDirection and intoWall) and targetDirection:Dot(intoWall) or 0
            local approach = trace.HitPos + normal * self:GetBMBSpiderClimbWallClearance()
            approach.z = current.z

            local clear = not self.IsBMBHullClearAtPosition or self:IsBMBHullClearAtPosition(approach)
            local distance = spiderFlatDistance(current, approach)
            local score = (entry.bias or 0) + wallDot * 3 + (1 - (trace.Fraction or 1)) * 2
            if clear then score = score + 1 end
            score = score - distance * 0.005

            if not best or score > best.score then
                best = {
                    approach = approach,
                    normal = normal,
                    trace = trace,
                    clear = clear,
                    score = score
                }
            end
        end
    end

    if not best then return nil end

    return best.approach, best.normal, best.trace, best.clear
end

function ENT:RunBMBSpiderChaseClimb(target)
    if not self:ShouldRunBMBSpiderChaseClimb(target) then return false end

    self.BMBSpiderClimbPendingReason = "chase_active"
    if self:RunBMBSpiderClimbSpike(target:GetPos()) then return true end

    local approach, normal, trace, clear = self:FindBMBSpiderChaseClimbApproach(target)
    if not approach then return false end

    local speed = self.RunSpeed or self.WalkSpeed
    local tolerance = math.max(8, self:GetBMBSpiderClimbWallClearance() * 0.35)
    local approachDistance = spiderFlatDistance(self:GetPos(), approach)
    local startDistance = math.max(self:GetBMBSpiderClimbProbeDistance(), self:GetBMBSpiderClimbChaseStartDistance())

    if approachDistance <= startDistance
        and self:TryBMBSpiderChaseClimbAtWall(target, normal, "chase_active_wall") then
        return true
    end

    self:SetBMBState("chase")
    self:SetBMBMoveMode("chase_climb_approach")
    self:UpdateBMBApproachDebug(approach, 0)
    self:DebugBMBSpiderClimb(string.format(
        "chase approach wall dist=%.1f normal=%s fraction=%.2f",
        approachDistance,
        tostring(normal),
        trace and trace.Fraction or -1
    ))

    if not clear then
        return false
    end

    local moved = self:MoveToWorldPosition(approach, speed, {
        skipSourcePath = true,
        allowPartial = true,
        acceptPartial = true,
        allowDirectFallback = true,
        timeout = math.max(0.1, self:GetBMBSpiderClimbChaseApproachTimeout()),
        duration = math.max(0.1, self:GetBMBSpiderClimbChaseApproachTimeout()),
        goalTolerance = tolerance,
        moveIntentSpeed = speed,
        minPathSpeed = speed
    })

    if moved then return true end

    return self:TryBMBSpiderChaseClimbAtWall(target, normal, "chase_active_blocked")
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
    self.BMBSpiderLastClimbResult = result
    self.BMBSpiderClimbing = false
    self.BMBSpiderClimbStartZ = nil
    self.BMBSpiderClimbGoalZ = nil
    self.BMBSpiderClimbLastPinnedPos = nil
    self.BMBSpiderClimbReason = nil
    self.BMBSpiderClimbHadCombatTarget = nil
    self.BMBSpiderClimbCancelCheckAt = nil
    self.BMBSpiderClimbForcedNormal = nil
    self.BMBSpiderClimbNextHoldLog = nil
    self.BMBSpiderClimbNextMantleCandidateLog = nil
    self.BMBSpiderClimbHoldReason = nil
    self.BMBSpiderClimbHoldStartedAt = nil

    local cooldown = 0.8
    if result == "success" then
        cooldown = 0.2
    elseif result == "giveup" then
        cooldown = math.max(0.8, self:GetBMBSpiderClimbGiveUpCooldown())
    elseif result == "target_lost" or result == "target_dropped" or result == "target_moved_away" then
        cooldown = math.max(0.8, self:GetBMBSpiderClimbCancelCooldown())
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
    local reason = self.BMBSpiderClimbPendingReason or "ambient"
    self.BMBSpiderClimbPendingReason = nil
    self.BMBSpiderLastClimbResult = nil

    if self.BMBSpiderClimbing then return false end

    local targetPos = self:GetBMBSpiderClimbTargetPosition(target)
    local scanTarget = targetPos or target
    local forcedNormal = self.BMBSpiderClimbForcedNormal
    self.BMBSpiderClimbForcedNormal = nil

    local normal
    if forcedNormal and self:GetBMBSpiderClimbPinnedPosition(self:GetPos(), forcedNormal) then
        normal = forcedNormal
    end

    normal = normal or self:FindBMBSpiderClimbWall(scanTarget)
    if not normal then return false end

    local shouldStart, combatTarget = self:ShouldBMBSpiderStartClimb(target, normal, reason)
    if not shouldStart then return false end

    local startPos = self:GetPos()
    local startPinned, startNormal = self:GetBMBSpiderClimbPinnedPosition(startPos, normal)
    if not startPinned then
        self:DebugBMBSpiderClimb("skip climb start: wall not pinned reason=" .. tostring(reason))
        return false
    end

    normal = startNormal or normal
    local startClear = self:CanBMBSpiderMoveHull(startPos, startPinned, normal)
    if not startClear then
        self:DebugBMBSpiderClimb("skip climb start: pin blocked reason=" .. tostring(reason))
        return false
    end

    self.BMBSpiderClimbing = true
    self.BMBSpiderClimbStartZ = startPinned.z
    self.BMBSpiderClimbGoalZ = startPinned.z
    self.BMBSpiderClimbLastPinnedPos = startPinned
    self.BMBSpiderClimbReason = reason
    self.BMBSpiderClimbHadCombatTarget = IsValid(combatTarget)
    self.BMBSpiderClimbCancelCheckAt = CurTime() + math.max(0, self:GetBMBSpiderClimbChaseCancelGrace())
    self:ClearBMBMovementInterrupt()
    if self.ClearBMBDebugMove then
        self:ClearBMBDebugMove()
    end
    print("[BMB spider climb] start normal=" .. tostring(normal) .. " reason=" .. tostring(reason))
    self:SetBMBState("climb_spike")
    self:SetBMBMoveMode("climb_spike")
    self:MaintainBMBMoveSpeed(0, 0)
    self:BeginBMBSpiderClimbMoveTypeOverride()
    self:SetPos(startPinned)

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

        local cancel, cancelReason = self:ShouldCancelBMBSpiderChaseClimb(normal)
        if cancel then
            self:DebugBMBSpiderClimb("cancel chase climb: " .. tostring(cancelReason))
            self:FinishBMBSpiderClimbSpike(cancelReason or "target_lost")
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
    self.BMBSpiderClimbPendingReason = reason
    return self:RunBMBSpiderClimbSpike(target)
end

function ENT:ApproachBMBSpiderPathClimbWall(normal, speed)
    if self:GetBMBSpiderClimbPinnedPosition(self:GetPos(), normal) then return true end

    local intoWall = self:GetBMBSpiderIntoWallDirection(normal)
    if not intoWall then return false end

    local desiredSpeed = speed or self.RunSpeed or self.WalkSpeed
    local deadline = CurTime() + math.max(0.2, self:GetBMBSpiderClimbChaseApproachTimeout())
    local progressWatch = self:StartBMBMoveProgressWatch()

    while CurTime() < deadline do
        if self.BMBDead or self.BMBHeld or self.BMBMoveInterrupt then return false end
        if self.IsBMBKnockbackActive and self:IsBMBKnockbackActive() then return false end
        if self.IsBMBFreezeEnabled and self:IsBMBFreezeEnabled() then return false end

        if self:GetBMBSpiderClimbPinnedPosition(self:GetPos(), normal) then return true end

        local current = self:GetPos()
        local target = current + intoWall * math.max(
            self:GetBMBSpiderClimbProbeDistance(),
            self:GetBMBSpiderClimbWallClearance()
        )
        target.z = current.z

        self:SetBMBState("chase")
        self:SetBMBMoveMode("path_climb_approach")
        self:MaintainBMBMoveSpeed(desiredSpeed, desiredSpeed)
        self:UpdateMoveActivity(desiredSpeed, desiredSpeed)
        self:UpdateBMBApproachDebug(target, 0)
        self:SteerTowards(target, progressWatch)
        self:BodyMoveXY()
        self:MaybePlayStep()

        if not self:CheckBMBMoveProgress(progressWatch) then
            return self:GetBMBSpiderClimbPinnedPosition(self:GetPos(), normal) ~= nil
        end

        coroutine.yield()
    end

    return self:GetBMBSpiderClimbPinnedPosition(self:GetPos(), normal) ~= nil
end

function ENT:RunBMBPathVerticalAction(action, node, final, _waypoints, _nodeIndex, speed, _options)
    if action ~= "climb" then return false end
    if not node or not node.wallNormal then return false end
    if not self:IsBMBSpiderClimbSpikeEnabled() then return false end
    if self.BMBSpiderClimbing then return false end
    if CurTime() < (self.BMBSpiderClimbCooldownUntil or 0) then return false end

    local rawNormal = node.wallNormal
    local normal = Vector(rawNormal.x or 0, rawNormal.y or 0, rawNormal.z or 0)
    if normal:LengthSqr() <= 0.0001 then return false end
    normal:Normalize()

    self:SetBMBMoveMode("path_climb")

    if not self:ApproachBMBSpiderPathClimbWall(normal, speed) then return false end

    self.BMBSpiderClimbForcedNormal = normal
    self.BMBSpiderClimbPendingReason = "path_climb"
    if not self:RunBMBSpiderClimbSpike(final or node) then return false end

    return self.BMBSpiderLastClimbResult == "success"
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

function ENT:OnBMBMeleeHit(target, _damageInfo)
    if not IsValid(target) then return end
    if not target:IsPlayer() then return end

    local soundName = randomSound(self.Sounds and self.Sounds.Hit)
    if soundName then
        target:EmitSound(soundName, 74, math.random(96, 104), 0.82)
    end
end

function ENT:PlayBMBSpiderSay(volume)
    local soundName = randomSound(self.Sounds and self.Sounds.Say)
    if not soundName then return end

    self:EmitSound(soundName, 72, math.random(92, 108), volume or 0.72)
end

function ENT:PlayBMBSpiderHurtSound(volume)
    local soundName = randomSound(self.Sounds and self.Sounds.Hurt)
    if not soundName then return end

    self:EmitSound(soundName, 72, math.random(95, 105), volume or 0.84)
end

function ENT:OnBMBHurtSound(damageInfo)
    if damageInfo and self:Health() - damageInfo:GetDamage() <= 0 then return end

    self:PlayBMBSpiderHurtSound(0.9)
end

function ENT:PlayBMBSpiderDeathSound()
    local soundName = randomSound(self.Sounds and self.Sounds.Death)
    if soundName then
        self:EmitSound(soundName, 76, math.random(95, 105), 0.95)
    end
end

function ENT:OnKilled(damageInfo)
    if CLIENT then return end

    self:PlayBMBSpiderDeathSound()
    self:BeginBMBDeath(damageInfo)
end

function ENT:ResetBMBAmbientSoundTime()
    self.BMBAmbientSoundTime = -(self.AmbientSoundIntervalTicks or 80)
end

function ENT:MaybePlayIdleSound()
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
            self:PlayBMBSpiderSay(0.72)
            self:ResetBMBAmbientSoundTime()
            soundTime = self.BMBAmbientSoundTime
        end

        self.BMBAmbientSoundTime = soundTime + 1
    end

    self.BMBNextAmbientSoundTickAt = nextTick + ticks * tickInterval
    if self.BMBNextAmbientSoundTickAt < now - tickInterval then
        self.BMBNextAmbientSoundTickAt = now + tickInterval
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

    if self:RunBMBSpiderChaseClimb(self.TargetEntity) then
        return
    end

    self:SetBMBState("chase")
    if not BMB.Behaviors.Chase.Run(self, self.TargetEntity) then
        if BMB.Behaviors.SeekTarget.IsValid(self, self.TargetEntity, self.TargetLoseRange or self.TargetRange) then
            if self:RunBMBSpiderChaseClimb(self.TargetEntity) then return end
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
