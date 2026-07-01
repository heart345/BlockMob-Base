local PORTAL_MATERIAL = Material("bmb/particles/mc_portal")
local FRAME_COUNT = 8
local MC_BLOCK_UNITS = 36.5
local PARTICLE_TICK = 0.05
local AMBIENT_FLAGS = 1

local function portalColor()
    local brightness = math.Rand(0.4, 1.0)

    return Color(
        math.floor(brightness * 0.9 * 255),
        math.floor(brightness * 0.3 * 255),
        math.floor(brightness * 255),
        255
    )
end

local function makePortalParticle(startBlock, offsetBlock)
    return {
        start = startBlock,
        offset = offsetBlock,
        age = 0,
        lifetime = math.random(40, 49),
        size = 0.1 * (math.Rand(0.5, 0.7)),
        color = portalColor(),
        rotation = math.Rand(0, 360),
        frame = math.random(0, FRAME_COUNT - 1),
        dead = false
    }
end

local function portalPosition(particle, partialTick)
    local rawT = math.Clamp((particle.age + partialTick) / math.max(1, particle.lifetime), 0, 1)
    local curve = 1 + rawT - 2 * rawT * rawT

    return Vector(
        particle.start.x + particle.offset.x * curve,
        particle.start.y + particle.offset.y * curve,
        particle.start.z + particle.offset.z * curve + (1 - rawT)
    )
end

local function countLiveParticles(particles)
    local count = 0

    for _, particle in ipairs(particles) do
        if not particle.dead then
            count = count + 1
        end
    end

    return count
end

function EFFECT:AddAmbientParticles(data, scale)
    local count = data:GetMagnitude() > 0 and math.floor(data:GetMagnitude() + 0.5) or 2
    local halfWidth = 0.3 * scale
    local minZ = -0.25 * scale
    local maxZ = 2.65 * scale

    for _ = 1, count do
        self.Particles[#self.Particles + 1] = makePortalParticle(
            Vector(math.Rand(-halfWidth, halfWidth), math.Rand(-halfWidth, halfWidth), math.Rand(minZ, maxZ)),
            Vector(math.Rand(-1, 1), math.Rand(-1, 1), math.Rand(-1, 0))
        )
    end

    local bound = MC_BLOCK_UNITS * 1.35 * scale
    local height = MC_BLOCK_UNITS * 3.8 * scale
    self:SetRenderBounds(Vector(-bound, -bound, -MC_BLOCK_UNITS), Vector(bound, bound, height))
end

function EFFECT:AddTeleportParticles(data, scale)
    local endPos = data:GetOrigin()
    local startPos = data:GetStart()
    local count = data:GetMagnitude() > 0 and math.floor(data:GetMagnitude() + 0.5) or 128
    local width = 0.6 * scale
    local height = 2.9 * scale

    for index = 0, count - 1 do
        local t = count > 1 and (index / (count - 1)) or 1
        local baseWorld = LerpVector(t, startPos, endPos)
        local baseBlock = (baseWorld - endPos) / MC_BLOCK_UNITS
        local spawnBlock = baseBlock + Vector(
            math.Rand(-width, width),
            math.Rand(-width, width),
            math.Rand(0, height)
        )

        self.Particles[#self.Particles + 1] = makePortalParticle(
            spawnBlock,
            Vector(math.Rand(-0.1, 0.1), math.Rand(-0.1, 0.1), math.Rand(-0.1, 0.1))
        )
    end

    local delta = startPos - endPos
    local bound = MC_BLOCK_UNITS * (width + 1.3)
    local zBound = MC_BLOCK_UNITS * (height + 1.2)
    self:SetRenderBounds(
        Vector(
            math.min(delta.x, 0) - bound,
            math.min(delta.y, 0) - bound,
            math.min(delta.z, 0) - bound
        ),
        Vector(
            math.max(delta.x, 0) + bound,
            math.max(delta.y, 0) + bound,
            math.max(delta.z, 0) + zBound
        )
    )
end

function EFFECT:Init(data)
    self.Origin = data:GetOrigin()
    self.Particles = {}
    self.Accumulator = 0
    self.LastTime = CurTime()

    local scale = math.max(data:GetScale(), 0.1)
    if data:GetFlags() == AMBIENT_FLAGS then
        self:AddAmbientParticles(data, scale)
    else
        self:AddTeleportParticles(data, scale)
    end

    local maxLifetime = 1
    for _, particle in ipairs(self.Particles) do
        maxLifetime = math.max(maxLifetime, particle.lifetime)
    end

    self.DieTime = CurTime() + maxLifetime * PARTICLE_TICK + 0.1
end

function EFFECT:Think()
    if not self.Particles then return false end

    local now = CurTime()
    self.Accumulator = self.Accumulator + (now - self.LastTime)
    self.LastTime = now

    local steps = 0
    while self.Accumulator >= PARTICLE_TICK and steps < 10 do
        self.Accumulator = self.Accumulator - PARTICLE_TICK
        steps = steps + 1

        for _, particle in ipairs(self.Particles) do
            if not particle.dead then
                particle.age = particle.age + 1
                if particle.age >= particle.lifetime then
                    particle.dead = true
                end
            end
        end
    end

    return now < (self.DieTime or 0) and countLiveParticles(self.Particles) > 0
end

function EFFECT:Render()
    if not self.Particles then return end

    render.SetMaterial(PORTAL_MATERIAL)
    local origin = self.Origin
    local eye = EyePos()
    local partialTick = math.Clamp(self.Accumulator / PARTICLE_TICK, 0, 1)

    for _, particle in ipairs(self.Particles) do
        if not particle.dead then
            local renderT = math.Clamp((particle.age + partialTick) / math.max(1, particle.lifetime), 0, 1)
            local sizeScale = 1 - (1 - renderT) * (1 - renderT)
            local size = particle.size * sizeScale * MC_BLOCK_UNITS

            if size > 0.1 then
                local worldPos = origin + portalPosition(particle, partialTick) * MC_BLOCK_UNITS
                local normal = eye - worldPos
                if normal:LengthSqr() > 1 then
                    normal:Normalize()
                else
                    normal = EyeVector() * -1
                end

                local emission = renderT * renderT * renderT * renderT
                local color = particle.color
                local r = math.min(255, math.floor(color.r + (255 - color.r) * emission * 0.45))
                local g = math.min(255, math.floor(color.g + (255 - color.g) * emission * 0.45))
                local b = math.min(255, math.floor(color.b + (255 - color.b) * emission * 0.45))

                PORTAL_MATERIAL:SetInt("$frame", particle.frame)
                render.DrawQuadEasy(worldPos, normal, size, size, Color(r, g, b, 255), particle.rotation)
            end
        end
    end
end
