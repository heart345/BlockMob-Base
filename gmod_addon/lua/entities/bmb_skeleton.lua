AddCSLuaFile()

ENT.Base = "bmb_base_mob"
ENT.Type = "nextbot"
ENT.PrintName = "BMB Skeleton"
ENT.Author = "Heart#"
ENT.Category = "BlockMob Base"
ENT.Spawnable = true
ENT.AdminOnly = false

-- M1 轨2 已重烘骷髅模型（手臂中性化 + 双足 rotate 0）。若模型有问题，回退占位：models/mcgm/zombie/zombie.mdl。
ENT.Model = "models/mcgm/skeleton/skeleton.mdl"
ENT.StartHealth = 70
ENT.WalkSpeed = 90
ENT.RunSpeed = 120
ENT.Acceleration = 420
ENT.Deceleration = 650

-- 索敌：放大到与僵尸相近，远处就发现玩家（远程攻击半径仍是 15 格，靠 chase 接近后才射）。
ENT.TargetRange = 1350
ENT.TargetLoseRange = 1725
ENT.TargetScanInterval = 0.35
ENT.TargetRequireLineOfSight = false

-- 接近段（Chase 复用）。strafe 会自己按距离修正，过冲 aim 线无所谓，故段超时拉长求平滑、不再短切。
ENT.ChaseRepathInterval = 0.4
ENT.ChaseSegmentTimeout = 1.0
ENT.ChaseFailureRepathDelay = 0.05
ENT.ChasePreferDirect = true
ENT.ChaseDirectDuration = 0.28
ENT.ChaseDirectProbeCells = 4

-- 远程战斗常量（MC 26.1，单位换算见 spec §7）：
ENT.RangedAttackRangeCells = 15    -- 攻击半径 15 格 = 547.5su
ENT.RangedAttackInterval = 2.0     -- 攻击间隔（MC 非困难 40 tick）
ENT.RangedDrawTime = 1.0           -- 满弓时长（MC 20 tick）
ENT.RangedSightGainTime = 1.0      -- 稳定看见 ≥1s 才从接近转 aim
ENT.RangedSightLossTime = -3.0     -- 丢失 ≤-3s 取消拉弓
ENT.RangedSpawnForward = 16        -- 箭生成点：眼睛前 X（手部近似，M2 接手骨）
ENT.RangedSpawnHeight = 50         -- 箭生成高度（脚底起算，约弓/手高；EyePos 对此 nextbot 偏低到裆部，故显式给）
ENT.ArrowSpeed = 1168
ENT.ArrowDamage = 6
ENT.ArrowSpread = 1               -- 散布锥角（度）；收紧让它更准（之前 3 在 15 格处可脱靶）
ENT.ArrowGravity = 730             -- MC 箭重力 ≈ 0.05 block/tick² = 730 su/s²（之前 320 太小→打太高）
ENT.ArrowArcTuning = 1.0           -- 抛物线补偿微调倍率（补偿本身按距离²精确算，1.0=精确；打高/低再微调）
ENT.RangedAimHeightFrac = 0.3333  -- 瞄准目标身高的几分之几处（MC performRangedAttack 的 getY(0.3333)=下半身躯干）；瞄眼睛会被小弧线误差从头顶掠过，打高调小、打低调大

-- 风筝走位（aim 内绕目标横移，MC RangedBowAttackGoal）：速度/换向节奏可调；身体转向用 TurnRate 跟 MC 30°/tick。
ENT.StrafeSpeed = 60
ENT.StrafeDiceInterval = 1.0
ENT.TurnRate = 540

-- 弓挂手（clientside 模型贴持弓手骨）。主手=右手(模型 leftArm 骨，视觉右侧=MC 主手)；
-- 5% 左撇子=左手(模型 rightArm 骨，视觉左侧，已实测调好)。
ENT.BowModelPath = "models/mcgm/bow/bow.mdl"
ENT.LeftHandedChance = 0.05
-- 右手(主)offset：游戏内实测。
ENT.BowAttachPos = Vector(-2, -20, -20)
ENT.BowAttachAng = Angle(4, 0, 0)
-- 左手(5%)offset：已实测。
ENT.BowAttachPosLeft = Vector(0.5, -18, -23)
ENT.BowAttachAngLeft = Angle(-5, 0, 0)
ENT.BowScale = 1
-- 拉弓帧（B1-B3）：拉弓进度切弓模型（弦/箭已烘进各帧贴图）。idle=BowModelPath(B0)。
ENT.BowPullModelPaths = {
    "models/mcgm/bow_pulling_0/bow_pulling_0.mdl", -- 进度 < 0.65（刚搭箭，轻微拉伸）
    "models/mcgm/bow_pulling_1/bow_pulling_1.mdl", -- 0.65 ~ 0.9
    "models/mcgm/bow_pulling_2/bow_pulling_2.mdl"  -- >= 0.9（满弓）
}
-- off-hand（非持弓手）搭弓姿态：pitch 按左右手镜像（右手主 -35 / 左撇子 35），roll -90；
-- 瞄准时 yaw 在 ±OffHandYawOscAmp 间缓慢摆（MC 式）。
ENT.RangedOffHandPitch = -35       -- 右手(主)
ENT.RangedOffHandPitchLeft = 35    -- 左撇子(5%)
ENT.RangedOffHandRoll = -90
ENT.OffHandYawOscAmp = 10
ENT.OffHandYawOscSpeed = 1.5

-- 游走（无目标）：MC 式低频随机散步。攻击性怪用短停顿，保证靠近时快速重扫目标转入攻击。
ENT.WanderDistanceMinCells = 2
ENT.WanderDistanceMaxCells = 5
ENT.WanderPauseMin = 0.5
ENT.WanderPauseMax = 1.5
ENT.WanderPathAttempts = 2

-- 逃狼（M1 仅逻辑就位，FindNearestWolfThreat 暂返回 nil 不触发）。
ENT.FleeWolfRangeCells = 6
ENT.FleeDurationMin = 2.0
ENT.FleeDurationMax = 2.5
ENT.FleePanicRadiusCells = 5
ENT.FleeKeepFullSpeed = true

ENT.CollisionMins = Vector(-10, -10, 0)
ENT.CollisionMaxs = Vector(10, 10, 72)

-- 程序化双足动画（占位僵尸模型骨）：腿反相摆 + 手臂无目标垂下 / 有目标抬弓（轴/值待实测）。
ENT.BipedLegSwingMax = 34
ENT.BipedArmSwingMax = 0
ENT.BipedArmForwardAngle = 0       -- 无目标手垂下
ENT.RangedAimArmAngle = -90        -- 有目标时持弓臂抬到水平前举（roll；M1 占位值，轴/符号待实测）
ENT.LimbSwingMinAmount = 0.3
ENT.LimbSwingPhaseScale = 0.12

-- 脚步音（客户端距离驱动，同僵尸双足；每半步波一声，StepSoundDistance≈pi/LimbSwingPhaseScale）。
ENT.StepSoundDistance = 26
ENT.StepSoundMinSpeed = 8
ENT.StepSoundLevel = 60
ENT.StepSoundVolumeMin = 0.42
ENT.StepSoundVolumeMax = 0.78
ENT.StepSoundPitchMin = 88
ENT.StepSoundPitchMax = 112
ENT.DeathTipDuration = 0.55
ENT.DeathTipDegrees = 90
ENT.TurnInPlaceAngle = 170

-- 头看向：沿用僵尸占位模型实测（换骷髅模型后再校）。
ENT.LookAtPitchSign = -1
ENT.LookAtPitchLimit = 35
ENT.LookAtEyeHeight = 64

-- Hop launch is now grounded-gated, so hostile hurt knockback can keep MC-style lift.
ENT.KnockbackUseJump = true
ENT.KnockbackVerticalSpeedScale = 6
ENT.KnockbackVerticalMinSpeed = 170
ENT.KnockbackVerticalMaxSpeed = 240
ENT.KnockbackDuration = 0.35

-- MC ambient 概率模型（同僵尸）。
ENT.AmbientSoundIntervalTicks = 80
ENT.AmbientSoundChanceDenominator = 1000
ENT.AmbientSoundTickRate = 20
ENT.AmbientSoundMaxCatchupTicks = 4

-- MC 骷髅音效（从 D:\BMBTools\解包音频\minecraft\sounds\mob\skeleton 复制，已重采样 44100Hz mono）。
-- 弓射击用 MC random/bow（归到 skeleton 目录命名 bow.ogg）。Idle=ambient say；Hurt/Death=受击钩子；Step=客户端距离驱动。
ENT.Sounds = {
    Idle = {
        "bmb/mob/skeleton/say1.ogg",
        "bmb/mob/skeleton/say2.ogg",
        "bmb/mob/skeleton/say3.ogg"
    },
    Hurt = {
        "bmb/mob/skeleton/hurt1.ogg",
        "bmb/mob/skeleton/hurt2.ogg",
        "bmb/mob/skeleton/hurt3.ogg",
        "bmb/mob/skeleton/hurt4.ogg"
    },
    Death = {
        "bmb/mob/skeleton/death.ogg"
    },
    Step = {
        "bmb/mob/skeleton/step1.ogg",
        "bmb/mob/skeleton/step2.ogg",
        "bmb/mob/skeleton/step3.ogg",
        "bmb/mob/skeleton/step4.ogg"
    },
    Shoot = {
        "bmb/mob/skeleton/bow.ogg"
    }
}

local function randomSound(list)
    if not list or #list == 0 then return nil end
    return list[math.random(#list)]
end

local skeletonSoundSets = {
    bmb_skeleton = ENT.Sounds,
    bmb_stray = {
        Idle = {
            "bmb/mob/stray/idle1.ogg",
            "bmb/mob/stray/idle2.ogg",
            "bmb/mob/stray/idle3.ogg",
            "bmb/mob/stray/idle4.ogg"
        },
        Hurt = {
            "bmb/mob/stray/hurt1.ogg",
            "bmb/mob/stray/hurt2.ogg",
            "bmb/mob/stray/hurt3.ogg",
            "bmb/mob/stray/hurt4.ogg"
        },
        Death = {
            "bmb/mob/stray/death1.ogg",
            "bmb/mob/stray/death2.ogg"
        },
        Step = {
            "bmb/mob/stray/step1.ogg",
            "bmb/mob/stray/step2.ogg",
            "bmb/mob/stray/step3.ogg",
            "bmb/mob/stray/step4.ogg"
        },
        Shoot = {
            "bmb/mob/skeleton/bow.ogg"
        }
    },
    bmb_parched = {
        Idle = {
            "bmb/mob/parched/ambient1.ogg",
            "bmb/mob/parched/ambient2.ogg",
            "bmb/mob/parched/ambient3.ogg",
            "bmb/mob/parched/ambient4.ogg"
        },
        Hurt = {
            "bmb/mob/parched/hurt1.ogg",
            "bmb/mob/parched/hurt2.ogg",
            "bmb/mob/parched/hurt3.ogg",
            "bmb/mob/parched/hurt4.ogg"
        },
        Death = {
            "bmb/mob/parched/death.ogg"
        },
        Step = {
            "bmb/mob/parched/step1.ogg",
            "bmb/mob/parched/step2.ogg",
            "bmb/mob/parched/step3.ogg",
            "bmb/mob/parched/step4.ogg"
        },
        Shoot = {
            "bmb/mob/skeleton/bow.ogg"
        }
    }
}

function ENT:GetBMBSkeletonSounds()
    return skeletonSoundSets[self:GetClass()] or self.Sounds or skeletonSoundSets.bmb_skeleton
end

if CLIENT then
    -- 弓挂手 offset 实时调（拖到贴合手再写回 ENT.BowAttachPos/Ang/BowScale 烘死）：
    CreateClientConVar("bmb_bow_off_x", "0", true, false)
    CreateClientConVar("bmb_bow_off_y", "0", true, false)
    CreateClientConVar("bmb_bow_off_z", "0", true, false)
    CreateClientConVar("bmb_bow_ang_p", "0", true, false)
    CreateClientConVar("bmb_bow_ang_y", "0", true, false)
    CreateClientConVar("bmb_bow_ang_r", "0", true, false)
    CreateClientConVar("bmb_bow_scale", "1", true, false)

    function ENT:CacheBMBSkeletonBones()
        local model = self:GetModel()
        if self.BMBSkeletonBoneCache and self.BMBSkeletonBoneCache.model == model then
            return self.BMBSkeletonBoneCache
        end

        self.BMBSkeletonBoneCache = {
            model = model,
            root = self:LookupBone("root"),
            head = self:LookupBone("head"),
            rightArm = self:LookupBone("rightArm"),
            leftArm = self:LookupBone("leftArm"),
            rightLeg = self:LookupBone("rightLeg"),
            leftLeg = self:LookupBone("leftLeg")
        }

        return self.BMBSkeletonBoneCache
    end

    -- 脚步：客户端按移动距离触发（同僵尸双足），跑动自动更密；MaybePlayStep 已覆盖为 no-op 不走 base 计时器。
    function ENT:UpdateBMBSkeletonStepSound(speed)
        speed = speed or self:GetVelocity():Length2D()

        if speed <= (self.StepSoundMinSpeed or 8) then
            self.BMBSkeletonStepDistance = 0
            return
        end

        local stepDistance = self.StepSoundDistance or 26
        self.BMBSkeletonStepDistance = (self.BMBSkeletonStepDistance or 0) + speed * FrameTime()
        if self.BMBSkeletonStepDistance < stepDistance then return end

        self.BMBSkeletonStepDistance = self.BMBSkeletonStepDistance - stepDistance

        local sounds = self:GetBMBSkeletonSounds()
        local soundName = randomSound(sounds and sounds.Step)
        if not soundName then return end

        local fullSpeed = math.max((self.StepSoundMinSpeed or 8) + 1, self.RunSpeed or 95)
        local speedFrac = math.Clamp((speed - (self.StepSoundMinSpeed or 8)) / (fullSpeed - (self.StepSoundMinSpeed or 8)), 0, 1)
        local volume = Lerp(speedFrac, self.StepSoundVolumeMin or 0.42, self.StepSoundVolumeMax or 0.78)
        self:EmitSound(soundName, self.StepSoundLevel or 60, math.random(self.StepSoundPitchMin or 88, self.StepSoundPitchMax or 112), volume)
    end

    function ENT:UpdateBMBVisualBones()
        local bones = self:CacheBMBSkeletonBones()
        if not bones then return end

        local state = self:GetNWString("BMBState", "idle")

        if state == "dead" or self:GetNWBool("BMBDead", false) then
            -- 死时手臂保持死前姿态：抬弓死则倒下仍抬着、垂手死则垂下（避免抬手死却垂手倒）。
            local armAng = self:GetNWBool("BMBSkeletonArmed", false)
                and (self.RangedAimArmAngle or -90)
                or (self.BipedArmForwardAngle or 0)
            self:SetBMBVisualBoneAngle(bones.head, angle_zero)
            self:SetBMBVisualBoneAngle(bones.rightArm, Angle(0, 0, armAng))
            self:SetBMBVisualBoneAngle(bones.leftArm, Angle(0, 0, armAng))
            self:SetBMBVisualBoneAngle(bones.rightLeg, angle_zero)
            self:SetBMBVisualBoneAngle(bones.leftLeg, angle_zero)

            if bones.root then
                local startedAt = self:GetNWFloat("BMBStateStartedAt", CurTime())
                local duration = self.DeathTipDuration or 0.55
                local t = duration > 0 and math.Clamp((CurTime() - startedAt) / duration, 0, 1) or 1
                local tip = t * (self.DeathTipDegrees or 90)
                local tipSign = (self:EntIndex() % 2 == 0) and 1 or -1
                self:SetBMBVisualBoneAngle(bones.root, Angle(0, tip * tipSign, 0))
            end

            return
        end

        -- 头：看向系统（与移动并行，有目标时 GetBMBForcedLookTarget 锁玩家）
        self:UpdateBMBLookAtHeadPose(bones.head)

        local speed = self:GetVelocity():Length2D()
        local phase, amount = self:UpdateBMBLimbSwing(speed)
        self:UpdateBMBSkeletonStepSound(speed)

        -- 腿走路摆 + 手臂静止（armSwing=0 停在 armForward）
        self:ApplyBMBBipedLocomotion(bones, phase, amount)

        -- 有目标就抬手持弓瞄准（用 NW bool，不看 state——受击 knockback/flee 时也保持抬起）。
        -- 持弓手抬到瞄准角；另一只手（off-hand）摆成搭在弓上的姿态。手别按左右撇子切换。
        if self:GetNWBool("BMBSkeletonArmed", false) then
            local aim = self.RangedAimArmAngle or -90
            local bowBone = bones[self:GetBMBBowHandBoneName()]
            local offBone = bones[self:GetBMBOffHandBoneName()]
            if bowBone then self:SetBMBVisualBoneAngle(bowBone, Angle(0, 0, aim)) end
            if offBone then self:SetBMBVisualBoneAngle(offBone, self:GetBMBOffHandAngle()) end
        end
    end

    -- 持弓手：主手=右手(模型 leftArm 骨)；左撇子=左手(模型 rightArm 骨)。off-hand 取另一只。
    function ENT:GetBMBBowHandBoneName()
        if self:GetNWBool("BMBLeftHanded", false) then return "rightArm" end
        return "leftArm"
    end

    function ENT:GetBMBOffHandBoneName()
        if self:GetNWBool("BMBLeftHanded", false) then return "leftArm" end
        return "rightArm"
    end

    function ENT:GetBMBOffHandAngle()
        -- pitch 按左右手镜像；yaw 在瞄准时 ±OffHandYawOscAmp 缓慢摆（MC 式）；roll 实测。
        local lh = self:GetNWBool("BMBLeftHanded", false)
        local pitch = lh and (self.RangedOffHandPitchLeft or 35) or (self.RangedOffHandPitch or -35)
        local yaw = math.sin(CurTime() * (self.OffHandYawOscSpeed or 1.5)) * (self.OffHandYawOscAmp or 10)
        return Angle(pitch, yaw, self.RangedOffHandRoll or -90)
    end

    function ENT:GetBMBBowOffset()
        -- 按左右撇子取烘死 offset；convar 非零时优先（游戏内调当前那只手）。
        local lh = self:GetNWBool("BMBLeftHanded", false)
        local basePos = (lh and self.BowAttachPosLeft or self.BowAttachPos) or vector_origin
        local baseAng = (lh and self.BowAttachAngLeft or self.BowAttachAng) or angle_zero

        local px = GetConVar("bmb_bow_off_x"):GetFloat()
        local py = GetConVar("bmb_bow_off_y"):GetFloat()
        local pz = GetConVar("bmb_bow_off_z"):GetFloat()
        local ap = GetConVar("bmb_bow_ang_p"):GetFloat()
        local ay = GetConVar("bmb_bow_ang_y"):GetFloat()
        local ar = GetConVar("bmb_bow_ang_r"):GetFloat()
        local sc = GetConVar("bmb_bow_scale"):GetFloat()

        local pos = (px ~= 0 or py ~= 0 or pz ~= 0) and Vector(px, py, pz) or basePos
        local ang = (ap ~= 0 or ay ~= 0 or ar ~= 0) and Angle(ap, ay, ar) or baseAng
        local scale = (sc and sc > 0) and sc or (self.BowScale or 1)
        return pos, ang, scale
    end

    -- 按拉弓进度选弓模型路径：未拉弓=idle(B0)；拉弓中按进度切 pulling_0/1/2（MC 阈值 0.65/0.9）。
    function ENT:GetBMBBowModelPath()
        local drawStart = self:GetNWFloat("BMBDrawStart", 0)
        if drawStart <= 0 then return self.BowModelPath end

        local pulls = self.BowPullModelPaths
        if not pulls then return self.BowModelPath end

        local progress = (CurTime() - drawStart) / (self.RangedDrawTime or 1.0)
        if progress >= 0.9 then return pulls[3] or self.BowModelPath end
        if progress >= 0.65 then return pulls[2] or self.BowModelPath end
        return pulls[1] or self.BowModelPath
    end

    function ENT:GetBMBBowModelFor(path)
        self.BMBBowModels = self.BMBBowModels or {}
        local bow = self.BMBBowModels[path]
        if not IsValid(bow) then
            bow = ClientsideModel(path, RENDERGROUP_OPAQUE)
            if not IsValid(bow) then return nil end
            bow:SetNoDraw(true)
            self.BMBBowModels[path] = bow
        end
        return bow
    end

    function ENT:DrawBMBBow()
        -- 死亡时不提前隐藏：弓继续贴手骨随尸体倾倒，最后在 OnRemove（poof 那刻）随骷髅一起消失。
        local bow = self:GetBMBBowModelFor(self:GetBMBBowModelPath())
        if not IsValid(bow) then return end

        local handBone = self:LookupBone(self:GetBMBBowHandBoneName())
        if not handBone then return end

        local m = self:GetBoneMatrix(handBone)
        if not m then return end

        local localPos, localAng, scale = self:GetBMBBowOffset()
        local pos, ang = LocalToWorld(localPos, localAng, m:GetTranslation(), m:GetAngles())

        bow:SetPos(pos)
        bow:SetAngles(ang)
        bow:SetModelScale(scale or 1, 0)
        bow:SetupBones()
        if self.DrawBMBModelWithMCLight then
            self:DrawBMBModelWithMCLight(bow)
        else
            bow:DrawModel()
        end
    end

    function ENT:Draw()
        -- 保留 base 的受击/死亡红闪 DrawModel，再画挂在手上的弓。
        local baseMob = scripted_ents.GetStored("bmb_base_mob")
        local baseTable = baseMob and baseMob.t
        if baseTable and baseTable.Draw then
            baseTable.Draw(self)
        else
            self:DrawModel()
        end
        self:DrawBMBBow()
    end

    function ENT:OnRemove()
        if self.BMBBowModels then
            for _, bow in pairs(self.BMBBowModels) do
                if IsValid(bow) then bow:Remove() end
            end
        end
    end
end

function ENT:Initialize()
    if CLIENT then return end

    self:BaseInitialize()
    self:SetBMBState("idle")
    self:SetNWBool("BMBLeftHanded", math.random() < (self.LeftHandedChance or 0.05))
    self.TargetEntity = nil
    self.NextTargetScanTime = 0
    self.NextRangedAttackTime = 0
    self.BMBDrawing = false
    self.BMBSeeTime = 0
    self:ResetBMBAmbientSoundTime()
    self.BMBNextAmbientSoundTickAt = CurTime() + math.Rand(0, 1 / (self.AmbientSoundTickRate or 20))
end

-- 最近的狼（6 格内）；现在没有狼实体，按类名前缀预测式匹配，将来狼 SENT 出现自动生效。
function ENT:FindNearestWolfThreat()
    local size = self.GetBMBBlockSize and self:GetBMBBlockSize() or (BMB.BS or 36.5)
    local radius = size * (self.FleeWolfRangeCells or 6)
    local origin = self:GetPos()
    local best, bestDistSqr = nil, radius * radius

    for _, ent in ipairs(ents.FindInSphere(origin, radius)) do
        if IsValid(ent) and ent ~= self then
            local class = ent:GetClass() or ""
            if string.find(class, "wolf", 1, true) then
                local d = origin:DistToSqr(ent:GetPos())
                if d <= bestDistSqr then
                    best, bestDistSqr = ent, d
                end
            end
        end
    end

    return best
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
            self:RunBMBSkeletonAI()
        end

        coroutine.yield()
    end
end

function ENT:RunBMBSkeletonRetaliationTarget()
    local target = self.BMBRetaliationTarget
    if not BMB.Behaviors.SeekTarget.IsValid(self, target, self.TargetLoseRange or self.TargetRange) then
        return false
    end

    self.TargetEntity = target
    self:SetNWBool("BMBSkeletonArmed", true)
    BMB.Behaviors.RangedAttack.Update(self, target)
    return true
end

function ENT:RunBMBSkeletonAILegacyMojibake()
    if self:RunBMBSkeletonRetaliationTarget() then return end

    local wolf = self:FindNearestWolfThreat()
    -- 1) 逃狼抢占一切（即使有玩家目标也先逃，不清 TargetEntity）。
    local wolf = self:FindNearestWolfThreat()
    if IsValid(wolf) then
        self:SetBMBState("flee")
        self.FleeUntil = CurTime() + math.Rand(self.FleeDurationMin or 2.0, self.FleeDurationMax or 2.5)
        BMB.Behaviors.Flee.Run(self, wolf)
        return
    end

    -- 2) 刷新目标
    self.TargetEntity = BMB.Behaviors.SeekTarget.Find(self, self.TargetEntity)
    self:SetNWBool("BMBSkeletonArmed", IsValid(self.TargetEntity))

    -- 3) 无目标 → 游走
    if not IsValid(self.TargetEntity) then
        self:SetBMBState("wander")
        BMB.Behaviors.Wander.Run(self)
        return
    end

    -- 4) 有目标 → 远程战斗（内部据距离/视线在 chase↔aim 切换 + strafe + 拉弓放箭）。
    -- 不在此 coroutine.wait：chase 段间的额外停顿会让 chase_direct 一走一停、速度上不满；
    -- RunBehaviour 每轮已 coroutine.yield，aim/strafe 逐 tick、chase 段背靠背连续。
    BMB.Behaviors.RangedAttack.Update(self, self.TargetEntity)
end

function ENT:RunBMBSkeletonAI()
    if self:RunBMBSkeletonRetaliationTarget() then return end

    local wolf = self:FindNearestWolfThreat()
    if IsValid(wolf) then
        self:SetBMBState("flee")
        self.FleeUntil = CurTime() + math.Rand(self.FleeDurationMin or 2.0, self.FleeDurationMax or 2.5)
        BMB.Behaviors.Flee.Run(self, wolf)
        return
    end

    self.TargetEntity = BMB.Behaviors.SeekTarget.Find(self, self.TargetEntity)
    self:SetNWBool("BMBSkeletonArmed", IsValid(self.TargetEntity))

    if not IsValid(self.TargetEntity) then
        self:SetBMBState("wander")
        BMB.Behaviors.Wander.Run(self)
        return
    end

    BMB.Behaviors.RangedAttack.Update(self, self.TargetEntity)
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

function ENT:PlayBMBRangedShootSound()
    local sounds = self:GetBMBSkeletonSounds()
    if not sounds or not sounds.Shoot then return end

    -- MC: pitch 倍率 1/(rand*0.4+0.8) ≈ 0.833~1.25 → GMod pitch 百分比。
    local pitch = math.Clamp(math.floor(100 / (math.Rand(0, 1) * 0.4 + 0.8)), 1, 255)
    self:EmitSound(randomSound(sounds.Shoot), 80, pitch, 1.0)
end

function ENT:OnBMBInjured(damageInfo, _)
    local sounds = self:GetBMBSkeletonSounds()
    if sounds and sounds.Hurt then
        self:EmitSound(randomSound(sounds.Hurt), 72, math.random(95, 105), 0.8)
    end
end

function ENT:OnKilled(damageInfo)
    if CLIENT then return end

    local sounds = self:GetBMBSkeletonSounds()
    if sounds and sounds.Death then
        self:EmitSound(randomSound(sounds.Death), 76, math.random(95, 105), 0.9)
    end

    self:BeginBMBDeath(damageInfo)
end

function ENT:MaybePlayStep()
    -- 骷髅脚步是客户端距离驱动（UpdateBMBSkeletonStepSound），不走 base 的计时器脚步。
end

function ENT:ResetBMBAmbientSoundTime()
    self.BMBAmbientSoundTime = -(self.AmbientSoundIntervalTicks or 80)
end

function ENT:MaybePlayIdleSound()
    local sounds = self:GetBMBSkeletonSounds()
    if not sounds or not sounds.Idle then return end

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
            self:EmitSound(randomSound(sounds.Idle), 72, math.random(92, 108), 0.6)
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
