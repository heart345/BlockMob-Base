AddCSLuaFile()

-- 桩狼：M2 逃狼测试用的最小占位实体。没有 AI、没有真模型——只需要一个
-- 类名含 "wolf"、能被骷髅 FindNearestWolfThreat 探测到的可见盒子，让骷髅有东西可逃。
-- 真狼（跳扑 + pack + 主动打羊/骷髅）以后单独做，跟占位箭一个套路。
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "BMB Stub Wolf (flee target)"
ENT.Author = "Heart#"
ENT.Category = "BlockMob Base"
ENT.Spawnable = true
ENT.AdminOnly = false

-- 占位盒子模型（GMod 自带），方便用物理枪挪到不同位置测逃狼。
ENT.Model = "models/hunter/blocks/cube025x025x025.mdl"

function ENT:Initialize()
    self:SetModel(self.Model)

    if SERVER then
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
        end
    end

    self:SetColor(Color(200, 200, 205)) -- 浅灰，像狼/明显是占位
end

if CLIENT then
    function ENT:Draw()
        self:DrawModel()
    end
end
