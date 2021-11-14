--@name Exploro
--@author Sevii
--@include ../../lib/noise.lua
--@include ./generation/generator.lua

settings = {
	generation = {
		chunk = {
			size = 1000,
			segments = 5 -- Currently does nothing
		},
		terrain = {
			scale = 10,
			detail = 4
		}
	}
}

player = {
	pos = Vector(),
	base = nil,
	props = {}
}

----------------------------------------

noise = require("../../lib/noise.lua")

generator = require("./generation/generator.lua")

----------------------------------------

if SERVER then
	
	local chunks = {}
	
	----------------------------------------
	
	local hud = prop.createComponent(chip():getPos() + Vector(0, 0, 5), Angle(), "starfall_hud", "models/bull/dynamicbutton.mdl", true)
	local target_pos = chip():getPos() + Vector(0, 0, 500)
	
	wire.adjustInputs({"VehicleBase"}, {"ENTITY"})
	
	hook.add("input", "", function(name, value)
		if name ~= "VehicleBase" then return end
		
		player.props = {}
		hud:linkComponent(nil)
		
		if not value then return end
		if not value:isValid() then return end
		
		player.base = value
		for _, prop in pairs(value:getAllConstrained({Weld = true, Rope = true, Axis = true})) do
			if prop ~= value and prop ~= chip() then
				table.insert(player.props, prop)
			end
		end
		
		-- Move into spot
		player.pos = Vector(0, 0, 500)
		
		local base = player.base
		local move = base:getPos() - target_pos
		for _, prop in pairs(player.props) do
			local a = prop:getAngles()
			prop:setPos(prop:getPos() - move)
			prop:setAngles(prop:getAngles())
		end
		
		base:setPos(target_pos)
		base:setAngles(base:getAngles())
		
		-- Find all seats and link hud
		hud:linkComponent(chip())
		
		for _, prop in pairs(player.props) do
			if prop:isVehicle() then
				hud:linkComponent(prop)
			end
		end
		
		local function checkChildren(ent)
			if not ent or not ent:isValid() then return end
			
			for _, prop in pairs(ent:getChildren()) do
				if prop:isVehicle() then
					hud:linkComponent(prop)
				end
				
				checkChildren(prop)
			end
		end
		
		checkChildren(ent)
	end)
	
	----------------------------------------
	
	local delta = 0
	hook.add("tick", "", function()
		delta = delta + timer.frametime()
		
		if delta <= 0.2 then return end
		delta = 0
		
		local base = player.base
		if not base or not base:isValid() then return end
		
		
		
		local base_vel = base:getVelocity()
		move = (base:getPos() - target_pos)
		
		player.pos = player.pos + move
		
		local props = {}
		for _, prop in pairs(player.props) do
			if isValid(prop) then
				table.insert(props, prop)
			end
		end
		player.props = props
		
		-- Move vehicle
		local vels = {}
		for _, prop in pairs(player.props) do
			vels[prop] = prop:getVelocity()
		end
		
		base:setPos(target_pos)
		base:setAngles(base:getAngles())
		base:setVelocity(base_vel)
		
		for prop, vel in pairs(vels) do
			prop:setPos(prop:getPos() - move)
			prop:setAngles(prop:getAngles())
			prop:setVelocity(vel)
		end
		
		-- Chunks
		local pos = player.pos
		local csize = settings.generation.chunk.size
		local cz = math.floor((pos.z + csize / 2) / csize)
		local cy = math.floor(pos.y / csize)
		local cx = math.floor(pos.x / csize)
		
		local chunks_old = {}
		local create_buffer = {}
		for id, _ in pairs(chunks) do
			chunks_old[id] = true
		end
		
		for z = cz, cz + 1 do
			for y = cy, cy + 1 do
				for x = cx, cx + 1 do
					local chunk_pos = Vector(x, y, z)
					local chunk_id = tostring(chunk_pos)
					
					if not chunks[chunk_id] then
						local ent = nil
						local vertices = generator.generateChunk(chunk_pos)
						
						local vc = 0
						for _, v in pairs(vertices) do
							vc = vc + #v
						end
						
						if vc == 0 then
							ent = true
						end
						
						chunks[chunk_id] = {
							pos = chunk_pos,
							pos_unit = chunk_pos * csize,
							vertices = vertices,
							ent = ent
						}
					end
					
					if not chunks[chunk_id].ent then
						create_buffer[chunk_id] = chunk_pos
					end
					
					chunks_old[chunk_id] = nil
				end
			end
		end
		
		-- Destroy
		for id, _ in pairs(chunks_old) do
			local ent = chunks[id].ent
			if ent and ent ~= true then
				ent:remove()
			end
			
			chunks[id] = nil
		end
		
		-- Move
		for id, chunk in pairs(chunks) do
			if chunk.ent and chunk.ent ~= true then
				chunk.ent:setPos(chunk.ent:getPos() - move)
			end
		end
		
		-- Create
		if prop.canSpawn() then
			for id, pos in pairs(create_buffer) do
				local ent = prop.createCustom(target_pos + pos * csize - player.pos, Angle(), chunks[id].vertices, true)
				
				chunks[id].ent = ent
				
				break
			end
		end
	end)
	
else
	
	
	
end