BMB = BMB or {}
BMB.Version = "0.1.0"

local resourceFiles = {
    "sound/bmb/mob/sheep/say1.ogg",
    "sound/bmb/mob/sheep/say2.ogg",
    "sound/bmb/mob/sheep/say3.ogg",
    "sound/bmb/mob/sheep/step1.ogg",
    "sound/bmb/mob/sheep/step2.ogg",
    "sound/bmb/mob/sheep/step3.ogg",
    "sound/bmb/mob/sheep/step4.ogg",
    "sound/bmb/mob/sheep/step5.ogg",
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
    Name = "BMB Prototype Sheep",
    Class = "bmb_sheep",
    Category = "BlockMob Base"
})
