--@include ../class.lua

local class, checktype = unpack(require("../class.lua"))

----------------------------------------

local cur_index = 0
local screens = {}

local function linePlane(line_start, line_end, plane, plane_normal)
	local line = line_end - line_start
	local dot = plane_normal:dot(line)
	
	if math.abs(dot) < 1e-6 then return end
	
	return line_start + line * (-plane_normal:dot(line_start - plane) / dot)
end

local render_original = {
	getResolution = render.getResolution,
	getScreenEntity = render.getScreenEntity,
	getScreenInfo = render.getScreenInfo,
	setBackgroundColor = rendersetBackgroundColor,
	cursorPos = render.cursorPos
}

local render_override = {
	getResolution = function(self)
		return self.width, self.height
	end,
	
	getScreenEntity = function(self)
		return self.holo
	end,
	
	getScreenInfo = function(self, ent)
		for index, screen in pairs(screens) do
			if screen.holo == ent then
				return {
					x2 = 0,
					RS = 0,
					rot = Angle(),
					Name = "",
					RatioX = self.width / self.height,
					y1 = 0,
					x1 = 0,
					offset = Vector(),
					z = 0,
					y2 = 0
				}
			end
		end
		
		return render_original.getScreenInfo(ent)
	end,
	
	setBackgroundColor = function(self, color, screen)
		local screen = screen or self
		
		if screen == self then
			self.bg_color = color
		else
			for index, scr in pairs(screens) do
				if scr == screen then
					screen.bg_color = color
					
					return
				end
			end
			
			render_original.setBackgroundColor(color, screen)
		end
	end,
	
	cursorPos = function(self, ply, screen)
		local ply = ply or player()
		
		if not screen then
			if not self.holo then return end
			
			local tr = ply:getEyeTrace()
			local p = self.holo:getPos()
			
			local pos = linePlane(tr.StartPos, tr.HitPos, p, self.holo:getUp())
			
			if not pos then return end
			
			pos = self.holo:worldToLocal(pos)
			
			return pos.x / self.size.x * self.width + self.width / 2, -pos.y / self.size.y * self.height + self.height / 2
		end
		
		for index, screen in pairs(screens) do
			if screen.holo == ent then
				if not screen.holo then return end
				
				local tr = ply:getEyeTrace()
				local p = screen.holo:getPos()
				
				local pos = linePlane(tr.StartPos, tr.HitPos, p, screen.holo:getUp())
				
				if not pos then return end
				
				pos = screen.holo:worldToLocal(pos)
				
				return pos.x / screen.size.x * screen.width + screen.width / 2, -pos.y / screen.size.y * screen.height + screen.height / 2
			end
		end
		
		return render_original.cursorPos(ply, screen)
	end
}

----------------------------------------

local Screen
Screen = class {
	type = "3dscreen",
	
	constructor = function(self, pos, ang, size)
		cur_index = cur_index + 1
		self.index = cur_index
		self.id = "3dscreen" .. cur_index
		render.createRenderTarget(self.id)
		
		self.width = 512 * math.max(size.x / size.y, 1)
		self.height = 512 * math.max(size.y / size.x, 1)
		self.size = size
		self.bg_color = Color(0, 0, 0)
		
		local u = self.width / 1024
		local v = self.height / 1024
		local p1 = {pos = Vector(-3, -3, 0), normal = Vector(0, 0, 1), u = 0, v = v}
		local p2 = {pos = Vector( 3, -3, 0), normal = Vector(0, 0, 1), u = u, v = v}
		local p3 = {pos = Vector( 3,  3, 0), normal = Vector(0, 0, 1), u = u, v = 0}
		local p4 = {pos = Vector(-3,  3, 0), normal = Vector(0, 0, 1), u = 0, v = 0}
		self.mesh = mesh.createFromTable({p2, p1, p4, p3, p2, p4})
		
		self.material = material.create("UnlitGeneric")
		self.material:setInt("$flags", 0x0100 + 0x0010)
		self.material:setTextureRenderTarget("$basetexture", self.id)
		
		local s = Vector(size.x, size.y, 1)
		self.holo = holograms.create(pos, ang, "models/sprops/cuboids/height06/size_1/cube_6x6x6.mdl", s / 6)
		self.holo:setRenderBounds(-s / 2, s / 2)
		self.holo:setMesh(self.mesh)
		self.holo:setMeshMaterial(self.material)
		
		screens[cur_index] = self
		
		hook.add("renderoffscreen", "lib_3dscreen" .. self.id, function()
			if not self.enabled then return end
			if self.mirrored then return end
			
			render.selectRenderTarget(self.id)
			
			if self.clear then
				render.clear(self.bg_color)
			end
			
			-- Override screen related functions
			for name, func in pairs(render_override) do
				render[name] = function(...)
					return func(self, ...)
				end
			end
			
			self.render()
			
			-- Reset the overwritten functions
			for name, func in pairs(render_original) do
				render[name] = func
			end
		end)
	end,
	
	----------------------------------------
	
	data = {
		index = 0,
		id = "",
		size = false,
		width = 512,
		height = 512,
		mirrored = false,
		enabled = true,
		clear = true,
		bg_color = 0,
		render = function() end,
		
		------------------------------
		
		__tostring = function(self)
			return self.id .. " " .. self.width .. "x" .. self.height
		end,
		
		------------------------------
		
		mirror = function(self, screen)
			if screen then
				self.mirrored = screen
				
				if self.material then
					render.destroyRenderTarget(self.id)
					
					self.material:destroy()
					self.material = nil
				end
				
				if self.holo then
					self.holo:setMeshMaterial(screen.material)
				end
			else
				self.mirrored = false
				
				if not self.material then
					render.createRenderTarget(self.id)
					
					self.material = material.create("UnlitGeneric")
					self.material:setInt("$flags", 0x0100 + 0x0010)
					self.material:setTextureRenderTarget("$basetexture", self.id)
				end
				
				if self.holo then
					self.holo:setMeshMaterial(self.material)
				end
			end
			
			return self
		end,
		
		setEnabled = function(self, state)
			self.enabled = state and true or false
			
			return self
		end,
		
		setClear = function(self, state)
			self.clear = state and true or false
			
			return self
		end,
		
		setClearColor = function(self, color)
			self.bg_color = color
			
			if self.material then
				if color.a ~= 255 then
					self.material:setInt("$flags", 0x0100 + 0x0010 + 0x2000)
				else
					self.material:setInt("$flags", 0x0100 + 0x0010)
				end
			end
			
			return self
		end,
		
		setRender = function(self, func)
			self.render = func
			
			return self
		end,
		
		------------------------------
		
		destroy = function(self)
			self.holo:remove()
			self.mesh:destroy()
			
			if self.material then
				self.material:destroy()
			end
			
			render.destroyRenderTarget(self.id)
			
			screens[self.index] = nil
		end,
		
		setPos = function(self, pos)
			self.holo:setPos(pos)
			
			return self
		end,
		
		setAngles = function(self, ang)
			self.holo:setAngles(ang)
			
			return self
		end,
		
		setSize = function(self, size)
			self.holo:setScale(Vector(size.x, size.y, 1) / 6)
			self.mesh:destroy()
			
			local u = self.width / 1024
			local v = self.height / 1024
			local p1 = {pos = Vector(-3, -3, 0), normal = Vector(0, 0, 1), u = 0, v = 0}
			local p2 = {pos = Vector( 3, -3, 0), normal = Vector(0, 0, 1), u = u, v = 0}
			local p3 = {pos = Vector( 3,  3, 0), normal = Vector(0, 0, 1), u = u, v = v}
			local p4 = {pos = Vector(-3,  3, 0), normal = Vector(0, 0, 1), u = 0, v = v}
			self.mesh = mesh.createFromTable({p2, p1, p4, p3, p2, p4})
			
			return self
		end,
		
		setParent = function(self, ent, attachment)
			self.holo:setParent(ent, attachment)
			
			return self
		end,
	},
	
	----------------------------------------
	
	properties = {
		
	},
	
	----------------------------------------
	
	static_data = {
		
	},
	
	----------------------------------------
	
	static_properties = {
		new = Screen,
		canCreate = holograms.canSpawn,
		screensLeft = holograms.hologramsLeft
	}
}

return Screen
