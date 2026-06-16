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
-- 死亡序列：纯客户端脚本化骨骼倾倒（不再用物理尸体施力，避免方向随机/不稳）。
-- UsePhysicsCorpseOnDeath / DeathPoof* 用 base 默认（base 已是 false + Java poof 默认）。
ENT.DeathRemoveDelay = 1.5              -- 倒下约 0.55s + 侧躺约 0.95s 后移除
ENT.DeathTipDuration = 0.55             -- root 侧倒到位用时（快一点）
ENT.DeathTipDegrees = 90                -- 侧倒角度（0 → 90°）
ENT.EatGrassAnimationDuration = 1.8
ENT.EatGrassBiteDelay = 0.45
ENT.WalkSpeed = 70
-- 当前先按 GMod/MC 模型手感调到 100u/s；FleeKeepFullSpeed 防止拐弯时 HUD 目标速度掉到跑步阈值。
ENT.RunSpeed = 100
ENT.FleeKeepFullSpeed = true
-- 程序化腿摆：满速腿摆 25°，随速度连续缩放；MinAmount 给走路一个下限，使走/跑摆幅都更饱满。
ENT.LimbSwingMinAmount = 0.25
ENT.LimbSwingPhaseScale = 0.09
ENT.StepSoundDistance = 35
ENT.StepSoundMinSpeed = 8
ENT.StepSoundLevel = 58
ENT.StepSoundVolumeMin = 0.50
ENT.StepSoundVolumeMax = 0.82
ENT.StepSoundPitchMin = 88
ENT.StepSoundPitchMax = 112
ENT.AmbientSoundIntervalTicks = 80
ENT.AmbientSoundChanceDenominator = 1000
ENT.AmbientSoundTickRate = 20
ENT.AmbientSoundMaxCatchupTicks = 4
-- Sequence locomotion is parked until exported sheep pivots and low-speed playback are stable.
-- ENT.AnimationSequences = {
--     idle = "idle",
--     walk = "walk",
--     run = "walk"
-- }
-- ENT.AnimationReferenceSpeeds = {
--     walk = 70
-- }
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

ENT.Sounds = {
    Say = {
        "bmb/mob/sheep/say1.ogg",
        "bmb/mob/sheep/say2.ogg",
        "bmb/mob/sheep/say3.ogg"
    },
    Step = {
        "bmb/mob/sheep/step1.ogg",
        "bmb/mob/sheep/step2.ogg",
        "bmb/mob/sheep/step3.ogg",
        "bmb/mob/sheep/step4.ogg",
        "bmb/mob/sheep/step5.ogg"
    },
    EatGrass = {
        "bmb/dig/grass1.ogg",
        "bmb/dig/grass2.ogg",
        "bmb/dig/grass3.ogg",
        "bmb/dig/grass4.ogg"
    }
}

local function randomSound(list)
    if not list or #list == 0 then return nil end
    return list[math.random(1, #list)]
end

if CLIENT then
    local zeroAngle = Angle(0, 0, 0)
    local zeroVector = Vector(0, 0, 0)
    local legSwingMax = 25.0
    local previewPose = CreateClientConVar("bmb_sheep_pose_preview", "0", true, false, "Preview sheep bone transforms live.")
    local previewKeyTime = CreateClientConVar("bmb_sheep_pose_key_time", "0", true, false, "Printed sheep keyframe time.")

    local sheepBoneNames = { "head", "leg0", "leg1", "leg2", "leg3" }

    local sheepAnimations = {
        eat_grass = {
            duration = 1.8,
            frames = {
                -- 低头吃草（实测：head 骨骼 roll 轴=俯仰，负值低头；够地姿势 roll -55 + pos Y -12）。
                -- 顺序：① pos Y 先下探到 -12（rot 不动）；② roll 低到 -55 够地（与 EatGrassBiteDelay 对齐咬草）；
                -- ③ roll 在 -55↔-40 之间咀嚼循环两回；④ rot 和 pos 一起均匀收回 0。
                { time = 0.00, bones = { head = { angle = Angle(0, 0, 0),   pos = Vector(0,   0, 0) } } },
                { time = 0.25, bones = { head = { angle = Angle(0, 0, 0),   pos = Vector(0, -12, 0) } } },
                { time = 0.45, bones = { head = { angle = Angle(0, 0, -55), pos = Vector(0, -12, 0) } } },
                { time = 0.70, bones = { head = { angle = Angle(0, 0, -40), pos = Vector(0, -12, 0) } } },
                { time = 0.95, bones = { head = { angle = Angle(0, 0, -55), pos = Vector(0, -12, 0) } } },
                { time = 1.20, bones = { head = { angle = Angle(0, 0, -40), pos = Vector(0, -12, 0) } } },
                { time = 1.45, bones = { head = { angle = Angle(0, 0, -55), pos = Vector(0, -12, 0) } } },
                { time = 1.80, bones = { head = { angle = Angle(0, 0, 0),   pos = Vector(0,   0, 0) } } }
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

        print("} },")
    end)

    local function resetSheepBones(ent, bones)
        applySheepPose(ent, bones, nil)
        ent.BMBSheepHeadPoseCleared = true
    end

    local function clearSheepHeadPoseOnce(ent, bones)
        if ent.BMBSheepHeadPoseCleared then return end

        setBoneAngle(ent, bones.head, zeroAngle)
        setBonePosition(ent, bones.head, zeroVector)
        ent.BMBSheepHeadPoseCleared = true
    end

    function ENT:UpdateBMBSheepStepSound(speed)
        speed = speed or self:GetVelocity():Length2D()

        if speed <= (self.StepSoundMinSpeed or 8) then
            self.BMBSheepStepDistance = 0
            return
        end

        local stepDistance = self.StepSoundDistance or 35
        self.BMBSheepStepDistance = (self.BMBSheepStepDistance or 0) + speed * FrameTime()
        if self.BMBSheepStepDistance < stepDistance then return end

        self.BMBSheepStepDistance = self.BMBSheepStepDistance - stepDistance

        local soundName = randomSound(self.Sounds and self.Sounds.Step)
        if not soundName then return end

        local speedFrac = math.Clamp((speed - (self.WalkSpeed or 70)) / math.max(1, (self.RunSpeed or 100) - (self.WalkSpeed or 70)), 0, 1)
        local volume = Lerp(speedFrac, self.StepSoundVolumeMin or 0.28, self.StepSoundVolumeMax or 0.48)
        self:EmitSound(soundName, self.StepSoundLevel or 58, math.random(self.StepSoundPitchMin or 88, self.StepSoundPitchMax or 112), volume)
    end

    function ENT:CacheBMBSheepBones()
        local model = self:GetModel()
        if self.BMBSheepBoneCache and self.BMBSheepBoneCache.model == model then
            return self.BMBSheepBoneCache
        end

        self.BMBSheepBoneCache = {
            model = model,
            root = self:LookupBone("root"),
            body = self:LookupBone("body"),
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
            self.BMBSheepHeadPoseCleared = false
            return
        end

        if state == "dead" or self:GetNWBool("BMBDead", false) then
            -- 脚本化侧倒：绕 root 从 0 lerp 到 DeathTipDegrees，约 DeathTipDuration 秒倒完停住。
            -- head/leg 是 root 的子骨骼，随 root 整只翻；自身归零冻住、不再摆动。
            resetSheepBones(self, bones)

            if bones.root then
                local startedAt = self:GetNWFloat("BMBStateStartedAt", CurTime())
                local duration = self.DeathTipDuration or 0.8
                local t = duration > 0 and math.Clamp((CurTime() - startedAt) / duration, 0, 1) or 1
                local tip = t * (self.DeathTipDegrees or 90)
                -- 侧倒：实测 roll(第三分量)=后仰；侧躺是 yaw(第二分量)。左右随机用 EntIndex 固定方向。
                local tipSign = (self:EntIndex() % 2 == 0) and 1 or -1
                setBoneAngle(self, bones.root, Angle(0, tip * tipSign, 0))
            end

            return
        end

        if state == "eat_grass" then
            local animation = sheepAnimations.eat_grass
            local startedAt = self:GetNWFloat("BMBEatGrassStartedAt", self:GetNWFloat("BMBStateStartedAt", CurTime()))
            local elapsed = math.Clamp(CurTime() - startedAt, 0, animation.duration)

            applySheepPose(self, bones, sampleSheepAnimation(animation, elapsed))
            self.BMBSheepHeadPoseCleared = false
            return
        end

        local lookAtActive = self:UpdateBMBLookAtHeadPose(bones.head)
        if lookAtActive then
            self.BMBSheepHeadPoseCleared = false
        else
            clearSheepHeadPoseOnce(self, bones)
        end

        local speed = self:GetVelocity():Length2D()
        -- 摆幅/频率统一走 base 的连续驱动:幅度随速度连续缩放,频率随速度推进。
        local phase, swingAmount = self:UpdateBMBLimbSwing(speed)
        self:UpdateBMBSheepStepSound(speed)

        local legSwing = math.sin(phase) * legSwingMax * swingAmount

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
    self.FleeThreat = nil
    self.FleeThreatPosition = nil
    self.FleeUntil = 0
    self.BMBInitialIdleUntil = CurTime() + math.Rand(self.InitialIdleMin or 4.0, self.InitialIdleMax or 9.0)
    self.NextEatGrassTime = CurTime() + math.Rand(8.0, 20.0)
    self:ResetBMBAmbientSoundTime()
    self.BMBNextAmbientSoundTickAt = CurTime() + math.Rand(0, 1 / (self.AmbientSoundTickRate or 20))
end

function ENT:ResetBMBAmbientSoundTime()
    self.BMBAmbientSoundTime = -(self.AmbientSoundIntervalTicks or 80)
end

function ENT:PlayBMBSheepSay(volume)
    local soundName = randomSound(self.Sounds and self.Sounds.Say)
    if not soundName then return end

    self:EmitSound(soundName, 70, math.random(90, 110), volume or 0.65)
end

function ENT:MaybePlayIdleSound()
    if self.BMBDead then return end

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
            self:PlayBMBSheepSay(0.92)
            self:ResetBMBAmbientSoundTime()
        else
            self.BMBAmbientSoundTime = soundTime + 1
        end
    end

    self.BMBNextAmbientSoundTickAt = nextTick + ticks * tickInterval
    if self.BMBNextAmbientSoundTickAt < now - tickInterval then
        self.BMBNextAmbientSoundTickAt = now + tickInterval
    end
end

function ENT:MaybePlayStep()
    -- Sheep footsteps are client-side and distance-driven from the same speed integration as the visual leg phase.
end

function ENT:PlayBMBEatGrassSound()
    local soundName = randomSound(self.Sounds and self.Sounds.EatGrass)
    if not soundName then return end

    self:EmitSound(soundName, 64, math.random(92, 108), 0.82)
end

function ENT:OnBMBHurtSound(_)
    self:PlayBMBSheepSay(0.98)
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
end
