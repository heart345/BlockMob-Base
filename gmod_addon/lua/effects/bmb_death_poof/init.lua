-- Minecraft Java 死亡 poof 粒子（ParticleTypes.POOF → ExplodeParticle）复刻。
-- 行为对照 D:\BMBTools\mc26_1_poof_particle_behavior.md：死亡那刻一次性 20 个粒子，
-- 逐 tick(20Hz) 模拟 MC 物理：friction 0.9、gravity -0.1(轻微上飘)、按年龄从 generic_7
-- 切到 generic_0、灰白 0.7~1.0、尺寸 0.1*(rand*rand*6+1) 多小少大、寿命 18~82 tick，
-- OPAQUE 无 alpha 渐隐（消散来自帧变化 + 到寿命移除）。
local POOF_MATERIAL = Material("bmb/particles/mc_poof")
local FRAME_COUNT = 8
local MC_BLOCK_UNITS = 36.5
local PARTICLE_TICK = 0.05   -- MC 粒子 20Hz

local function gaussian()
    -- 近似标准正态（3 个均匀分布求和，std≈1），对齐 MC random.nextGaussian()
    return math.Rand(-1, 1) + math.Rand(-1, 1) + math.Rand(-1, 1)
end

function EFFECT:Init(data)
    local origin = data:GetOrigin()
    local scale = math.max(data:GetScale(), 0.1)
    -- 用 radius(u) 估实体水平半宽(block)，垂直按比例略高（对齐 getRandomX/Y/Z 的包围盒散布）
    local halfWidthBlock = math.max(data:GetRadius(), MC_BLOCK_UNITS * 0.4 * scale) / MC_BLOCK_UNITS
    local halfHeightBlock = halfWidthBlock * 1.3
    local count = data:GetMagnitude() > 0 and math.floor(data:GetMagnitude() + 0.5) or 20

    self.Origin = origin
    self.Particles = {}
    self.Accumulator = 0
    self.LastTime = CurTime()
    local maxLifetime = 1

    for _ = 1, count do
        -- 速度 block/tick：gaussian*0.02（makePoof）+ 扰动 ±0.05（ExplodeParticle 构造）
        local vel = Vector(
            gaussian() * 0.02 + math.Rand(-1, 1) * 0.05,
            gaussian() * 0.02 + math.Rand(-1, 1) * 0.05,
            gaussian() * 0.02 + math.Rand(-1, 1) * 0.05
        )
        -- 出生点 block（相对 center）：包围盒内随机 - vel*10（让团从中心向外蓬开）
        local pos = Vector(
            math.Rand(-1, 1) * halfWidthBlock - vel.x * 10,
            math.Rand(-1, 1) * halfWidthBlock - vel.y * 10,
            math.Rand(-1, 1) * halfHeightBlock - vel.z * 10
        )
        -- 尺寸 block：0.1*(rand*rand*6+1) → 0.1~0.7，多数小烟点、少数大团
        local size = 0.1 * (math.Rand(0, 1) * math.Rand(0, 1) * 6 + 1)
        -- 寿命 tick：16/(rand*0.8+0.2)+2 → 18~82 tick（约 0.9~4.1s，差异大）
        local lifetime = math.floor(16 / (math.Rand(0, 1) * 0.8 + 0.2) + 2)
        maxLifetime = math.max(maxLifetime, lifetime)
        -- 颜色：灰白随机 0.7~1.0（三通道相同）
        local col = math.floor((math.Rand(0, 1) * 0.3 + 0.7) * 255)

        self.Particles[#self.Particles + 1] = {
            pos = pos,
            vel = vel,
            age = 0,
            lifetime = lifetime,
            size = size,
            col = col,
            rotation = math.Rand(0, 360),
            dead = false
        }
    end

    self.DieTime = CurTime() + maxLifetime * PARTICLE_TICK + 0.1
    local bound = (halfWidthBlock + 3) * MC_BLOCK_UNITS
    self:SetRenderBounds(Vector(-bound, -bound, -bound), Vector(bound, bound, bound * 3))
end

function EFFECT:Think()
    if not self.Particles then return false end

    local now = CurTime()
    self.Accumulator = self.Accumulator + (now - self.LastTime)
    self.LastTime = now

    -- 逐 tick(20Hz) 推进 MC 粒子物理；限步数防卡顿后大跳
    local steps = 0
    while self.Accumulator >= PARTICLE_TICK and steps < 10 do
        self.Accumulator = self.Accumulator - PARTICLE_TICK
        steps = steps + 1

        for _, p in ipairs(self.Particles) do
            if not p.dead then
                p.age = p.age + 1
                if p.age >= p.lifetime then
                    p.dead = true
                else
                    p.vel.z = p.vel.z + 0.004   -- gravity -0.1 → 每 tick 轻微上飘
                    p.pos:Add(p.vel)             -- move
                    p.vel:Mul(0.9)               -- friction
                end
            end
        end
    end

    return now < (self.DieTime or 0)
end

function EFFECT:Render()
    if not self.Particles then return end

    render.SetMaterial(POOF_MATERIAL)
    local origin = self.Origin
    local eye = EyePos()
    -- 帧间外插：粒子物理走 20Hz（对齐 MC），渲染按 tick 余量平滑外插，避免低 Hz 视觉卡顿
    local frac = math.Clamp(self.Accumulator / PARTICLE_TICK, 0, 1)

    for _, p in ipairs(self.Particles) do
        if not p.dead then
            -- 帧：MC sprites=[generic_7..generic_0]，idx=age*(n-1)/lifetime；
            -- 我们的 VTF 是 generic_0..7，故 VTF 帧号 = (n-1) - idx，实现 generic_7→0。
            local idx = math.Clamp(math.floor(p.age * (FRAME_COUNT - 1) / math.max(1, p.lifetime)), 0, FRAME_COUNT - 1)
            local frame = (FRAME_COUNT - 1) - idx

            local worldPos = origin + (p.pos + p.vel * frac) * MC_BLOCK_UNITS
            local sizeU = p.size * MC_BLOCK_UNITS

            local normal = eye - worldPos
            if normal:LengthSqr() > 1 then
                normal:Normalize()
            else
                normal = EyeVector() * -1
            end

            -- OPAQUE：不做 alpha 渐隐，顶点 alpha 固定 255，形状靠贴图 alpha + 帧变化
            POOF_MATERIAL:SetInt("$frame", frame)
            render.DrawQuadEasy(worldPos, normal, sizeU, sizeU, Color(p.col, p.col, p.col, 255), p.rotation)
        end
    end
end
