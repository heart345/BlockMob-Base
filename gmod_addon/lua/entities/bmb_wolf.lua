AddCSLuaFile()

ENT.Base = "bmb_base_mob"
ENT.Type = "nextbot"
ENT.PrintName = "BMB Wolf"
ENT.Author = "Heart#"
ENT.Category = "BlockMob Base"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Model = "models/mcgm/wolf/wolf.mdl"
ENT.StartHealth = 40
ENT.DeathRemoveDelay = 1.5
ENT.DeathTipDuration = 0.5
ENT.DeathTipDegrees = 90

ENT.WalkSpeed = 85
ENT.RunSpeed = 135
ENT.Acceleration = 360
ENT.Deceleration = 460
ENT.CollisionMins = Vector(-11, -11, 0)
ENT.CollisionMaxs = Vector(11, 11, 32)

ENT.WanderDistanceMinCells = 4
ENT.WanderDistanceMaxCells = 10
ENT.WanderPauseMin = 3.0
ENT.WanderPauseMax = 7.0
ENT.WanderPathAttempts = 2
ENT.WanderFailurePauseMin = 0.5
ENT.WanderFailurePauseMax = 1.3
ENT.InitialIdleMin = 1.5
ENT.InitialIdleMax = 4.0

ENT.LimbSwingMinAmount = 0.2
ENT.LimbSwingPhaseScale = 0.12
ENT.WolfLegSwingMax = 28
ENT.WolfTailSwingXDegrees = 40
ENT.LookAtEyeHeight = 27
ENT.LookAtPitchLimit = 22
ENT.LookAroundPitchLimit = 12

if CLIENT then
    local zeroAngle = Angle(0, 0, 0)
    local zeroVector = Vector(0, 0, 0)
    local wolfBoneNames = { "root", "body", "upperBody", "head", "leg0", "leg1", "leg2", "leg3", "tail" }
    local wolfPoseConVars = {}

    local function createWolfPoseConVars(prefix, defaultAngle, defaultPos)
        defaultAngle = defaultAngle or zeroAngle
        defaultPos = defaultPos or zeroVector

        return {
            angle = {
                x = CreateClientConVar(prefix .. "_rot_x", tostring(defaultAngle.p), true, false),
                y = CreateClientConVar(prefix .. "_rot_y", tostring(defaultAngle.y), true, false),
                z = CreateClientConVar(prefix .. "_rot_z", tostring(defaultAngle.r), true, false)
            },
            pos = {
                x = CreateClientConVar(prefix .. "_pos_x", tostring(defaultPos.x), true, false),
                y = CreateClientConVar(prefix .. "_pos_y", tostring(defaultPos.y), true, false),
                z = CreateClientConVar(prefix .. "_pos_z", tostring(defaultPos.z), true, false)
            }
        }
    end

    wolfPoseConVars.body = createWolfPoseConVars("bmb_wolf_body", zeroAngle, zeroVector)
    wolfPoseConVars.upperBody = createWolfPoseConVars("bmb_wolf_upper_body", zeroAngle, Vector(0, 0, -10))
    wolfPoseConVars.tail = createWolfPoseConVars("bmb_wolf_tail", Angle(0, 0, -45), zeroVector)

    local function setBoneAngle(ent, boneId, angle)
        if not boneId then return end
        ent:ManipulateBoneAngles(boneId, angle or zeroAngle)
    end

    local function setBonePosition(ent, boneId, pos)
        if not boneId then return end
        ent:ManipulateBonePosition(boneId, pos or zeroVector)
    end

    local function angleFromConVars(convars)
        return Angle(convars.x:GetFloat(), convars.y:GetFloat(), convars.z:GetFloat())
    end

    local function vectorFromConVars(convars)
        return Vector(convars.x:GetFloat(), convars.y:GetFloat(), convars.z:GetFloat())
    end

    local function applyWolfPose(ent, boneId, poseConVars)
        if not boneId or not poseConVars then return end
        setBoneAngle(ent, boneId, angleFromConVars(poseConVars.angle))
        setBonePosition(ent, boneId, vectorFromConVars(poseConVars.pos))
    end

    local function resetWolfBones(ent, bones)
        for _, boneName in ipairs(wolfBoneNames) do
            setBoneAngle(ent, bones[boneName], zeroAngle)
            setBonePosition(ent, bones[boneName], zeroVector)
        end
    end

    function ENT:CacheBMBWolfBones()
        local model = self:GetModel()
        if self.BMBWolfBoneCache and self.BMBWolfBoneCache.model == model then
            return self.BMBWolfBoneCache
        end

        self.BMBWolfBoneCache = {
            model = model,
            root = self:LookupBone("root"),
            body = self:LookupBone("body"),
            upperBody = self:LookupBone("upperBody") or self:LookupBone("upperbody"),
            head = self:LookupBone("head"),
            leg0 = self:LookupBone("leg0"),
            leg1 = self:LookupBone("leg1"),
            leg2 = self:LookupBone("leg2"),
            leg3 = self:LookupBone("leg3"),
            tail = self:LookupBone("tail")
        }

        return self.BMBWolfBoneCache
    end

    function ENT:UpdateBMBVisualBones()
        local bones = self:CacheBMBWolfBones()
        if not bones then return end

        local state = self:GetNWString("BMBState", "idle")
        if state == "dead" or self:GetNWBool("BMBDead", false) then
            resetWolfBones(self, bones)

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
        applyWolfPose(self, bones.body, wolfPoseConVars.body)
        applyWolfPose(self, bones.upperBody, wolfPoseConVars.upperBody)

        if not self:UpdateBMBLookAtHeadPose(bones.head) then
            setBoneAngle(self, bones.head, zeroAngle)
            setBonePosition(self, bones.head, zeroVector)
        end

        local speed = self:GetVelocity():Length2D()
        local phase, swingAmount = self:UpdateBMBLimbSwing(speed)
        local legSwing = math.sin(phase) * (self.WolfLegSwingMax or 28) * swingAmount
        local tailAngle = angleFromConVars(wolfPoseConVars.tail.angle)
        tailAngle.p = tailAngle.p + math.sin(phase) * (self.WolfTailSwingXDegrees or 40) * swingAmount
        setBoneAngle(self, bones.tail, tailAngle)
        setBonePosition(self, bones.tail, vectorFromConVars(wolfPoseConVars.tail.pos))

        -- Same diagonal pair convention as MC wolf leg_default: leg0/leg3 together, leg1/leg2 opposite.
        setBoneAngle(self, bones.leg0, Angle(0, 0, legSwing))
        setBoneAngle(self, bones.leg3, Angle(0, 0, legSwing))
        setBoneAngle(self, bones.leg1, Angle(0, 0, -legSwing))
        setBoneAngle(self, bones.leg2, Angle(0, 0, -legSwing))
    end
end

function ENT:Initialize()
    if CLIENT then return end

    self:BaseInitialize()
    self:SetBMBState("idle")
    self.BMBInitialIdleUntil = CurTime() + math.Rand(self.InitialIdleMin or 1.5, self.InitialIdleMax or 4.0)
end

function ENT:MaybePlayStep()
    -- Wolf Phase 0 has no sound pass yet; keep Base's placeholder zombie footstep silent.
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
            self:SetBMBState("wander")
            BMB.Behaviors.Wander.Run(self)
        end

        coroutine.yield()
    end
end
