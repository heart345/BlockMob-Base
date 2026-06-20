AddCSLuaFile()

-- Stray = 雪地骷髅弓箭手，远程行为与 Skeleton 完全一致，只换模型和 MC stray 音效。
-- 继承 bmb_skeleton：RangedAttack 远程循环 + strafe 风筝、弓挂手/拉弓帧/左撇子、
-- 客户端双足动画/抬弓/死亡侧倒、所有行为参数全部复用；Sounds 覆盖为 stray 自己的
-- idle/hurt/death/step。弓射击仍用通用 MC bow，箭命中音走 bmb_arrow 的 bowhit。
ENT.Base = "bmb_skeleton"
ENT.Type = "nextbot"
ENT.PrintName = "BMB Stray"
ENT.Author = "Heart#"
ENT.Category = "BlockMob Base"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Model = "models/mcgm/stray/stray.mdl"
ENT.StartHealth = 70

ENT.Sounds = {
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
}

local function randomSound(list)
    if not list or #list == 0 then return nil end
    return list[math.random(1, #list)]
end

function ENT:OnBMBHurtSound(damageInfo)
    if damageInfo and self:Health() <= (damageInfo:GetDamage() or 0) then return end

    local sounds = self:GetBMBSkeletonSounds()
    local soundName = randomSound(sounds and sounds.Hurt)
    if soundName then
        self:EmitSound(soundName, 72, math.random(95, 105), 0.8)
    end
end

function ENT:OnKilled(damageInfo)
    if CLIENT then return end

    local sounds = self:GetBMBSkeletonSounds()
    local soundName = randomSound(sounds and sounds.Death)
    if soundName then
        self:EmitSound(soundName, 76, math.random(95, 105), 0.9)
    end

    self:BeginBMBDeath(damageInfo)
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
