AddCSLuaFile()

ENT.Base = "bmb_base_mob"
ENT.Type = "nextbot"
ENT.PrintName = "BMB Prototype Sheep"
ENT.Author = "BMB"
ENT.Category = "BlockMob Base"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Model = "models/kleiner.mdl"
ENT.StartHealth = 20
ENT.WalkSpeed = 70
-- MC PanicGoal 速度倍率：羊/猪 1.25×走速（牛 2.0×、兔 2.2×，做新怪时参考源码各自的 addGoal）
ENT.RunSpeed = 90
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
-- MC 恐慌窗口 = lastDamageSource 有效期 40 tick（2s），每次受击刷新；窗口内一段接一段跑，
-- 窗口过了跑完当前段就停，所以原版友好生物受击后跑不远
ENT.FleeDurationMin = 2.0
ENT.FleeDurationMax = 2.5
ENT.FleePanicRadiusCells = 5    -- 恐慌单段目标 ±5 格（MC DefaultRandomPos.getPos(mob, 5, 4)）
ENT.FleePanicMinDistanceCells = 1
ENT.FleeGiveUpFailures = 4       -- 连续 4 次选不出点/起步即被挡 → 认定无路可逃，放弃恐慌
ENT.CollisionMins = Vector(-16, -16, 0) -- MC 成年羊宽 0.9 格 ~= 32.4u；保持略小于 36u 一格走廊
ENT.CollisionMaxs = Vector(16, 16, 44)

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
        self.FleeUntil = CurTime() + math.Rand(self.FleeDurationMin or 3.5, self.FleeDurationMax or 6.0)
    end

    if not wasFleeing and self.InterruptBMBMovement then
        self:InterruptBMBMovement()
    elseif not wasFleeing then
        self.BMBMoveInterrupt = true
    end

    self:EmitSound("npc/headcrab/pain1.wav", 70, math.random(98, 108), 0.55)
end
