-- https://www.geometrictools.com/Documentation/TriangulationByEarClipping.pdf

local earclip = {}
local pi = math.pi

--[[
	Version 0.1
	
	TODO:
	support holes
	support complex shapes
	check if vertex in triangle
]]

----------------------------------------

function earclip.getPointsAngle(a, b, c)
	local al, bl, cl = (b - a):getLength2DSqr(), (c - a):getLength2DSqr(), (b - c):getLength2DSqr()
	
	local ang = math.acos((al + bl - cl) / (2 * math.sqrt(al) * math.sqrt(bl)))
	local inv = (b - a):cross(c - a).z < 0
	
	return inv and (pi - ang + pi) or ang
end

function earclip.getTriangles(points, reverse)
	local triangles = {}
	local points_left = {}
	local ear, convex = {}, {}
	
	-----
	
	local function getPrev(id)
		return points_left[(id - 2) % #points_left + 1]
	end
	
	local function getNext(id)
		return points_left[id % #points_left + 1]
	end
	
	local function checkPoint(point)
		local id = 1
		for i2, i in pairs(points_left) do
			if i == point then
				id = i2
				break
			end
		end
		
		local ang = earclip.getPointsAngle(points[point], points[getPrev(id)], points[getNext(id)])
		if reverse then
			ang = pi * 2 - ang
		end
		
		if ang <= pi / 2 then
			table.insert(ear, point)
		elseif ang <= pi then
			table.insert(convex, point)
		end
	end
	
	-----
	
	for i, point in pairs(points) do
		points_left[i] = i
	end
	
	for i, point in pairs(points) do
		checkPoint(i)
	end
	
	while #points_left > 2 do
		local point = #ear > 0 and ear[1] or convex[1]
		
		local id = 1
		for i2, i in pairs(points_left) do
			if i == point then
				id = i2
				break
			end
		end
		
		local prev = getPrev(id)
		local next = getNext(id)
		
		table.insert(triangles, {
			points[reverse and prev or point],
			points[reverse and point or prev],
			points[next]
		})
		
		-- Remove current point from points_left and ear or convex
		table.remove(points_left, id)
		table.remove(#ear > 0 and ear or convex, 1)
		
		-- Remove prev point from ear and convex and recheck
		for i, i2 in pairs(ear) do
			if i2 == prev then
				table.remove(ear, i)
			end
		end
		for i, i2 in pairs(convex) do
			if i2 == prev then
				table.remove(convex, i)
			end
		end
		
		checkPoint(prev)
		
		-- Remove next point from ear and convex and recheck
		for i, i2 in pairs(ear) do
			if i2 == next then
				table.remove(ear, i)
			end
		end
		for i, i2 in pairs(convex) do
			if i2 == next then
				table.remove(convex, i)
			end
		end
		
		checkPoint(next)
	end
	
	return triangles
end

----------------------------------------

return earclip