--@name PVP
--@author Sevii
--@server
--@includedir ./modes/

--[[
	This uses https://steamcommunity.com/sharedfiles/filedetails/?id=330382441
	altho the loaded modes and their settings can be changed to work
	with other weapon addons
]]

local start_mode = "gungame"
local modes = {
	"gungame"
}

----------------------------------------

pvp = {
	modes = {},
	players = {},
	mode = {},
}

function pvp.setMode(mode)
	pvp.active_mode = mode
	pvp.mode = pvp.modes[mode]
	pvp.mode.onStart()
end

function pvp.playerJoin(ply)
	if pvp.playerIsPlaying(ply) then return end
	
	table.insert(pvp.players, ply)
	
	pvp.mode.playerJoin(ply)
end

function pvp.playerLeave(ply)
	local plying, i = pvp.playerIsPlaying(ply)
	if not plying then return end
	
	table.remove(pvp.players, i)
	
	pvp.mode.playerLeave(ply)
end

function pvp.playerIsPlaying(ply)
	for i, p in ipairs(pvp.players) do
		if p == ply then return true, i end
	end
	
	return false
end

function pvp.endMode()
	pvp.setMode(pvp.active_mode)
end

----------------------------------------

for _, mode in ipairs(modes) do
	pvp.modes[mode] = require("./modes/" .. mode .. ".lua")
end

pvp.setMode(start_mode)

----------------------------------------

hook.add("playerSay", "", function(ply, text)
	local cmd = string.split(text, " ")
	if cmd[1] ~= ".pvp" then return end
	
	if cmd[2] == "join" then
		pvp.playerJoin(ply)
	elseif cmd[2] == "leave" then
		pvp.playerLeave(ply)
	end
end)

hook.add("playerDeath", "", function(ply, inflictor, attacker)
	if not pvp.playerIsPlaying(ply) then return end
	
	local killer = (inflictor and inflictor:getClass() == "player") and inflictor or ((attacker and attacker:getClass() == "player") and attacker or ply)
	if not pvp.playerIsPlaying(killer) then return end
	
	pvp.mode.onKill(ply, killer, killer:getActiveWeapon())
end)

hook.add("playerSpawn", "", function(ply)
	if not pvp.playerIsPlaying(ply) then return end
	
	timer.simple(0, function()
		pvp.mode.playerSpawn(ply)
	end)
end)

pvp.playerJoin(owner())
-- pvp.playerJoin(player(36))
