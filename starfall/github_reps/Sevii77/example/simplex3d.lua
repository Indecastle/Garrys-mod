--@name Simplex 3D Example
--@include ../lib/noise/simplex3d.lua

local size = 32
local scale = 32 / size

if SERVER then
	
	local holo = holograms.create(chip():getPos() + Vector(0, 0, 100), Angle(), "models/props_junk/PopCan01a.mdl", Vector(1, 1, 1))
	
	net.receive("", function(_, ply)
		net.start("")
		net.writeUInt(holo:entIndex(), 13)
		net.send(ply)
	end)
	
else
	
	local simplex = require("../lib/noise/simplex3d.lua")
	
	local points = {}
	for y = 0, size do
		points[y] = {}
		
		local m = math.sin(y / size * math.pi)
		local dz = math.cos(y / size * math.pi)
		
		for x = 1, size do
			local rad = x / size * math.pi * 2
			
			local dx = math.sin(rad) * m
			local dy = math.cos(rad) * m
			
			local height = simplex(dx * scale, dy * scale, dz * scale) * 20 + 60
			
			points[y][x] = {
				pos = Vector(dx * height, dy * height, dz * height),
				color = Color(dx * 128 + 128, dy * 128 + 128, dz * 128 + 128)
			}
		end
	end
	
	local vertices = {}
	for y = 1, size do
		for x = 1, size do
			local nx = x % size + 1
			
			table.insert(vertices, points[y    ][ x])
			table.insert(vertices, points[y    ][nx])
			table.insert(vertices, points[y - 1][ x])
			
			table.insert(vertices, points[y    ][nx])
			table.insert(vertices, points[y - 1][nx])
			table.insert(vertices, points[y - 1][ x])
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
		end)
	end)
	
end