--@name Farmland
--@author Sevii
--@include ./lib/net.lua

local settings = {
	chunk_size = 8,
	crop_size = 48,
	step_size = 6,
	
	crop_texture = "https://i.imgur.com/gNJvemt.png",
	crop_detail = 2,
	crop_resolution = 16,
	crop_pixelated = true,
	crop_height = 2,
	
	landsize = Vector(4, 4)
}

----------------------------------------

local net = require("./lib/net.lua")

net.registerPacketType("crops_changed", function(crops_changed)
	net.writeUInt(table.count(crops_changed), 12)
	for _, v in pairs(crops_changed) do
		net.writeUInt(v.x, 8)
		net.writeUInt(v.y, 8)
		net.writeBool(v.state)
	end
end, function()
	local crops_changed = {}
	
	for i = 1, net.readUInt(12) do
		local x, y = net.readUInt(8), net.readUInt(8)
		
		crops_changed[x .. "," .. y] = {x = x, y = y, state = net.readBool()}
	end
	
	return crops_changed
end)

net.registerRequestName("farmland")
net.registerNetworkName("crops_changed", "crops_changed")

----------------------------------------

local cs = settings.chunk_size
local crs = settings.crop_size

if SERVER then
	
	local holos = {}
	for x = 0, settings.landsize.x - 1 do
		for y = 0, settings.landsize.y - 1 do
			holos[x .. "," .. y] = holograms.create(chip():getPos() + Vector(x * cs * crs, y * cs * crs, 0), Angle(), "models/props_junk/PopCan01a.mdl", Vector(crs))
		end
	end
	
	local crops = {}
	local crops_changed = {}
	for x = 0, settings.landsize.x * cs - 1 do
		crops[x] = {}
		
		for y = 0, settings.landsize.y * cs - 1 do
			crops[x][y] = true
		end
	end
	
	----------------------------------------
	
	net.setupRequest("farmland", function()
		for x = 0, settings.landsize.x - 1 do
			for y = 0, settings.landsize.y - 1 do
				net.writeUInt(holos[x .. "," .. y]:entIndex(), 13)
			end
		end
	
		for x = 0, settings.landsize.x * cs - 1 do
			for y = 0, settings.landsize.y * cs - 1 do
				net.writeBool(crops[x][y])
			end
		end
	end)
	
	----------------------------------------
	
	local harvesters = {}
	local score = {}
	hook.add("playerSay", "", function(ply, text)
		if ply ~= owner() then return end
		
		if text == ".do" then
			local target = owner():getEyeTrace().Entity
			
			if target == entity(0) then return end
			
			harvesters[target] = true
		elseif text == ".score" then
			printTable(score)
		end
	end)
	
	timer.create("", 0.1, 0, function()
		local steps = settings.step_size
		local cp = chip():getPos()
		local height = cp.z
		
		for harvester, _ in pairs(harvesters) do
			if not isValid(harvester) then
				harvesters[harvester] = nil
				
				continue
			end
			
			local min, max = harvester:obbMins(), harvester:obbMaxs()
			local size = max - min
			
			for x = min.x, max.x, size.x / steps do
				for y = min.y, max.y, size.y / steps do
					for z = min.z, max.z, size.z / steps do
						if (x ~= min.x and x ~= max.x) and (y ~= min.y and y ~= max.y) and (z ~= min.z and z ~= max.z) then continue end
						
						local lpos = Vector(x, y, z)
						local pos = harvester:localToWorld(lpos)
						
						if pos.z > height + 32 or pos.z < height - 32 then continue end
						
						local cropx = math.floor((pos.x - cp.x) / crs)
						local cropy = math.floor((pos.y - cp.y) / crs)
						
						if cropx < 0 or cropx >= settings.landsize.x * cs or cropy < 0 or cropy >= settings.landsize.y * cs then continue end
						
						if crops[cropx][cropy] then
							crops[cropx][cropy] = false
							crops_changed[cropx .. "," .. cropy] = {
								x = cropx,
								y = cropy,
								state = false
							}
							
							local owner = harvester:getOwner()
							score[owner] = (score[owner] or 0) + 1
						end
					end
				end
			end
		end
		
		if table.count(crops_changed) > 0 then
			net.send("crops_changed", crops_changed)
			crops_changed = {}
		end
	end)
	
else
	
	local crops = {}
	local crops_changed = {}
	local chunks = {}
	local chunks_changed = {}
	
	local mat = material.create("VertexLitGeneric")
	mat:setInt("$flags", 0x0100 + 0x2000)
	mat:setFloat("$alphatestreference", 0.1)
	mat:setInt("$treeSway", 2)
	mat:setInt("$treeSwayStatic", 1)
	mat:setFloat("$treeSwayRadius", 999999)
	mat:setFloat("$treeSwayScrumbleStrength", 0.3)
	mat:setFloat("$treeSwayScrumbleFrequency", 30)
	mat:setFloat("$treeSwayScrumbleFalloffExp", 1)
	mat:setTextureURL("$basetexture", settings.crop_texture, function(_, _, w, h, layout)
		if layout then
			layout(0, 0, settings.crop_resolution, settings.crop_resolution)
		end
	end)
	
	net.request("farmland", function()
		for x = 0, settings.landsize.x - 1 do
			for y = 0, settings.landsize.y - 1 do
				local holo = net.readUInt(13)
				
				timer.simple(1, function()
					chunks[x .. "," .. y] = {
						x = x,
						y = y,
						holo = holo,
						loaded = false,
						mesh = nil,
						cache = {}
					}
				end)
			end
		end
		
		for x = 0, settings.landsize.x * cs - 1 do
			crops[x] = crops[x] or {}
			
			for y = 0, settings.landsize.y * cs - 1 do
				if not crops[x][y] then
					crops[x][y] = net.readBool()
					crops_changed[x .. "," .. y] = {x = x, y = y, state = true}
				end
			end
		end
	end)
	
	net.receive("crops_changed", function(data)
		for k, v in pairs(data) do
			crops[v.x] = crops[v.x] or {}
			crops[v.x][v.y] = v.state
			crops_changed[k] = v
			
			local cx, cy = math.floor(v.x / cs), math.floor(v.y / cs)
			chunks_changed[cx .. "," .. cy] = {x = cx, y = cy}
		end
	end)
	
	----------------------------------------
	
	local detail = settings.crop_detail
	local uv = settings.crop_resolution / 1024
	local normal = Vector(1, 1, 1)
	function createCrop(xo, yo, height)
		local vertices = {}
		
		local xo = xo + math.random() - 0.5
		local yo = yo + math.random() - 0.5
		local ro = math.random() * math.pi * 8
		for i = 1, detail do
			local rad = i / detail * math.pi + ro
			local x = math.sin(rad)
			local x1 = x * 0.9 + 0.5
			local x2 = -x * 0.9 + 0.5
			local y = math.cos(rad)
			local y1 = y * 0.9 + 0.5
			local y2 = -y * 0.9 + 0.5
			local mul = 0.5 + math.random() * 0.5
			
			local a = {pos = Vector(x1 * mul + xo, y1 * mul + yo, height), normal = normal, u = 0 , v = 0}
			local b = {pos = Vector(x2 * mul + xo, y2 * mul + yo, height), normal = normal, u = uv, v = 0}
			local c = {pos = Vector(x2 * mul + xo, y2 * mul + yo, 0     ), normal = normal, u = uv, v = uv}
			local d = {pos = Vector(x1 * mul + xo, y1 * mul + yo, 0     ), normal = normal, u = 0 , v = uv}
			
			table.insert(vertices, a)
			table.insert(vertices, b)
			table.insert(vertices, c)
			
			table.insert(vertices, a)
			table.insert(vertices, c)
			table.insert(vertices, d)
		end
		
		return vertices
	end
	
	function buildChunk(x, y)
		local chunk = chunks[x .. "," .. y]
		local cx, cy = x * cs, y * cs
		
		for i, v in pairs(crops_changed) do
			if v.x - cx >= 0 and v.x - cx < cs and v.y - cy >= 0 and v.y - cy < cs then
				chunk.cache[v.x - cx] = chunk.cache[v.x - cx] or {}
				
				if v.state then
					chunk.cache[v.x - cx][v.y - cy] = createCrop(v.x - cx, v.y - cy, settings.crop_height)
				else
					chunk.cache[v.x - cx][v.y - cy] = {}
				end
				
				crops_changed[i] = nil
			end
		end
		
		local vertices = {}
		for x = 0, cs - 1 do
			for y = 0, cs - 1 do
				for _, vertex in pairs((chunk.cache[x] or {})[y] or {}) do
					table.insert(vertices, vertex)
				end
			end
		end
		
		if chunk.mesh then
			chunk.mesh:destroy()
			chunk.mesh = nil
		end
		
		if #vertices > 0 then
			chunk.mesh = mesh.createFromTable(vertices)
			chunk.holo:setColor(Color(255, 255, 255))
		else
			chunk.holo:setColor(Color(0, 0, 0, 0))
		end
		
		chunk.holo:setMesh(chunk.mesh)
	end
	
	----------------------------------------
	
	timer.create("chunk_build", 0.1, 0, function()
		for x = 0, settings.landsize.x - 1 do
			for y = 0, settings.landsize.y - 1 do
				local chunk = chunks[x .. "," .. y]
				
				if not chunk then continue end
				
				if not chunk.loaded then
					local holo = entity(chunk.holo)
					
					if isValid(holo) then
						chunk.holo = holo:toHologram()
						chunk.loaded = true
						chunk.holo:setRenderBounds(Vector(-cs * crs), Vector(cs * crs))
						chunk.holo:setMeshMaterial(mat)
						if settings.crop_pixelated then
							chunk.holo:setFilterMin(1)
							chunk.holo:setFilterMag(1)
						end
						
						buildChunk(x, y)
					end
				elseif chunks_changed[x .. "," .. y] then
					buildChunk(x, y)
					
					chunks_changed[x .. "," .. y] = nil
				end
			end
		end
	end)
	
end
