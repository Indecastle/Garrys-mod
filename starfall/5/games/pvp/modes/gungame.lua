local kills_per_weapon = 2

local melee = "weapon_cs_knife"

local categories = {
	smg = {
		"weapon_cs_mac10",
		"weapon_cs_mp5",
		"weapon_cs_p90",
		"weapon_cs_tmp",
		"weapon_cs_ump"
	},
	
	rifle = {
		"weapon_cs_ak47",
		"weapon_cs_aug",
		"weapon_cs_famas",
		"weapon_cs_galil",
		"weapon_cs_m4",
		"weapon_cs_sig552"
	},
	
	shotgun = {
		"weapon_cs_m3",
		"weapon_cs_xm1014"
	},
	
	sniper = {
		"weapon_cs_awp",
		"weapon_cs_g3",
		"weapon_cs_scout",
		"weapon_cs_sig550"
	},
	
	machinegun = {
		"weapon_cs_para"
	},
	
	pistol = {
		"weapon_cs_deserteagle",
		"weapon_cs_p228",
		"weapon_cs_glock",
		"weapon_cs_fiveseven",
		"weapon_cs_usp",
		"weapon_cs_dualbertta"
	}
}

local assortment = {
	"smg",
	"smg",
	"smg",
	"rifle",
	"rifle",
	"rifle",
	"rifle",
	"shotgun",
	"sniper",
	"sniper",
	"machinegun",
	"pistol",
	"pistol",
	"pistol",
	"pistol",
}

----------------------------------------

local gungame = {}

function gungame.giveWeapon(ply)
	local wep = gungame.assortment[gungame.players[ply].weapon]
	
	if wep then
		prop.createSent(ply:getPos(), Angle(), wep, true)
	else
		prop.createSent(ply:getPos(), Angle(), melee, true)
		
		timer.simple(0.5, function()
			if not ply:isValid() then return end
			
			local view = ply:getViewModel()
			if view and view:isValid() then
				view:setMaterial("models/debug/debugwhite")
				view:setColor(Color(255, 200, 0))
			end
			
			local wep = ply:getWeapon(melee)
			if wep and wep:isValid() then
				wep:setMaterial("models/debug/debugwhite")
				wep:setColor(Color(255, 200, 0))
			end
		end)
	end
end

----------------------------------------

local mode = {
	name = "Gun Game"
}

function mode.onStart()
	-- make the assortment
	gungame.assortment = {}
	
	local cats = table.copy(categories)
	for i, class in ipairs(assortment) do
		local class_id = math.random(1, #cats[class])
		
		gungame.assortment[i] = cats[class][class_id]
		table.remove(cats[class], class_id)
	end
	
	-- setup players
	gungame.players = {}
	
	for _, ply in ipairs(pvp.players) do
		gungame.players[ply] = {
			weapon = 1,
			wep_kills = 0,
		}
	end
end

function mode.onKill(ply, killer, wep)
	local melee_kill = wep and wep:isValid() and wep:getClass() == melee
	
	-- upgrade weapon
	if killer and killer ~= ply then
		local data = gungame.players[killer]
		data.wep_kills = data.wep_kills + 1
		
		if data.wep_kills == kills_per_weapon or melee_kill then
			if data.weapon <= #gungame.assortment then
				data.wep_kills = 0
				data.weapon = data.weapon + 1
				
				if data.weapon == #gungame.assortment + 1 then
					concmd("ulx csay " .. killer:getName() .. " has reached golden knife!")
				end
				
				for _, wep in ipairs(killer:getWeapons()) do
					wep:remove()
				end
				
				gungame.giveWeapon(killer)
				timer.simple(0, function()
					prop.createSent(killer:getPos(), Angle(), melee, true)
				end)
			else
				for _, ply in ipairs(pvp.players) do
					for _, wep in ipairs(ply:getWeapons()) do
						wep:remove()
					end
				end
				
				concmd("ulx csay " .. killer:getName() .. " has won the game!")
				
				timer.simple(3, function()
					pvp.endMode()
				end)
			end
		end
	end
	
	-- downgrade of melee or suicide
	if melee_kill or ply == killer then
		local data = gungame.players[ply]
		data.wep_kills = 0
		data.weapon = math.max(data.weapon - 1, 1)
	end
end

function mode.playerJoin(ply)
	gungame.players[ply] = {
		weapon = 1,
		wep_kills = 0,
	}
	
	mode.playerSpawn(ply)
end

function mode.playerLeave(ply)
	gungame.players[ply] = nil
end

function mode.playerSpawn(ply)
	for _, wep in ipairs(ply:getWeapons()) do
		wep:remove()
	end
	
	gungame.giveWeapon(ply)
	timer.simple(0, function()
		prop.createSent(ply:getPos(), Angle(), melee, true)
	end)
end

----------------------------------------

return mode
