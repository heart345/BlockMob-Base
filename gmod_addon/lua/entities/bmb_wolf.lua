AddCSLuaFile()

ENT.Base = "bmb_base_mob"
ENT.Type = "nextbot"
ENT.PrintName = "BMB Wolf"
ENT.Author = "Heart#"
ENT.Category = "BlockMob Base"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Model = "models/mcgm/wolf/wolf.mdl"
ENT.StartHealth = 40
ENT.DeathRemoveDelay = 1.5
ENT.DeathTipDuration = 0.5
ENT.DeathTipDegrees = 90

ENT.WalkSpeed = 85
ENT.RunSpeed = 135
ENT.Acceleration = 360
ENT.Deceleration = 460
ENT.CollisionMins = Vector(-11, -11, 0)
ENT.CollisionMaxs = Vector(11, 11, 32)
ENT.MobSeparationRadiusScale = 1.45
ENT.MobSeparationApproachDistance = 24
ENT.MobSeparationMaxSpeed = 125

ENT.WanderDistanceMinCells = 4
ENT.WanderDistanceMaxCells = 10
ENT.WanderPauseMin = 3.0
ENT.WanderPauseMax = 7.0
ENT.WanderPathAttempts = 2
ENT.WanderFailurePauseMin = 0.5
ENT.WanderFailurePauseMax = 1.3
ENT.InitialIdleMin = 1.5
ENT.InitialIdleMax = 4.0
ENT.TargetRange = 820
ENT.TargetLoseRange = 1050
ENT.TargetScanInterval = 0.35
ENT.ChaseRepathInterval = 0.45
ENT.ChaseSegmentTimeout = 1.2
ENT.ChaseFailureRepathDelay = 0.06
ENT.ChasePreferDirect = true
ENT.ChaseDirectDuration = 0.24
ENT.ChaseDirectMaxDistanceCells = 5
ENT.ChaseDirectProbeCells = 4
ENT.AttackRange = 52
ENT.AttackVerticalRange = 26
ENT.AttackVerticalOverlapRange = 62
ENT.AttackVerticalOverlapFlatRange = 22
ENT.AttackDamage = 10
ENT.AttackCooldown = 0.85
ENT.AttackHitDelay = 0
ENT.AttackMoveSpeed = 120
ENT.AttackHitSlop = 14
ENT.AttackKnockback = 90
ENT.AttackVerticalKnockback = 75
ENT.AttackGroundedVerticalKnockback = 110
ENT.LeapEnabled = true
ENT.LeapIgnoreCliff = true
ENT.LeapMinDistanceCells = 1.2
ENT.LeapMaxDistanceCells = 3.6
ENT.LeapMaxUpCells = 0.25
ENT.LeapMaxDownCells = 1.4
ENT.LeapTargetStopDistance = 18
ENT.LeapHorizontalSpeed = 300
ENT.LeapVerticalSpeed = 225
ENT.LeapChance = 0.65
ENT.LeapAttemptInterval = 0.3
ENT.LeapCooldownMin = 1.6
ENT.LeapCooldownMax = 3.0
ENT.LeapCommitTime = 0.28
ENT.PackEnabled = true
ENT.PackMinMembers = 2
ENT.PackMemberRadiusCells = 6.0
ENT.PackEngageRangeCells = 7.0
ENT.PackFlankRadiusCells = 1.65
ENT.PackMinRangeScale = 1.45
ENT.PackSegmentTimeout = 0.5
ENT.PackSlotSearchRadiusCells = 2
ENT.PackRetaliationAlertEnabled = true
ENT.PackRetaliationAlertRadiusCells = 8.0

ENT.AmbientSoundIntervalTicks = 80
ENT.AmbientSoundChanceDenominator = 1000
ENT.AmbientSoundTickRate = 20
ENT.AmbientSoundMaxCatchupTicks = 4
ENT.StepSoundDistance = 31
ENT.StepSoundMinSpeed = 8
ENT.StepSoundLevel = 62
ENT.StepSoundVolumeMin = 0.55
ENT.StepSoundVolumeMax = 0.92
ENT.StepSoundPitchMin = 88
ENT.StepSoundPitchMax = 112

ENT.LimbSwingMinAmount = 0.2
ENT.LimbSwingPhaseScale = 0.12
ENT.WolfLegSwingMax = 28
ENT.WolfTailSwingXDegrees = 40
ENT.LookAtEyeHeight = 27
ENT.LookAtPitchLimit = 22
ENT.LookAroundPitchLimit = 12
ENT.WolfAngrySkinOnChase = true
ENT.WolfRetaliatePlayers = true

ENT.Sounds = {
    Step = {
        "bmb/mob/wolf/step1.ogg",
        "bmb/mob/wolf/step2.ogg",
        "bmb/mob/wolf/step3.ogg",
        "bmb/mob/wolf/step4.ogg",
        "bmb/mob/wolf/step5.ogg"
    },
    Hit = {
        "bmb/damage/hit1.ogg",
        "bmb/damage/hit2.ogg",
        "bmb/damage/hit3.ogg"
    }
}

local wolfSkinVariants = { "woods", "ashen", "black", "chestnut", "rusty", "snowy", "spotted", "striped", "classic" }
local wolfSkinVariantIds = {}
for index, variant in ipairs(wolfSkinVariants) do
    wolfSkinVariantIds[variant] = index - 1
end

ENT.WolfSkinVariants = wolfSkinVariants
ENT.WolfDefaultSkinVariant = "woods"

local function randomSound(list)
    if not list or #list == 0 then return nil end
    return list[math.random(1, #list)]
end

local wolfSoundVariants = { "angry", "big", "classic", "cute", "grumpy", "puglin", "sad" }
local wolfSoundVariantWeights = {
    angry = 10 / 3,
    big = 10 / 3,
    classic = 80,
    cute = 10 / 3,
    grumpy = 10 / 3,
    puglin = 10 / 3,
    sad = 10 / 3
}
local wolfSoundSets = {}

local function makeWolfVariantSounds(variant)
    local prefix = "bmb/mob/wolf/" .. variant .. "/"

    return {
        Bark = {
            prefix .. "bark1.ogg",
            prefix .. "bark2.ogg",
            prefix .. "bark3.ogg"
        },
        Growl = {
            prefix .. "growl1.ogg",
            prefix .. "growl2.ogg",
            prefix .. "growl3.ogg"
        },
        Hurt = {
            prefix .. "hurt1.ogg",
            prefix .. "hurt2.ogg",
            prefix .. "hurt3.ogg"
        },
        Death = {
            prefix .. "death.ogg"
        }
    }
end

for _, variant in ipairs(wolfSoundVariants) do
    wolfSoundSets[variant] = makeWolfVariantSounds(variant)
end

function ENT:ChooseBMBWolfSoundVariant()
    local total = 0
    for _, variant in ipairs(wolfSoundVariants) do
        total = total + (wolfSoundVariantWeights[variant] or 1)
    end

    local roll = math.Rand(0, total)
    local accumulated = 0
    for _, variant in ipairs(wolfSoundVariants) do
        accumulated = accumulated + (wolfSoundVariantWeights[variant] or 1)
        if roll <= accumulated then return variant end
    end

    return "classic"
end

function ENT:GetBMBWolfSoundVariant()
    local variant = self.BMBWolfSoundVariant
    if not variant or not wolfSoundSets[variant] then
        variant = self:GetNWString("BMBWolfSoundVariant", "classic")
    end

    if not wolfSoundSets[variant] then variant = "classic" end
    return variant
end

function ENT:GetBMBWolfSounds()
    return wolfSoundSets[self:GetBMBWolfSoundVariant()] or wolfSoundSets.classic
end

if SERVER then
    ENT.WolfRetaliatePlayersConVar = CreateConVar(
        "bmb_wolf_retaliate_players",
        "1",
        FCVAR_ARCHIVE,
        "Allow wild BMB wolves to target players who damage them."
    )
    ENT.WolfVariantLockConVar = CreateConVar(
        "bmb_wolf_variant_lock",
        "",
        FCVAR_ARCHIVE,
        "Lock BMB wolf skin variant by name or zero-based index; empty uses weighted random."
    )
    ENT.WolfVariantWeightConVars = {}
    for _, variant in ipairs(wolfSkinVariants) do
        ENT.WolfVariantWeightConVars[variant] = CreateConVar(
            "bmb_wolf_variant_weight_" .. variant,
            "1",
            FCVAR_ARCHIVE,
            "Spawn weight for the BMB wolf " .. variant .. " skin variant."
        )
    end
end

local entitySetSkin = FindMetaTable("Entity").SetSkin

local function wolfVariantNameFromValue(value)
    local text = string.lower(tostring(value or "")):gsub("%s+", "_")
    if text == "" or text == "random" or text == "none" then return nil end
    if text == "pale" then text = "classic" end
    if wolfSkinVariantIds[text] ~= nil then return text end

    local numeric = tonumber(text)
    if numeric then
        local index = math.Clamp(math.floor(numeric), 0, #wolfSkinVariants - 1)
        return wolfSkinVariants[index + 1]
    end

    return nil
end

function ENT:GetBMBWolfSkinVariantName(index)
    index = math.Clamp(math.floor(tonumber(index) or 0), 0, #wolfSkinVariants - 1)
    return wolfSkinVariants[index + 1] or self.WolfDefaultSkinVariant or "woods"
end

function ENT:GetBMBWolfSkinVariantIndex(name)
    local normalized = wolfVariantNameFromValue(name)
    if normalized and wolfSkinVariantIds[normalized] ~= nil then
        return wolfSkinVariantIds[normalized]
    end

    return wolfSkinVariantIds[self.WolfDefaultSkinVariant or "woods"] or 0
end

function ENT:GetBMBWolfLockedSkinVariant()
    local convar = self.WolfVariantLockConVar
    if not convar then return nil end
    return wolfVariantNameFromValue(convar:GetString())
end

function ENT:ChooseBMBWolfSkinVariant()
    local locked = self:GetBMBWolfLockedSkinVariant()
    if locked then return self:GetBMBWolfSkinVariantIndex(locked) end

    local total = 0
    local weights = self.WolfVariantWeightConVars or {}
    for _, variant in ipairs(wolfSkinVariants) do
        local convar = weights[variant]
        total = total + math.max(0, convar and convar:GetFloat() or 1)
    end

    if total <= 0 then
        return self:GetBMBWolfSkinVariantIndex(self.WolfDefaultSkinVariant)
    end

    local roll = math.Rand(0, total)
    local accumulated = 0
    for index, variant in ipairs(wolfSkinVariants) do
        local convar = weights[variant]
        accumulated = accumulated + math.max(0, convar and convar:GetFloat() or 1)
        if roll <= accumulated then return index - 1 end
    end

    return self:GetBMBWolfSkinVariantIndex(self.WolfDefaultSkinVariant)
end

function ENT:GetBMBWolfSkinVariant()
    local variant = self.variant
    if variant == nil then variant = self.BMBWolfVariant end
    if variant == nil then variant = self:GetNWInt("BMBWolfVariant", 0) end
    return math.Clamp(math.floor(tonumber(variant) or 0), 0, #wolfSkinVariants - 1)
end

function ENT:SetBMBWolfSkinVariant(index)
    if CLIENT then return end

    local variant = math.Clamp(math.floor(tonumber(index) or 0), 0, #wolfSkinVariants - 1)
    self.variant = variant
    self.BMBWolfVariant = variant
    self:SetNWInt("BMBWolfVariant", variant)
    self:SetNWString("BMBWolfVariantName", self:GetBMBWolfSkinVariantName(variant))
    self:UpdateBMBWolfSkin()
end

function ENT:GetBMBWolfDesiredSkin()
    local angry = self:GetNWBool("BMBWolfAngry", false) and 1 or 0
    return self:GetBMBWolfSkinVariant() * 2 + angry
end

function ENT:SetBMBWolfRawSkin(skin)
    if not entitySetSkin then return end

    self.BMBWolfApplyingSkin = true
    entitySetSkin(self, skin)
    self.BMBWolfApplyingSkin = false
    self.BMBWolfLastSkin = skin
end

function ENT:UpdateBMBWolfSkin()
    if CLIENT then return end

    local skin = self:GetBMBWolfDesiredSkin()
    self:SetBMBWolfRawSkin(skin)
end

function ENT:ApplyBMBWolfSkinToolSkin(skin)
    if CLIENT then return end

    local maxSkin = #wolfSkinVariants * 2 - 1
    local skinIndex = math.Clamp(math.floor(tonumber(skin) or 0), 0, maxSkin)
    self:SetBMBWolfSkinVariant(math.floor(skinIndex / 2))
end

function ENT:MaintainBMBWolfSkin()
    if CLIENT then return end

    local desired = self:GetBMBWolfDesiredSkin()
    local actual = self:GetSkin() or 0
    if actual ~= desired and actual ~= self.BMBWolfLastSkin then
        self:ApplyBMBWolfSkinToolSkin(actual)
        return
    end

    if actual ~= desired then
        self:SetBMBWolfRawSkin(desired)
    else
        self.BMBWolfLastSkin = actual
    end
end

function ENT:SetBMBWolfAngry(angry)
    if CLIENT then return end

    self:SetNWBool("BMBWolfAngry", angry == true and self.WolfAngrySkinOnChase ~= false)
    self:UpdateBMBWolfSkin()
end

function ENT:SetSkin(skin)
    if entitySetSkin then entitySetSkin(self, skin) end
    if SERVER and not self.BMBWolfApplyingSkin then
        self:ApplyBMBWolfSkinToolSkin(skin)
    end
end

if CLIENT then
    local zeroAngle = Angle(0, 0, 0)
    local zeroVector = Vector(0, 0, 0)
    local wolfBoneNames = { "root", "body", "upperBody", "head", "leg0", "leg1", "leg2", "leg3", "tail" }
    local wolfBasePose = {
        body = { angle = Angle(0, 0, 0), pos = Vector(0, 0, 0) },
        upperBody = { angle = Angle(0, 0, 0), pos = Vector(0, 0, -10) },
        tail = { angle = Angle(0, 0, -45), pos = Vector(0, 0, 0) }
    }
    local wolfPoseConVars = {}

    local function createWolfPoseOffsetConVars(prefix)
        return {
            angle = {
                x = CreateClientConVar(prefix .. "_offset_rot_x", "0", true, false),
                y = CreateClientConVar(prefix .. "_offset_rot_y", "0", true, false),
                z = CreateClientConVar(prefix .. "_offset_rot_z", "0", true, false)
            },
            pos = {
                x = CreateClientConVar(prefix .. "_offset_pos_x", "0", true, false),
                y = CreateClientConVar(prefix .. "_offset_pos_y", "0", true, false),
                z = CreateClientConVar(prefix .. "_offset_pos_z", "0", true, false)
            }
        }
    end

    wolfPoseConVars.body = createWolfPoseOffsetConVars("bmb_wolf_body")
    wolfPoseConVars.upperBody = createWolfPoseOffsetConVars("bmb_wolf_upper_body")
    wolfPoseConVars.tail = createWolfPoseOffsetConVars("bmb_wolf_tail")

    local function setBoneAngle(ent, boneId, angle)
        if not boneId then return end
        ent:ManipulateBoneAngles(boneId, angle or zeroAngle)
    end

    local function setBonePosition(ent, boneId, pos)
        if not boneId then return end
        ent:ManipulateBonePosition(boneId, pos or zeroVector)
    end

    local function angleFromConVars(convars)
        return Angle(convars.x:GetFloat(), convars.y:GetFloat(), convars.z:GetFloat())
    end

    local function vectorFromConVars(convars)
        return Vector(convars.x:GetFloat(), convars.y:GetFloat(), convars.z:GetFloat())
    end

    local function addAngles(base, offset)
        return Angle(
            (base and base.p or 0) + (offset and offset.p or 0),
            (base and base.y or 0) + (offset and offset.y or 0),
            (base and base.r or 0) + (offset and offset.r or 0)
        )
    end

    local function addVectors(base, offset)
        return Vector(
            (base and base.x or 0) + (offset and offset.x or 0),
            (base and base.y or 0) + (offset and offset.y or 0),
            (base and base.z or 0) + (offset and offset.z or 0)
        )
    end

    local function getWolfPose(poseName)
        local base = wolfBasePose[poseName] or {}
        local offsets = wolfPoseConVars[poseName]

        return addAngles(base.angle or zeroAngle, offsets and angleFromConVars(offsets.angle) or zeroAngle),
            addVectors(base.pos or zeroVector, offsets and vectorFromConVars(offsets.pos) or zeroVector)
    end

    local function applyWolfPose(ent, boneId, poseName)
        if not boneId then return end

        local angle, pos = getWolfPose(poseName)
        setBoneAngle(ent, boneId, angle)
        setBonePosition(ent, boneId, pos)
    end

    local function resetWolfBones(ent, bones)
        for _, boneName in ipairs(wolfBoneNames) do
            setBoneAngle(ent, bones[boneName], zeroAngle)
            setBonePosition(ent, bones[boneName], zeroVector)
        end
    end

    function ENT:CacheBMBWolfBones()
        local model = self:GetModel()
        if self.BMBWolfBoneCache and self.BMBWolfBoneCache.model == model then
            return self.BMBWolfBoneCache
        end

        self.BMBWolfBoneCache = {
            model = model,
            root = self:LookupBone("root"),
            body = self:LookupBone("body"),
            upperBody = self:LookupBone("upperBody") or self:LookupBone("upperbody"),
            head = self:LookupBone("head"),
            leg0 = self:LookupBone("leg0"),
            leg1 = self:LookupBone("leg1"),
            leg2 = self:LookupBone("leg2"),
            leg3 = self:LookupBone("leg3"),
            tail = self:LookupBone("tail")
        }

        return self.BMBWolfBoneCache
    end

    function ENT:UpdateBMBVisualBones()
        local bones = self:CacheBMBWolfBones()
        if not bones then return end

        local state = self:GetNWString("BMBState", "idle")
        if state == "dead" or self:GetNWBool("BMBDead", false) then
            resetWolfBones(self, bones)
            applyWolfPose(self, bones.body, "body")
            applyWolfPose(self, bones.upperBody, "upperBody")
            applyWolfPose(self, bones.tail, "tail")

            if bones.root then
                local startedAt = self:GetNWFloat("BMBStateStartedAt", CurTime())
                local duration = self.DeathTipDuration or 0.5
                local t = duration > 0 and math.Clamp((CurTime() - startedAt) / duration, 0, 1) or 1
                local tip = t * (self.DeathTipDegrees or 90)
                local tipSign = (self:EntIndex() % 2 == 0) and 1 or -1
                setBoneAngle(self, bones.root, Angle(0, tip * tipSign, 0))
            end

            return
        end

        setBoneAngle(self, bones.root, zeroAngle)
        setBonePosition(self, bones.root, zeroVector)
        applyWolfPose(self, bones.body, "body")
        applyWolfPose(self, bones.upperBody, "upperBody")

        if not self:UpdateBMBLookAtHeadPose(bones.head) then
            setBoneAngle(self, bones.head, zeroAngle)
            setBonePosition(self, bones.head, zeroVector)
        end

        local speed = self:GetVelocity():Length2D()
        local phase, swingAmount = self:UpdateBMBLimbSwing(speed)
        local legSwing = math.sin(phase) * (self.WolfLegSwingMax or 28) * swingAmount
        local tailAngle, tailPos = getWolfPose("tail")
        tailAngle.p = tailAngle.p + math.sin(phase) * (self.WolfTailSwingXDegrees or 40) * swingAmount
        setBoneAngle(self, bones.tail, tailAngle)
        setBonePosition(self, bones.tail, tailPos)

        -- Same diagonal pair convention as MC wolf leg_default: leg0/leg3 together, leg1/leg2 opposite.
        setBoneAngle(self, bones.leg0, Angle(0, 0, legSwing))
        setBoneAngle(self, bones.leg3, Angle(0, 0, legSwing))
        setBoneAngle(self, bones.leg1, Angle(0, 0, -legSwing))
        setBoneAngle(self, bones.leg2, Angle(0, 0, -legSwing))

        self:UpdateBMBWolfStepSound(speed)
    end

    function ENT:UpdateBMBWolfStepSound(speed)
        speed = speed or self:GetVelocity():Length2D()

        if speed <= (self.StepSoundMinSpeed or 8) then
            self.BMBWolfStepDistance = 0
            return
        end

        local stepDistance = self.StepSoundDistance or 31
        self.BMBWolfStepDistance = (self.BMBWolfStepDistance or 0) + speed * FrameTime()
        if self.BMBWolfStepDistance < stepDistance then return end

        self.BMBWolfStepDistance = self.BMBWolfStepDistance - stepDistance

        local soundName = randomSound(self.Sounds and self.Sounds.Step)
        if not soundName then return end

        local fullSpeed = math.max((self.StepSoundMinSpeed or 8) + 1, self.RunSpeed or 135)
        local speedFrac = math.Clamp((speed - (self.StepSoundMinSpeed or 8)) / (fullSpeed - (self.StepSoundMinSpeed or 8)), 0, 1)
        local volume = Lerp(speedFrac, self.StepSoundVolumeMin or 0.55, self.StepSoundVolumeMax or 0.92)
        self:EmitSound(soundName, self.StepSoundLevel or 62, math.random(self.StepSoundPitchMin or 88, self.StepSoundPitchMax or 112), volume)
    end

end

function ENT:Initialize()
    if CLIENT then return end

    self:BaseInitialize()
    self:SetBMBState("idle")
    self.TargetEntity = nil
    self.NextTargetScanTime = 0
    self.NextMeleeAttackTime = 0
    self:SetBMBWolfSkinVariant(self:ChooseBMBWolfSkinVariant())
    self.BMBWolfSoundVariant = self:ChooseBMBWolfSoundVariant()
    self:SetNWString("BMBWolfSoundVariant", self.BMBWolfSoundVariant)
    self:ResetBMBAmbientSoundTime()
    self.BMBNextAmbientSoundTickAt = CurTime() + math.Rand(0, 1 / (self.AmbientSoundTickRate or 20))
    self.BMBInitialIdleUntil = CurTime() + math.Rand(self.InitialIdleMin or 1.5, self.InitialIdleMax or 4.0)
end

function ENT:MaybePlayStep()
    -- Wolf footsteps are client-side and distance-driven from the procedural leg phase.
end

function ENT:OnBMBMeleeHit(target, _)
    if not IsValid(target) then return end
    if not target:IsPlayer() then return end

    local soundName = randomSound(self.Sounds and self.Sounds.Hit)
    if soundName then
        target:EmitSound(soundName, 74, math.random(96, 104), 0.82)
    end
end

function ENT:ShouldBMBWolfUseGrowlSound()
    return IsValid(self.TargetEntity)
        or self:GetNWBool("BMBWolfAngry", false)
        or CurTime() < (self.BMBWolfGrowlUntil or 0)
end

function ENT:PlayBMBWolfHurtSound(volume)
    local sounds = self:GetBMBWolfSounds()
    local soundName = randomSound(sounds and sounds.Hurt)
    if not soundName then return end

    self:EmitSound(soundName, 72, math.random(95, 105), volume or 0.86)
end

function ENT:OnBMBHurtSound(damageInfo)
    self.BMBWolfGrowlUntil = CurTime() + 3.0
    if damageInfo and self:Health() - damageInfo:GetDamage() <= 0 then return end

    self:PlayBMBWolfHurtSound(0.9)
end

function ENT:PlayBMBWolfDeathSound()
    local sounds = self:GetBMBWolfSounds()
    local soundName = randomSound(sounds and sounds.Death)
    if soundName then
        self:EmitSound(soundName, 76, math.random(95, 105), 0.95)
    end
end

function ENT:OnKilled(damageInfo)
    if CLIENT then return end

    self:PlayBMBWolfDeathSound()
    self:BeginBMBDeath(damageInfo)
end

function ENT:ResetBMBAmbientSoundTime()
    self.BMBAmbientSoundTime = -(self.AmbientSoundIntervalTicks or 80)
end

function ENT:MaybePlayIdleSound()
    self:MaintainBMBWolfSkin()

    local sounds = self:GetBMBWolfSounds()
    if not sounds then return end

    local now = CurTime()
    local tickRate = self.AmbientSoundTickRate or 20
    local tickInterval = 1 / tickRate
    local nextTick = self.BMBNextAmbientSoundTickAt or now
    if now < nextTick then return end

    local ticks = math.floor((now - nextTick) / tickInterval) + 1
    ticks = math.Clamp(ticks, 1, self.AmbientSoundMaxCatchupTicks or 4)

    for _ = 1, ticks do
        local soundTime = self.BMBAmbientSoundTime
        if soundTime == nil then
            soundTime = -(self.AmbientSoundIntervalTicks or 80)
        end

        local soundList = self:ShouldBMBWolfUseGrowlSound() and sounds.Growl or sounds.Bark
        if soundList and math.random(0, (self.AmbientSoundChanceDenominator or 1000) - 1) < soundTime then
            local soundName = randomSound(soundList)
            if soundName then
                local volume = self:ShouldBMBWolfUseGrowlSound() and 0.72 or 0.68
                self:EmitSound(soundName, 72, math.random(92, 108), volume)
            end
            self:ResetBMBAmbientSoundTime()
            soundTime = self.BMBAmbientSoundTime
        end

        self.BMBAmbientSoundTime = soundTime + 1
    end

    self.BMBNextAmbientSoundTickAt = nextTick + ticks * tickInterval
    if self.BMBNextAmbientSoundTickAt < now - tickInterval then
        self.BMBNextAmbientSoundTickAt = now + tickInterval
    end
end

ENT.WolfPreyClasses = {
    bmb_sheep = true,
    bmb_skeleton = true,
    bmb_stray = true,
    bmb_parched = true
}

function ENT:IsBMBWolfPrey(target)
    if not IsValid(target) or target == self then return false end
    if target.BMBDead then return false end
    if target.Health and target:Health() <= 0 then return false end

    local class = target:GetClass()
    if not class then return false end

    return self.WolfPreyClasses and self.WolfPreyClasses[class] == true
end

function ENT:ShouldBMBWolfRetaliatePlayer(target)
    if self.WolfRetaliatePlayers == false then return false end
    if not IsValid(target) or not target:IsPlayer() then return false end

    local convar = self.WolfRetaliatePlayersConVar
    if convar and not convar:GetBool() then return false end

    return self:IsBMBCombatTarget(target)
end

function ENT:CanBMBTarget(target)
    return self:IsBMBWolfPrey(target) or self:ShouldBMBWolfRetaliatePlayer(target)
end

function ENT:FindNearestWolfPrey(currentTarget)
    local loseRange = self.TargetLoseRange or (self.TargetRange or 820) * 1.25
    if BMB.Behaviors.SeekTarget.IsValid(self, currentTarget, loseRange) then
        return currentTarget
    end

    local now = CurTime()
    if self.NextTargetScanTime and now < self.NextTargetScanTime then return nil end
    self.NextTargetScanTime = now + (self.TargetScanInterval or 0.35)

    local range = self.TargetRange or 820
    local origin = self:GetPos()
    local bestTarget
    local bestDistance = range * range

    for _, ent in ipairs(ents.FindInSphere(origin, range)) do
        if self:IsBMBWolfPrey(ent) and BMB.Behaviors.SeekTarget.IsValid(self, ent, range) then
            local distance = origin:DistToSqr(ent:GetPos())
            if distance < bestDistance then
                bestTarget = ent
                bestDistance = distance
            end
        end
    end

    return bestTarget
end

function ENT:GetBMBForcedLookTarget()
    if self:CanBMBTarget(self.TargetEntity) then
        return self.TargetEntity
    end
    return nil
end

function ENT:ShouldBreakBMBWolfInitialIdle()
    local retaliation = self.BMBRetaliationTarget
    if self:CanBMBTarget(retaliation)
        and BMB.Behaviors.SeekTarget.IsValid(self, retaliation, self.TargetLoseRange or self.TargetRange) then
        self.TargetEntity = retaliation
        return true
    end

    local prey = self:FindNearestWolfPrey(self.TargetEntity)
    if IsValid(prey) then
        self.TargetEntity = prey
        return true
    end

    return false
end

function ENT:RunBMBInitialIdle()
    if self:ShouldBreakBMBWolfInitialIdle() then
        self.BMBInitialIdleUntil = 0
        self:SetBMBWolfAngry(true)
        return false
    end

    local idleUntil = self.BMBInitialIdleUntil
    if not idleUntil or CurTime() >= idleUntil then return false end

    self:SetBMBState("idle")
    self:InterruptibleWait(math.min(0.2, math.max(0, idleUntil - CurTime())))
    return true
end

function ENT:RunBMBWolfAI()
    self.TargetEntity = self:FindNearestWolfPrey(self.TargetEntity)
    self:SetBMBWolfAngry(IsValid(self.TargetEntity))

    if not IsValid(self.TargetEntity) then
        self.TargetEntity = nil
        self:SetBMBState("wander")
        BMB.Behaviors.Wander.Run(self)
        self:SetBMBWolfAngry(IsValid(self.TargetEntity))
        return
    end

    if BMB.Behaviors.MeleeAttack.Try(self, self.TargetEntity) then
        coroutine.wait(0.05)
        return
    end

    if BMB.Behaviors.Leap.Try(self, self.TargetEntity) then
        return
    end

    if BMB.Behaviors.Pack.Run(self, self.TargetEntity) then
        return
    end

    self:SetBMBState("chase")
    if not BMB.Behaviors.Chase.Run(self, self.TargetEntity) then
        if BMB.Behaviors.SeekTarget.IsValid(self, self.TargetEntity, self.TargetLoseRange or self.TargetRange) then
            if BMB.Behaviors.Chase.StalkHighTarget(self, self.TargetEntity) then return end

            self:SetBMBState("chase")
            self:SetBMBMoveMode("chase_repath")
            if BMB.Behaviors.Chase.TryRepathPressure then
                BMB.Behaviors.Chase.TryRepathPressure(
                    self,
                    self.TargetEntity,
                    self.RunSpeed,
                    self.ChaseRepathProbeDistance or self:GetBMBBlockSize() * 1.5
                )
            end
            coroutine.wait(self.ChaseFailureRepathDelay or 0.08)
        else
            self.TargetEntity = nil
            self:SetBMBWolfAngry(false)
            self:InterruptibleWait(math.Rand(0.25, 0.55))
        end
    end
end

function ENT:RunBehaviour()
    while true do
        if self.BMBDead then
            return
        elseif self.MaintainBMBFreeze and self:MaintainBMBFreeze() then
            coroutine.wait(0.05)
        elseif self.BMBHeld then
            self:SetBMBState("held")
            coroutine.wait(0.2)
        elseif self.RunBMBKnockback and self:RunBMBKnockback() then
            self.BMBDebugMoveActive = false
        elseif self.RunBMBDebugMove and self:RunBMBDebugMove() then
            self.BMBDebugMoveActive = true
        elseif self.RunBMBStrandedRecovery and self:RunBMBStrandedRecovery() then
            self.BMBDebugMoveActive = false
        elseif self.RunBMBInitialIdle and self:RunBMBInitialIdle() then
            self.BMBDebugMoveActive = false
        else
            self.BMBDebugMoveActive = false
            self:RunBMBWolfAI()
        end

        coroutine.yield()
    end
end
