AddCSLuaFile()

ENT.Base = "bmb_spider"
ENT.Type = "nextbot"
ENT.PrintName = "BMB Cave Spider"
ENT.Author = "Heart#"
ENT.Category = "BlockMob Base"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Model = "models/mcgm/cave_spider/cave_spider.mdl"
ENT.StartHealth = 45
ENT.AttackDamage = 4
ENT.CollisionMins = Vector(-13, -13, 0)
ENT.CollisionMaxs = Vector(13, 13, 22)
ENT.MobSeparationApproachDistance = 16
ENT.MobSeparationMaxSpeed = 80
ENT.LookAtEyeHeight = 10

ENT.CaveSpiderPoisonDuration = 4
ENT.CaveSpiderPoisonInterval = 1.0
ENT.CaveSpiderPoisonDps = 2

local function callSpiderMeleeHit(self, target, damageInfo)
    local stored = scripted_ents.GetStored("bmb_spider")
    local baseTable = stored and stored.t
    if baseTable and baseTable.OnBMBMeleeHit then
        baseTable.OnBMBMeleeHit(self, target, damageInfo)
    end
end

function ENT:OnBMBMeleeHit(target, damageInfo)
    callSpiderMeleeHit(self, target, damageInfo)

    if not BMB or not BMB.Status or not BMB.Status.Apply then return end

    BMB.Status.Apply(target, "poison", {
        duration = self.CaveSpiderPoisonDuration or 4,
        interval = self.CaveSpiderPoisonInterval or 1.0,
        dps = self.CaveSpiderPoisonDps or 2,
        source = self
    })
end
