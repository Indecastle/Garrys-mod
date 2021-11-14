--@include ./terrain.lua

local terrain = require("./terrain.lua")

local generator = {}

local set = settings.generation
local set_chunk = set.chunk

----------------------------------------

--[[
	Generated a chunk.
	This included terrain, roads and any structures on it
	
	returns a table containing a convex shapes
]]
function generator.generateChunk(pos)
	local x, y, z = pos.x, pos.y, pos.z
	
	local csize = set_chunk.size / 2
	local shapes = {}
	
	-- Terrain
	if z == 0 then
		local height00 = terrain(x,     y    )
		local height10 = terrain(x + 1, y    )
		local height01 = terrain(x,     y + 1)
		local height11 = terrain(x + 1, y + 1)
		--print(csize)
		shapes[1] = {
			Vector(-csize, -csize, -csize),
			Vector( csize, -csize, -csize),
			Vector(-csize,  csize, -csize),
			Vector( csize,  csize, -csize),
			
			Vector(-csize, -csize, height00 - csize),
			Vector( csize, -csize, height10 - csize),
			Vector(-csize,  csize, height01 - csize),
			Vector( csize,  csize, height11 - csize)
		}
	end
	
	--[[local z_units = z * csize
	local points = {}
	local shape_index = #shapes + 1
	
	for y = 0, set_chunk.segments - 1 do
		points[y] = {}
		
		for x = 0, set_chunk.segments - 1 do
			local height_x = x > 0 and points[y][x - 1].height or -9999
			local height_y = y > 0 and points[y - 1][x].height or -9999
			
			local max_incline_x = x > 1 and points[y][x - 1].incline or 9999
			local max_incline_y = y > 1 and points[y - 1][x].incline or 9999
			
			local height = terrain(x, y)
			
			
		end
	end]]
	
	return shapes
end

----------------------------------------

return generator