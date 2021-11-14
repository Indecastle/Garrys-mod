--@name Simplex 2D Example
--@client
--@include ../lib/noise/simplex2d.lua

local size = 64
local scale = 5 / size
local simplex = require("../lib/noise/simplex2d.lua")

----------------------------------------

render.createRenderTarget("")
hook.add("render", "", function()
	render.setRenderTargetTexture("")
	render.drawTexturedRect(0, 0, 1024 / size * 512, 1024 / size * 512)
end)


local draw = coroutine.create(function()
	local x, y = 0, 0
	
	for y = 0, size - 1 do
		for x = 0, size - 1 do
			local clr = simplex(x * scale, y * scale) * 128 + 128
			
			render.setRGBA(clr, clr, clr, 255)
			render.drawRect(x, y, 1, 1)
			
			if math.max(quotaAverage(), quotaUsed()) / quotaMax() > 0.95 then
				coroutine.yield()
			end
		end
	end
	
	return true
end)

hook.add("render", "draw", function()
	render.selectRenderTarget("")
	if coroutine.resume(draw) then
		hook.remove("render", "draw")
	end
end)
