AddCSLuaFile()

ENT.Base = "bmb_base_mob"
ENT.Type = "nextbot"
ENT.PrintName = "BMB Prototype Zombie"
ENT.Author = "BMB"
ENT.Category = "BlockMob Base"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Model = "models/mcgm/zombie/zombie.mdl"
ENT.StartHealth = 20
ENT.WalkSpeed = 65
ENT.RunSpeed = 70
ENT.Acceleration = 420
ENT.Deceleration = 650
ENT.TargetRange = 1350
ENT.TargetLoseRange = 1725
ENT.TargetScanInterval = 0.35
ENT.TargetRequireLineOfSight = false
ENT.ChaseRepathInterval = 0.5
ENT.ChaseSegmentTimeout = 2.0
ENT.ChaseFailureRepathDelay = 0.05
ENT.ChasePreferDirect = true
ENT.ChaseDirectDuration = 0.28
ENT.ChaseDirectMaxDistanceCells = 6
ENT.ChaseDirectProbeCells = 4
ENT.ChaseHighTargetHoldCells = 1.65
ENT.ChaseHighTargetStalkDelay = 0.12
ENT.WanderDistanceMinCells = 2
ENT.WanderDistanceMaxCells = 5
ENT.WanderPauseMin = 0.5
ENT.WanderPauseMax = 1.8
ENT.WanderPathAttempts = 1
ENT.WanderFailurePauseMin = 0.35
ENT.WanderFailurePauseMax = 0.8
ENT.AttackRange = 60
ENT.AttackVerticalRange = 28
ENT.AttackVerticalOverlapRange = 86
ENT.AttackVerticalOverlapFlatRange = 24
ENT.AttackDamage = 10
ENT.AttackCooldown = 1.0
ENT.AttackHitDelay = 0
ENT.AttackMoveSpeed = 70
ENT.AttackHitSlop = 16
ENT.AttackKnockback = 150
ENT.AttackVerticalKnockback = 155
ENT.AttackGroundedVerticalKnockback = 190
ENT.HitViewPunchPitch = -0.85
ENT.HitViewPunchYaw = 0.38
ENT.HitScreenShakeAmplitude = 0.85
ENT.HitScreenShakeFrequency = 12
ENT.HitScreenShakeDuration = 0.11
ENT.HitScreenShakeRadius = 96
ENT.AmbientSoundIntervalTicks = 80
ENT.AmbientSoundChanceDenominator = 1000
ENT.AmbientSoundTickRate = 20
ENT.AmbientSoundMaxCatchupTicks = 4
ENT.StepSoundDistance = 26          -- ~= pi / LimbSwingPhaseScale: one foot plant per half gait wave
ENT.StepSoundMinSpeed = 8
ENT.StepSoundLevel = 60
ENT.StepSoundVolumeMin = 0.45
ENT.StepSoundVolumeMax = 0.78
ENT.StepSoundPitchMin = 88
ENT.StepSoundPitchMax = 112
ENT.CollisionMins = Vector(-11, -11, 0)
ENT.CollisionMaxs = Vector(11, 11, 72)
-- 程序化双足动画（不再用模型 sequence / ACT_WALK）：腿反相摆 + 手臂前伸轻微摆，攻击播手臂前挥关键帧。
ENT.BipedLegSwingMax = 38          -- 腿摆幅（roll 轴，实测调）
ENT.BipedArmSwingMax = 0           -- 手臂不走路摆，静止停在 armForward（前伸基角）
ENT.BipedArmForwardAngle = -90     -- 手臂前伸基角（roll；-90≈水平平举，更负=更高，约 -90 后可能拧轴）
ENT.AttackKeyframeDuration = 0.6   -- 攻击手臂上抬关键帧时长（抬/落都放慢）
ENT.DeathTipDuration = 0.55        -- 死亡侧倒用时（复用羊脚本化倾倒）
ENT.DeathTipDegrees = 90
ENT.LimbSwingMinAmount = 0.3       -- 走路也保持可见腿摆
ENT.LimbSwingPhaseScale = 0.12     -- 腿频率（实测调）
ENT.TurnInPlaceAngle = 170
ENT.BlockHopAllowCloseLaunch = true
-- 头看向：僵尸头骨 pitch 轴与羊相反（玩家在上方时羊抬头、僵尸会低头），翻号纠正；放宽 pitch 范围以便仰视近处/高处玩家。
ENT.LookAtPitchSign = -1
ENT.LookAtPitchLimit = 35
ENT.LookAtEyeHeight = 64            -- 头部高度，pitch 从此高度算，玩家与头同高时平视（不再近距离猛仰头）
-- Chasing zombies should not turn ordinary hurt knockback into a locomotion jump on MC block tops.
ENT.KnockbackUseJump = false
ENT.KnockbackVerticalSpeedScale = 0
ENT.KnockbackVerticalMinSpeed = 0
ENT.KnockbackVerticalMaxSpeed = 0

ENT.Sounds = {
    Say = {
        "bmb/mob/zombie/say1.ogg",
        "bmb/mob/zombie/say2.ogg",
        "bmb/mob/zombie/say3.ogg"
    },
    Hurt = {
        "bmb/mob/zombie/hurt1.ogg",
        "bmb/mob/zombie/hurt2.ogg"
    },
    Death = {
        "bmb/mob/zombie/death.ogg"
    },
    Step = {
        "bmb/mob/zombie/step1.ogg",
        "bmb/mob/zombie/step2.ogg",
        "bmb/mob/zombie/step3.ogg",
        "bmb/mob/zombie/step4.ogg",
        "bmb/mob/zombie/step5.ogg"
    },
    Hit = {
        "bmb/damage/hit1.ogg",
        "bmb/damage/hit2.ogg",
        "bmb/damage/hit3.ogg"
    }
}

local function randomSound(list)
    if not list or #list == 0 then return nil end
    return list[math.random(1, #list)]
end

local zombieSoundSets = {
    bmb_zombie = ENT.Sounds,
    bmb_husk = {
        Say = {
            "bmb/mob/husk/idle1.ogg",
            "bmb/mob/husk/idle2.ogg",
            "bmb/mob/husk/idle3.ogg"
        },
        Hurt = {
            "bmb/mob/husk/hurt1.ogg",
            "bmb/mob/husk/hurt2.ogg"
        },
        Death = {
            "bmb/mob/husk/death1.ogg",
            "bmb/mob/husk/death2.ogg"
        },
        Step = {
            "bmb/mob/husk/step1.ogg",
            "bmb/mob/husk/step2.ogg",
            "bmb/mob/husk/step3.ogg",
            "bmb/mob/husk/step4.ogg",
            "bmb/mob/husk/step5.ogg"
        },
        Hit = {
            "bmb/damage/hit1.ogg",
            "bmb/damage/hit2.ogg",
            "bmb/damage/hit3.ogg"
        }
    }
}

function ENT:GetBMBZombieSounds()
    return zombieSoundSets[self:GetClass()] or self.Sounds or zombieSoundSets.bmb_zombie
end

local function validTarget(target)
    if not IsValid(target) then return false end

    if target:IsPlayer() then
        return target:Alive()
    end

    return false
end

if CLIENT then
    local zombieAnimations = {
        -- 攻击：双臂从水平基线上抬再回水平（roll 偏移，同 armForward 轴，叠加在 BipedArmForwardAngle 上；更负=抬更高）。抬/落都放慢。
        attack = {
            duration = 0.6,
            frames = {
                { time = 0.00, bones = { rightArm = { angle = Angle(0, 0, 0) }, leftArm = { angle = Angle(0, 0, 0) } } },   -- 水平基线
                { time = 0.25, bones = { rightArm = { angle = Angle(0, 0, -45) }, leftArm = { angle = Angle(0, 0, -45) } } }, -- 上抬（慢抬，更负=更高）
                { time = 0.60, bones = { rightArm = { angle = Angle(0, 0, 0) }, leftArm = { angle = Angle(0, 0, 0) } } }    -- 慢放回水平
            }
        }
    }

    function ENT:UpdateBMBZombieStepSound(speed)
        speed = speed or self:GetVelocity():Length2D()

        if speed <= (self.StepSoundMinSpeed or 8) then
            self.BMBZombieStepDistance = 0
            return
        end

        local stepDistance = self.StepSoundDistance or 26
        self.BMBZombieStepDistance = (self.BMBZombieStepDistance or 0) + speed * FrameTime()
        if self.BMBZombieStepDistance < stepDistance then return end

        self.BMBZombieStepDistance = self.BMBZombieStepDistance - stepDistance

        local sounds = self:GetBMBZombieSounds()
        local soundName = randomSound(sounds and sounds.Step)
        if not soundName then return end

        local fullSpeed = math.max((self.StepSoundMinSpeed or 8) + 1, self.RunSpeed or 95)
        local speedFrac = math.Clamp((speed - (self.StepSoundMinSpeed or 8)) / (fullSpeed - (self.StepSoundMinSpeed or 8)), 0, 1)
        local volume = Lerp(speedFrac, self.StepSoundVolumeMin or 0.45, self.StepSoundVolumeMax or 0.78)
        self:EmitSound(soundName, self.StepSoundLevel or 60, math.random(self.StepSoundPitchMin or 88, self.StepSoundPitchMax or 112), volume)
    end

    function ENT:CacheBMBZombieBones()
        local model = self:GetModel()
        if self.BMBZombieBoneCache and self.BMBZombieBoneCache.model == model then
            return self.BMBZombieBoneCache
        end

        self.BMBZombieBoneCache = {
            model = model,
            root = self:LookupBone("root"),
            head = self:LookupBone("head"),
            rightArm = self:LookupBone("rightArm"),
            leftArm = self:LookupBone("leftArm"),
            rightLeg = self:LookupBone("rightLeg"),
            leftLeg = self:LookupBone("leftLeg")
        }

        return self.BMBZombieBoneCache
    end

    function ENT:UpdateBMBVisualBones()
        local bones = self:CacheBMBZombieBones()
        if not bones then return end

        local state = self:GetNWString("BMBState", "idle")

        if state == "dead" or self:GetNWBool("BMBDead", false) then
            -- 脚本化侧倒：冻结头/腿，手臂保持前伸（直挺挺前伸着栽下去），绕 root 整只翻。
            local armForward = self.BipedArmForwardAngle or 0
            self:SetBMBVisualBoneAngle(bones.head, angle_zero)
            self:SetBMBVisualBoneAngle(bones.rightArm, Angle(0, 0, armForward))
            self:SetBMBVisualBoneAngle(bones.leftArm, Angle(0, 0, armForward))
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

        -- 头：看向系统（与移动并行，只控头）
        self:UpdateBMBLookAtHeadPose(bones.head)

        local speed = self:GetVelocity():Length2D()
        local phase, amount = self:UpdateBMBLimbSwing(speed)
        self:UpdateBMBZombieStepSound(speed)

        -- 腿 + 手臂走路摆（双足通用：腿反相 + 手臂前伸 + 轻微反相摆）
        self:ApplyBMBBipedLocomotion(bones, phase, amount)

        -- 攻击窗内：手臂改播前挥关键帧（叠在前伸基线上），覆盖走路臂摆；腿继续走
        local attackStart = self:GetNWFloat("BMBAttackStartedAt", 0)
        if attackStart > 0 then
            local elapsed = CurTime() - attackStart
            local duration = self.AttackKeyframeDuration or 0.5
            if elapsed >= 0 and elapsed <= duration then
                local pose = BMB.SampleKeyframeAnimation(zombieAnimations.attack, elapsed)
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

function ENT:Initialize()
    if CLIENT then return end

    self:BaseInitialize()
    self:SetBMBState("idle")
    self.TargetEntity = nil
    self.NextTargetScanTime = 0
    self.NextMeleeAttackTime = 0
    self:ResetBMBAmbientSoundTime()
    self.BMBNextAmbientSoundTickAt = CurTime() + math.Rand(0, 1 / (self.AmbientSoundTickRate or 20))
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
            self:RunBMBZombieAI()
        end

        coroutine.yield()
    end
end

function ENT:RunBMBZombieAI()
    self.TargetEntity = BMB.Behaviors.SeekTarget.Find(self, self.TargetEntity)

    if not IsValid(self.TargetEntity) then
        self:SetBMBState("wander")
        BMB.Behaviors.Wander.Run(self)
        return
    end

    if BMB.Behaviors.MeleeAttack.Try(self, self.TargetEntity) then
        coroutine.wait(0.05)
        return
    end

    self:SetBMBState("chase")
    if not BMB.Behaviors.Chase.Run(self, self.TargetEntity) then
        if BMB.Behaviors.SeekTarget.IsValid(self, self.TargetEntity, self.TargetLoseRange or self.TargetRange) then
            if BMB.Behaviors.Chase.StalkHighTarget(self, self.TargetEntity) then return end

            self:SetBMBState("chase")
            self:SetBMBMoveMode("chase_repath")
            if BMB.Behaviors.Chase.ApplySafePressure then
                BMB.Behaviors.Chase.ApplySafePressure(
                    self,
                    self.TargetEntity,
                    self.RunSpeed,
                    "chase_repath",
                    self.ChaseRepathProbeDistance or self:GetBMBBlockSize() * 1.5
                )
            else
                self:MaintainBMBMoveSpeed(self.RunSpeed, self.RunSpeed)
                self:FaceTarget(self.TargetEntity:GetPos())
            end
            coroutine.wait(self.ChaseFailureRepathDelay or 0.08)
        else
            self.TargetEntity = nil
            self:InterruptibleWait(math.Rand(0.25, 0.55))
        end
    end
end

function ENT:CanBMBTarget(target)
    return validTarget(target)
end

function ENT:GetBMBForcedLookTarget()
    -- 追击/攻击中头锁死盯玩家；无目标时回落到 base 概率环视。
    if IsValid(self.TargetEntity) and self.TargetEntity:IsPlayer() then
        return self.TargetEntity
    end
    return nil
end

function ENT:PlayBMBMeleeGesture(_)
    -- 程序化攻击：标记攻击开始时刻，客户端 UpdateBMBVisualBones 播手臂前挥关键帧。
    self:SetNWFloat("BMBAttackStartedAt", CurTime())
end

function ENT:ApplyBMBPlayerHitFeedback(target)
    if not IsValid(target) or not target:IsPlayer() then return end

    if target.ViewPunch then
        local pitch = self.HitViewPunchPitch or -0.55
        local yaw = self.HitViewPunchYaw or 0.28
        target:ViewPunch(Angle(pitch, math.Rand(-yaw, yaw), 0))
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

function ENT:OnBMBMeleeHit(target, _)
    if not IsValid(target) then return end

    local sounds = self:GetBMBZombieSounds()
    local soundName = randomSound(sounds and sounds.Hit)
    if soundName then
        target:EmitSound(soundName, 74, math.random(96, 104), 0.82)
    end

    self:ApplyBMBPlayerHitFeedback(target)
end

function ENT:PlayBMBZombieSay(volume)
    local sounds = self:GetBMBZombieSounds()
    local soundName = randomSound(sounds and sounds.Say)
    if not soundName then return end

    self:EmitSound(soundName, 72, math.random(92, 108), volume or 0.78)
end

function ENT:PlayBMBZombieHurt(volume)
    local sounds = self:GetBMBZombieSounds()
    local soundName = randomSound(sounds and sounds.Hurt)
    if not soundName then return end

    self:EmitSound(soundName, 72, math.random(95, 105), volume or 0.88)
end

function ENT:OnBMBHurtSound(damageInfo)
    if damageInfo and self:Health() <= (damageInfo:GetDamage() or 0) then return end

    self:PlayBMBZombieHurt(0.88)
end

function ENT:OnBMBInjured(damageInfo, _)
    local attacker = damageInfo:GetAttacker()

    if self:CanBMBTarget(attacker) then
        self.TargetEntity = attacker
        self.NextTargetScanTime = 0
    end
end

function ENT:OnKilled(damageInfo)
    if CLIENT then return end

    local sounds = self:GetBMBZombieSounds()
    local soundName = randomSound(sounds and sounds.Death)
    if soundName then
        self:EmitSound(soundName, 76, math.random(95, 105), 0.95)
    end

    self:BeginBMBDeath(damageInfo)
end

function ENT:ResetBMBAmbientSoundTime()
    self.BMBAmbientSoundTime = -(self.AmbientSoundIntervalTicks or 80)
end

function ENT:MaybePlayStep()
    -- Zombie footsteps are client-side and distance-driven from the same speed integration as the procedural legs.
end

function ENT:MaybePlayIdleSound()
    local sounds = self:GetBMBZombieSounds()
    if not sounds or not sounds.Say then return end

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
            self:PlayBMBZombieSay(0.78)
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
