-- Bedrock resource_pack/particles/white_smoke.json style, rendered with the
-- matching 8x8 frame cropped from textures/particle/particles.png.
local MC_BLOCK_UNITS = 36.5
local SMOKE_MATERIAL = Material("bmb/particles/mc_white_smoke")
local SMOKE_COLOR = Color(255, 255, 255)
local START_ALPHA = 230

local function randomDiscOffset(radius, scale)
    local theta = math.Rand(0, math.pi * 2)
    local distance = math.sqrt(math.Rand(0, 1)) * radius

    return Vector(math.cos(theta) * distance, math.sin(theta) * distance, math.Rand(-10, 12) * scale)
end

function EFFECT:Init(data)
    local origin = data:GetOrigin()
    local scale = math.max(data:GetScale(), 0.1)
    local radius = math.max(data:GetRadius(), MC_BLOCK_UNITS * 0.6 * scale)
    local count = data:GetMagnitude() > 0 and math.floor(data:GetMagnitude() + 0.5) or math.random(5, 8)
    local now = CurTime()

    count = math.Clamp(count, 5, 8)
    self.Puffs = {}
    self.DieTime = now + 1.3

    for _ = 1, count do
        local velocity = Vector(math.Rand(-0.85, 0.85), math.Rand(-0.85, 0.85), math.Rand(0.55, 1.0))
        velocity:Normalize()
        velocity:Mul(math.Rand(MC_BLOCK_UNITS * 0.45, MC_BLOCK_UNITS * 0.9) * math.Clamp(scale, 0.75, 1.35))

        self.Puffs[#self.Puffs + 1] = {
            origin = origin + randomDiscOffset(radius, scale),
            velocity = velocity,
            acceleration = Vector(0, 0, math.Rand(MC_BLOCK_UNITS * 0.12, MC_BLOCK_UNITS * 0.28) * scale),
            startTime = now + math.Rand(0, 0.16),
            lifetime = math.Rand(0.75, 1.12),
            baseSize = math.Rand(25, 35),
            alphaScale = math.Rand(0.86, 1.0),
            rotation = math.Rand(0, 360)
        }
    end

    self:SetRenderBounds(Vector(-320, -320, -96), Vector(320, 320, 320))
end

function EFFECT:Think()
    return CurTime() < (self.DieTime or 0)
end

function EFFECT:Render()
    if not self.Puffs then return end

    render.SetMaterial(SMOKE_MATERIAL)

    local now = CurTime()
    local eye = EyePos()

    for _, puff in ipairs(self.Puffs) do
        local age = now - puff.startTime
        if age >= 0 and age <= puff.lifetime then
            local t = age / puff.lifetime
            local pos = puff.origin + puff.velocity * age + puff.acceleration * (age * age * 0.5)
            local normal = eye - pos

            if normal:LengthSqr() > 1 then
                normal:Normalize()
            else
                normal = EyeVector() * -1
            end

            local alpha = START_ALPHA
            if t > 0.55 then
                alpha = alpha * (1 - (t - 0.55) / 0.45)
            end

            alpha = math.Clamp(alpha * puff.alphaScale, 0, START_ALPHA)
            render.DrawQuadEasy(pos, normal, puff.baseSize, puff.baseSize, Color(SMOKE_COLOR.r, SMOKE_COLOR.g, SMOKE_COLOR.b, alpha), puff.rotation)
        end
    end
end
