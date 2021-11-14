--@name Image Wrapper
--@author Sevii (https://steamcommunity.com/id/dadamrival/)
--@include ../lib/mesh.lua
--@include ../lib/polyclip.lua

--[[
	It is recommended to use image_wrapper_multi, it can save and supports multiple decals per chip
	
	Red sphere is the sphere where props will be checked to see if they should be wrapped, having as little props in it as possible is a good idea
	
	size = Vector(x, y)
	image = url to image (best to use whitelisted url)
	
	min_face_ang = what the normal.z should be larger than (0 - 1), altho -1 also would work it would put the faces inside the prop
	class_whitelist = all classes that will be attempted to wrapped
	model_filter = only attempts to wrap props of which their models match any of the filters
	
	to wrap the image type '.do' in chat while looking at the chip
]]

local size = Vector(318, 143) / 143 * 30
local image = "https://i.imgur.com/f5FIyJM.jpg"

local min_face_ang = 0.3
local class_whitelist = {
	["prop_physics"] = true
}
local model_filter = {
	["models/sprops/rectangles(.+)"] = true,
	["models/sprops/cuboids/(.+)"] = true,
	["models/sprops/geometry/(.+)"] = true,
	["models/sprops/misc/(.+)"] = true,
	["models/sprops/cylinders/(.+)"] = true
}

----------------------------------------

if SERVER then
	
	local holo = holograms.create(chip():getPos(), chip():getAngles(), "models/sprops/geometry/sphere_144.mdl", Vector(math.max(size.x, size.y) / 72))
	holo:setColor(Color(255, 0, 0, 50))
	holo:setParent(chip())
	
	local holo_img = holograms.create(chip():getPos(), chip():getAngles(), "models/sprops/cuboids/height06/size_1/cube_6x6x6.mdl", Vector(size.x / 6, size.y / 6, 0.1))
	holo_img:setParent(chip())
	
	----------------------------------------
	
	hook.add("playerSay", "", function(ply, text)
		if ply ~= owner() or text ~= ".do" or ply:getEyeTrace().Entity ~= chip() then return end
		
		local ents = find.inSphere(chip():getPos(), math.max(size.x, size.y), function(ent)
			if not class_whitelist[ent:getClass()] then return false end
			
			local model = ent:getModel()
			for filter, _ in pairs(model_filter) do
				if string.match(model, filter) then
					return true
				end
			end
			
			return false
		end)
		
		local ents_sorted = {}
		for _, ent in pairs(ents) do
			local parent = ent:getParent()
			local id = parent:isValid() and parent or ent
			ents_sorted[id] = ents_sorted[id] or {}
			
			table.insert(ents_sorted[id], ent)
		end
		
		print(#ents .. " Entities")
		
		net.start("map")
		net.writeUInt(table.count(ents_sorted), 8)
		for parent, ents in pairs(ents_sorted) do
			net.writeUInt(parent:entIndex(), 13)
			net.writeUInt(#ents, 8)
			
			for _, ent in pairs(ents) do
				net.writeUInt(ent:entIndex(), 13)
			end
		end
		net.send(owner())
		
		return ""
	end)
	
	----------------------------------------
	
	local vertices_sorted = {}
	local holos = {}
	
	function sendVertices(plys)
		net.start("data")
		net.writeStream(fastlz.compress(json.encode(vertices_sorted)))
		net.send(plys)
	end
	
	----------------------------------------
	
	net.receive("data", function(_, ply)
		if ply ~= owner() then return end
		
		vertices_sorted = {}
		
		net.readStream(function(data)
			local data = json.decode(fastlz.decompress(data))
			
			local valid_holos = {}
			for _, holo in pairs(holos) do
				if holo:isValid() then
					table.insert(valid_holos, holo)
				end
			end
			holos = valid_holos
			
			local i = 1
			for parent, vertices in pairs(data) do
				local p = entity(parent)
				
				local holo = holos[i] or holograms.create(p:getPos(), p:getAngles(), "models/sprops/cuboids/height06/size_1/cube_6x6x6.mdl", Vector(1))
				holo:setParent(p)
				
				local holo_index = holo:entIndex()
				
				holos[i] = holo
				vertices_sorted[holo_index] = vertices
				
				i = i + 1
			end
			
			local count = table.count(data)
			if count < #holos then
				for i = count + 1, #holos do
					holos[i]:remove()
					table.remove(holos, count + 1)
				end
			end
			
			sendVertices()
		end)
	end)
	
	----------------------------------------
	
	net.receive("rpholo", function(_, ply)
		net.start("pholo")
		net.writeUInt(holo_img:entIndex(), 13)
		net.send(ply)
	end)
	
	net.receive("request", function(_, ply)
		if table.count(vertices_sorted) == 0 then return end
		
		sendVertices(ply)
	end)
	
else
	
	-- Check if we can create the mesh, if not dont run the rest of the code
	if not hasPermission("mesh") then return end
	
	-- Check if we got permissions to create a material, if not skip it
	local mat
	if hasPermission("material.create") and hasPermission("material.urlcreate", image) then
		mat = material.create("VertexLitGeneric")
		mat:setInt("$flags", 0x0100 + 0x2000)
		mat:setFloat("$alphatestreference", 0.1)
		mat:setTextureURL("$basetexture", image, function(_, _, w, h, layout)
			layout(0, 0, 1024, 1024)
		end)
	end
	
	local c = chip()
	
	----------------------------------------
	-- Projection holo
	
	net.start("rpholo")
	net.send()
	
	net.receive("pholo", function()
		local p = entity(net.readUInt(13)):toHologram()
		
		local p1 = {pos = Vector(-3, -3, 0), normal = Vector(0, 0, 1), u = 0, v = 0}
		local p2 = {pos = Vector( 3, -3, 0), normal = Vector(0, 0, 1), u = 1, v = 0}
		local p3 = {pos = Vector( 3,  3, 0), normal = Vector(0, 0, 1), u = 1, v = 1}
		local p4 = {pos = Vector(-3,  3, 0), normal = Vector(0, 0, 1), u = 0, v = 1}
		
		local mesh = mesh.createFromTable({p2, p1, p4, p3, p2, p4})
		p:setMesh(mesh)
		p:setMeshMaterial(mat)
	end)
	
	----------------------------------------
	
	function doVerticies(data)
		local vertices = {}
		local p = data.parent
		
		local ang_chip = c:getAngles()
		local ang_parent = p:getAngles()
		for i, vertex in pairs(data.vertices) do
			local uv = vertex.pos / size + Vector(0.5, 0.5)
			
			table.insert(vertices, {
				pos = p:worldToLocal(c:localToWorld(vertex.pos - Vector(0, 0, 0.5))), -- + vertex.normal)
				normal = vertex.normal,
				u = uv.x,
				v = uv.y
			})
		end
		
		local mesh = mesh.createFromTable(vertices)
		p:setMesh(mesh)
		p:setMeshMaterial(mat)
		
		return mesh
	end
	
	----------------------------------------
	
	net.start("request")
	net.send()
	
	local vertices_sorted = {}
	
	net.receive("data", function()
		net.readStream(function(data)
			local tbl = json.decode(fastlz.decompress(data))
			
			for _, data in pairs(vertices_sorted) do
				if data.mesh then
					data.mesh:destroy()
				end
			end
			
			vertices_sorted = {}
			
			for parent, vertices in pairs(tbl) do
				vertices_sorted[parent] = {
					loaded = false,
					vertices = {}
				}
				
				for i, vertex in pairs(vertices) do
					vertices_sorted[parent].vertices[i] = {
						pos = vertex.pos,
						normal = vertex.normal
					}
				end
			end
		end)
	end)
	
	hook.add("think", "", function()
		for parent, data in pairs(vertices_sorted) do
			if not data.loaded then
				local p = entity(parent)
				
				if p:isValid() then
					data.parent = p:toHologram()
					data.loaded = true
					data.mesh = doVerticies(data)
				end
			end
		end
	end)
	
	----------------------------------------
	
	if player() == owner() then
		local mesh = require("../lib/mesh.lua")
		local polyclip = require("../lib/polyclip.lua")
		
		local function linePlane(pos, plane_pos, plane_normal)
			local x = plane_normal:dot(plane_pos - pos) / plane_normal:dot(Vector(0, 0, 9999))
			return pos + Vector(0, 0, x * 9999)
		end
		
		net.receive("map", function()
			local ents_sorted = {}
			
			for i = 1, net.readUInt(8) do
				local tbl = {}
				local parent = net.readUInt(13)
				
				for i2 = 1, net.readUInt(8) do
					tbl[i2] = entity(net.readUInt(13))
				end
				
				ents_sorted[parent] = tbl
			end
			
			local vertices_sorted = {}
			local ang = c:getAngles()
			for parent, ents in pairs(ents_sorted) do
				local vertices = {}
				
				for _, vertex in pairs(mesh.getEntityVertices(ents, Vector())) do
					table.insert(vertices, c:worldToLocal(vertex.pos))
				end
				
				local new = {}
				for i = 1, #vertices, 3 do
					local a = vertices[i]
					local b = vertices[i + 1]
					local c = vertices[i + 2]
					
					if a.z < 0 then continue end
					if b.z < 0 then continue end
					if c.z < 0 then continue end
					
					local normal = (b - a):cross(c - a):getNormalized()
					
					-- Check normal
					if normal.z < min_face_ang then continue end
					
					-- Clip poly
					local pos_a = Vector(a.x, a.y)
					local pos_b = Vector(b.x, b.y)
					local pos_c = Vector(c.x, c.y)
					
					local s = size / 2
					local poly = polyclip.clip({pos_a, pos_b, pos_c}, {Vector(-s.x, -s.y), Vector(s.x, -s.y), Vector(s.x, s.y), Vector(-s.x, s.y)})
					
					if #poly > 0 then
						local start = poly[1]
						for i = 3, #poly do
							table.insert(new, {
								pos = linePlane(start, a, normal),
								normal = normal
							})
							
							table.insert(new, {
								pos = linePlane(poly[i - 1], a, normal),
								normal = normal
							})
							
							table.insert(new, {
								pos = linePlane(poly[i], a, normal),
								normal = normal
							})
						end
					end
				end
				
				if #new > 0 then
					vertices_sorted[parent] = new
				end
			end
			
			net.start("data")
			net.writeStream(fastlz.compress(json.encode(vertices_sorted)))
			net.send()
		end)
	end
	
end