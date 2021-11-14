--@include ./enum/stencil.lua

local STENCIL = require("./enum/stencil.lua")

local stencil = {}

----------------------------------------

function stencil.pushMask(mask, invert)
	render.setStencilWriteMask(0xFF)
	render.setStencilTestMask(0xFF)
	render.setStencilReferenceValue(0)
	render.setStencilCompareFunction(8)
	render.setStencilPassOperation(1)
	render.setStencilFailOperation(1)
	render.setStencilZFailOperation(1)
	render.clearStencil()
	
	render.setStencilEnable(true)
	
	render.setStencilReferenceValue(1)
	render.setStencilCompareFunction(1)
	render.setStencilFailOperation(3)
	
	mask()
	
	render.setStencilCompareFunction(invert and STENCIL.EQUAL or STENCIL.NOTEQUAL)
	render.setStencilFailOperation(1)
end

function stencil.popMask()
	render.setStencilEnable(false)
end

----------------------------------------

return stencil