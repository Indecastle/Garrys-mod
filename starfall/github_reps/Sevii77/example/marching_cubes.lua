--@name Marching Cubes Example
--@include ../lib/noise/simplex3d.lua
--@include ../lib/marching_cubes.lua

local res = 16
local scale = res / 128
local iso = 0

local holo_scale = 20

if SERVER then
	
	local holo = holograms.create(chip():getPos(), Angle(), "models/props_junk/PopCan01a.mdl", Vector(holo_scale))
	
	net.receive("", function(_, ply)
		net.start("")
		net.writeUInt(holo:entIndex(), 13)
		net.send(ply)
	end)
	
else
	
	local simplex = require("../lib/noise/simplex3d.lua")
	local marchingCubes = require("../lib/marching_cubes.lua")
	
	local function id(x, y, z)
		return x .. "," .. y .. "," .. z
	end
	
	local points = {}
	for z = 1, res do
		for y = 1, res do
			for x = 1, res do
				points[id(x, y, z)] = simplex(x * scale, y * scale, z * scale)
			end
		end
	end
	
	local vertices = {}
	for z = 1, res - 1 do
		for y = 1, res - 1 do
			for x = 1, res - 1 do
				local tris = marchingCubes({
					points[id(x    , y    , z    )],
					points[id(x + 1, y    , z    )],
					points[id(x + 1, y + 1, z    )],
					points[id(x    , y + 1, z    )],
					points[id(x    , y    , z + 1)],
					points[id(x + 1, y    , z + 1)],
					points[id(x + 1, y + 1, z + 1)],
					points[id(x    , y + 1, z + 1)]
				}, iso)
				
				for i = 1, #tris, 3 do
					local a = tris[i    ]
					local b = tris[i + 1]
					local c = tris[i + 2]
					
					local normal = (b - a):cross(c - a):getNormalized()
					local color = Color(normal.x * 128 + 128, normal.y * 128 + 128, normal.z * 128 + 128)
					
					table.insert(vertices, {
						pos = a + Vector(x, y, z),
						normal = normal,
						color = color
					})
					
					table.insert(vertices, {
						pos = b + Vector(x, y, z),
						normal = normal,
						color = color
					})
					
					table.insert(vertices, {
						pos = c + Vector(x, y, z),
						normal = normal,
						color = color
					})
				end
			end
		end
	end
	
	local mesh = mesh.createFromTable(vertices)
	local mat = material.create("UnlitGeneric")
	mat:setInt("$flags", 0x0010)
	
	net.start("")
	net.send()
	
	net.receive("", function()
		local holo = entity(net.readUInt(13)):toHologram()
		
		timer.simple(1, function()
			holo:setMesh(mesh)
			holo:setMeshMaterial(mat)
			holo:setRenderBounds(Vector(), Vector(res * holo_scale))
		end)
	end)
	
end