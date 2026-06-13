TOOL.Category = "BlockMob Base"
TOOL.Name = "#tool.bmb_debug.name"

TOOL.Information = {
    { name = "left" },
    { name = "right" },
    { name = "reload" }
}

TOOL.ClientConVar = TOOL.ClientConVar or {}
TOOL.ClientConVar["move_speed"] = "120"
TOOL.ClientConVar["move_duration"] = "8"
TOOL.ClientConVar["edit_health"] = "20"
TOOL.ClientConVar["edit_walk"] = "70"
TOOL.ClientConVar["edit_run"] = "145"
TOOL.ClientConVar["edit_accel"] = "240"
TOOL.ClientConVar["edit_decel"] = "260"

if CLIENT then
    language.Add("tool.bmb_debug.name", "BMB Debug")
    language.Add("tool.bmb_debug.desc", "Inspect and control BlockMob Base entities.")
    language.Add("tool.bmb_debug.left", "Select a BMB mob")
    language.Add("tool.bmb_debug.right", "Move selected mob to the target point")
    language.Add("tool.bmb_debug.reload", "Stop selected mob debug movement")
end

local function isBMBMob(ent)
    return IsValid(ent) and string.sub(ent:GetClass() or "", 1, 4) == "bmb_"
end

local function findMobFromTrace(trace)
    if isBMBMob(trace.Entity) then return trace.Entity end
    if not trace.HitPos then return nil end

    local best
    local bestDist = 96 * 96

    for _, ent in ipairs(ents.FindInSphere(trace.HitPos, 96)) do
        if isBMBMob(ent) then
            local dist = ent:WorldSpaceCenter():DistToSqr(trace.HitPos)

            if dist < bestDist then
                best = ent
                bestDist = dist
            end
        end
    end

    return best
end

local function selectMob(ply, mob)
    if not IsValid(ply) or not isBMBMob(mob) then return false end

    ply.BMBDebugSelected = mob
    ply:SetNWEntity("BMBDebugSelected", mob)

    return true
end

local function selectedMob(ply)
    if not IsValid(ply) then return nil end

    local mob = ply.BMBDebugSelected
    if isBMBMob(mob) then return mob end

    mob = ply:GetNWEntity("BMBDebugSelected")
    if isBMBMob(mob) then return mob end

    return nil
end

local function blockSize()
    return BMB and BMB.GetBlockSize and BMB.GetBlockSize() or (BMB and BMB.BS) or 36.5
end

local function clearDebugMovement(mob)
    if mob.ClearBMBDebugMove then
        mob:ClearBMBDebugMove()
    else
        mob.BMBDebugMoveUntil = 0
        mob.BMBDebugMoveDirection = nil
        mob.BMBDebugMoveTarget = nil
        mob.BMBDebugMoveUsePath = nil
    end

    mob.FleeUntil = 0
    mob.FleeThreat = nil
    mob.FleeThreatPosition = nil

    if mob.InterruptBMBMovement then
        mob:InterruptBMBMovement()
    else
        mob.BMBMoveInterrupt = true
    end
end

local function targetFromTrace(trace)
    local target = trace.HitPos
    if not target then return nil end

    local normal = trace.HitNormal or Vector(0, 0, 1)
    if normal.z > 0.4 then
        return target + Vector(0, 0, 4)
    end

    return target + normal * (blockSize() * 0.5)
end

local function startTargetMove(mob, target, speed, duration)
    local delta = target - mob:GetPos()
    delta.z = 0

    local distance = delta:Length2D()
    local pathBudget = (distance / math.max(speed or 1, 1)) * 3.0 + 4.0

    mob.BMBDebugMoveTarget = target
    mob.BMBDebugMoveDirection = nil
    mob.BMBDebugMoveUsePath = true
    mob.BMBDebugMoveSpeed = speed
    -- 右键寻路目标不能用面板 duration 当硬截断；长路径预算由 MoveAlongPath
    -- 按路径长度再算一次。这里的 Until 只保证行为循环有足够时间接到 debug 请求。
    mob.BMBDebugMoveUntil = CurTime() + math.max(duration or 0, pathBudget, mob.DebugPathCommandTimeout or 120)
    mob.BMBDebugMoveLookAhead = math.max(speed * 1.2, 160)
    mob.BMBDebugMoveTolerance = BMB and BMB.Config and BMB.Config.DefaultGoalTolerance or (blockSize() * 0.5)
    mob.FleeUntil = 0
    mob.FleeThreat = nil
    mob.FleeThreatPosition = nil

    if mob.InterruptBMBMovement then
        mob:InterruptBMBMovement()
    else
        mob.BMBMoveInterrupt = true
    end
end

local function applyHealth(mob, value)
    mob:SetHealth(value)
    mob:SetNWInt("BMBHealth", mob:Health())
end

local function applySpeed(mob, walk, run, accel, decel)
    if walk then mob.WalkSpeed = walk end
    if run then mob.RunSpeed = run end
    if accel then
        mob.Acceleration = accel
        mob.loco:SetAcceleration(accel)
    end
    if decel then
        mob.Deceleration = decel
        mob.loco:SetDeceleration(decel)
    end
end

function TOOL:LeftClick(trace)
    local mob = findMobFromTrace(trace)
    if not isBMBMob(mob) then return false end
    if CLIENT then return true end

    return selectMob(self:GetOwner(), mob)
end

function TOOL:RightClick(trace)
    if CLIENT then return true end

    local ply = self:GetOwner()
    local mob = selectedMob(ply)

    if not isBMBMob(mob) then
        mob = findMobFromTrace(trace)
        if not selectMob(ply, mob) then return false end
    end

    local target = targetFromTrace(trace)
    if not target then return false end

    startTargetMove(mob, target, self:GetClientNumber("move_speed", 120), self:GetClientNumber("move_duration", 8))

    return true
end

function TOOL:Reload()
    if CLIENT then return true end

    local mob = selectedMob(self:GetOwner())
    if not isBMBMob(mob) then return false end

    clearDebugMovement(mob)

    return true
end

if SERVER then
    concommand.Add("bmb_tool_apply_health", function(ply)
        local mob = selectedMob(ply)
        if not isBMBMob(mob) then return end

        applyHealth(mob, ply:GetInfoNum("bmb_debug_edit_health", mob.StartHealth or 20))
    end)

    concommand.Add("bmb_tool_apply_speed", function(ply)
        local mob = selectedMob(ply)
        if not isBMBMob(mob) then return end

        applySpeed(
            mob,
            ply:GetInfoNum("bmb_debug_edit_walk", mob.WalkSpeed or 70),
            ply:GetInfoNum("bmb_debug_edit_run", mob.RunSpeed or 145),
            ply:GetInfoNum("bmb_debug_edit_accel", mob.Acceleration or 240),
            ply:GetInfoNum("bmb_debug_edit_decel", mob.Deceleration or 260)
        )
    end)

    concommand.Add("bmb_tool_force_flee", function(ply)
        local mob = selectedMob(ply)
        if not isBMBMob(mob) then return end

        local duration = ply:GetInfoNum("bmb_debug_move_duration", 5)

        mob.FleeThreat = nil
        mob.FleeThreatPosition = ply:GetPos()
        mob.FleeUntil = CurTime() + duration

        if mob.InterruptBMBMovement then
            mob:InterruptBMBMovement()
        else
            mob.BMBMoveInterrupt = true
        end
    end)

    concommand.Add("bmb_tool_stop", function(ply)
        local mob = selectedMob(ply)
        if not isBMBMob(mob) then return end

        clearDebugMovement(mob)
    end)
end

function TOOL.BuildCPanel(panel)
    panel:Help("#tool.bmb_debug.desc")
    panel:Help("Left: select mob. Right: move selected mob to point. Reload: stop debug movement.")
    panel:CheckBox("Show debug HUD", "bmb_debug_hud")
    panel:NumSlider("Move speed", "bmb_debug_move_speed", 20, 400, 0)
    panel:NumSlider("Move duration", "bmb_debug_move_duration", 1, 20, 1)
    panel:Button("Stop selected", "bmb_tool_stop")
    panel:Button("Force flee", "bmb_tool_force_flee")
    panel:NumSlider("Health", "bmb_debug_edit_health", 1, 200, 0)
    panel:Button("Apply health", "bmb_tool_apply_health")
    panel:NumSlider("Walk speed", "bmb_debug_edit_walk", 10, 300, 0)
    panel:NumSlider("Run speed", "bmb_debug_edit_run", 10, 500, 0)
    panel:NumSlider("Acceleration", "bmb_debug_edit_accel", 10, 1200, 0)
    panel:NumSlider("Deceleration", "bmb_debug_edit_decel", 10, 1600, 0)
    panel:Button("Apply movement tuning", "bmb_tool_apply_speed")
end
