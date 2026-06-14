AddCSLuaFile()

ENT.Base = "bmb_base_mob"
ENT.Type = "nextbot"
ENT.PrintName = "BMB Prototype Sheep"
ENT.Author = "BMB"
ENT.Category = "BlockMob Base"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Model = "models/mcgm/sheep/sheep.mdl"
ENT.StartHealth = 20
ENT.UsePhysicsCorpseOnDeath = true
ENT.DeathCorpseRightPushSpeed = 70
ENT.DeathCorpseRollVelocity = 35
ENT.DeathCorpseRightForce = 0
ENT.DeathCorpseRightRollVelocity = 95
ENT.DeathPoofParticleCountMin = 5
ENT.DeathPoofParticleCountMax = 8
ENT.DeathPoofRadiusScale = 50
ENT.EatGrassAnimationDuration = 1.05
ENT.EatGrassBiteDelay = 0.42
ENT.WalkSpeed = 70
-- 当前先按 GMod/MC 模型手感调到 100u/s；FleeKeepFullSpeed 防止拐弯时 HUD 目标速度掉到跑步阈值。
ENT.RunSpeed = 100
ENT.FleeKeepFullSpeed = true
ENT.Acceleration = 240
ENT.Deceleration = 260
ENT.WanderDistanceMinCells = 3  -- 单段游荡 3~8 格
ENT.WanderDistanceMaxCells = 8
ENT.WanderPauseMin = 6.0     -- 到站站立 6~14s，站立是常态
ENT.WanderPauseMax = 14.0
ENT.WanderPathAttempts = 2
ENT.WanderFailurePauseMin = 0.8
ENT.WanderFailurePauseMax = 1.8
ENT.InitialIdleMin = 4.0
ENT.InitialIdleMax = 9.0
-- 比 MC 40 tick 稍长一点，避免 GMod 场景里受击后刚起跑就结束。
ENT.FleeDurationMin = 3.5
ENT.FleeDurationMax = 5.0
ENT.FleePanicRadiusCells = 5    -- 恐慌单段目标 ±5 格（MC DefaultRandomPos.getPos(mob, 5, 4)）
ENT.FleePanicMinDistanceCells = 1
ENT.FleeGiveUpFailures = 4       -- 连续 4 次选不出点/起步即被挡 → 认定无路可逃，放弃恐慌
ENT.CollisionMins = Vector(-16, -16, 0) -- MC 成年羊宽 0.9 格 ~= 32.4u；保持略小于 36u 一格走廊
ENT.CollisionMaxs = Vector(16, 16, 44)

if CLIENT then
    local zeroAngle = Angle(0, 0, 0)
    local zeroVector = Vector(0, 0, 0)
    local previewPose = CreateClientConVar("bmb_sheep_pose_preview", "0", true, false, "Preview sheep bone transforms live.")
    local previewKeyTime = CreateClientConVar("bmb_sheep_pose_key_time", "0", true, false, "Printed sheep keyframe time.")

    local sheepBoneNames = { "head", "leg0", "leg1", "leg2", "leg3" }

    local sheepAnimations = {
        eat_grass = {
            duration = 1.05,
            frames = {
                { time = 0.00, bones = { head = { angle = Angle(0, 0, 0), pos = Vector(0, 0, 0) } } },
                { time = 0.18, bones = { head = { angle = Angle(0, 0, 30), pos = Vector(0, -1.5, -2.5) } } },
                { time = 0.42, bones = { head = { angle = Angle(0, 0, 66), pos = Vector(0, -4.0, -7.0) } } },
                { time = 0.62, bones = { head = { angle = Angle(0, 0, 58), pos = Vector(0, -4.0, -6.0) } } },
                { time = 0.82, bones = { head = { angle = Angle(0, 0, 66), pos = Vector(0, -4.0, -7.0) } } },
                { time = 1.05, bones = { head = { angle = Angle(0, 0, 0), pos = Vector(0, 0, 0) } } }
            }
        }
    }

    local function createAxisConVars(prefix, description)
        return {
            x = CreateClientConVar(prefix .. "_x", "0", true, false, description .. " X."),
            y = CreateClientConVar(prefix .. "_y", "0", true, false, description .. " Y."),
            z = CreateClientConVar(prefix .. "_z", "0", true, false, description .. " Z.")
        }
    end

    local previewHeadRot = createAxisConVars("bmb_sheep_pose_head_rot", "Preview sheep head rotation")
    local previewHeadPos = createAxisConVars("bmb_sheep_pose_head_pos", "Preview sheep head position")
    local previewLegRot = {}

    for index = 0, 3 do
        previewLegRot[index] = createAxisConVars("bmb_sheep_pose_leg" .. index .. "_rot", "Preview sheep leg" .. index .. " rotation")
    end

    local function angleFromConVars(convars)
        return Angle(convars.x:GetFloat(), convars.y:GetFloat(), convars.z:GetFloat())
    end

    local function vectorFromConVars(convars)
        return Vector(convars.x:GetFloat(), convars.y:GetFloat(), convars.z:GetFloat())
    end

    local function lerpAngle(fromAngle, toAngle, fraction)
        return Angle(
            Lerp(fraction, fromAngle.p, toAngle.p),
            Lerp(fraction, fromAngle.y, toAngle.y),
            Lerp(fraction, fromAngle.r, toAngle.r)
        )
    end

    local function lerpVector(fromVector, toVector, fraction)
        return Vector(
            Lerp(fraction, fromVector.x, toVector.x),
            Lerp(fraction, fromVector.y, toVector.y),
            Lerp(fraction, fromVector.z, toVector.z)
        )
    end

    local function setBoneAngle(ent, boneId, angle)
        if not boneId then return end
        ent:ManipulateBoneAngles(boneId, angle or zeroAngle)
    end

    local function setBonePosition(ent, boneId, position)
        if not boneId then return end
        ent:ManipulateBonePosition(boneId, position or zeroVector)
    end

    local function applySheepPose(ent, bones, pose)
        pose = pose or {}

        for _, boneName in ipairs(sheepBoneNames) do
            local bonePose = pose[boneName] or {}

            setBoneAngle(ent, bones[boneName], bonePose.angle or zeroAngle)

            if boneName == "head" then
                setBonePosition(ent, bones[boneName], bonePose.pos or zeroVector)
            end
        end
    end

    local function sampleSheepAnimation(animation, elapsed)
        local frames = animation.frames
        if not frames or #frames == 0 then return nil end
        if elapsed <= frames[1].time then return frames[1].bones end

        for index = 1, #frames - 1 do
            local currentFrame = frames[index]
            local nextFrame = frames[index + 1]

            if elapsed <= nextFrame.time then
                local span = math.max(0.001, nextFrame.time - currentFrame.time)
                local fraction = math.Clamp((elapsed - currentFrame.time) / span, 0, 1)
                local pose = {}

                for _, boneName in ipairs(sheepBoneNames) do
                    local currentPose = (currentFrame.bones and currentFrame.bones[boneName]) or {}
                    local nextPose = (nextFrame.bones and nextFrame.bones[boneName]) or {}

                    if currentPose.angle or nextPose.angle or currentPose.pos or nextPose.pos then
                        pose[boneName] = {
                            angle = lerpAngle(currentPose.angle or zeroAngle, nextPose.angle or zeroAngle, fraction),
                            pos = lerpVector(currentPose.pos or zeroVector, nextPose.pos or zeroVector, fraction)
                        }
                    end
                end

                return pose
            end
        end

        return frames[#frames].bones
    end

    local function formatNumber(value)
        return string.format("%.2f", value or 0)
    end

    local function formatAngle(angle)
        return "Angle(" .. formatNumber(angle.p) .. ", " .. formatNumber(angle.y) .. ", " .. formatNumber(angle.r) .. ")"
    end

    local function formatVector(vec)
        return "Vector(" .. formatNumber(vec.x) .. ", " .. formatNumber(vec.y) .. ", " .. formatNumber(vec.z) .. ")"
    end

    concommand.Add("bmb_sheep_pose_print_keyframe", function()
        print("{ time = " .. formatNumber(previewKeyTime:GetFloat()) .. ", bones = {")
        print("    head = { angle = " .. formatAngle(angleFromConVars(previewHeadRot)) .. ", pos = " .. formatVector(vectorFromConVars(previewHeadPos)) .. " },")

        for index = 0, 3 do
            print("    leg" .. index .. " = { angle = " .. formatAngle(angleFromConVars(previewLegRot[index])) .. " },")
        end

        print("} },")
    end)

    local function resetSheepBones(ent, bones)
        applySheepPose(ent, bones, nil)
    end

    function ENT:CacheBMBSheepBones()
        local model = self:GetModel()
        if self.BMBSheepBoneCache and self.BMBSheepBoneCache.model == model then
            return self.BMBSheepBoneCache
        end

        self.BMBSheepBoneCache = {
            model = model,
            head = self:LookupBone("head"),
            leg0 = self:LookupBone("leg0"),
            leg1 = self:LookupBone("leg1"),
            leg2 = self:LookupBone("leg2"),
            leg3 = self:LookupBone("leg3")
        }

        return self.BMBSheepBoneCache
    end

    function ENT:UpdateBMBVisualBones()
        local bones = self:CacheBMBSheepBones()
        if not bones then return end

        local state = self:GetNWString("BMBState", "idle")
        if previewPose:GetBool() then
            setBoneAngle(self, bones.head, angleFromConVars(previewHeadRot))
            setBonePosition(self, bones.head, vectorFromConVars(previewHeadPos))
            setBoneAngle(self, bones.leg0, angleFromConVars(previewLegRot[0]))
            setBoneAngle(self, bones.leg1, angleFromConVars(previewLegRot[1]))
            setBoneAngle(self, bones.leg2, angleFromConVars(previewLegRot[2]))
            setBoneAngle(self, bones.leg3, angleFromConVars(previewLegRot[3]))
            return
        end

        if state == "dead" or self:GetNWBool("BMBDead", false) then
            resetSheepBones(self, bones)
            return
        end

        local speed = self:GetVelocity():Length2D()

        if state == "eat_grass" then
            local animation = sheepAnimations.eat_grass
            local startedAt = self:GetNWFloat("BMBEatGrassStartedAt", self:GetNWFloat("BMBStateStartedAt", CurTime()))
            local elapsed = math.Clamp(CurTime() - startedAt, 0, animation.duration)

            applySheepPose(self, bones, sampleSheepAnimation(animation, elapsed))
            return
        end

        setBonePosition(self, bones.head, zeroVector)

        if speed > 8 then
            local rate = math.Clamp(speed / 48.0, 1.1, 2.8)
            local swing = math.sin(CurTime() * rate * math.pi * 2.0) * 24.0
            local headBob = math.sin(CurTime() * rate * math.pi) * 2.0

            setBoneAngle(self, bones.head, Angle(0, 0, headBob))
            setBoneAngle(self, bones.leg0, Angle(0, 0, swing))
            setBoneAngle(self, bones.leg3, Angle(0, 0, swing))
            setBoneAngle(self, bones.leg1, Angle(0, 0, -swing))
            setBoneAngle(self, bones.leg2, Angle(0, 0, -swing))
            return
        end

        local idleHead = math.sin(CurTime() * 1.2) * 1.5
        setBoneAngle(self, bones.head, Angle(0, 0, idleHead))
        setBoneAngle(self, bones.leg0, zeroAngle)
        setBoneAngle(self, bones.leg1, zeroAngle)
        setBoneAngle(self, bones.leg2, zeroAngle)
        setBoneAngle(self, bones.leg3, zeroAngle)
    end
end

function ENT:Initialize()
    if CLIENT then return end

    self:BaseInitialize()
    self:SetBMBState("idle")
    self.FleeThreat = nil
    self.FleeThreatPosition = nil
    self.FleeUntil = 0
    self.BMBInitialIdleUntil = CurTime() + math.Rand(self.InitialIdleMin or 4.0, self.InitialIdleMax or 9.0)
    self.NextEatGrassTime = CurTime() + math.Rand(8.0, 20.0)
end

function ENT:RunBehaviour()
    while true do
        if self.BMBDead then return end

        local fleeThreat = IsValid(self.FleeThreat) and self.FleeThreat or self.FleeThreatPosition

        if self.BMBHeld then
            -- 物理枪持握中：行为整体挂起（拎在手里不乱蹬腿、不触发吃草/游荡；
            -- loco 缴械在 base Think 里做），松手后下一轮恢复正常调度
            self:SetBMBState("held")
            coroutine.wait(0.2)
        elseif self.RunBMBKnockback and self:RunBMBKnockback() then
            self.BMBDebugMoveActive = false
        elseif self.RunBMBDebugMove and self:RunBMBDebugMove() then
            self.BMBDebugMoveActive = true
        elseif self.RunBMBStrandedRecovery and self:RunBMBStrandedRecovery() then
            -- 物理上站住但 BMB 方块语义无支撑（玻璃板、脚下支撑失效等）时，
            -- 先逃回最近合法 standable 格，避免 Wander/Flee 从非法起点空转。
            self.BMBDebugMoveActive = false
        elseif CurTime() < self.FleeUntil and fleeThreat then
            self:SetBMBState("flee")
            BMB.Behaviors.Flee.Run(self, fleeThreat)
        elseif self.RunBMBInitialIdle and self:RunBMBInitialIdle() then
            self.BMBDebugMoveActive = false
        elseif BMB.Behaviors.EatGrass.Try(self) then
            self:SetBMBState("eat_grass")
        else
            self:SetBMBState("wander")
            BMB.Behaviors.Wander.Run(self)
        end

        coroutine.yield()
    end
end

function ENT:OnBMBInjured(damageInfo, wasFleeing)
    local attacker = damageInfo:GetAttacker()
    local damagePosition = damageInfo:GetDamagePosition()
    local damageForce = damageInfo:GetDamageForce()

    if IsValid(attacker) then
        self.FleeThreat = nil
        self.FleeThreatPosition = attacker:GetPos()
    elseif damagePosition and damagePosition:LengthSqr() > 1 then
        self.FleeThreat = nil
        self.FleeThreatPosition = damagePosition
    elseif damageForce and damageForce:LengthSqr() > 1 then
        damageForce:Normalize()
        self.FleeThreat = nil
        self.FleeThreatPosition = self:GetPos() - damageForce * 128
    end

    if self.FleeThreatPosition then
        self.FleeUntil = CurTime() + math.Rand(self.FleeDurationMin or 3.5, self.FleeDurationMax or 5.0)
    end

    if not wasFleeing and self.InterruptBMBMovement then
        self:InterruptBMBMovement()
    elseif not wasFleeing then
        self.BMBMoveInterrupt = true
    end

    self:EmitSound("npc/headcrab/pain1.wav", 70, math.random(98, 108), 0.55)
end
