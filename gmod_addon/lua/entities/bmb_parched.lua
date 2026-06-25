AddCSLuaFile()

-- Parched = 沙漠骷髅弓箭手，远程行为与 Skeleton/Stray 完全一致，只换模型和 MC parched 音效。
-- 具体声音表在 bmb_skeleton 的 class-based sound set 中按 self:GetClass()=="bmb_parched" 分流，
-- 避免继承链/热加载时串回 skeleton 或 stray 音效。
ENT.Base = "bmb_skeleton"
ENT.Type = "nextbot"
ENT.PrintName = "BMB Parched"
ENT.Author = "Heart#"
ENT.Category = "BlockMob Base"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Model = "models/mcgm/parched/parched.mdl"
ENT.StartHealth = 70
ENT.ParchedWeaknessDuration = 5

function ENT:OnBMBArrowHit(target, _damageInfo, _trace, _arrow)
    if not IsValid(target) then return end
    if target.BMBDead then return end
    if target.Health and target:Health() <= 0 then return end
    if not BMB or not BMB.Status or not BMB.Status.Apply then return end

    BMB.Status.Apply(target, "weakness", {
        duration = self.ParchedWeaknessDuration or 5,
        source = self
    })
end
