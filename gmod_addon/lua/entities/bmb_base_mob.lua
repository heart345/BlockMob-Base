AddCSLuaFile()

if SERVER then
    BMB = BMB or {}
    include("bmb/sh_config.lua")
    include("bmb/sv_block_world_mock.lua")
    include("bmb/sv_pathfinder.lua")
    include("bmb/sv_behaviors.lua")

    if not GetConVar("bmb_use_source_path") then
        -- 默认关：寻路走自写方块 A*（CLAUDE.md：不用 navmesh），此开关仅留作普通地图实验
        CreateConVar("bmb_use_source_path", "0", FCVAR_ARCHIVE, "EXPERIMENTAL: use GMod Source PathFollower instead of BMB block-grid A*.")
    end
end

ENT.Base = "base_nextbot"
ENT.Type = "nextbot"
ENT.PrintName = "BMB Base Mob"
ENT.Author = "BMB"
ENT.Category = "BlockMob Base"
ENT.Spawnable = false
ENT.AdminOnly = true

ENT.Model = "models/kleiner.mdl"
ENT.StartHealth = 20
ENT.WalkSpeed = 80
ENT.RunSpeed = 120
ENT.Acceleration = 420
ENT.Deceleration = 650
ENT.CollisionMins = Vector(-16, -16, 0)
ENT.CollisionMaxs = Vector(16, 16, 48)
ENT.WaypointTimeout = 2.0
ENT.GroundProbeHeight = 32
ENT.GroundProbeDepth = 96
ENT.ForwardSafetyDistance = 48
ENT.SafetyProbeSpeedScale = 0.45
ENT.SafetyHullScale = 0.65
ENT.WallStopDistance = 20
ENT.StepHeight = 28
-- 必须 > 一格（36）：MC 生物下一格台阶是日常移动，34 会把"从方块地板走下来"判成悬崖；
-- 两格（72）仍然算悬崖
ENT.MaxStepDown = 40
ENT.TurnRate = 400
ENT.TurnInPlaceAngle = 110
ENT.UseSourcePathFollower = true
ENT.SourcePathLookAhead = 120
ENT.SourcePathGoalTolerance = 18
ENT.PathNodeTolerance = 18
ENT.PathCarrotMinDistance = 72
ENT.PathCarrotMaxDistance = 150
ENT.PathCarrotSpeedScale = 1.1
ENT.PathTimeoutPerNode = 0.8
ENT.MoveNoProgressGrace = 0.35
ENT.MoveNoProgressTimeout = 0.25
ENT.MoveNoProgressDistance = 8
ENT.MoveNoProgressSpeed = 16
ENT.PathGoalProgressTimeout = 0.9
ENT.PathGoalProgressDistance = 10
ENT.PhysicsImpactRadius = 44
ENT.PhysicsImpactInterval = 0.08
ENT.PhysicsImpactCooldown = 0.22
ENT.PhysicsImpactMinSpeed = 260
ENT.PhysicsImpactDamageScale = 0.035
ENT.PhysicsImpactMaxDamage = 80
ENT.PhysicsPropImpactDamping = 0.45
ENT.PhysicsPropKillDamping = 0.68

local function flatDistance(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y

    return math.sqrt(dx * dx + dy * dy)
end

local function copyVector(vec)
    return Vector(vec.x, vec.y, vec.z)
end

function ENT:Initialize()
    if CLIENT then return end
    self:BaseInitialize()
end

function ENT:BaseInitialize()
    self:SetModel(self.Model)
    self:SetHealth(self.StartHealth)
    self:SetCollisionBounds(self.CollisionMins, self.CollisionMaxs)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionGroup(COLLISION_GROUP_NPC)

    self.loco:SetStepHeight(self.StepHeight)
    self.loco:SetJumpHeight(58)
    self.loco:SetMaxYawRate(self.TurnRate or 400)
    self.loco:SetAcceleration(self.Acceleration)
    self.loco:SetDeceleration(self.Deceleration)
    self.loco:SetDesiredSpeed(self.WalkSpeed)

    self.State = self.State or "idle"
    self.CurrentMoveActivity = nil
    self.NextStepSoundTime = 0
    self.BMBMoveInterrupt = false
    self.BMBDead = false
    self.NextPhysicsImpactCheck = 0
    self.PhysicsImpactTimes = {}

    -- mock/real 块世界的懒选择：MCSWEP 比 BMB 后加载，include 时选不到 real，
    -- 生成 mob 时再选一次（幂等，已选对则无操作）
    if BMB and BMB.SelectBlockWorld then
        BMB.SelectBlockWorld()
    end

    if BMB and BMB.BlockWorld then
        BMB.BlockWorld.EnsureInitialized(self:GetPos())
    end

    self:SetNWString("BMBState", self.State)
    self:SetNWInt("BMBHealth", self:Health())
    self:SetNWFloat("BMBDesiredSpeed", self.WalkSpeed)
    self:SetNWString("BMBMoveMode", "idle")
    self:SetNWFloat("BMBDistToGoal", 0)
    self:SetNWInt("BMBPathNode", 0)
    self:SetNWInt("BMBPathAdvance", 0)
end

function ENT:UpdateMoveActivity(speed)
    local runThreshold = (self.WalkSpeed + self.RunSpeed) * 0.5
    local activity = (speed or self.WalkSpeed) >= runThreshold and ACT_RUN or ACT_WALK

    if self.CurrentMoveActivity == activity then return end

    self:StartActivity(activity)
    self.CurrentMoveActivity = activity
    self:SetNWFloat("BMBDesiredSpeed", speed or self.WalkSpeed)
end

function ENT:ShouldUseSourcePath()
    local convar = GetConVar("bmb_use_source_path")
    return self.UseSourcePathFollower and (not convar or convar:GetBool())
end

function ENT:InterruptBMBMovement()
    self.BMBMoveInterrupt = true
end

function ENT:ClearBMBMovementInterrupt()
    self.BMBMoveInterrupt = false
end

function ENT:SetBMBMoveMode(mode)
    mode = mode or "idle"
    if self.BMBCurrentMoveMode == mode then return end

    self.BMBCurrentMoveMode = mode
    self:SetNWString("BMBMoveMode", mode)

    if mode == "idle" and self.StartBMBIdleActivity then
        self:StartBMBIdleActivity()
    end
end

function ENT:MaintainBMBMoveSpeed(speed)
    local desiredSpeed = speed or self.WalkSpeed

    self.loco:SetDesiredSpeed(desiredSpeed)
    self:SetNWFloat("BMBDesiredSpeed", desiredSpeed)
end

function ENT:UpdateBMBApproachDebug(target, nodeIndex)
    if target then
        self:SetNWFloat("BMBDistToGoal", flatDistance(self:GetPos(), target))
    else
        self:SetNWFloat("BMBDistToGoal", 0)
    end

    if nodeIndex then
        self:SetNWInt("BMBPathNode", nodeIndex)
    end
end

function ENT:MarkBMBPathAdvanced(nodeIndex)
    self.BMBPathAdvanceCount = (self.BMBPathAdvanceCount or 0) + 1
    self:SetNWInt("BMBPathAdvance", self.BMBPathAdvanceCount)

    if nodeIndex then
        self:SetNWInt("BMBPathNode", nodeIndex)
    end
end

function ENT:StartBMBIdleActivity()
    if self.CurrentMoveActivity == ACT_IDLE then return end

    self:StartActivity(ACT_IDLE)
    self.CurrentMoveActivity = ACT_IDLE
end

function ENT:StartBMBMoveProgressWatch()
    return {
        pos = copyVector(self:GetPos()),
        deadline = CurTime() + (self.MoveNoProgressGrace or 0.75)
    }
end

function ENT:CheckBMBMoveProgress(watch)
    if not watch then return true end

    local velocity = self:GetVelocity():Length2D()
    local moved = flatDistance(self:GetPos(), watch.pos)

    if velocity >= (self.MoveNoProgressSpeed or 8) or moved >= (self.MoveNoProgressDistance or 3) then
        watch.pos = copyVector(self:GetPos())
        watch.deadline = CurTime() + (self.MoveNoProgressTimeout or 0.45)
        return true
    end

    return CurTime() < watch.deadline
end

function ENT:StartBMBGoalProgressWatch(goal)
    return {
        distance = flatDistance(self:GetPos(), goal),
        deadline = CurTime() + (self.PathGoalProgressTimeout or 0.9)
    }
end

function ENT:CheckBMBGoalProgress(watch, goal)
    if not watch or not goal then return true end

    local distance = flatDistance(self:GetPos(), goal)
    if distance <= watch.distance - (self.PathGoalProgressDistance or 10) then
        watch.distance = distance
        watch.deadline = CurTime() + (self.PathGoalProgressTimeout or 0.9)
        return true
    end

    if distance > watch.distance then
        watch.distance = distance
    end

    return CurTime() < watch.deadline
end

function ENT:FailBMBMove(mode, keepMomentum)
    -- 安全层拦下移动时主动杀掉水平动量：高速冲向平台边缘时仅靠自然减速刹不住，
    -- 惯性会把 mob 顺势带下悬崖。撞墙类失败（keepMomentum）不急刹：墙本身挡得住，
    -- 急刹反而造成"离 prop 还有段距离就掉速、一点一点给油转向"的犹豫观感
    if not keepMomentum then
        local velocity = self:GetVelocity()
        self.loco:SetVelocity(Vector(velocity.x * 0.1, velocity.y * 0.1, velocity.z))
    end

    self:SetBMBMoveMode(mode or "blocked")
    self:StartBMBIdleActivity()
    self:UpdateBMBApproachDebug(nil, 0)
end

function ENT:InterruptibleWait(duration)
    self:StartBMBIdleActivity()
    self:SetBMBMoveMode("idle")
    self:UpdateBMBApproachDebug(nil, 0)

    local deadline = CurTime() + duration

    while CurTime() < deadline do
        if self.BMBMoveInterrupt then return false end
        coroutine.wait(math.min(0.05, deadline - CurTime()))
    end

    return true
end

function ENT:RunBehaviour()
    while true do
        coroutine.wait(0.2)
        coroutine.yield()
    end
end

function ENT:Think()
    if SERVER then
        self:CheckPhysicsImpacts()
        self:NextThink(CurTime())
        return true
    end
end

function ENT:SetBMBState(state)
    if self.State == state then return end
    self.State = state
    self:SetNWString("BMBState", state)
end

function ENT:HasBMBDebugMove()
    return self.BMBDebugMoveUntil and CurTime() < self.BMBDebugMoveUntil and (self.BMBDebugMoveDirection or self.BMBDebugMoveTarget)
end

function ENT:ClearBMBDebugMove()
    self.BMBDebugMoveUntil = 0
    self.BMBDebugMoveDirection = nil
    self.BMBDebugMoveTarget = nil
end

function ENT:RunBMBDebugMove()
    if not self:HasBMBDebugMove() then return false end

    local desiredSpeed = self.BMBDebugMoveSpeed or self.RunSpeed

    self:SetBMBState("debug_move")
    self:SetBMBMoveMode("debug_direct")
    self:ClearBMBMovementInterrupt()
    self:MaintainBMBMoveSpeed(desiredSpeed)
    self:UpdateMoveActivity(desiredSpeed)

    local progressWatch = self:StartBMBMoveProgressWatch()

    while self:HasBMBDebugMove() do
        local target

        if self.BMBDebugMoveTarget then
            local delta = self.BMBDebugMoveTarget - self:GetPos()
            delta.z = 0

            if delta:Length2D() <= (self.BMBDebugMoveTolerance or 24) then
                self:ClearBMBDebugMove()
                self:SetBMBMoveMode("idle")
                self:UpdateBMBApproachDebug(nil, 0)
                return true
            end

            delta:Normalize()

            local lookAhead = math.min(math.max(self:GetPos():Distance(self.BMBDebugMoveTarget), 96), self.BMBDebugMoveLookAhead or 220)
            target = self:GetPos() + delta * lookAhead
        else
            local direction = self.BMBDebugMoveDirection
            if not direction then
                self:ClearBMBDebugMove()
                self:SetBMBMoveMode("idle")
                self:UpdateBMBApproachDebug(nil, 0)
                return true
            end

            target = self:GetPos() + direction * (self.BMBDebugMoveLookAhead or 180)
        end

        target.z = self:GetPos().z

        if not self.BMBDebugMoveIgnoreSafety and not self:IsMovementTargetSafe(target) then
            self:ClearBMBDebugMove()
            self:SetBMBMoveMode("idle")
            self:UpdateBMBApproachDebug(nil, 0)
            return true
        end

        self:MaintainBMBMoveSpeed(desiredSpeed)
        self:UpdateBMBApproachDebug(target, 0)
        self:SteerTowards(target, progressWatch)
        self:BodyMoveXY()
        self:MaybePlayStep()

        if not self:CheckBMBMoveProgress(progressWatch) then
            self:ClearBMBDebugMove()
            self:FailBMBMove("debug_blocked")
            return true
        end

        if self.loco:IsStuck() then
            self:HandleStuck()
            self:ClearBMBDebugMove()
            self:FailBMBMove("debug_stuck")
            return true
        end

        coroutine.yield()
    end

    self:SetBMBMoveMode("idle")
    self:UpdateBMBApproachDebug(nil, 0)
    return true
end

function ENT:MoveToWorldPosition(destination, speed, options)
    options = options or {}

    local desiredSpeed = speed or self.WalkSpeed
    self.loco:SetDesiredSpeed(desiredSpeed)
    self:UpdateMoveActivity(desiredSpeed)

    if not options.keepInterrupt then
        self:ClearBMBMovementInterrupt()
    end

    if self:ShouldUseSourcePath() and not options.skipSourcePath then
        if self:MoveWithSourcePath(destination, desiredSpeed, options) then return true end
        if self.BMBMoveInterrupt then return false end
    end

    local waypoints = BMB.Pathfinder.FindPath(self:GetPos(), destination)
    if not waypoints or #waypoints == 0 then
        if options.allowDirectFallback then
            return self:MoveDirectFallback(destination, speed, options)
        end

        return false
    end

    if self:MoveAlongPath(waypoints, desiredSpeed, options) then return true end
    if self.BMBMoveInterrupt then return false end

    if options.allowDirectFallback then
        return self:MoveDirectFallback(destination, speed, options)
    end

    return false
end

function ENT:MoveWithSourcePath(destination, speed, options)
    options = options or {}

    if not Path then return false end

    local path = Path("Follow")
    local goalTolerance = options.goalTolerance or self.SourcePathGoalTolerance

    path:SetMinLookAheadDistance(options.lookAhead or self.SourcePathLookAhead)
    path:SetGoalTolerance(goalTolerance)
    path:Compute(self, destination)

    if not path:IsValid() then return false end

    local timeout = CurTime() + (options.timeout or options.duration or self.WaypointTimeout)

    self:ClearBMBMovementInterrupt()
    self.loco:SetDesiredSpeed(speed or self.WalkSpeed)
    self:UpdateMoveActivity(speed or self.WalkSpeed)

    local progressWatch = self:StartBMBMoveProgressWatch()

    while path:IsValid() and CurTime() < timeout do
        if self.BMBMoveInterrupt then return false end
        if self:GetPos():DistToSqr(destination) <= goalTolerance * goalTolerance then return true end

        self:SetBMBMoveMode("source_path")
        self:MaintainBMBMoveSpeed(speed or self.WalkSpeed)
        self:UpdateBMBApproachDebug(destination, 0)
        path:Update(self)
        self:BodyMoveXY()
        self:MaybePlayStep()

        if not self:CheckBMBMoveProgress(progressWatch) then
            self:FailBMBMove("source_blocked")
            return false
        end

        if self.loco:IsStuck() then
            self:HandleStuck()
            self:FailBMBMove("source_stuck")
            return false
        end

        coroutine.yield()
    end

    if options.acceptPartial then return true end

    return self:GetPos():DistToSqr(destination) <= goalTolerance * goalTolerance
end

function ENT:GetPathCarrot(waypoints, startIndex, carrotDistance)
    local current = self:GetPos()
    local cursor = Vector(current.x, current.y, current.z)
    local remaining = carrotDistance

    for i = startIndex, #waypoints do
        local node = Vector(waypoints[i].x, waypoints[i].y, current.z)
        local segment = node - cursor
        segment.z = 0

        local length = segment:Length()
        if length > 0.1 then
            if length >= remaining then
                segment:Normalize()

                local carrot = cursor + segment * remaining
                carrot.z = current.z

                return carrot
            end

            remaining = remaining - length
            cursor = node
        end
    end

    local final = waypoints[#waypoints]
    if not final then return nil end

    -- 路径快走完时把 carrot 投到终点之外：让 mob 全速跨过到达圈再由行为层停下，
    -- 否则 Approach 在终点减速区把速度拖到 watchdog 阈值以下，会被误判成"被卡住"
    if remaining > 0 then
        local overshoot = Vector(final.x - current.x, final.y - current.y, 0)

        if overshoot:LengthSqr() > 1 then
            overshoot:Normalize()
            return Vector(final.x, final.y, current.z) + overshoot * remaining
        end
    end

    return Vector(final.x, final.y, current.z)
end

function ENT:GetPathSafetyTarget(waypoints, nodeIndex)
    local current = self:GetPos()
    local target = waypoints[nodeIndex]
    if not target then return nil end

    if nodeIndex < #waypoints and flatDistance(current, target) <= 4 then
        target = waypoints[nodeIndex + 1]
    end

    return Vector(target.x, target.y, current.z)
end

function ENT:MoveAlongPath(waypoints, speed, options)
    options = options or {}

    if not waypoints or #waypoints == 0 then return false end

    local desiredSpeed = speed or self.WalkSpeed
    local goalTolerance = options.goalTolerance or BMB.Config.DefaultGoalTolerance
    local nodeTolerance = options.nodeTolerance or self.PathNodeTolerance
    local carrotDistance = options.carrotDistance or math.Clamp(
        desiredSpeed * (self.PathCarrotSpeedScale or 1.1),
        self.PathCarrotMinDistance or 72,
        self.PathCarrotMaxDistance or 150
    )
    local timeout = CurTime() + (options.timeout or math.max(
        self.WaypointTimeout,
        #waypoints * (self.PathTimeoutPerNode or 0.8) + 1.0
    ))
    local nodeIndex = 1
    local final = waypoints[#waypoints]

    -- 路径头部是出发格中心，可能落在身后：起步前先跳过脚下这一格，避免开局回头拐一下
    local startPos = self:GetPos()
    while nodeIndex < #waypoints and flatDistance(startPos, waypoints[nodeIndex]) <= BMB.Config.BlockSize * 0.75 do
        nodeIndex = nodeIndex + 1
    end

    self:ClearBMBMovementInterrupt()
    self:MaintainBMBMoveSpeed(desiredSpeed)
    self:UpdateMoveActivity(desiredSpeed)
    self:SetBMBMoveMode("path_carrot")

    local progressWatch = self:StartBMBMoveProgressWatch()
    local goalProgressWatch = self:StartBMBGoalProgressWatch(final)

    while CurTime() < timeout do
        if self.BMBMoveInterrupt then return false end

        local current = self:GetPos()
        if flatDistance(current, final) <= goalTolerance then
            self:SetBMBMoveMode("idle")
            self:UpdateBMBApproachDebug(nil, 0)
            return true
        end

        while nodeIndex < #waypoints do
            local node = waypoints[nodeIndex]
            local nodeDistance = flatDistance(current, node)

            if nodeDistance <= nodeTolerance then
                nodeIndex = nodeIndex + 1
                self:MarkBMBPathAdvanced(nodeIndex)
            elseif nodeDistance <= BMB.Config.BlockSize * 1.5 then
                -- 切弯时会从节点旁边掠过（横向 > nodeTolerance），只按距离判定节点永远推进不了，
                -- carrot 会折回身后的漏过节点导致原地转圈。已越过该节点朝下一节点的垂面就视为通过
                local nextNode = waypoints[nodeIndex + 1]
                local passedX = (nextNode.x - node.x) * (current.x - node.x)
                local passedY = (nextNode.y - node.y) * (current.y - node.y)

                if passedX + passedY > 0 then
                    nodeIndex = nodeIndex + 1
                    self:MarkBMBPathAdvanced(nodeIndex)
                else
                    break
                end
            else
                break
            end
        end

        local carrot = self:GetPathCarrot(waypoints, nodeIndex, carrotDistance)
        local safetyTarget = self:GetPathSafetyTarget(waypoints, nodeIndex)
        if not carrot or not safetyTarget then return false end

        local safe, blockReason = self:IsMovementTargetSafe(safetyTarget)
        if not safe then
            self:FailBMBMove("path_blocked", blockReason == "wall")
            return false
        end

        self:SetBMBMoveMode("path_carrot")
        self:MaintainBMBMoveSpeed(desiredSpeed)
        self:UpdateBMBApproachDebug(carrot, nodeIndex)
        self:SteerTowards(carrot, progressWatch)
        self:BodyMoveXY()
        self:MaybePlayStep()

        if not self:CheckBMBMoveProgress(progressWatch) then
            -- 已经贴到终点附近的"无进度"按到达处理：到站减速被 watchdog 误杀会跳过行为层的停顿
            if flatDistance(current, final) <= goalTolerance * 2 then
                self:SetBMBMoveMode("idle")
                self:UpdateBMBApproachDebug(nil, 0)
                return true
            end

            self:FailBMBMove("path_blocked")
            return false
        end

        if not self:CheckBMBGoalProgress(goalProgressWatch, final) then
            if flatDistance(current, final) <= goalTolerance * 2 then
                self:SetBMBMoveMode("idle")
                self:UpdateBMBApproachDebug(nil, 0)
                return true
            end

            self:FailBMBMove("path_no_goal_progress")
            return false
        end

        if self.loco:IsStuck() then
            self:HandleStuck()
            self:FailBMBMove("path_stuck")
            return false
        end

        coroutine.yield()
    end

    if options.acceptPartial then return true end

    return flatDistance(self:GetPos(), final) <= goalTolerance
end

function ENT:MoveDirectFallback(destination, speed, options)
    options = options or {}

    local desiredSpeed = speed or self.RunSpeed
    local duration = options.duration or 0.55
    local timeout = CurTime() + duration
    local target = Vector(destination.x, destination.y, self:GetPos().z)

    self:ClearBMBMovementInterrupt()
    self:MaintainBMBMoveSpeed(desiredSpeed)
    self:UpdateMoveActivity(desiredSpeed)
    self:SetBMBMoveMode("direct")

    local progressWatch = self:StartBMBMoveProgressWatch()

    while CurTime() < timeout do
        if self.BMBMoveInterrupt then return false end

        target.z = self:GetPos().z

        local safe, blockReason = self:IsMovementTargetSafe(target, self:GetBMBTickSafetyProbe(options.safetyProbe))
        if not safe then
            self:FailBMBMove("direct_blocked", blockReason == "wall")
            return false
        end

        self:MaintainBMBMoveSpeed(desiredSpeed)
        self:UpdateBMBApproachDebug(target, 0)
        self:SteerTowards(target, progressWatch)
        self:BodyMoveXY()
        self:MaybePlayStep()

        if not self:CheckBMBMoveProgress(progressWatch) then
            self:FailBMBMove("direct_blocked")
            return false
        end

        coroutine.yield()
    end

    return true
end

function ENT:MoveAlongDirection(direction, speed, options)
    options = options or {}

    local moveDirection = Vector(direction.x, direction.y, 0)
    -- 只挡零向量：Flee 传进来的是归一化单位向量（LengthSqr ≈ 1.0），阈值用 1 会把它拒收
    if moveDirection:LengthSqr() < 0.01 then return false end

    moveDirection:Normalize()

    local desiredSpeed = speed or self.WalkSpeed
    local duration = options.duration or 1.0
    local lookAhead = options.lookAhead or 150
    local timeout = CurTime() + duration
    local pathDestination = self:GetPos() + moveDirection * lookAhead
    pathDestination.z = self:GetPos().z

    if options.useSourcePath and self:ShouldUseSourcePath() and not options.skipSourcePath then
        if self:MoveWithSourcePath(pathDestination, speed or self.WalkSpeed, {
            duration = duration,
            lookAhead = options.pathLookAhead or self.SourcePathLookAhead,
            goalTolerance = options.goalTolerance or self.SourcePathGoalTolerance,
            acceptPartial = true,
            skipSourcePath = true
        }) then
            return true
        end

        if self.BMBMoveInterrupt then return false end
    end

    self:ClearBMBMovementInterrupt()
    self:MaintainBMBMoveSpeed(desiredSpeed)
    self:UpdateMoveActivity(desiredSpeed)
    self:SetBMBMoveMode("direction_direct")

    local progressWatch = self:StartBMBMoveProgressWatch()

    while CurTime() < timeout do
        if self.BMBMoveInterrupt then return false end

        local target = self:GetPos() + moveDirection * lookAhead
        target.z = self:GetPos().z

        local safe, blockReason = self:IsMovementTargetSafe(target, self:GetBMBTickSafetyProbe(options.safetyProbe))
        if not safe then
            self:FailBMBMove("direction_blocked", blockReason == "wall")
            return false
        end

        self:MaintainBMBMoveSpeed(desiredSpeed)
        self:UpdateBMBApproachDebug(target, 0)
        self:SteerTowards(target, progressWatch)
        self:BodyMoveXY()
        self:MaybePlayStep()

        if not self:CheckBMBMoveProgress(progressWatch) then
            self:FailBMBMove("direction_blocked")
            return false
        end

        coroutine.yield()
    end

    return true
end

function ENT:MoveToWaypoint(waypoint)
    local target = Vector(waypoint.x, waypoint.y, self:GetPos().z)
    local timeout = CurTime() + self.WaypointTimeout

    self:SetBMBMoveMode("waypoint_legacy")

    local progressWatch = self:StartBMBMoveProgressWatch()

    while CurTime() < timeout do
        if self.BMBMoveInterrupt then return false end

        target.z = self:GetPos().z

        local delta = target - self:GetPos()
        delta.z = 0

        if delta:Length2D() <= BMB.Config.DefaultGoalTolerance then return true end

        local safe, blockReason = self:IsMovementTargetSafe(target)
        if not safe then
            self:FailBMBMove("waypoint_blocked", blockReason == "wall")
            return false
        end

        self:MaintainBMBMoveSpeed(self:GetNWFloat("BMBDesiredSpeed", self.WalkSpeed))
        self:UpdateBMBApproachDebug(target, 0)
        self:SteerTowards(target, progressWatch)
        self:BodyMoveXY()
        self:MaybePlayStep()

        if not self:CheckBMBMoveProgress(progressWatch) then
            self:FailBMBMove("waypoint_blocked")
            return false
        end

        if self.loco:IsStuck() then
            self:HandleStuck()
            self:FailBMBMove("waypoint_stuck")
            return false
        end

        coroutine.yield()
    end

    return false
end

-- 移动中每 tick 复查用的探测距离：悬崖前瞻随速度缩放（刹得住即可），
-- 但不超过选方向时验证过的档位——选向短档、复查长档会"选中即失败"，又回到冻住
function ENT:GetBMBTickSafetyProbe(selectionProbe)
    local dynamicProbe = math.max(
        self.ForwardSafetyDistance,
        self:GetVelocity():Length2D() * (self.SafetyProbeSpeedScale or 0.45)
    )

    if selectionProbe then return math.min(selectionProbe, dynamicProbe) end

    return dynamicProbe
end

function ENT:IsMovementTargetSafe(target, probeDistance)
    local current = self:GetPos()
    local probeHeight = self.GroundProbeHeight
    local delta = target - current
    delta.z = 0

    local distance = delta:Length2D()
    if distance <= 1 then return true end

    delta:Normalize()

    -- 探测距离随当前速度放大：固定 48u 在跑动速度（Flee 145u/s，刹车距离约 40u）下
    -- 等探到没地面时动量已经把 mob 带下悬崖
    local probe = math.min(distance, probeDistance or math.max(
        self.ForwardSafetyDistance,
        self:GetVelocity():Length2D() * (self.SafetyProbeSpeedScale or 0.45)
    ))
    local forwardTarget = current + delta * probe
    local startPos = current + Vector(0, 0, probeHeight)
    local endPos = forwardTarget + Vector(0, 0, probeHeight)
    local hullScale = self.SafetyHullScale
    local traceFilter = function(ent)
        return self:ShouldSafetyTraceHit(ent)
    end

    local wallTrace = util.TraceHull({
        start = startPos,
        endpos = endPos,
        mins = Vector(self.CollisionMins.x * hullScale, self.CollisionMins.y * hullScale, -probeHeight * 0.35),
        maxs = Vector(self.CollisionMaxs.x * hullScale, self.CollisionMaxs.y * hullScale, probeHeight * 0.45),
        filter = traceFilter,
        mask = MASK_SOLID
    })

    -- 起步就嵌在 prop 里（StartSolid）时不按墙处理：被 prop 挤住/贴住（尤其斜放的 prop）时
    -- 所有方向的 hull 都从重叠开始，按墙判会全方向被毙 → Flee 原地冻住。
    -- 放行后撞不动的方向由 loco 碰撞挡住、no-progress watchdog 换向，能走的方向自然脱困
    if wallTrace.Hit and not wallTrace.StartSolid and not self:CanStepPastTrace(wallTrace, forwardTarget, traceFilter) then
        -- 撞墙无害（loco 碰撞自己挡得住），不需要像悬崖那样在整个探测距离上提前避让：
        -- 远处的墙允许继续接近，贴脸（WallStopDistance）才算挡路。否则 mob 在离 prop
        -- 一个探测距离外就开始犹豫掉速，永远碰不到 prop（三面围起来时直接不敢进）
        local hitDistance = wallTrace.Fraction * probe
        if hitDistance <= (self.WallStopDistance or 20) then return false, "wall" end

        -- 墙还远：把地面探测截到墙跟前，否则探测点落进墙体/墙顶会误报
        probe = hitDistance - 4
        forwardTarget = current + delta * probe
    end

    local groundTrace = util.TraceHull({
        start = forwardTarget + Vector(0, 0, self.GroundProbeHeight),
        endpos = forwardTarget - Vector(0, 0, self.GroundProbeDepth),
        mins = Vector(self.CollisionMins.x * 0.75, self.CollisionMins.y * 0.75, 0),
        maxs = Vector(self.CollisionMaxs.x * 0.75, self.CollisionMaxs.y * 0.75, 4),
        filter = traceFilter,
        mask = MASK_SOLID
    })

    if not groundTrace.Hit then return false, "cliff" end
    if groundTrace.HitNormal.z < 0.65 then return false, "cliff" end
    if current.z - groundTrace.HitPos.z > self.MaxStepDown then return false, "cliff" end

    return true
end

function ENT:CanStepPastTrace(wallTrace, forwardTarget, traceFilter)
    if not wallTrace.Hit then return true end

    local current = self:GetPos()
    local stepHeight = self.StepHeight

    if wallTrace.HitPos.z - current.z > stepHeight + 4 then return false end

    local raisedStart = current + Vector(0, 0, stepHeight + self.GroundProbeHeight)
    local raisedEnd = forwardTarget + Vector(0, 0, stepHeight + self.GroundProbeHeight)
    local hullScale = self.SafetyHullScale

    local raisedTrace = util.TraceHull({
        start = raisedStart,
        endpos = raisedEnd,
        mins = Vector(self.CollisionMins.x * hullScale, self.CollisionMins.y * hullScale, -self.GroundProbeHeight * 0.35),
        maxs = Vector(self.CollisionMaxs.x * hullScale, self.CollisionMaxs.y * hullScale, self.GroundProbeHeight * 0.45),
        filter = traceFilter,
        mask = MASK_SOLID
    })

    if raisedTrace.Hit then return false end

    local landingTrace = util.TraceHull({
        start = forwardTarget + Vector(0, 0, stepHeight + self.GroundProbeHeight),
        endpos = forwardTarget - Vector(0, 0, self.GroundProbeDepth),
        mins = Vector(self.CollisionMins.x * 0.6, self.CollisionMins.y * 0.6, 0),
        maxs = Vector(self.CollisionMaxs.x * 0.6, self.CollisionMaxs.y * 0.6, 4),
        filter = traceFilter,
        mask = MASK_SOLID
    })

    if not landingTrace.Hit then return false end
    if landingTrace.HitNormal.z < 0.65 then return false end
    if landingTrace.HitPos.z - current.z > stepHeight + 4 then return false end
    if current.z - landingTrace.HitPos.z > self.MaxStepDown then return false end

    return true
end

function ENT:ShouldSafetyTraceHit(ent)
    if ent == self then return false end
    if not IsValid(ent) then return true end
    if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() then return false end

    return true
end

function ENT:CheckPhysicsImpacts()
    if self.BMBDead then return end
    if CurTime() < (self.NextPhysicsImpactCheck or 0) then return end

    self.NextPhysicsImpactCheck = CurTime() + self.PhysicsImpactInterval

    local center = self:WorldSpaceCenter()
    for _, ent in ipairs(ents.FindInSphere(center, self.PhysicsImpactRadius)) do
        self:HandlePhysicsImpact(ent)
    end
end

function ENT:HandlePhysicsImpact(ent)
    if not self:IsPhysicsImpactEntity(ent) then return false end

    local now = CurTime()
    self.PhysicsImpactTimes = self.PhysicsImpactTimes or {}

    if now < (self.PhysicsImpactTimes[ent] or 0) then return false end

    local phys = ent:GetPhysicsObject()
    local velocity = phys:GetVelocity()
    local speed = velocity:Length()

    if speed < self.PhysicsImpactMinSpeed then return false end

    self.PhysicsImpactTimes[ent] = now + self.PhysicsImpactCooldown

    local massScale = math.Clamp(phys:GetMass() / 45, 0.75, 2.25)
    local damageAmount = math.Clamp((speed - self.PhysicsImpactMinSpeed) * self.PhysicsImpactDamageScale * massScale, 1, self.PhysicsImpactMaxDamage)

    local damage = DamageInfo()
    damage:SetAttacker(IsValid(ent:GetOwner()) and ent:GetOwner() or ent)
    damage:SetInflictor(ent)
    damage:SetDamage(damageAmount)
    damage:SetDamageType(DMG_CRUSH)
    damage:SetDamageForce(velocity * phys:GetMass())
    damage:SetDamagePosition(ent:WorldSpaceCenter())

    self:TakeDamageInfo(damage)
    self:ReactToPhysicsImpact(ent, phys, velocity, self.BMBDead)

    return true
end

function ENT:IsPhysicsImpactEntity(ent)
    if not IsValid(ent) then return false end
    if ent == self then return false end
    if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() then return false end

    local phys = ent:GetPhysicsObject()
    if not IsValid(phys) or not phys:IsMoveable() then return false end

    return ent:GetSolid() ~= SOLID_NONE
end

function ENT:ReactToPhysicsImpact(ent, phys, velocity, killed)
    local damping = killed and self.PhysicsPropKillDamping or self.PhysicsPropImpactDamping

    phys:SetVelocity(velocity * damping)
end

function ENT:OnContact(ent)
    self:HandlePhysicsImpact(ent)
end

function ENT:StartTouch(ent)
    self:HandlePhysicsImpact(ent)
end

function ENT:FaceTarget(position)
    local direction = position - self:GetPos()
    direction.z = 0

    if direction:LengthSqr() <= 1 then return end

    -- 转向只走 loco（CLAUDE.md：禁止 SetAngles 手动转向，会打断客户端插值）
    -- 转速由 BaseInitialize 里的 loco:SetMaxYawRate(TurnRate) 控制
    self.loco:FaceTowards(position)
end

-- 移动循环统一入口：目标在身后超过 TurnInPlaceAngle 时先原地转身再走，
-- 否则 Approach 会不顾朝向直接倒退（MC 生物不会面朝前倒着走）
function ENT:SteerTowards(target, progressWatch)
    local direction = target - self:GetPos()
    direction.z = 0

    if direction:LengthSqr() <= 1 then return end

    self.loco:FaceTowards(target)

    local yawDiff = math.abs(math.AngleDifference(direction:Angle().y, self:GetAngles().y))
    if yawDiff > (self.TurnInPlaceAngle or 110) then
        -- 原地转身阶段速度为 0 是预期行为，不让 no-progress watchdog 计时
        if progressWatch then
            progressWatch.deadline = CurTime() + (self.MoveNoProgressGrace or 0.35)
        end

        return
    end

    self.loco:Approach(target, 1)
end

function ENT:MaybePlayStep()
    if CurTime() < self.NextStepSoundTime then return end
    if self:GetVelocity():Length2D() < 18 then return end

    self:EmitSound("npc/zombie/foot1.wav", 58, math.random(96, 104), 0.25)
    self.NextStepSoundTime = CurTime() + 0.5
end

function ENT:PlayBMBAnimation(name)
    if name == "eat" then
        self:RestartGesture(ACT_GESTURE_RANGE_ATTACK1)
    elseif name == "hurt" then
        self:RestartGesture(ACT_FLINCH_PHYSICS)
    end
end

function ENT:OnInjured(damageInfo)
    if CLIENT then return end

    self:InterruptBMBMovement()
    self:PlayBMBAnimation("hurt")

    if self.OnBMBInjured then
        self:OnBMBInjured(damageInfo)
    end
end

function ENT:OnTakeDamage(damageInfo)
    if CLIENT or self.BMBDead then return end

    local damage = damageInfo:GetDamage()
    self:SetHealth(self:Health() - damage)
    self:SetNWInt("BMBHealth", self:Health())
    self:OnInjured(damageInfo)

    if self:Health() <= 0 then
        self.BMBDead = true
        self:OnKilled(damageInfo)
    end

    return damage
end

function ENT:OnKilled(damageInfo)
    if CLIENT then return end

    hook.Run("OnNPCKilled", self, damageInfo:GetAttacker(), damageInfo:GetInflictor())
    self:BecomeRagdoll(damageInfo)
end
