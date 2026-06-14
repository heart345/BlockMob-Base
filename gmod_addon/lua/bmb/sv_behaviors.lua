BMB = BMB or {}
BMB.Behaviors = BMB.Behaviors or {}

BMB.Behaviors.Wander = BMB.Behaviors.Wander or {}
BMB.Behaviors.Flee = BMB.Behaviors.Flee or {}
BMB.Behaviors.EatGrass = BMB.Behaviors.EatGrass or {}
BMB.Behaviors.SeekTarget = BMB.Behaviors.SeekTarget or {}
BMB.Behaviors.Chase = BMB.Behaviors.Chase or {}
BMB.Behaviors.MeleeAttack = BMB.Behaviors.MeleeAttack or {}

local MIN_VALID_DIRECTION_SQR = 0.0001

local function blockSize()
    return BMB.GetBlockSize and BMB.GetBlockSize() or (BMB.BS or 36.5)
end

if SERVER and not GetConVar("bmb_debug_melee_knockback") then
    CreateConVar("bmb_debug_melee_knockback", "0", FCVAR_ARCHIVE, "Print BMB melee knockback diagnostics.")
end

if SERVER then
    concommand.Add("bmb_melee_knockback_debug", function(ply, _, args)
        if IsValid(ply) and not ply:IsAdmin() then return end

        local enabled = tostring(args and args[1] or "1") ~= "0"
        RunConsoleCommand("bmb_debug_melee_knockback", enabled and "1" or "0")
        print("[BMB] melee knockback debug " .. (enabled and "enabled" or "disabled"))
    end)
end

local function shouldLogMeleeKnockback()
    local cvar = GetConVar and GetConVar("bmb_debug_melee_knockback")
    return cvar and cvar:GetBool()
end

local function formatVector2D(vec)
    if not vec then return "nil" end
    return string.format("(%.1f,%.1f,%.1f)", vec.x or 0, vec.y or 0, vec.z or 0)
end

-- 娓歌崱 = 閫変竴涓殢鏈哄彲璧扮偣锛屾部 A* 璺緞瀹屾暣璧板埌锛屽埌杈惧悗鎸?MC 鑺傚鍋滈】涓€涓嬪啀閫変笅涓€涓€?-- 涓嶈鍦ㄩ€斾腑鎸夊浐瀹氭椂闀垮垏娈碉細閭ｄ細鍙樻垚"璧颁竴浼?鍒瑰仠-鎹㈠悜"鐨勮妭濂忥紙宸茶俯杩囧潙锛夈€?
-- 閫斾腑鐨勮浆鍚戝叏閮ㄧ敱 MoveAlongPath 鐨?carrot point 骞虫粦瀹屾垚銆?
function BMB.Behaviors.Wander.Run(mob)
    -- 鍗曟琛岀▼鐨勮窛绂昏寖鍥达細MC 寮忕煭閫旀暎姝ワ紙2~5 鏍硷級锛屼笉璺ㄥ崐寮犲湴鍥?
    local size = blockSize()
    local minDistance = mob.WanderDistanceMin or size * (mob.WanderDistanceMinCells or 2)
    local maxDistance = mob.WanderDistanceMax or mob.WanderRadius or size * (mob.WanderDistanceMaxCells or 5)
    local attempts = mob.WanderPathAttempts or 2

    for _ = 1, attempts do
        if mob.BMBMoveInterrupt then return end

        local destination = BMB.BlockWorld.GetRandomWalkablePoint(mob:GetPos(), maxDistance, mob)
        local direction = destination - mob:GetPos()
        direction.z = 0

        local distance = direction:Length2D()

        if distance >= minDistance and distance <= maxDistance then
            if mob:MoveToWorldPosition(destination, mob.WalkSpeed, { skipSourcePath = true }) then
                -- 鍘熺増 MC 娓歌崱鏄?绔欏緢涔呫€佸伓灏旇蛋涓€娈?锛氬埌绔欏悗闀垮仠椤匡紝绔欑珛鎵嶆槸甯告€?
                mob:InterruptibleWait(math.Rand(mob.WanderPauseMin or 6.0, mob.WanderPauseMax or 14.0))
                return
            end

            -- 璧颁笉閫氾紙璺緞澶辫触/琚尅锛夌洿鎺ユ崲涓洰鏍囩偣閲嶈瘯锛屼笉鎻掑叆鍋滈】锛屼繚鎸佺Щ鍔ㄨ繛璐?
            if mob.BMBMoveInterrupt then return end
            coroutine.yield()
        end
    end

    -- 鍊欓€夌偣鍏ㄩ儴澶辫触锛屾瓏涓€鎷嶉伩鍏嶅鍙?mob 鍦ㄥ悓涓€甯ц繛缁埛 A*銆?
    mob:InterruptibleWait(math.Rand(mob.WanderFailurePauseMin or 0.8, mob.WanderFailurePauseMax or 1.8))
end

-- Flee = MC 鐨?PanicGoal锛堝弬鑰?net/minecraft/world/entity/ai/goal/PanicGoal.java +
-- ai/util/DefaultRandomPos.java / RandomPos.java锛屾簮鐮佸湪鐢ㄦ埛鏈湴锛夛細
-- 鎭愭厡**涓嶆槸**鏈濅激瀹冲弽鏂瑰悜璺戯紝鑰屾槸鍙嶅"闅忔満閫変竴涓彲杈剧殑杩戠偣锛埪? 鏍硷級鈫?鍏ㄩ€熻窇杩囧幓"锛?
-- 璺戝畬涓€娈佃繕鍦ㄦ亹鎱岀獥鍙ｅ唴灏卞啀閫変笅涓€娈碘€斺€斿ぇ骞冲湴鐨勮鎰熷氨鏄殢鏈轰贡璺戙€佷笖璺戜笉杩溿€?
-- 鍊欓€夌偣鍏ㄩ儴涓嶅彲杈撅紙MC锛?0 娆″叏杩囦笉浜嗗璺牎楠?鈫?canUse false锛? 娌″湴鏂硅窇锛岀珯浣忎笉鎭愭厡銆?

local function pickPanicDestination(mob)
    -- MC DefaultRandomPos.getPos(mob, 5, 4)锛氭按骞?卤5 鏍奸殢鏈猴紱RANDOM_POS_ATTEMPTS = 10
    local size = blockSize()
    local radius = mob.FleePanicRadius or size * (mob.FleePanicRadiusCells or 5)
    local minDistance = mob.FleePanicMinDistance or size * (mob.FleePanicMinDistanceCells or 1)

    for _ = 1, 10 do
        local candidate = BMB.BlockWorld.GetRandomWalkablePoint(mob:GetPos(), radius, mob)
        local offset = candidate - mob:GetPos()
        offset.z = 0

        local distance = offset:Length2D()

        if distance >= minDistance and distance <= radius then
            offset:Normalize()

            -- MC 鐢ㄥ璺?malus 鏍￠獙鍊欓€夌偣鍙揪锛汢MB 鐨勬柟鍧?A* 鐪嬩笉鍒?prop 鍜?Source 骞冲彴杈圭紭锛?
            -- 鏀圭敤鍓嶅悜瀹夊叏鎺㈡祴浠ｆ浛锛氭湞鍊欓€夌偣鐨勭涓€娈靛繀椤昏兘璧帮紙鎸℃帀鎮礀澶栥€乸rop 姝ｅ悗鏂圭殑鐐癸級
            local probe = math.min(distance, 110)
            local probeTarget = mob:GetPos() + offset * probe
            probeTarget.z = mob:GetPos().z

            if not mob.IsMovementTargetSafe or mob:IsMovementTargetSafe(probeTarget, probe) then
                return candidate
            end
        end
    end

    return nil
end

function BMB.Behaviors.Flee.Run(mob)
    -- 杩炵画澶辫触锛堥€変笉鍑哄€欓€夌偣 / 璧锋鍗宠鎸★級杈惧埌涓婇檺 = 纭鏃犺矾鍙€冿紝鎻愬墠缁撴潫鎭愭厡銆?
    -- 瀵归綈 MC 瀹炴祴锛氳鍥村湪灏忓彴瀛愪笂鐨勫弸濂界敓鐗╁啿鍑犱笅灏辩珯浣忥紝涓嶄細鏃犻檺涔辨挒缁曞湀
    local failures = 0
    local giveUpAfter = mob.FleeGiveUpFailures or 4

    while CurTime() < (mob.FleeUntil or 0) do
        if mob.IsBMBKnockbackActive and mob:IsBMBKnockbackActive() then return end

        if mob.ClearBMBMovementInterrupt then
            mob:ClearBMBMovementInterrupt()
        else
            mob.BMBMoveInterrupt = false
        end

        local destination = pickPanicDestination(mob)
        local moved = false

        if destination then
            local airborneStart = mob.IsBMBOnGround and not mob:IsBMBOnGround() or false
            local fleeMinPathSpeed
            if mob.FleeKeepFullSpeed then
                fleeMinPathSpeed = mob.RunSpeed or mob.WalkSpeed or 0
            elseif mob.FleeMinPathSpeed then
                fleeMinPathSpeed = mob.FleeMinPathSpeed
            elseif mob.GetBMBRunActivityThreshold then
                fleeMinPathSpeed = mob:GetBMBRunActivityThreshold() + (mob.FleeMinPathSpeedPadding or 1)
            else
                fleeMinPathSpeed = ((mob.WalkSpeed or mob.RunSpeed or 0) + (mob.RunSpeed or mob.WalkSpeed or 0)) * 0.5 + 1
            end

            fleeMinPathSpeed = math.min(mob.RunSpeed or fleeMinPathSpeed, fleeMinPathSpeed)

            -- allowPartial=false锛氭亹鎱屽€欓€変笉鍙揪灏辫绠楀け璐ヨ鏁帮紙MC锛氳鍥翠綇鍐插嚑涓嬫斁寮冿級锛?
            -- 閮ㄥ垎璺緞浼氭妸"鎾炲"娲楁垚"鎴愬姛鍐插埡"锛屽け璐ヨ鏁版案杩滄竻闆躲€佸洿鏍忛噷鏃犻檺涔辨挒
            moved = mob:MoveToWorldPosition(destination, mob.RunSpeed, {
                skipSourcePath = true,
                allowPartial = false,
                allowStrandedStart = airborneStart,
                moveIntentSpeed = mob.RunSpeed,
                minPathSpeed = fleeMinPathSpeed
            })
        end

        if mob.BMBMoveInterrupt then
            if mob.IsBMBKnockbackActive and mob:IsBMBKnockbackActive() then return end

            -- 璺戝姩涓啀娆″彈鍑伙細FleeUntil 宸茶鍒锋柊锛屼笉绠楅€冭窇澶辫触锛岀洿鎺ヨ繘涓嬩竴娈?
            if mob.ClearBMBMovementInterrupt then
                mob:ClearBMBMovementInterrupt()
            else
                mob.BMBMoveInterrupt = false
            end
        elseif moved then
            failures = 0
        else
            failures = failures + 1

            if failures >= giveUpAfter then
                mob.FleeUntil = 0
                return
            end

            coroutine.yield()
        end
    end
end

function BMB.Behaviors.EatGrass.Try(mob)
    if CurTime() < (mob.NextEatGrassTime or 0) then return false end

    local blockCoord = BMB.BlockWorld.WorldToBlock(mob:GetPos() - Vector(0, 0, 4))
    local blockType = BMB.BlockWorld.GetBlockAt(blockCoord)

    if blockType ~= BMB.BlockTypes.Grass then
        mob.NextEatGrassTime = CurTime() + math.Rand(2.0, 4.0)
        return false
    end

    local totalDuration = mob.EatGrassAnimationDuration or 1.05
    local biteDelay = math.Clamp(mob.EatGrassBiteDelay or 0.42, 0, totalDuration)

    if mob.SetBMBState then mob:SetBMBState("eat_grass") end
    if mob.SetBMBMoveMode then mob:SetBMBMoveMode("eat_grass") end
    if mob.SetNWFloat then mob:SetNWFloat("BMBEatGrassStartedAt", CurTime()) end

    if mob.PlayBMBAnimation then
        mob:PlayBMBAnimation("eat")
    end

    if biteDelay > 0 then
        if mob.InterruptibleWait then
            if not mob:InterruptibleWait(biteDelay) then return false end
        else
            coroutine.wait(biteDelay)
        end
    end

    BMB.BlockWorld.SetBlockAt(blockCoord, BMB.BlockTypes.Dirt, mob)
    mob:EmitSound("npc/barnacle/barnacle_crunch2.wav", 65, math.random(95, 105), 0.45)
    mob.NextEatGrassTime = CurTime() + math.Rand(mob.EatGrassCooldownMin or 25, mob.EatGrassCooldownMax or 45)

    local remaining = math.max(0, totalDuration - biteDelay)
    if remaining > 0 then
        if mob.InterruptibleWait then
            if not mob:InterruptibleWait(remaining) then return false end
        else
            coroutine.wait(remaining)
        end
    end

    return true
end
local function isAliveTarget(target)
    if not IsValid(target) then return false end

    if target:IsPlayer() then
        return target:Alive()
    end

    local isNextBot = target.IsNextBot and target:IsNextBot()
    if target:IsNPC() or isNextBot then
        return (not target.Health or target:Health() > 0)
    end

    return false
end

local function targetFlatDistanceSqr(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y

    return dx * dx + dy * dy
end

local function targetVerticalDistance(a, b)
    return math.abs((a.z or 0) - (b.z or 0))
end

local function targetFlatDelta(mob, target)
    local delta = target:GetPos() - mob:GetPos()
    delta.z = 0

    return delta
end

local function normalizedFlatDirection(fromPos, toPos)
    if not fromPos or not toPos then return nil end

    local direction = toPos - fromPos
    direction.z = 0

    if direction:LengthSqr() <= MIN_VALID_DIRECTION_SQR then return nil end

    direction:Normalize()
    return direction
end

local function logMeleeDebug(mob, target, phase, detail, range, verticalRange, throttleKey)
    if not shouldLogMeleeKnockback() then return end
    if not IsValid(mob) then return end

    if throttleKey then
        mob.BMBMeleeDebugNextLog = mob.BMBMeleeDebugNextLog or {}
        local now = CurTime()
        if now < (mob.BMBMeleeDebugNextLog[throttleKey] or 0) then return end
        mob.BMBMeleeDebugNextLog[throttleKey] = now + (mob.MeleeDebugLogInterval or 0.25)
    end

    local flat = -1
    local vertical = -1

    if IsValid(target) then
        flat = math.sqrt(targetFlatDistanceSqr(mob:GetPos(), target:GetPos()))
        vertical = targetVerticalDistance(mob:GetPos(), target:GetPos())
    end

    print(string.format(
        "[BMB] melee %s mob=%s target=%s detail=%s flat=%.1f vert=%.1f range=%.1f vRange=%.1f now=%.2f next=%.2f",
        phase or "debug",
        tostring(mob),
        tostring(target),
        tostring(detail or "ok"),
        flat,
        vertical,
        range or -1,
        verticalRange or -1,
        CurTime(),
        IsValid(mob) and (mob.NextMeleeAttackTime or 0) or 0
    ))
end

function BMB.Behaviors.MeleeAttack.RememberTargetDirection(mob, target)
    if not IsValid(mob) or not IsValid(target) then return nil end

    local direction = normalizedFlatDirection(mob:GetPos(), target:GetPos())
    if not direction then return nil end

    mob.BMBLastMeleeTarget = target
    mob.BMBLastMeleeDirection = Vector(direction.x, direction.y, 0)
    mob.BMBLastMeleeDirectionAt = CurTime()

    return direction
end

function BMB.Behaviors.MeleeAttack.GetTargetKnockbackDirection(mob, target)
    if not IsValid(mob) or not IsValid(target) then return nil end

    local direction = normalizedFlatDirection(mob:GetPos(), target:GetPos())
    if direction then return direction end

    local memoryTime = mob.MeleeKnockbackDirectionMemory or mob.AttackKnockbackDirectionMemory or 1.0
    if mob.BMBLastMeleeTarget == target
        and mob.BMBLastMeleeDirection
        and CurTime() - (mob.BMBLastMeleeDirectionAt or 0) <= memoryTime then
        direction = Vector(mob.BMBLastMeleeDirection.x, mob.BMBLastMeleeDirection.y, 0)
        if direction:LengthSqr() > MIN_VALID_DIRECTION_SQR then
            direction:Normalize()
            return direction
        end
    end

    if mob.GetForward then
        direction = mob:GetForward()
        direction.z = 0
        if direction:LengthSqr() > MIN_VALID_DIRECTION_SQR then
            direction:Normalize()
            return direction
        end
    end

    return nil
end

function BMB.Behaviors.SeekTarget.IsValid(mob, target, range)
    if not IsValid(mob) or not isAliveTarget(target) or target == mob then return false end

    if mob.CanBMBTarget and not mob:CanBMBTarget(target) then return false end

    local maxRange = range or mob.TargetLoseRange or mob.TargetRange
    if maxRange and mob:GetPos():DistToSqr(target:GetPos()) > maxRange * maxRange then
        return false
    end

    if mob.TargetRequireLineOfSight and mob.Visible and not mob:Visible(target) then
        return false
    end

    return true
end

function BMB.Behaviors.SeekTarget.Find(mob, currentTarget)
    if not IsValid(mob) then return nil end

    local loseRange = mob.TargetLoseRange or (mob.TargetRange or 900) * 1.25
    if BMB.Behaviors.SeekTarget.IsValid(mob, currentTarget, loseRange) then
        return currentTarget
    end

    local now = CurTime()
    if mob.NextTargetScanTime and now < mob.NextTargetScanTime then return nil end

    mob.NextTargetScanTime = now + (mob.TargetScanInterval or 0.35)

    local targetRange = mob.TargetRange or 900
    local bestTarget
    local bestDistance = targetRange * targetRange

    for _, ply in ipairs(player.GetAll()) do
        if BMB.Behaviors.SeekTarget.IsValid(mob, ply, targetRange) then
            local distance = mob:GetPos():DistToSqr(ply:GetPos())
            if distance < bestDistance then
                bestTarget = ply
                bestDistance = distance
            end
        end
    end

    return bestTarget
end

function BMB.Behaviors.Chase.ShouldStalkHighTarget(mob, target)
    if not IsValid(mob) or not IsValid(target) then return false end

    local size = blockSize()
    local current = mob:GetPos()
    local targetPos = target:GetPos()
    local vertical = targetPos.z - current.z
    local minVertical = mob.ChaseHighTargetMinVertical or math.max(mob.AttackVerticalRange or 0, size * 0.85)

    if vertical <= minVertical then return false end

    local holdRange = mob.ChaseHighTargetHoldRange or size * (mob.ChaseHighTargetHoldCells or 1.65)

    return targetFlatDistanceSqr(current, targetPos) <= holdRange * holdRange
end

function BMB.Behaviors.Chase.CanDirect(mob, target)
    if not IsValid(mob) or not IsValid(target) then return false end
    if mob.ChasePreferDirect == false then return false end
    if BMB.Behaviors.Chase.ShouldStalkHighTarget(mob, target) then return false end

    if mob.ChaseDirectRequireLineOfSight ~= false and mob.Visible and not mob:Visible(target) then
        return false
    end

    local size = blockSize()
    local flat = targetFlatDelta(mob, target)
    local distance = flat:Length2D()
    local attackRange = mob.AttackRange or mob.MeleeRange or size
    local minDistance = mob.ChaseDirectMinDistance or math.max(attackRange * 0.9, size * 0.75)

    if distance <= minDistance then return false end

    flat:Normalize()

    if mob.IsMovementTargetSafe then
        local probe = math.min(distance, mob.ChaseDirectProbeDistance or size * (mob.ChaseDirectProbeCells or 4))
        local probeTarget = mob:GetPos() + flat * probe
        probeTarget.z = mob:GetPos().z

        if not mob:IsMovementTargetSafe(probeTarget, probe) then return false end
    end

    return true
end

function BMB.Behaviors.Chase.GetSteerTarget(mob, target)
    if not IsValid(mob) or not IsValid(target) then return nil, nil end

    local targetPos = target:GetPos()
    return Vector(targetPos.x, targetPos.y, mob:GetPos().z), targetPos
end

function BMB.Behaviors.Chase.IsSteerTargetSafe(mob, steerTarget, probeDistance)
    if not IsValid(mob) or not steerTarget then return false end
    if not mob.IsMovementTargetSafe then return true end

    local delta = steerTarget - mob:GetPos()
    delta.z = 0

    local distance = delta:Length2D()
    if distance <= 1 then return true end

    local probe = math.min(distance, probeDistance or distance)
    return mob:IsMovementTargetSafe(steerTarget, probe)
end

function BMB.Behaviors.Chase.ApplySafePressure(mob, target, speed, mode, probeDistance, progressWatch)
    local steerTarget, targetPos = BMB.Behaviors.Chase.GetSteerTarget(mob, target)
    if not steerTarget then return false, "invalid" end

    BMB.Behaviors.MeleeAttack.RememberTargetDirection(mob, target)

    if not BMB.Behaviors.Chase.IsSteerTargetSafe(mob, steerTarget, probeDistance) then
        if mob.SetBMBState then mob:SetBMBState("chase") end
        if mob.SetBMBMoveMode then mob:SetBMBMoveMode((mode or "chase") .. "_cliff") end
        if mob.MaintainBMBMoveSpeed then mob:MaintainBMBMoveSpeed(speed, speed) end
        if mob.UpdateMoveActivity then mob:UpdateMoveActivity(speed, speed) end
        if mob.UpdateBMBApproachDebug then mob:UpdateBMBApproachDebug(steerTarget, 0) end
        if mob.FaceTarget then mob:FaceTarget(targetPos) end
        if mob.loco and mob.GetVelocity then
            local velocity = mob:GetVelocity()
            mob.loco:SetVelocity(Vector(velocity.x * 0.1, velocity.y * 0.1, velocity.z))
        end

        return false, "cliff"
    end

    if mob.SetBMBState then mob:SetBMBState("chase") end
    if mob.SetBMBMoveMode then mob:SetBMBMoveMode(mode or "chase_direct") end
    if mob.MaintainBMBMoveSpeed then mob:MaintainBMBMoveSpeed(speed, speed) end
    if mob.UpdateMoveActivity then mob:UpdateMoveActivity(speed, speed) end
    if mob.UpdateBMBApproachDebug then mob:UpdateBMBApproachDebug(steerTarget, 0) end
    if mob.FaceTarget then mob:FaceTarget(targetPos) end
    if mob.SteerTowards then mob:SteerTowards(steerTarget, progressWatch) end
    if mob.BodyMoveXY then mob:BodyMoveXY() end
    if mob.MaybePlayStep then mob:MaybePlayStep() end

    return true
end

function BMB.Behaviors.Chase.RunDirect(mob, target, speed)
    local duration = mob.ChaseDirectDuration or 0.28
    local timeout = CurTime() + duration
    local progressWatch = mob.StartBMBMoveProgressWatch and mob:StartBMBMoveProgressWatch() or nil
    local probe = mob.ChaseDirectProbeDistance or blockSize() * (mob.ChaseDirectProbeCells or 4)

    if mob.ClearBMBMovementInterrupt then mob:ClearBMBMovementInterrupt() end

    while CurTime() < timeout do
        if mob.BMBMoveInterrupt then return false end
        if not BMB.Behaviors.SeekTarget.IsValid(mob, target, mob.TargetLoseRange or mob.TargetRange) then return false end
        if BMB.Behaviors.MeleeAttack.IsInRange(mob, target) then return true end
        if not BMB.Behaviors.Chase.CanDirect(mob, target) then
            local steerTarget = BMB.Behaviors.Chase.GetSteerTarget(mob, target)
            if steerTarget and not BMB.Behaviors.Chase.IsSteerTargetSafe(mob, steerTarget, probe) then
                BMB.Behaviors.Chase.ApplySafePressure(mob, target, speed, "chase_direct", probe, progressWatch)
            end

            return false
        end

        local safe = BMB.Behaviors.Chase.ApplySafePressure(mob, target, speed, "chase_direct", probe, progressWatch)
        if not safe then return false end

        if mob.CheckBMBMoveProgress and not mob:CheckBMBMoveProgress(progressWatch) then
            if mob.FailBMBMove then mob:FailBMBMove("chase_direct_blocked") end
            return false
        end

        coroutine.yield()
    end

    return true
end

function BMB.Behaviors.Chase.StalkHighTarget(mob, target)
    if not BMB.Behaviors.Chase.ShouldStalkHighTarget(mob, target) then return false end

    local targetPos = target:GetPos()

    if mob.SetBMBState then mob:SetBMBState("chase") end
    if mob.SetBMBMoveMode then mob:SetBMBMoveMode("chase_stalk") end
    if mob.UpdateBMBApproachDebug then mob:UpdateBMBApproachDebug(targetPos, 0) end
    if mob.FaceTarget then mob:FaceTarget(targetPos) end

    coroutine.wait(mob.ChaseHighTargetStalkDelay or 0.12)
    return true
end

function BMB.Behaviors.MeleeAttack.IsInRange(mob, target, rangeOverride, verticalRangeOverride)
    if not BMB.Behaviors.SeekTarget.IsValid(mob, target, mob.TargetLoseRange or mob.TargetRange) then
        return false
    end

    local range = rangeOverride or mob.AttackRange or mob.MeleeRange or blockSize()
    local verticalRange = verticalRangeOverride or mob.AttackVerticalRange or mob.MeleeVerticalRange or range * 0.65
    local mobPos = mob:GetPos()
    local targetPos = target:GetPos()
    local flatDistanceSqr = targetFlatDistanceSqr(mobPos, targetPos)
    local verticalDistance = targetVerticalDistance(mobPos, targetPos)

    if verticalDistance <= verticalRange then
        return flatDistanceSqr <= range * range
    end

    local overlapVerticalRange = mob.AttackVerticalOverlapRange or mob.MeleeVerticalOverlapRange or 0
    if overlapVerticalRange <= 0 or verticalDistance > overlapVerticalRange then return false end
    if targetPos.z <= mobPos.z then return false end

    local overlapFlatRange = mob.AttackVerticalOverlapFlatRange
        or mob.MeleeVerticalOverlapFlatRange
        or math.min(range, blockSize() * 0.65)

    return flatDistanceSqr <= overlapFlatRange * overlapFlatRange
end

function BMB.Behaviors.MeleeAttack.ApplyTargetKnockback(mob, target, direction)
    if not IsValid(target) then return end

    local horizontal = mob.AttackKnockback or mob.MeleeKnockback or 0
    local vertical = mob.AttackVerticalKnockback or mob.MeleeVerticalKnockback or 0
    if horizontal <= 0 and vertical <= 0 then return end

    direction = direction or BMB.Behaviors.MeleeAttack.GetTargetKnockbackDirection(mob, target)
    if not direction then
        logMeleeDebug(mob, target, "knockback", "direction_nil")
        return
    end

    direction = Vector(direction.x, direction.y, 0)
    if direction:LengthSqr() <= MIN_VALID_DIRECTION_SQR then
        logMeleeDebug(mob, target, "knockback", "direction_invalid")
        return
    end
    direction:Normalize()

    local groundedPlayer = target:IsPlayer() and target:IsOnGround()
    local launchVertical = vertical
    if groundedPlayer and vertical > 0 then
        launchVertical = math.max(vertical, mob.AttackGroundedVerticalKnockback or mob.MeleeGroundedVerticalKnockback or vertical)

        if target.SetGroundEntity then
            target:SetGroundEntity(NULL)
        end
    end

    local velocityBefore = target:GetVelocity()

    if shouldLogMeleeKnockback() then
        print(string.format(
            "[BMB] melee knockback apply mob=%s target=%s dir=%s horiz=%.1f vert=%.1f grounded=%s velBefore=%s",
            tostring(mob), tostring(target), formatVector2D(direction), horizontal, launchVertical,
            tostring(groundedPlayer), formatVector2D(velocityBefore)
        ))
    end

    local desiredVelocity = direction * horizontal + Vector(0, 0, launchVertical)
    if target:IsPlayer() then
        -- Player:SetVelocity adds to current velocity. Cancel residual shove/fall velocity first
        -- so the launch z is deterministic and stays above Source's grounded-player threshold.
        if target.SetGroundEntity then
            target:SetGroundEntity(NULL)
        end

        target:SetVelocity(-velocityBefore)
        target:SetVelocity(desiredVelocity)
    else
        target:SetVelocity(desiredVelocity)
    end
end

function BMB.Behaviors.MeleeAttack.ResolveHit(mob, target, range, hitSlop)
    if not IsValid(mob) or mob.BMBDead then return false end
    if not IsValid(target) then
        logMeleeDebug(mob, target, "resolve", "invalid_target", range, nil)
        return false
    end

    local verticalRange = mob.AttackVerticalRange or mob.MeleeVerticalRange or (range or blockSize()) * 0.65
    if not BMB.Behaviors.MeleeAttack.IsInRange(mob, target, range + hitSlop) then
        logMeleeDebug(mob, target, "resolve", "range_fail", range + hitSlop, verticalRange)
        return false
    end

    local direction = BMB.Behaviors.MeleeAttack.GetTargetKnockbackDirection(mob, target)

    if mob.FaceTarget then mob:FaceTarget(target:GetPos()) end

    local damageInfo = DamageInfo()
    damageInfo:SetAttacker(mob)
    damageInfo:SetInflictor(mob)
    damageInfo:SetDamage(mob.AttackDamage or mob.MeleeDamage or 2)
    damageInfo:SetDamageType(mob.AttackDamageType or mob.MeleeDamageType or DMG_SLASH)

    if direction then
        damageInfo:SetDamageForce(direction * (mob.AttackDamageForce or mob.MeleeDamageForce or 180))
    end

    target:TakeDamageInfo(damageInfo)
    logMeleeDebug(mob, target, "resolve", "hit", range + hitSlop, verticalRange)
    BMB.Behaviors.MeleeAttack.ApplyTargetKnockback(mob, target, direction)

    if mob.OnBMBMeleeHit then
        mob:OnBMBMeleeHit(target, damageInfo)
    end

    return true
end

function BMB.Behaviors.MeleeAttack.Try(mob, target)
    local now = CurTime()
    local cooldown = mob.AttackCooldown or mob.MeleeCooldown or 1.0
    local hitDelay = mob.AttackHitDelay or mob.MeleeHitDelay or 0.25
    local range = mob.AttackRange or mob.MeleeRange or blockSize()
    local hitSlop = mob.AttackHitSlop or mob.MeleeHitSlop or blockSize() * 0.35
    local verticalRange = mob.AttackVerticalRange or mob.MeleeVerticalRange or range * 0.65
    local attackMoveSpeed = mob.AttackMoveSpeed or mob.MeleeMoveSpeed or mob.RunSpeed or mob.WalkSpeed

    if not BMB.Behaviors.MeleeAttack.IsInRange(mob, target) then
        logMeleeDebug(mob, target, "try", "range_blocked", range, verticalRange, "try_range")
        return false
    end

    if now < (mob.NextMeleeAttackTime or 0) then
        logMeleeDebug(mob, target, "try", "cooldown", range, verticalRange, "try_cooldown")
        return false
    end

    mob.NextMeleeAttackTime = now + cooldown
    mob.BMBMeleeAttackSerial = (mob.BMBMeleeAttackSerial or 0) + 1
    BMB.Behaviors.MeleeAttack.RememberTargetDirection(mob, target)
    logMeleeDebug(mob, target, "try", "ok", range, verticalRange)

    if mob.SetBMBState then mob:SetBMBState("attack") end
    if mob.SetBMBMoveMode then mob:SetBMBMoveMode("attack") end
    if mob.MaintainBMBMoveSpeed then mob:MaintainBMBMoveSpeed(attackMoveSpeed, mob.RunSpeed or attackMoveSpeed) end
    if mob.FaceTarget then mob:FaceTarget(target:GetPos()) end

    if mob.PlayBMBMeleeGesture then
        mob:PlayBMBMeleeGesture(target)
    elseif mob.RestartGesture then
        mob:RestartGesture(ACT_MELEE_ATTACK1)
    end

    local serial = mob.BMBMeleeAttackSerial

    local function resolveHit()
        if not IsValid(mob) or mob.BMBDead then return end
        if mob.BMBMeleeAttackSerial ~= serial then
            logMeleeDebug(mob, target, "resolve", "serial_stale", range + hitSlop, verticalRange)
            return
        end
        BMB.Behaviors.MeleeAttack.ResolveHit(mob, target, range, hitSlop)
    end

    if hitDelay <= 0 then
        resolveHit()
    else
        timer.Simple(hitDelay, resolveHit)
    end

    return true
end

function BMB.Behaviors.Chase.Run(mob, target)
    if not BMB.Behaviors.SeekTarget.IsValid(mob, target, mob.TargetLoseRange or mob.TargetRange) then
        return false
    end

    local attackRange = mob.AttackRange or mob.MeleeRange or blockSize()
    local speed = mob.RunSpeed or mob.WalkSpeed

    if BMB.Behaviors.MeleeAttack.IsInRange(mob, target) then
        local attackMoveSpeed = mob.AttackMoveSpeed or mob.MeleeMoveSpeed or speed
        local attackProbe = mob.AttackSafetyProbeDistance or attackRange

        BMB.Behaviors.Chase.ApplySafePressure(mob, target, attackMoveSpeed, "attack_ready", attackProbe)

        coroutine.wait(0.05)
        return true
    end

    if BMB.Behaviors.Chase.CanDirect(mob, target) then
        local directResult = BMB.Behaviors.Chase.RunDirect(mob, target, speed)
        if directResult then return true end
        if mob.BMBMoveInterrupt then return false end
    end

    local segmentTime = mob.ChaseSegmentTimeout or mob.ChaseRepathInterval or 0.75
    local minPathSpeed

    if mob.GetBMBRunActivityThreshold then
        minPathSpeed = mob:GetBMBRunActivityThreshold() + (mob.ChaseMinPathSpeedPadding or 1)
        minPathSpeed = math.min(speed, minPathSpeed)
    end

    if mob.SetBMBState then mob:SetBMBState("chase") end

    local pathResult = mob:MoveToWorldPosition(target:GetPos(), speed, {
        skipSourcePath = true,
        allowPartial = true,
        acceptPartial = true,
        timeout = segmentTime,
        goalTolerance = math.max(attackRange * 0.65, blockSize() * 0.5),
        moveIntentSpeed = speed,
        minPathSpeed = minPathSpeed
    })

    if pathResult then return true end
    if BMB.Behaviors.Chase.StalkHighTarget(mob, target) then return true end

    return false
end
