AddCSLuaFile()

ENT.Base = "bmb_base_mob"
ENT.Type = "nextbot"
ENT.PrintName = "BMB Prototype Skeleton"
ENT.Author = "BMB"
ENT.Category = "BlockMob Base"
ENT.Spawnable = true
ENT.AdminOnly = false

-- M1 轨2 已重烘骷髅模型（手臂中性化 + 双足 rotate 0）。若模型有问题，回退占位：models/mcgm/zombie/zombie.mdl。
ENT.Model = "models/mcgm/skeleton/skeleton.mdl"
ENT.StartHealth = 20
ENT.WalkSpeed = 90
ENT.RunSpeed = 120
ENT.Acceleration = 420
ENT.Deceleration = 650

-- 索敌：放大到与僵尸相近，远处就发现玩家（远程攻击半径仍是 15 格，靠 chase 接近后才射）。
ENT.TargetRange = 1350
ENT.TargetLoseRange = 1725
ENT.TargetScanInterval = 0.35
ENT.TargetRequireLineOfSight = false

-- 接近段（Chase 复用）。段超时短一点，让 ResolveMovement 频繁复评、少冲过 15 格 aim 线。
ENT.ChaseRepathInterval = 0.4
ENT.ChaseSegmentTimeout = 0.3
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
ENT.ArrowSpread = 3
ENT.ArrowGravity = 730             -- MC 箭重力 ≈ 0.05 block/tick² = 730 su/s²（之前 320 太小→打太高）
ENT.ArrowArcTuning = 1.0           -- 抛物线补偿微调倍率（补偿本身按距离²精确算，1.0=精确；打高/低再微调）

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
ENT.DeathTipDuration = 0.55
ENT.DeathTipDegrees = 90
ENT.TurnInPlaceAngle = 170

-- 头看向：沿用僵尸占位模型实测（换骷髅模型后再校）。
ENT.LookAtPitchSign = -1
ENT.LookAtPitchLimit = 35
ENT.LookAtEyeHeight = 64

-- 受击不转成跳跃（同僵尸，敌对怪）。延长击退窗口让被打后退后明显（aim 怪打完会立刻停下，0.12s 推不动）。
ENT.KnockbackUseJump = false
ENT.KnockbackVerticalSpeedScale = 0
ENT.KnockbackVerticalMinSpeed = 0
ENT.KnockbackVerticalMaxSpeed = 0
ENT.KnockbackDuration = 0.35

-- MC ambient 概率模型（同僵尸）。
ENT.AmbientSoundIntervalTicks = 80
ENT.AmbientSoundChanceDenominator = 1000
ENT.AmbientSoundTickRate = 20
ENT.AmbientSoundMaxCatchupTicks = 4

-- M1 占位音效：用引擎自带音保证可听、不刷缺文件警告；MC 骷髅 OGG 由声音收尾批替换 + resource.AddFile。
ENT.Sounds = {
    Idle = {
        "npc/zombie/zombie_voice_idle1.wav",
        "npc/zombie/zombie_voice_idle2.wav",
        "npc/zombie/zombie_voice_idle3.wav"
    },
    Hurt = {
        "npc/zombie/zombie_pain1.wav",
        "npc/zombie/zombie_pain2.wav",
        "npc/zombie/zombie_pain3.wav"
    },
    Death = {
        "npc/zombie/zombie_die1.wav",
        "npc/zombie/zombie_die2.wav"
    },
    Shoot = {
        "weapons/crossbow/fire1.wav"
    }
}

local function randomSound(list)
    return list[math.random(#list)]
end

local function validTarget(target)
    if not IsValid(target) then return false end

    if target:IsPlayer() then
        return target:Alive()
    end

    return false
end

if CLIENT then
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

        -- 腿走路摆 + 手臂静止（armSwing=0 停在 armForward）
        self:ApplyBMBBipedLocomotion(bones, phase, amount)

        -- 有目标就抬持弓臂（用 NW bool，不看 state——受击 knockback/flee 时也保持抬起，不垂下）。
        -- M1 占位 = 双臂抬到 RangedAimArmAngle；M2 换骷髅模型后改成持弓臂追目标指向。
        if self:GetNWBool("BMBSkeletonArmed", false) then
            local aim = self.RangedAimArmAngle or -90
            self:SetBMBVisualBoneAngle(bones.rightArm, Angle(0, 0, aim))
            self:SetBMBVisualBoneAngle(bones.leftArm, Angle(0, 0, aim))
        end
    end
end

function ENT:Initialize()
    if CLIENT then return end

    self:BaseInitialize()
    self:SetBMBState("idle")
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

function ENT:RunBMBSkeletonAI()
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

    -- 4) 有目标 → 远程战斗（内部据距离/视线在 chase↔aim 切换 + 拉弓放箭）
    BMB.Behaviors.RangedAttack.Update(self, self.TargetEntity)
    coroutine.wait(0.05)
end

function ENT:CanBMBTarget(target)
    return validTarget(target)
end

function ENT:GetBMBForcedLookTarget()
    if IsValid(self.TargetEntity) and self.TargetEntity:IsPlayer() then
        return self.TargetEntity
    end
    return nil
end

function ENT:PlayBMBRangedShootSound()
    if not self.Sounds or not self.Sounds.Shoot then return end

    -- MC: pitch 倍率 1/(rand*0.4+0.8) ≈ 0.833~1.25 → GMod pitch 百分比。
    local pitch = math.Clamp(math.floor(100 / (math.Rand(0, 1) * 0.4 + 0.8)), 1, 255)
    self:EmitSound(randomSound(self.Sounds.Shoot), 80, pitch, 1.0)
end

function ENT:OnBMBInjured(damageInfo, _)
    local attacker = damageInfo:GetAttacker()

    if self:CanBMBTarget(attacker) then
        self.TargetEntity = attacker
        self.NextTargetScanTime = 0
    end

    if self.Sounds and self.Sounds.Hurt then
        self:EmitSound(randomSound(self.Sounds.Hurt), 72, math.random(95, 105), 0.8)
    end
end

function ENT:OnKilled(damageInfo)
    if CLIENT then return end

    if self.Sounds and self.Sounds.Death then
        self:EmitSound(randomSound(self.Sounds.Death), 76, math.random(95, 105), 0.9)
    end

    self:BeginBMBDeath(damageInfo)
end

function ENT:ResetBMBAmbientSoundTime()
    self.BMBAmbientSoundTime = -(self.AmbientSoundIntervalTicks or 80)
end

function ENT:MaybePlayIdleSound()
    if not self.Sounds or not self.Sounds.Idle then return end

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
            self:EmitSound(randomSound(self.Sounds.Idle), 72, math.random(92, 108), 0.6)
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
