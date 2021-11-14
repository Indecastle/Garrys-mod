--@name Image Wrapper Multi
--@author Sevii (https://steamcommunity.com/id/dadamrival/)
--@include ../lib/polyclip.lua

--[[
	Does the same as the non multi version but allows for multiple images per chip and can save
	
	Red sphere is the sphere where props will be checked to see if they should be wrapped, having as little props in it as possible is a good idea
	
	decals, table containing all decals
		size = Vector(x, y)
		image = url to image (best to use whitelisted url)
		find_size_override = override for the search sphere size, if nil it will use size
		full_bright = same as the other one but overrides it
		min_face_ang = same as the other one but overrides it
		model_filter = same as the other one but overrides it
		class_whitelist = same as the other one but overrides it
		animation = animation data
	
	full_bright = should this texture use UnlitGeneric or VertexLitGeneric
	min_face_ang = what the normal.z should be larger than (0 - 1), altho -1 also would work it would put the faces inside the prop
	class_whitelist = all classes that will be attempted to wrapped
	model_filter = only attempts to wrap props of which their models match any of the filters
	
	to wrap the image type '.do' in chat while looking at the projection prop
	to save the positions of the decal projectors type '.save' in chat while looking at the chip
		when the chip is reloaded or dupe finished it will load the decals.
		Be sure to remove the projection props before duping because after pasting the dupe will spawn the props and sf also will. 
	
	
	TODO:
		Make V2 with better performance and better working
]]

local decals = {
	{
		size = Vector(318, 143) / 143 * 30,
		image = "https://i.imgur.com/f5FIyJM.jpg",
		find_size_override = 50,
		full_bright = true,
		min_face_ang = 0.1,
		model_filter = {
			"(.+)"
		},
		class_whitelist = {
			"prop_(.+)"
		}
	},
	
	{
		size = Vector(40, 40),
		image = "https://i.imgur.com/uY7bH0m.png"
	},
	
	{
		size = Vector(204, 144) / 144 * 40,
		image = "https://i.imgur.com/eGgl1rU.png",
		full_bright = true,
		min_face_ang = 0.1,
		animation = {
			speed = 1,
			xcount = 5,
			ycount = 7,
			width = 204,
			height = 144,
			timing = {0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1}
		}
	}
}

local full_bright = false
local min_face_ang = 0.5
local model_filter = {
	"models/sprops/rectangles(.+)",
	"models/sprops/cuboids/(.+)",
	"models/sprops/geometry/(.+)",
	"models/sprops/misc/(.+)",
	"models/sprops/cylinders/(.+)"
}
local class_whitelist = {
	"prop_physics"
}

----------------------------------------

if SERVER then
	
	local saved_pos = getUserdata()
	if #saved_pos > 0 then
		saved_pos = json.decode(saved_pos)
	else
		saved_pos = {}
	end
	
	
	local project_request_buffer = {}
	local projectors = {}
	local projectors_ents = {}
	
	----------------------------------------
	
	local function writeEntities(projector_ent)
		local decals_data = decals[projectors_ents[projector_ent]]
		local ents = find.inSphere(projector_ent:getPos(), decals_data.find_size_override or math.max(decals_data.size.x, decals_data.size.y, 30), function(ent)
			if projectors_ents[ent] then return false end
			--if not class_whitelist[ent:getClass()] then return false end
			local class, valid = ent:getClass(), false
			for _, filter in pairs(decals_data.class_whitelist or class_whitelist) do
				if string.match(class, filter) then
					valid = true
					
					break
				end
			end
			
			if not valid then return false end
			
			local model = ent:getModel()
			if not model then return false end
			
			for _, filter in pairs(decals_data.model_filter or model_filter) do
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
		
		net.writeUInt(projectors_ents[projector_ent], 8)
		net.writeUInt(projector_ent:entIndex(), 13)
		net.writeUInt(table.count(ents_sorted), 8)
		for parent, ents in pairs(ents_sorted) do
			net.writeUInt(parent:entIndex(), 13)
			net.writeUInt(#ents, 8)
			
			for _, ent in pairs(ents) do
				net.writeUInt(ent:entIndex(), 13)
			end
		end
	end
	
	----------------------------------------
	
	hook.add("think", "projection_prop_spawner", function()
		while prop.canSpawn() and #projectors < #decals do
			local index = #projectors + 1
			local decal = decals[index]
			
			local pos, ang
			if saved_pos[index] then
				pos = chip():localToWorld(saved_pos[index].pos)
				ang = chip():localToWorldAngles(saved_pos[index].ang)
			else
				pos = chip():getPos() + Vector(0, 0, 18 * index)
				ang = Angle()
			end
			
			local ent = prop.create(pos, ang, "models/sprops/misc/cones/size_0/cone_6x12.mdl", true)
			ent:setColor(Color(0, 255, 0, 50))
			
			local holo_radius = holograms.create(ent:getPos(), ent:getAngles(), "models/sprops/geometry/sphere_144.mdl", Vector((decal.find_size_override or math.max(decal.size.x, decal.size.y, 30)) / 72))
			holo_radius:setColor(Color(255, 0, 0, 50))
			holo_radius:setParent(ent)
			
			local holo_img = holograms.create(ent:getPos(), ent:getAngles(), "models/sprops/cuboids/height06/size_1/cube_6x6x6.mdl", Vector(decal.size.x / 6, decal.size.y / 6, 0.1))
			holo_img:setParent(ent)
			
			projectors_ents[ent] = index
			projectors[index] = {
				ent = ent,
				holo_radius = holo_radius,
				holo_img = holo_img
			}
			
			if index == #decals then
				hook.remove("think", "projection_prop_spawner")
				
				-- Load saved data and send to owner for building
				if #saved_pos > 0 then
					-- Put a 2 second delay on it to be save
					timer.simple(2, function()
						local count = 0
						for i = 1, #saved_pos do
							if i > #decals then break end
							
							count = count + 1
						end
						
						if count > 0 then
							net.start("map")
							net.writeUInt(count, 8)
							for i = 1, count do
								writeEntities(projectors[i].ent)
							end
							net.send(owner())
						end
					end)
				end
				
				-- Send build request to owner for all saved projectors
				if #project_request_buffer > 0 then
					-- Send projectors to clients to make preview
					net.start("pholo")
					for i, v in pairs(projectors) do
						net.writeUInt(v.holo_img:entIndex(), 13)
					end
					net.send(project_request_buffer)
				end
			end
		end
	end)
	
	----------------------------------------
	
	hook.add("playerSay", "", function(ply, text)
		if ply ~= owner() then return end
		
		if text == ".save" then
			if ply:getEyeTrace().Entity ~= chip() then return end
			
			local save = {}
			for i, data in pairs(projectors) do
				save[i] = {
					pos = chip():worldToLocal(data.ent:getPos()),
					ang = chip():worldToLocalAngles(data.ent:getAngles())
				}
			end
			
			setUserdata(json.encode(save))
			
			return ""
		elseif text == ".do" then
			local projector_ent = ply:getEyeTrace().Entity
			if not projectors_ents[projector_ent] then return end
			
			net.start("map")
			net.writeUInt(1, 8) -- Amount of projectors it wants to do
			writeEntities(projector_ent)
			net.send(owner())
			
			return ""
		end
	end)
	
	----------------------------------------
	
	local vertices_sorted = {}
	local holos = {}
	
	function sendVertices(plys, vertices)
		net.start("data")
		net.writeStream(fastlz.compress(json.encode(vertices)))
		net.send(plys)
	end
	
	----------------------------------------
	
	net.receive("data", function(_, ply)
		if ply ~= owner() then return end
		
		--[[local projector_id = net.readUInt(8)
		vertices_sorted[projector_id] = {
			ent = projectors[projector_id].ent:entIndex(),
			data = {}
		}]]
		
		net.readStream(function(data)
			local data = json.decode(fastlz.decompress(data))
			
			local send = {}
			for projector_id, data in pairs(data) do
				vertices_sorted[projector_id] = {
					ent = projectors[projector_id].ent:entIndex(),
					data = {}
				}
				
				holos[projector_id] = holos[projector_id] or {}
				
				local valid_holos = {}
				for _, holo in pairs(holos[projector_id]) do
					if holo:isValid() then
						table.insert(valid_holos, holo)
					end
				end
				holos[projector_id] = valid_holos
				
				local i = 1
				for parent, vertices in pairs(data) do
					local p = entity(parent)
					
					local holo = holos[projector_id][i] or holograms.create(p:getPos(), p:getAngles(), "models/sprops/cuboids/height06/size_1/cube_6x6x6.mdl", Vector(1))
					holo:setParent(p)
					
					local holo_index = holo:entIndex()
					
					holos[projector_id][i] = holo
					vertices_sorted[projector_id].data[holo_index] = vertices
					
					i = i + 1
				end
				
				local count = table.count(data)
				if count < #holos[projector_id] then
					for i = count + 1, #holos[projector_id] do
						holos[projector_id][i]:remove()
						table.remove(holos[projector_id], count + 1)
					end
				end
				
				send[projector_id] = vertices_sorted[projector_id]
			end
			
			-- Just send the new stuff
			sendVertices(nil, send)
			--sendVertices(nil, {[projector_id] = vertices_sorted[projector_id]})
		end)
	end)
	
	----------------------------------------
	
	net.receive("rpholo", function(_, ply)
		if #projectors < #decals then
			project_request_buffer[ply] = ply
			
			return
		end
		
		net.start("pholo")
		for i, v in pairs(projectors) do
			net.writeUInt(v.holo_img:entIndex(), 13)
		end
		net.send(ply)
	end)
	
	net.receive("request", function(_, ply)
		if table.count(vertices_sorted) == 0 then return end
		
		-- Send everything
		sendVertices(ply, vertices_sorted)
	end)
	
else
	
	local animations = {}
	
	-- Check if we can create the mesh, if not dont run the rest of the code
	if not hasPermission("mesh") then return end
	
	-- Check if we got permissions to create a material, if not skip it
	local mats = {}
	if hasPermission("material.create") then
		for i, data in pairs(decals) do
			if hasPermission("material.urlcreate", data.image) then
				if data.animation then
					local rt = tostring(i)
					
					render.createRenderTarget(rt)
					
					mats[i] = material.create((data.full_bright or full_bright) and "UnlitGeneric" or "VertexLitGeneric")
					mats[i]:setInt("$flags", 0x0100 + 0x2000)
					mats[i]:setFloat("$alphatestreference", 0.1)
					mats[i]:setTextureRenderTarget("$basetexture", rt)
					
					table.insert(animations, {
						rt = rt,
						--mat = mats[i],
						width = data.animation.width,
						height = data.animation.height,
						xcount = data.animation.xcount,
						ycount = data.animation.ycount,
						timing = data.animation.timing,
						speed = data.animation.speed or 1,
						next = 0,
						frame = 0,
						count = #data.animation.timing,
						sheet = render.createMaterial(data.image)
					})
				else
					mats[i] = material.create((data.full_bright or full_bright) and "UnlitGeneric" or "VertexLitGeneric")
					mats[i]:setInt("$flags", 0x0100 + 0x2000)
					mats[i]:setFloat("$alphatestreference", 0.1)
					mats[i]:setTextureURL("$basetexture", data.image, function(_, _, w, h, layout)
						layout(0, 0, 1024, 1024)
					end)
				end
			end
		end
	end
	
	----------------------------------------
	-- Animation
	
	if #animations > 0 and hasPermission("render.offscreen") then
		hook.add("renderoffscreen", "animations", function()
			local t = timer.curtime()
			
			for _, data in pairs(animations) do
				if t > data.next then
					data.frame = data.frame % data.count + 1
					
					render.selectRenderTarget(data.rt)
					render.clear(Color(0, 0, 0, 0))
					render.setMaterial(data.sheet)
					
					local u = ((data.frame - 1) % data.xcount) * data.width / 1024
					local v = math.floor((data.frame - 1) / data.xcount) * data.height / 1024
					render.drawTexturedRectUV(0, 0, 1024, 1024, u, v, u + (data.width / 1024), v + (data.height / 1024))
					
					data.next = t + data.timing[data.frame] / data.speed
				end
			end
		end)
	end
	
	----------------------------------------
	-- Projection holo
	
	net.start("rpholo")
	net.send()
	
	net.receive("pholo", function()
		for i = 1, #decals do
			local p = entity(net.readUInt(13)):toHologram()
			
			local p1 = {pos = Vector(-3, -3, 0), normal = Vector(0, 0, 1), u = 0, v = 0}
			local p2 = {pos = Vector( 3, -3, 0), normal = Vector(0, 0, 1), u = 1, v = 0}
			local p3 = {pos = Vector( 3,  3, 0), normal = Vector(0, 0, 1), u = 1, v = 1}
			local p4 = {pos = Vector(-3,  3, 0), normal = Vector(0, 0, 1), u = 0, v = 1}
			
			local mesh = mesh.createFromTable({p2, p1, p4, p3, p2, p4})
			p:setMesh(mesh)
			p:setMeshMaterial(mats[i])
		end
	end)
	
	----------------------------------------
	
	function doVerticies(data, projector_id, projector_ent)
		local vertices = {}
		local p = data.parent
		
		local min, max = Vector(math.huge), Vector(-math.huge)
		for i, vertex in pairs(data.vertices) do
			local pos = p:worldToLocal(projector_ent:localToWorld(vertex.pos - Vector(0, 0, 0.5)))
			local uv = vertex.pos / decals[projector_id].size + Vector(0.5, 0.5) -- + vertex.normal)
			
			if pos.x < min.x then
				min.x = pos.x
			end if pos.y < min.y then
				min.y = pos.y
			end if pos.z < min.z then
				min.z = pos.z
			end
			
			if pos.x > max.x then
				max.x = pos.x
			end if pos.y > max.y then
				max.y = pos.y
			end if pos.z > max.z then
				max.z = pos.z
			end
			
			table.insert(vertices, {
				pos = pos,
				normal = vertex.normal,
				u = uv.x,
				v = uv.y
			})
		end
		
		local mesh = mesh.createFromTable(vertices)
		p:setMesh(mesh)
		p:setMeshMaterial(mats[projector_id])
		p:setRenderBounds(min, max)
		
		return mesh
	end
	
	----------------------------------------
	
	net.start("request")
	net.send()
	
	local vertices_sorted = {}
	
	net.receive("data", function()
		net.readStream(function(data)
			local tbl = json.decode(fastlz.decompress(data))
			
			for projector_id, d in pairs(tbl) do
				if vertices_sorted[projector_id] then
					for _, data in pairs(vertices_sorted[projector_id].segments) do
						if data.mesh then
							data.mesh:destroy()
						end
					end
				end
				
				vertices_sorted[projector_id] = {
					projector_ent_id = d.ent,
					segments = {}
				}
				
				for parent, vertices in pairs(d.data) do
					vertices_sorted[projector_id].segments[parent] = {
						loaded = false,
						vertices = {}
					}
					
					for i, vertex in pairs(vertices) do
						vertices_sorted[projector_id].segments[parent].vertices[i] = {
							pos = vertex.pos,
							normal = vertex.normal
						}
					end
				end
			end
		end)
	end)
	
	hook.add("think", "", function()
		for projector_id, main_data in pairs(vertices_sorted) do
			local p = entity(main_data.projector_ent_id)
			
			if p:isValid() then
				main_data.projector_ent = p
			end
			
			if main_data.projector_ent then
				for parent, data in pairs(main_data.segments) do
					if not data.loaded then
						local p = entity(parent)
						
						if p:isValid() then
							data.parent = p:toHologram()
							data.loaded = true
							
							timer.simple(1, function()
								data.mesh = doVerticies(data, projector_id, main_data.projector_ent)
							end)
						end
					end
				end
			end
		end
	end)
	
	----------------------------------------
	
	if player() == owner() then
		local polyclip = require("../lib/polyclip.lua")
		
		local function linePlane(pos, plane_pos, plane_normal)
			local x = plane_normal:dot(plane_pos - pos) / plane_normal:dot(Vector(0, 0, 9999))
			return pos + Vector(0, 0, x * 9999)
		end
		
		net.receive("map", function()
			local vertices_sorted = {}
			
			for _ = 1, net.readUInt(8) do
				local projector_id = net.readUInt(8)
				local projector_ent = entity(net.readUInt(13))
				
				local ents_sorted = {}
				for i = 1, net.readUInt(8) do
					local tbl = {}
					local parent = net.readUInt(13)
					
					for i2 = 1, net.readUInt(8) do
						tbl[i2] = entity(net.readUInt(13))
					end
					
					ents_sorted[parent] = tbl
				end
				
				local s = decals[projector_id].size / 2
				local cliparea = {Vector(-s.x, -s.y), Vector(s.x, -s.y), Vector(s.x, s.y), Vector(-s.x, s.y)}
				
				vertices_sorted[projector_id] = {}
				local ang = projector_ent:getAngles()
				for parent, ents in pairs(ents_sorted) do
					local new = {}
					for _, ent in pairs(ents) do
						local ent_pos = ent:getPos()
						local ent_ang = ent:getAngles()
						local clipping = ent:getClipping()
						
						local vertices = {}
						for _, data in pairs(mesh.getModelMeshes(ent:getModel(), 0, 0)) do
							local verts = data.triangles
							for _, clip in pairs(clipping) do
								local v = {}
								for i = 1, #verts, 3 do
									local poly = polyclip.clipPlane3D({
										verts[i    ].pos,
										verts[i + 1].pos,
										verts[i + 2].pos,
									}, clip.origin, clip.normal)
									
									if #poly > 0 then
										for i = 3, #poly do
											table.insert(v, {pos = poly[1    ]})
											table.insert(v, {pos = poly[i - 1]})
											table.insert(v, {pos = poly[i    ]})
										end
									end
								end
								verts = v
							end
							
							for _, vertex in pairs(verts) do
								table.insert(vertices, projector_ent:worldToLocal(vertex.pos:getRotated(ent_ang) + ent_pos))
							end
						end
						
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
							
							local poly = polyclip.clip({pos_a, pos_b, pos_c}, cliparea)
							
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
					end
					
					if #new > 0 then
						vertices_sorted[projector_id][parent] = new
					end
				end
			end
			
			net.start("data")
			--net.writeUInt(projector_id, 8)
			net.writeStream(fastlz.compress(json.encode(vertices_sorted)))
			net.send()
		end)
	end
	
end