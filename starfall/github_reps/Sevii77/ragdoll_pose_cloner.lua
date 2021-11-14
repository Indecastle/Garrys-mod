--@server

local ply = "Sevii"
local dist = 100
local fps = 60

------------------------------

for k, v in pairs(find.allPlayers()) do
	if string.find(string.lower(v:getName()), string.lower(ply)) then
		ply = v
		
		break
	end
end

local ragdolls = {}

local last_use = false
local last_time = timer.curtime()
--hook.add("think", "", function()
timer.create("", 1 / fps, 0, function()
	local time = timer.curtime()
	local dt = time - last_time --timer.frametime()
	last_time = time
	
	local ppos = ply:getPos()
	
	local new = {}
	for k, ragdoll in pairs(ragdolls) do
		if isValid(ragdoll) then
			table.insert(new, ragdoll)
		end
	end
	ragdolls = new
	
	local down = ply:keyDown(IN_KEY.USE)
	if down and not last_use then
		local t = ply:getEyeTrace()
		if isValid(t.Entity) and t.Entity:getClass() == "prop_ragdoll" then
			local has = false
			for k, ragdoll in pairs(ragdolls) do
				if ragdoll == t.Entity then
					has = k
					
					break
				end
			end
			
			if has then
				table.remove(ragdolls, has)
			else
				table.insert(ragdolls, 0, t.Entity)
			end
		end
	end
	last_use = down
	
	for k, ragdoll in pairs(ragdolls) do
		local rad = k / #ragdolls * math.pi * 2
		local bpos = ppos + Vector(math.sin(rad) * dist, math.cos(rad) * dist, 0) --chip():getPos()
		
		for i = 1, ragdoll:getBoneCount() do
			local phys = ragdoll:getPhysicsObjectNum(i)
			
			if isValid(phys) then
				local pos, ang = ply:getBonePosition(ply:lookupBone(ragdoll:getBoneName(ragdoll:translatePhysBoneToBone(i))))
				
				if pos then
					phys:setVelocity(((pos - ppos) - (phys:getPos() - bpos)) / dt)
					
					--[[local m = Matrix()
					m:setAngles(ang)
					m:rotate(-phys:getAngles())
					local ang = m:getAngles()
					phys:setAngleVelocity(Vector(ang.p, ang.y, ang.r) / dt)]]
				end
			end
		end
	end
end)