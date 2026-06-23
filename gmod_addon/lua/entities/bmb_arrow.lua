AddCSLuaFile()

-- BMB 箭矢弹丸。纯 GMod trace 物理，不碰体素系统。
-- 服务端手动积分重力 + 沿位移 TraceLine 命中；客户端只画模型。
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "BMB Arrow"
ENT.Author = "Heart#"
ENT.Spawnable = false
ENT.AdminOnly = false

ENT.Model = "models/mcgm/arrow/arrow.mdl"
ENT.ArrowModelAngleOffset = Angle(0, -90, 0) -- 模型朝向修正（实测：箭模型默认横置，yaw -90 转正对齐飞行方向；vel:Angle() roll 恒 0，可分量加）

-- 弹道参数（手感实测，由 Fire 传入覆盖）：
ENT.ArrowSpeed = 1168     -- su/s，约 MC 1.6 block/tick × 36.5 × 20
ENT.ArrowDamage = 6       -- ≈3 心
ENT.ArrowGravity = 730    -- su/s²，竖直下坠（≈MC 0.05 block/tick²；抛物线补偿配套）
ENT.ArrowSpread = 3       -- 散布锥角（度）
ENT.ArrowLifetime = 5     -- 秒，飞行中没命中的兜底自毁
ENT.ArrowStuckLifetime = 15 -- 秒，插在表面后多久移除（防插一地箭把实体堆爆）
ENT.ArrowEmbedDepth = 2   -- su，命中后沿飞行方向推入表面的深度（箭头埋进、杆和翎露出，可调）

-- 命中音（MC random/bowhit；命中玩家受击 + 插静态表面都播）。
ENT.HitSounds = {
    "bmb/random/bowhit1.ogg",
    "bmb/random/bowhit2.ogg",
    "bmb/random/bowhit3.ogg",
    "bmb/random/bowhit4.ogg"
}
ENT.HitSoundLevel = 75
ENT.HitSoundVolume = 0.85

-- 远程诊断日志开关（与骷髅 Fire 共用 bmb_debug_ranged；convar 在 sv_behaviors.lua 创建）。
local function shouldLogRanged()
    local cvar = GetConVar and GetConVar("bmb_debug_ranged")
    return cvar and cvar:GetBool()
end

local function randomSound(list)
    if not list or #list == 0 then return nil end
    return list[math.random(#list)]
end

local function applyLocalAngleOffset(angle, offset)
    offset = offset or angle_zero

    local result = Angle(angle.p, angle.y, angle.r)
    if offset.p ~= 0 then result:RotateAroundAxis(result:Right(), offset.p) end
    if offset.y ~= 0 then result:RotateAroundAxis(result:Up(), offset.y) end
    if offset.r ~= 0 then result:RotateAroundAxis(result:Forward(), offset.r) end

    return result
end

function ENT:GetBMBArrowFlightAngle(velocity)
    if not velocity or velocity:LengthSqr() <= 1 then return self:GetAngles() end

    return applyLocalAngleOffset(velocity:Angle(), self.ArrowModelAngleOffset)
end

function ENT:UpdateBMBArrowFlightAngle(velocity)
    self:SetAngles(self:GetBMBArrowFlightAngle(velocity or self.BMBArrowVelocity))
end

function ENT:Initialize()
    self:SetModel(self.Model)

    if SERVER then
        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_NONE)
        self:DrawShadow(false)
        self.BMBArrowVelocity = self.BMBArrowVelocity or vector_origin
        self.BMBArrowSpawnTime = CurTime()
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
        self:UpdateBMBArrowFlightAngle(self.BMBArrowVelocity)
    end

    function ENT:PlayBMBArrowHitSound()
        local snd = randomSound(self.HitSounds)
        if not snd then return end
        self:EmitSound(snd, self.HitSoundLevel or 75, math.random(94, 106), self.HitSoundVolume or 0.85)
    end

    -- 命中静态世界/物体：插在表面（纯视觉 SOLID_NONE，人能穿过），停弹道，起 despawn 计时器。
    -- 不 SetParent 跟随会动的 prop（静态版覆盖几乎所有情况，跟随那点按需求跳过）；命中生物走扣血+移除分支。
    function ENT:StickToSurface(hitPos)
        self.BMBStuck = true

        local vel = self.BMBArrowVelocity or vector_origin
        local dir = vel:GetNormalized()
        -- 角度保持命中那刻（已对着表面），位置摆到命中点再沿飞行方向推入一点（箭头埋进表面）。
        self:UpdateBMBArrowFlightAngle(vel)
        self:SetPos(hitPos + dir * (self.ArrowEmbedDepth or 8))
        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_NONE)

        self:PlayBMBArrowHitSound()
        self.BMBArrowDie = CurTime() + (self.ArrowStuckLifetime or 15)
        self:NextThink(CurTime())
    end

    function ENT:Think()
        -- 已插在表面：停止弹道积分，只等 despawn。
        if self.BMBStuck then
            if CurTime() >= (self.BMBArrowDie or 0) then
                self:Remove()
                return
            end
            self:NextThink(CurTime())
            return true
        end

        local dt = FrameTime()

        local vel = self.BMBArrowVelocity or vector_origin
        vel.z = vel.z - (self.ArrowGravity or 320) * dt
        self.BMBArrowVelocity = vel
        self:UpdateBMBArrowFlightAngle(vel)

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
            local isCreature = IsValid(hitEnt) and (hitEnt:IsPlayer() or hitEnt:IsNPC() or hitEnt:IsNextBot() or hitEnt.IsBMBMob)

            if isCreature then
                local dmg = DamageInfo()
                dmg:SetDamage(self.ArrowDamage or 6)
                dmg:SetDamageType(DMG_SLASH)
                dmg:SetAttacker(IsValid(self.BMBArrowOwner) and self.BMBArrowOwner or self)
                dmg:SetInflictor(self)
                dmg:SetDamagePosition(tr.HitPos)
                dmg:SetDamageForce(vel:GetNormalized() * 100)
                hitEnt:TakeDamageInfo(dmg)

                self:PlayBMBArrowHitSound()

                if shouldLogRanged() then
                    print(string.format(
                        "[BMB ranged] arrow hit %s (damage) pos=(%.0f,%.0f,%.0f) t=%.2fs",
                        hitEnt:GetClass(),
                        tr.HitPos.x, tr.HitPos.y, tr.HitPos.z,
                        CurTime() - (self.BMBArrowSpawnTime or CurTime())))
                end

                -- 命中生物：扣血后移除，不插。
                self:Remove()
                return
            end

            -- 命中静态世界/物体：插在表面，不移除（会动的 prop 不跟随，按需求跳过）。
            if shouldLogRanged() then
                print(string.format(
                    "[BMB ranged] arrow stuck on %s pos=(%.0f,%.0f,%.0f) t=%.2fs",
                    IsValid(hitEnt) and hitEnt:GetClass() or "world",
                    tr.HitPos.x, tr.HitPos.y, tr.HitPos.z,
                    CurTime() - (self.BMBArrowSpawnTime or CurTime())))
            end

            self:StickToSurface(tr.HitPos)
            return
        end

        self:SetPos(newPos)

        if CurTime() >= (self.BMBArrowDie or 0) then
            if shouldLogRanged() then
                local p = self:GetPos()
                print(string.format(
                    "[BMB ranged] arrow expired (no hit) pos=(%.0f,%.0f,%.0f)",
                    p.x, p.y, p.z))
            end
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
