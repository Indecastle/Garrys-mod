--@include ./core.lua
--@include ../binpacker.lua

local binpacker = require("../binpacker.lua")

local atlas = require("./core.lua")
local renders = {}
local sheets = {}
local queue = {}

----------------------------------------

hook.add("renderoffscreen", "lib_atlas_render", function()
	for _, func in pairs(queue) do
		func()
	end
	
	queue = {}
end)

local function createSheet()
	local rt_id = "lib_atlas_render_rt_" .. (#sheets + 1)
	table.insert(sheets, {
		packer = binpacker(1024, 1024),
		rt = rt_id
	})
	
	table.insert(queue, function()
		render.createRenderTarget(rt_id)
		render.selectRenderTarget(rt_id)
		render.clear(Color(0, 0, 0, 0))
		render.selectRenderTarget()
	end)
	
	--[[local id = "lib_icon_sheet_" .. #sheets
	hook.add("renderoffscreen", id, function()
		render.createRenderTarget(rt_id)
		render.selectRenderTarget(rt_id)
		render.clear(Color(0, 0, 0, 0), true)
		render.selectRenderTarget()
		
		hook.remove("renderoffscreen", id)
	end)]]
end

----------------------------------------

function atlas.drawRender(id, x, y, w, h, u1, v1, u2, v2)
	assert(renders[id], "Render with id of " .. id .. " doesn't exists")
	
	local u1, v1, u2, v2 = u1 or 0, v1 or 0, u2 or 1, v2 or 1
	local rndr = renders[id]
	
	render.setRenderTargetTexture(rndr.rt)
	render.drawTexturedRectUV(x, y, w, h, rndr.u + u1 * rndr.w, rndr.v + v1 * rndr.h, rndr.u + u2 * rndr.w, rndr.v + v2 * rndr.h)
	render.setRenderTargetTexture()
end

function atlas.getRender(id)
	return renders[id]
end

function atlas.registerRender(id, w, h, render_func)
	assert(not renders[id], "Render with id of " .. id .. " already exists")
	assert(w <= 1024 and h <= 1024, "Max size is 1024x1024, given size is " .. w .. "x" .. h)
	
	if #sheets == 0 then
		createSheet()
	end
	
	local sheet = sheets[#sheets]
	local x, y = sheet.packer:insert(w, h)
	if not x then
		createSheet()
		
		sheet = sheets[#sheets]
		x, y = sheet.packer:insert(w, h)
	end
	
	table.insert(queue, function()
		local m = Matrix()
		m:setTranslation(Vector(x, y))
		
		render.enableScissorRect(x, y, x + w, y + h)
		render.pushMatrix(m)
		render.selectRenderTarget(sheet.rt)
		render_func()
		render.selectRenderTarget()
		render.popMatrix()
		render.disableScissorRect()
	end)
	
	renders[id] = {
		u = x / 1024,
		v = y / 1024,
		w = w / 1024,
		h = h / 1024,
		rt = sheet.rt
	}
end

----------------------------------------

return atlas