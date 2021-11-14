--[[
	Sutherland–Hodgman algorithm
	
	Source:
	https://rosettacode.org/wiki/Sutherland-Hodgman_polygon_clipping#Lua
]]

----------------------------------------

local function inside(p, cp1, cp2)
	return (cp2.x - cp1.x) * (p.y - cp1.y) > (cp2.y - cp1.y) * (p.x - cp1.x)
end
 
local function intersection(cp1, cp2, s, e)
	local dcx, dcy = cp1.x - cp2.x, cp1.y - cp2.y
	local dpx, dpy = s.x - e.x, s.y - e.y
	local n1 = cp1.x * cp2.y - cp1.y * cp2.x
	local n2 = s.x * e.y - s.y * e.x
	local n3 = 1 / (dcx * dpy - dcy * dpx)
	local x = (n1 * dpx - n2 * dcx) * n3
	local y = (n1 * dpy - n2 * dcy) * n3
	
	return Vector(x, y)
end
 
local function clip(subjectPolygon, clipPolygon)
	local outputList = subjectPolygon
	local cp1 = clipPolygon[#clipPolygon]
	for _, cp2 in ipairs(clipPolygon) do  -- WP clipEdge is cp1,cp2 here
		local inputList = outputList
		local s = inputList[#inputList]
		outputList = {}
		
		for _, e in ipairs(inputList) do
			if inside(e, cp1, cp2) then
				if not inside(s, cp1, cp2) then
					outputList[#outputList+1] = intersection(cp1, cp2, s, e)
				end
				outputList[#outputList+1] = e
			elseif inside(s, cp1, cp2) then
				outputList[#outputList+1] = intersection(cp1, cp2, s, e)
			end
			
			s = e
		end
		
		cp1 = cp2
	end
	
	return outputList
end

-- Just clip but break instantly cuz im lazy and it works so why not, probably improve at some point
local function clipPlane(subjectPolygon, planePos, planeNormal)
	local cp1 = planePos
	local cp2 = planePos + planeNormal:getRotated(Angle(0, 90, 0))
	
	local outputList = subjectPolygon
	local inputList = outputList
	local s = inputList[#inputList]
	outputList = {}
	
	for _, e in ipairs(inputList) do
		if inside(e, cp1, cp2) then
			if not inside(s, cp1, cp2) then
				outputList[#outputList+1] = intersection(cp1, cp2, s, e)
			end
			outputList[#outputList+1] = e
		elseif inside(s, cp1, cp2) then
			outputList[#outputList+1] = intersection(cp1, cp2, s, e)
		end
		
		s = e
	end
	
	return outputList
end

----------------------------------------
-- 3D

local function abovePlane(point, plane, plane_dir)
	return plane_dir:dot(point - plane) > 0
end

local function intersection3D(line_start, line_end, plane, plane_dir)
	local line = line_end - line_start
	local dot = plane_dir:dot(line)
	
	if math.abs(dot) < 1e-6 then return end
	
	return line_start + line * (-plane_dir:dot(line_start - plane) / dot)
end

local function clipPlane3D(poly, plane, plane_dir)
	local n = {}
	
	local last = poly[#poly]
	for _, cur in pairs(poly) do
		local a = abovePlane(last, plane, plane_dir)
		local b = abovePlane(cur, plane, plane_dir)
		
		if a and b then
			table.insert(n, cur)
		elseif a or b then
			table.insert(n, intersection3D(last, cur, plane, plane_dir))
			
			if b then
				table.insert(n, cur)
			end
		end
		
		last = cur
	end
	
	return n
end

----------------------------------------

return {
	inside = inside,
	intersection = intersection,
	clip = clip,
	clipPlane = clipPlane,
	
	-- 3D
	abovePlane = abovePlane,
	intersection3D = intersection3D,
	clipPlane3D = clipPlane3D
}