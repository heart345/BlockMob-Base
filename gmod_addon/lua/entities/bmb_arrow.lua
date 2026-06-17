AddCSLuaFile()

-- BMB 箭矢弹丸（v1 占位视觉）。纯 GMod trace 物理，不碰体素系统。
-- 服务端手动积分重力 + 沿位移 TraceLine 命中；客户端只画占位模型。
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "BMB Arrow"
ENT.Author = "BMB"
ENT.Spawnable = false
ENT.AdminOnly = false

-- 占位模型：GMod 自带的小球。换真箭模型是 polish。
ENT.Model = "models/hunter/misc/sphere025x025.mdl"

-- 弹道参数（手感实测，由 Fire 传入覆盖）：
ENT.ArrowSpeed = 1168     -- su/s，约 MC 1.6 block/tick × 36.5 × 20
ENT.ArrowDamage = 6       -- ≈3 心
ENT.ArrowGravity = 730    -- su/s²，竖直下坠（≈MC 0.05 block/tick²；抛物线补偿配套）
ENT.ArrowSpread = 3       -- 散布锥角（度）
ENT.ArrowLifetime = 5     -- 秒，超时自毁

function ENT:Initialize()
    self:SetModel(self.Model)

    if SERVER then
        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_NONE)
        self:DrawShadow(false)
        self.BMBArrowVelocity = self.BMBArrowVelocity or vector_origin
        self.BMBArrowDie = CurTime() + (self.ArrowLifetime or 5)
        self:NextThink(CurTime())
    end
end

if SERVER then
    -- dir = 已含抛物线补偿的单位方向；spread/speed/damage/gravity 可覆盖默认。
    function ENT:SetupArrow(arrowOwner, dir, speed, spread, damage, gravity)
        if IsValid(arrowOwner) then self:SetOwner(arrowOwner) end
        self.BMBArrowOwner = arrowOwner

        speed = speed or self.ArrowSpeed
        spread = spread or self.ArrowSpread
        if damage then self.ArrowDamage = damage end
        if gravity then self.ArrowGravity = gravity end

        local ang = dir:Angle()
        if spread and spread > 0 then
            ang:RotateAroundAxis(ang:Up(), math.Rand(-spread, spread))
            ang:RotateAroundAxis(ang:Right(), math.Rand(-spread, spread))
        end

        self.BMBArrowVelocity = ang:Forward() * speed
        self:SetAngles(self.BMBArrowVelocity:Angle())
    end

    function ENT:Think()
        local dt = FrameTime()

        local vel = self.BMBArrowVelocity or vector_origin
        vel.z = vel.z - (self.ArrowGravity or 320) * dt
        self.BMBArrowVelocity = vel

        local pos = self:GetPos()
        local newPos = pos + vel * dt

        local tr = util.TraceLine({
            start = pos,
            endpos = newPos,
            filter = { self, self.BMBArrowOwner },
            mask = MASK_SHOT
        })

        if tr.Hit then
            local hitEnt = tr.Entity
            if IsValid(hitEnt) and (hitEnt:IsPlayer() or hitEnt:IsNPC() or hitEnt:IsNextBot() or hitEnt.IsBMBMob) then
                local dmg = DamageInfo()
                dmg:SetDamage(self.ArrowDamage or 6)
                dmg:SetDamageType(DMG_SLASH)
                dmg:SetAttacker(IsValid(self.BMBArrowOwner) and self.BMBArrowOwner or self)
                dmg:SetInflictor(self)
                dmg:SetDamagePosition(tr.HitPos)
                dmg:SetDamageForce(vel:GetNormalized() * 100)
                hitEnt:TakeDamageInfo(dmg)
            end

            -- 命中世界或生物都移除（插在表面是 polish）。
            self:Remove()
            return
        end

        self:SetPos(newPos)
        self:SetAngles(vel:Angle())

        if CurTime() >= (self.BMBArrowDie or 0) then
            self:Remove()
            return
        end

        self:NextThink(CurTime())
        return true
    end
end

if CLIENT then
    function ENT:Draw()
        self:DrawModel()
    end
end
