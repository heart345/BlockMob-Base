AddCSLuaFile()

-- Husk = 沙漠僵尸，近战行为与 Zombie 完全一致，只换模型和 MC husk 音效。
-- 继承 bmb_zombie：SeekTarget/Chase/MeleeAttack、客户端双足动画/攻击关键帧/死亡侧倒、
-- 所有行为参数全部复用；Sounds 覆盖为 husk 自己的 idle/hurt/death/step。
ENT.Base = "bmb_zombie"
ENT.Type = "nextbot"
ENT.PrintName = "BMB Prototype Husk"
ENT.Author = "BMB"
ENT.Category = "BlockMob Base"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Model = "models/mcgm/husk/husk.mdl"

ENT.Sounds = {
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

local function randomSound(list)
    if not list or #list == 0 then return nil end
    return list[math.random(1, #list)]
end

local function validTarget(target)
    if not IsValid(target) then return false end

    if target:IsPlayer() then
        return target:Alive()
    end

    return false
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

    if validTarget(attacker) then
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
