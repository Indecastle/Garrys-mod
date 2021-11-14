--@name Mirror
--@author Sevii (https://steamcommunity.com/id/dadamrival/)

-- This code doesnt work, need to fix someday

local fps = 30 -- The fps to run the mirror at, higher means more cpu time
local submaterial_replace_index = 6 -- Submaterial index to replace

----------------------------------------

if SERVER then
	
	wire.adjustInputs({"Mirror", "Reflect"}, {"ENTITY", "Entity"})
	
	net.receive("", function(_, ply)
		net.start("")
		net.writeUInt(wire.ports.Mirror:isValid() and wire.ports.Mirror:entIndex() or 0, 12)
		net.writeUInt(wire.ports.Reflect:isValid() and wire.ports.Reflect:entIndex() or 0, 12)
		net.send(ply)
	end)
	
else
	
	local mirror, reflect, mat_temp, mat_mirror
	
	-- Check if we have all permissions, if not dont do manything
	for _, perm in pairs({
		"material.create",
		"render.offscreen",
		"render.renderView",
		"render.renderscene"
	}) do
		if not hasPermission(perm) then return end
	end
	
	-- Send request to server for mirror entity
	net.start("")
	net.send()
	
	-- Receive mirror entity
	net.receive("", function()
		local index1 = net.readUInt(12)
		local index2 = net.readUInt(12)
		
		if index1 == 0 then return end
		if index2 == 0 then return end
		
		mirror = entity(index1)
		reflect = entity(index2)
		
		if not mirror or not mirror:isValid() then return end
		if not reflect or not reflect:isValid() then return end
		
		render.createRenderTarget("temp")
		mat_temp = material.create("gmodscreenspace")
		mat_temp:setTextureRenderTarget("$basetexture", "temp")
		
		render.createRenderTarget("mirror")
		mat_mirror = material.create("VertexLitGeneric")
		mat_mirror:setTextureRenderTarget("$basetexture", "mirror")
		
		mirror:setSubMaterial(submaterial_replace_index, "!" .. mat_mirror:getName())
		
		local last_render, do_render, w, h = 0, false, render.getGameResolution()
		hook.add("renderscene", "", function()
			if not do_render then return end
			if render.isInRenderView() then return end
			if not w then return end
			
			render.selectRenderTarget("temp")
			render.enableClipping(true)
			
			local clipNormal = reflect:getUp()
			render.pushCustomClipPlane(clipNormal, (reflect:getPos() + clipNormal):dot(clipNormal))
			
			local localOrigin = reflect:worldToLocal(eyePos())
			local reflectedOrigin = reflect:localToWorld(localOrigin * Vector(1, 1, -1))  
			
			local localAng = reflect:worldToLocalAngles(eyeAngles())
			local reflectedAngle = reflect:localToWorldAngles(Angle(-localAng.p, localAng.y, -localAng.r + 180))
			
			render.renderView({
				origin = reflectedOrigin,
				angles = reflectedAngle,
				aspectratio = w / h,
				x = 0,
				y = 0,
				w = 1024,
				h = 1024,
				drawviewmodel = false,
				drawviewer = true,
			})
			
			render.popCustomClipPlane()
			render.selectRenderTarget()
		end)
		
		hook.add("renderoffscreen", "", function()
			if last_render < timer.curtime() then
				do_render = true
				last_render = timer.curtime() + 1 / fps
			else
				do_render = false
			end
			
			if not do_render then return end
			
			--w, h = render.getGameResolution()
			--reflect = render.getScreenEntity()
			
			render.pushViewMatrix({type = "2D"})
			render.selectRenderTarget("mirror")
			render.setMaterial(mat_temp)
			render.drawTexturedRect(w, 0, -w, h)
			render.selectRenderTarget()
			render.popViewMatrix()
		end)
		
		hook.add("render", "", function()
			if not w then return end
			
			render.pushViewMatrix({type = "2D"})
			render.setMaterial(mat_temp)
			render.drawTexturedRect(w, 0, -w, h)
			render.popViewMatrix()
		end)
	end)
	
end