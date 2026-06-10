BMB = BMB or {}
BMB.Version = "0.1.0"

local function addServerFile(path)
    if SERVER then include(path) end
end

if SERVER then
    AddCSLuaFile("bmb/sh_config.lua")
    AddCSLuaFile("bmb/cl_debug.lua")
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
