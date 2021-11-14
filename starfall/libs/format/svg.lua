--@include ./xml.lua
--@include ../enum/color.lua
--@include ../bezier.lua
--@include ../earclip.lua

local xml = require("./xml.lua")
local colors = require("../enum/color.lua")
local bezier = require("../bezier.lua")
local earclip = require("../earclip.lua")

local svg = {quality = 10} -- units per segment
local cache = {}
local id_list = {}

--[[
	Version 0.1
	
	Currently this only supports the basics of basics like most fontawesome objects
	
	TODO:
	more object types
	more other stuff
	stroke support for most objects
]]

----------------------------------------

function svg.drawSVG(id, x, y, w, h, maintain_aspect)
	assert(id_list[id], "svg by id of " .. id .. " does not exist")
	
	id_list[id](x, y, w, h, maintain_aspect)
end

function svg.drawSVGRotated(id, x, y, w, h, r, maintain_aspect)
	assert(id_list[id], "svg by id of " .. id .. " does not exist")
	
	id_list[id](x, y, w, h, maintain_aspect)
end

function svg.drawSVGRaw(x, y, w, h, maintain_aspect, svg_data)
	local svg_data = svg_data or maintain_aspect
	local sum = crc(svg_data)
	local draw = cache[sum]
	
	if not draw then
		draw = svg.createSVGDrawFunction(svg_data)
		cache[sum] = draw
	end
	
	draw(x, y, w, h, svg_data and maintain_aspect or nil)
end

function svg.registerSVG(id, svg_data)
	local sum = crc(svg_data)
	cache[sum] = svg.createSVGDrawFunction(svg_data)
	id_list[id] = cache[sum]
end

----------------------------------------

if not render.getColor then -- Have a way to get current draw color
	local current_color = Color(255, 255, 255)
	
	local render_setColor = render.setColor
	function render.setColor(color)
		current_color = color
		
		render_setColor(color)
	end
	
	local render_setRGBA = render.setRGBA
	function render.setRGBA(r, g, b, a)
		current_color = Color(r, g, b, a)
		
		render_setRGBA(r, g, b, a)
	end
	
	function render.getColor()
		return current_color
	end
end

----------------------------------------

local current_color
local function getColor(color)
	if not color then return end
	
	if string.lower(color) == "currentcolor" then
		return render.getColor()
	elseif color[1] == "#" then
		local color = string.sub(color, 2)
		
		if #color == 3 then
			return Color(tonumber("0x" .. color[1]) * 17, tonumber("0x" .. color[2]) * 17, tonumber("0x" .. color[3]) * 17)
		else
			return Color(tonumber("0x" .. string.sub(color, 1, 2)), tonumber("0x" .. string.sub(color, 3, 4)), tonumber("0x" .. string.sub(color, 5, 6)))
		end
	else
		return colors[string.lower(color)] or render.getColor()
	end
end

local objects = {
	rect = {
		create = function(data)
			return {
				x = data.x,
				y = data.y,
				w = data.width,
				h = data.height,
				--stroke = data.stroke,
				fill = getColor(data.fill) and data.fill
			}
		end,
		draw = function(data)
			if data.fill then
				render.setColor(getColor(data.fill))
				render.drawRect(data.x, data.y, data.w, data.h)
			end
		end
	},
	
	circle = {
		create = function(data)
			local fill = getColor(data.fill)
			local poly = {}
			if fill then
				local x, y, r = data.cx, data.cy, data.r
				local segments = math.min(math.ceil(r / svg.quality), 16) * 4
				for i = 1, segments do
					local rad = i / segments * math.pi * 2
					
					table.insert(poly, {
						x = x + math.sin(rad) * r,
						y = y - math.cos(rad) * r
					})
				end
			end
			
			return {
				poly = poly,
				--stroke = data.stroke,
				fill = fill and data.fill
			}
		end,
		draw = function(data)
			if data.fill then
				render.setColor(getColor(data.fill))
				render.drawPoly(data.poly)
			end
		end
	},
	
	line = {
		create = function(data)
			return {
				x = data.x1,
				y = data.y1,
				x2 = data.x2,
				y2 = data.y2,
				stroke = getColor(data.stroke) and data.stroke
			}
		end,
		draw = function(data)
			if data.stroke then
				render.setColor(getColor(data.stroke))
				render.drawLine(data.x, data.y, data.x2, data.y2)
			end
		end,
	},
	
	polyline = {
		create = function(data)
			local stroke = getColor(data.stroke)
			local points = {}
			if stroke then
				for x, y in string.gmatch(data.points, "(%d+),(%d+)") do
					table.insert(points, {
						x = x,
						y = y
					})
				end
			end
			
			return {
				points = points,
				stroke = stroke and data.stroke,
				--fill = data.fill
			}
		end,
		draw = function(data)
			if data.stroke then
				render.setColor(getColor(data.stroke))
				
				local lx, ly
				for i, pos in pairs(data.points) do
					local x, y = pos.x, pos.y
					
					if lx then
						render.drawLine(lx, ly, x, y)
					end
					
					lx, ly = x, y
				end
			end
		end
	},
	
	path = {
		create = function(data)
			local path, points, segment, pos, current_point = data.d, {}, {}, 1, Vector()
			while true do
				local s, e, cmd, data = string.find(path, "(%a)([%A]*)", pos)
				if not s then break end
				pos = s + 1
				
				local cmdt = string.lower(cmd)
				if cmdt == "m" then -- moveto
					local x, y = string.match(data, "(%-?%d+%.?%d*)[%s,]*(%-?%d+%.?%d*)")
					x, y = tonumber(x), tonumber(y)
					
					if cmdt == cmd then
						x = current_point.x + x
						y = current_point.y + y
					end
					
					segment = {Vector(x, y)}
					current_point = Vector(x, y)
				elseif cmdt == "z" then -- closepath
					table.insert(points, segment)
					current_point = segment[1]
				elseif cmdt == "l" then -- lineto
					for x, y in string.gmatch(data, "(%-?%d+%.?%d*)[%s,]*(%-?%d+%.?%d*)") do
						local x, y = tonumber(x), tonumber(y)
						
						if cmdt == cmd then
							x = current_point.x + x
							y = current_point.y + y
						end
						
						table.insert(segment, Vector(x, y))
						current_point = Vector(x, y)
					end
				elseif cmdt == "h" then -- horizontal lineto
					for x in string.gmatch(data, "(%-?%d+%.?%d*)") do
						local x, y = tonumber(x), current_point.y
						
						if cmdt == cmd then
							x = current_point.x + x
						end
						
						table.insert(segment, Vector(x, y))
						current_point = Vector(x, y)
					end
				elseif cmdt == "v" then -- vertical lineto
					for y in string.gmatch(data, "(%-?%d+%.?%d*)") do
						local x, y = current_point.x, tonumber(y)
						
						if cmdt == cmd then
							y = current_point.y + y
						end
						
						table.insert(segment, Vector(x, y))
						current_point = Vector(x, y)
					end
				elseif cmdt == "c" then -- curveto
					local p, i = {current_point}, 0
					for x, y in string.gmatch(data, "(%-?%d+%.?%d*)[%s,]*(%-?%d+%.?%d*)") do
						local x, y = tonumber(x), tonumber(y)
						
						if cmdt == cmd then
							x = current_point.x + x
							y = current_point.y + y
						end
						
						table.insert(p, Vector(x, y))
						
						i = i + 1
						if i == 3 then
							local a, b, c, d = p[1], p[2], p[3], p[4]
							local dist = Vector(b.x - a.x + c.x - b.x + d.x - c.x, b.y - a.y + c.y - b.y + d.y - c.y):getLength2D()
							local segments = math.min(math.ceil(dist / svg.quality), 16)
							for i = 1, segments - 1 do
								local pos = bezier.cubic(a, b, c, d, i / segments)
								table.insert(segment, pos)
							end
							
							i = 0
							current_point = Vector(x, y)
						end
					end
				elseif cmdt == "s" then -- smooth curveto
					
				elseif cmdt == "q" then -- quadratic Bézier curveto
					
				elseif cmdt == "t" then -- smooth quadratic Bézier curveto
					
				elseif cmdt == "a" then -- elliptical arc
					for rx, ry, rot, arch_flag, sweep_flag, x, y in string.gmatch(data, "(%-?%d+%.?%d*)[%s,]*(%-?%d+%.?%d*)[%s,]*(%-?%d+%.?%d*)[%s,]*(%-?%d+%.?%d*)[%s,]*(%-?%d+%.?%d*)[%s,]*(%-?%d+%.?%d*)[%s,]*(%-?%d+%.?%d*)") do
						local x, y = tonumber(x), tonumber(y)
						
						if cmdt == cmd then
							x = current_point.x + x
							y = current_point.y + y
						end
						
						table.insert(segment, Vector(x, y))
						current_point = Vector(x, y)
					end
				end
			end
			
			local fill = getColor(data.fill)
			local polygons = {}
			if fill then
				for i, segment in pairs(points) do
					local total = 0
					for i2, point in pairs(segment) do
						local ang = earclip.getPointsAngle(point, segment[(i2 - 2) % #segment + 1], segment[i2 % #segment + 1])
						total = total + (ang - math.pi)
					end
					
					for i2, poly in pairs(earclip.getTriangles(segment, total > 0)) do
						table.insert(polygons, poly)
					end
				end
			end
			
			return {
				points = points,
				polygons = polygons,
				stroke = getColor(data.stroke) and data.stroke,
				fill = fill and data.fill
			}
		end,
		draw = function(data, matrix)
			if data.fill then
				render.setColor(getColor(data.fill))
				
				for i, poly in pairs(data.polygons) do
					render.drawPoly(poly)
					--render.drawLine(poly[1].x, poly[1].y, poly[2].x, poly[2].y)
					--render.drawLine(poly[3].x, poly[3].y, poly[2].x, poly[2].y)
					--render.drawLine(poly[1].x, poly[1].y, poly[3].x, poly[3].y)
				end
			end
			
			if data.stroke then
				render.setColor(getColor(data.stroke))
				
				for i, segment in pairs(data.points) do
					for i2, pos in pairs(segment) do
						local next = segment[i2 % #segment + 1]
						render.drawLine(pos.x, pos.y, next.x, next.y)
					end
				end
			end
		end
	}
}

function svg.createSVGDrawFunction(svg_data)
	local objs = {}
	
	local svg_data = xml.xmlToTable(svg_data)
	
	local function doChildren(tbl)
		for _, object in pairs(tbl) do
			if object.type == "g" then
				doChildren(object.children)
			else
				local func = objects[object.type]
				if func then
					table.insert(objs, {
						func = func.draw,
						data = func.create(object.attributes)
					})
				end
			end
		end
	end
	
	doChildren(svg_data[1].children)
	
	local viewbox = string.split(svg_data[1].attributes.viewBox, " ")
	local vx, vy, vw, vh = tonumber(viewbox[1]), tonumber(viewbox[2]), tonumber(viewbox[3]), tonumber(viewbox[4])
	return function(x, y, w, h, maintain_aspect)
		local vx, vy, vw, vh = vx, vy, vw, vh
		if maintain_aspect then
			local ox, oy = math.min(0, (vw - vx) - (vh - vy)), math.min(0, (vh - vy) - (vw - vx))
			vx = vx + ox / 2
			vy = vy + oy / 2
			vw = vw - ox
			vh = vh - oy
		end
		
		local sw, sh = w / (vw - vx), h / (vh - vy)
		local m = Matrix()
		m:setTranslation(Vector(x, y))
		m:setScale(Vector(sw, sh))
		m:translate(Vector(-vx, -vy))
		
		current_color = render.getColor()
		
		render.pushMatrix(m)
		for _, data in pairs(objs) do
			--data.func(data.data, svg.quality / math.max(sw, sh))
			data.func(data.data, m)
		end
		render.popMatrix()
	end
end

----------------------------------------

return svg