AddCSLuaFile()

-- Bogged = 沼骸骷髅弓箭手。行为完全继承 Skeleton，只换模型、音效，并在箭命中时施加 poison。
ENT.Base = "bmb_skeleton"
ENT.Type = "nextbot"
ENT.PrintName = "BMB Bogged"
ENT.Author = "Heart#"
ENT.Category = "BlockMob Base"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Model = "models/mcgm/bogged/bogged.mdl"
ENT.StartHealth = 70

ENT.BoggedPoisonDuration = 4
ENT.BoggedPoisonInterval = 1.0
ENT.BoggedPoisonDps = 2

ENT.Sounds = {
    Idle = {
        "bmb/mob/bogged/ambient1.ogg",
        "bmb/mob/bogged/ambient2.ogg",
        "bmb/mob/bogged/ambient3.ogg",
        "bmb/mob/bogged/ambient4.ogg"
    },
    Hurt = {
        "bmb/mob/bogged/hurt1.ogg",
        "bmb/mob/bogged/hurt2.ogg",
        "bmb/mob/bogged/hurt3.ogg",
        "bmb/mob/bogged/hurt4.ogg"
    },
    Death = {
        "bmb/mob/bogged/death.ogg"
    },
    Step = {
        "bmb/mob/bogged/step1.ogg",
        "bmb/mob/bogged/step2.ogg",
        "bmb/mob/bogged/step3.ogg",
        "bmb/mob/bogged/step4.ogg"
    },
    Shoot = {
        "bmb/mob/skeleton/bow.ogg"
    }
}

function ENT:OnBMBArrowHit(target, _damageInfo, _trace, _arrow)
    if not IsValid(target) then return end
    if target.BMBDead then return end
    if target.Health and target:Health() <= 0 then return end
    if not BMB or not BMB.Status or not BMB.Status.Apply then return end

    BMB.Status.Apply(target, "poison", {
        duration = self.BoggedPoisonDuration or 4,
        interval = self.BoggedPoisonInterval or 1.0,
        dps = self.BoggedPoisonDps or 2,
        source = self
    })
end
