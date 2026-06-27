local SLIME_MATERIAL = Material("bmb/particles/slime_ball")
local MC_BLOCK_UNITS = 36.5
local PARTICLE_TICK = 0.05
local GRAVITY_PER_TICK = 0.04 * MC_BLOCK_UNITS

local function randomBreakingVelocity()
    local x = math.Rand(-0.4, 0.4)
    local y = math.Rand(-0.4, 0.4)
    local z = math.Rand(-0.4, 0.4)
    local length = math.sqrt(x * x + y * y + z * z)

    if length < 0.0001 then
        x = 0
        y = 1
        z = 0
        length = 1
    end

    local speed = (math.Rand(0, 1) + math.Rand(0, 1) + 1) * 0.15
    local horizontalScale = speed * 0.4 * MC_BLOCK_UNITS
    local vertical = ((y / length) * speed * 0.4 + 0.1) * MC_BLOCK_UNITS

    return Vector(
        (x / length) * horizontalScale,
        (z / length) * horizontalScale,
        vertical
    )
end

function EFFECT:Init(data)
    local origin = data:GetOrigin()
    local radius = math.max(data:GetRadius(), MC_BLOCK_UNITS * 0.45)
    local scale = math.max(data:GetScale(), 0.1)
    local count = data:GetMagnitude() > 0 and math.floor(data:GetMagnitude() + 0.5) or 17

    self.Origin = origin
    self.Particles = {}
    self.Accumulator = 0
    self.LastTime = CurTime()

    local maxLifetime = 1

    for _ = 1, count do
        local angle = math.Rand(0, math.pi * 2)
        local radiusScale = math.Rand(0.5, 1.0)
        local lifetime = math.max(1, math.floor(4 / (math.Rand(0, 1) * 0.9 + 0.1)))
        local uo = math.Rand(0, 3)
        local vo = math.Rand(0, 3)

        maxLifetime = math.max(maxLifetime, lifetime)

        self.Particles[#self.Particles + 1] = {
            pos = Vector(math.sin(angle) * radius * radiusScale, math.cos(angle) * radius * radiusScale, 0),
            vel = randomBreakingVelocity(),
            age = 0,
            lifetime = lifetime,
            size = math.Rand(0.05, 0.1) * MC_BLOCK_UNITS * scale,
            color = Color(255, 255, 255, 255),
            u0 = (uo + 1) / 4,
            u1 = uo / 4,
            v0 = vo / 4,
            v1 = (vo + 1) / 4,
            dead = false
        }
    end

    self.DieTime = CurTime() + maxLifetime * PARTICLE_TICK + 0.1

    local bound = radius + MC_BLOCK_UNITS * 1.5
    self:SetRenderBounds(Vector(-bound, -bound, -MC_BLOCK_UNITS * 0.25), Vector(bound, bound, MC_BLOCK_UNITS * 1.5))
end

local function stepParticle(particle)
    if particle.dead then return end

    particle.age = particle.age + 1

    if particle.age >= particle.lifetime then
        particle.dead = true
        return
    end

    particle.vel.z = particle.vel.z - GRAVITY_PER_TICK
    particle.pos:Add(particle.vel)

    local onGround = false
    if particle.pos.z <= 0 then
        particle.pos.z = 0
        if particle.vel.z < 0 then
            particle.vel.z = 0
        end
        onGround = true
    end

    particle.vel:Mul(0.98)
    if onGround then
        particle.vel.x = particle.vel.x * 0.7
        particle.vel.y = particle.vel.y * 0.7
    end
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
            stepParticle(particle)
        end
    end

    return now < (self.DieTime or 0)
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

local function addVertex(pos, u, v, color)
    mesh.Position(pos)
    mesh.TexCoord(0, u, v)
    mesh.Color(color.r, color.g, color.b, color.a)
    mesh.AdvanceVertex()
end

local function addParticleQuad(origin, eye, frac, particle)
    if particle.dead then return end

    local worldPos = origin + particle.pos + particle.vel * frac
    local normal = eye - worldPos

    if normal:LengthSqr() > 1 then
        normal:Normalize()
    else
        normal = EyeVector() * -1
    end

    local angle = normal:Angle()
    local right = angle:Right()
    local up = angle:Up()
    local halfSize = particle.size * 0.5
    local rightOffset = right * halfSize
    local upOffset = up * halfSize
    local color = particle.color

    addVertex(worldPos - rightOffset - upOffset, particle.u0, particle.v1, color)
    addVertex(worldPos + rightOffset - upOffset, particle.u1, particle.v1, color)
    addVertex(worldPos + rightOffset + upOffset, particle.u1, particle.v0, color)
    addVertex(worldPos - rightOffset + upOffset, particle.u0, particle.v0, color)
end

function EFFECT:Render()
    if not self.Particles then return end
    local liveCount = countLiveParticles(self.Particles)
    if liveCount <= 0 then return end

    render.SetMaterial(SLIME_MATERIAL)

    local origin = self.Origin
    local eye = EyePos()
    local frac = math.Clamp(self.Accumulator / PARTICLE_TICK, 0, 1)

    mesh.Begin(MATERIAL_QUADS, liveCount)
    for _, particle in ipairs(self.Particles) do
        addParticleQuad(origin, eye, frac, particle)
    end
    mesh.End()
end
