BMB = BMB or {}
BMB.Version = "1.0.0"

local resourceFiles = {
    "materials/icon16/bmb.png",
    "sound/bmb/mob/sheep/say1.ogg",
    "sound/bmb/mob/sheep/say2.ogg",
    "sound/bmb/mob/sheep/say3.ogg",
    "sound/bmb/mob/sheep/step1.ogg",
    "sound/bmb/mob/sheep/step2.ogg",
    "sound/bmb/mob/sheep/step3.ogg",
    "sound/bmb/mob/sheep/step4.ogg",
    "sound/bmb/mob/sheep/step5.ogg",
    "sound/bmb/mob/zombie/death.ogg",
    "sound/bmb/mob/zombie/hurt1.ogg",
    "sound/bmb/mob/zombie/hurt2.ogg",
    "sound/bmb/mob/zombie/say1.ogg",
    "sound/bmb/mob/zombie/say2.ogg",
    "sound/bmb/mob/zombie/say3.ogg",
    "sound/bmb/mob/zombie/step1.ogg",
    "sound/bmb/mob/zombie/step2.ogg",
    "sound/bmb/mob/zombie/step3.ogg",
    "sound/bmb/mob/zombie/step4.ogg",
    "sound/bmb/mob/zombie/step5.ogg",
    "sound/bmb/mob/husk/idle1.ogg",
    "sound/bmb/mob/husk/idle2.ogg",
    "sound/bmb/mob/husk/idle3.ogg",
    "sound/bmb/mob/husk/hurt1.ogg",
    "sound/bmb/mob/husk/hurt2.ogg",
    "sound/bmb/mob/husk/death1.ogg",
    "sound/bmb/mob/husk/death2.ogg",
    "sound/bmb/mob/husk/step1.ogg",
    "sound/bmb/mob/husk/step2.ogg",
    "sound/bmb/mob/husk/step3.ogg",
    "sound/bmb/mob/husk/step4.ogg",
    "sound/bmb/mob/husk/step5.ogg",
    "sound/bmb/mob/skeleton/say1.ogg",
    "sound/bmb/mob/skeleton/say2.ogg",
    "sound/bmb/mob/skeleton/say3.ogg",
    "sound/bmb/mob/skeleton/hurt1.ogg",
    "sound/bmb/mob/skeleton/hurt2.ogg",
    "sound/bmb/mob/skeleton/hurt3.ogg",
    "sound/bmb/mob/skeleton/hurt4.ogg",
    "sound/bmb/mob/skeleton/death.ogg",
    "sound/bmb/mob/skeleton/step1.ogg",
    "sound/bmb/mob/skeleton/step2.ogg",
    "sound/bmb/mob/skeleton/step3.ogg",
    "sound/bmb/mob/skeleton/step4.ogg",
    "sound/bmb/mob/skeleton/bow.ogg",
    "sound/bmb/mob/stray/idle1.ogg",
    "sound/bmb/mob/stray/idle2.ogg",
    "sound/bmb/mob/stray/idle3.ogg",
    "sound/bmb/mob/stray/idle4.ogg",
    "sound/bmb/mob/stray/hurt1.ogg",
    "sound/bmb/mob/stray/hurt2.ogg",
    "sound/bmb/mob/stray/hurt3.ogg",
    "sound/bmb/mob/stray/hurt4.ogg",
    "sound/bmb/mob/stray/death1.ogg",
    "sound/bmb/mob/stray/death2.ogg",
    "sound/bmb/mob/stray/step1.ogg",
    "sound/bmb/mob/stray/step2.ogg",
    "sound/bmb/mob/stray/step3.ogg",
    "sound/bmb/mob/stray/step4.ogg",
    "sound/bmb/mob/parched/ambient1.ogg",
    "sound/bmb/mob/parched/ambient2.ogg",
    "sound/bmb/mob/parched/ambient3.ogg",
    "sound/bmb/mob/parched/ambient4.ogg",
    "sound/bmb/mob/parched/hurt1.ogg",
    "sound/bmb/mob/parched/hurt2.ogg",
    "sound/bmb/mob/parched/hurt3.ogg",
    "sound/bmb/mob/parched/hurt4.ogg",
    "sound/bmb/mob/parched/death.ogg",
    "sound/bmb/mob/parched/step1.ogg",
    "sound/bmb/mob/parched/step2.ogg",
    "sound/bmb/mob/parched/step3.ogg",
    "sound/bmb/mob/parched/step4.ogg",
    "sound/bmb/random/bowhit1.ogg",
    "sound/bmb/random/bowhit2.ogg",
    "sound/bmb/random/bowhit3.ogg",
    "sound/bmb/random/bowhit4.ogg",
    "sound/bmb/damage/hit1.ogg",
    "sound/bmb/damage/hit2.ogg",
    "sound/bmb/damage/hit3.ogg",
    "sound/bmb/dig/grass1.ogg",
    "sound/bmb/dig/grass2.ogg",
    "sound/bmb/dig/grass3.ogg",
    "sound/bmb/dig/grass4.ogg"
}

local function addServerFile(path)
    if SERVER then include(path) end
end

if SERVER then
    AddCSLuaFile("bmb/sh_config.lua")
    AddCSLuaFile("bmb/cl_debug.lua")

    for _, resourceFile in ipairs(resourceFiles) do
        resource.AddFile(resourceFile)
    end
end

include("bmb/sh_config.lua")
if CLIENT then include("bmb/cl_debug.lua") end

addServerFile("bmb/sv_block_world_mock.lua")
addServerFile("bmb/sv_block_world_real.lua")
addServerFile("bmb/sv_pathfinder.lua")
addServerFile("bmb/sv_behaviors.lua")
addServerFile("bmb/sv_debug_tools.lua")

list.Set("NPC", "bmb_sheep", {
    Name = "BMB Sheep",
    Class = "bmb_sheep",
    Category = "BlockMob Base"
})
