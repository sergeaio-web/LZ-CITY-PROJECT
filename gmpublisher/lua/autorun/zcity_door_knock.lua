ZCityDoorKnock = ZCityDoorKnock or {}

if SERVER then
    AddCSLuaFile("zcity_door_knock/sh_core.lua")
    AddCSLuaFile("zcity_door_knock/cl_animation.lua")
end

include("zcity_door_knock/sh_core.lua")

if SERVER then
    include("zcity_door_knock/sv_knock.lua")
else
    include("zcity_door_knock/cl_animation.lua")
end
