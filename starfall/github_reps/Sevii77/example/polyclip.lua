--@name Polyclip Example
--@client
--@include ../lib/polyclip.lua

local poly = {Vector(50, 50), Vector(500, 300), Vector(200, 350)}
local clip = {Vector(156, 156), Vector(356, 156), Vector(356, 356), Vector(156, 356)}

local polyclip = require("../lib/polyclip.lua")
local vertices = polyclip.clip(poly, clip)

hook.add("render", "", function()
	for i, pos in pairs(clip) do
		local next = clip[i % #clip + 1]
		render.drawLine(next.x, next.y, pos.x, pos.y)
	end
	
	render.setRGBA(255, 0, 0, 255)
	for i, pos in pairs(poly) do
		local next = poly[i % #poly + 1]
		render.drawLine(next.x, next.y, pos.x, pos.y)
	end
	
	render.setRGBA(0, 255, 0, 255)
	for i, pos in pairs(vertices) do
		local next = vertices[i % #vertices + 1]
		render.drawLine(next.x, next.y, pos.x, pos.y)
	end
end)
