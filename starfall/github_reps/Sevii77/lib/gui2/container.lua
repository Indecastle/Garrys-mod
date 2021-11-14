local GUI = GUI

local slant = {
	{x = 0, y = 0},
	{x = 1, y = 0},
	{x = 0, y = 1}
}

local curve = {{x = 0, y = 0}}
for i = 0, 9 do
	local rad = i / 18 * math.pi
	table.insert(curve, {x = 1 - math.sin(rad), y = 1 - math.cos(rad)})
end


return {
	inherit = "base",
	constructor = function(self)
		-- self:_createShapePoly()
	end,
	
	----------------------------------------
	
	data = {
		_is_visibly_translucent = false,
		
		_corner_style = {},
		_corner_size = {},
		_border_size = false,
		_clamp_corner_size = true,
		
		_main_color = false,
		
		------------------------------
		
		_customRenderMask = function(self, w, h)
			-- render.drawPoly(self._mask_poly)
			
			local stl, str, sbr, sbl = self:getCornerStyle()
			local ztl, ztr, zbr, zbl = self:getCornerSize()
			
			-- Top Left
			if stl ~= 0 then
				local m = Matrix()
				m:setScale(Vector(ztl))
				
				render.pushMatrix(m)
				render.drawPoly(stl == 1 and curve or slant)
				render.popMatrix()
			end
			
			-- Top Right
			if str ~= 0 then
				local m = Matrix()
				m:setTranslation(Vector(w, 0))
				m:setAngles(Angle(0, 90, 0))
				m:setScale(Vector(ztr))
				
				render.pushMatrix(m)
				render.drawPoly(str == 1 and curve or slant)
				render.popMatrix()
			end
			
			-- Bottom Right
			if sbr ~= 0 then
				local m = Matrix()
				m:setTranslation(Vector(w, h))
				m:setAngles(Angle(0, 180, 0))
				m:setScale(Vector(zbr))
				
				render.pushMatrix(m)
				render.drawPoly(sbr == 1 and curve or slant)
				render.popMatrix()
			end
			
			-- Bottom Left
			if sbl ~= 0 then
				local m = Matrix()
				m:setTranslation(Vector(0, h))
				m:setAngles(Angle(0, 270, 0))
				m:setScale(Vector(zbl))
				
				render.pushMatrix(m)
				render.drawPoly(sbl == 1 and curve or slant)
				render.popMatrix()
			end
		end,
		
		_customInputMask = function(self, cx, cy)
			local stl, str, sbr, sbl = self:getCornerStyle()
			local ztl, ztr, zbr, zbl = self:getCornerSize()
			local w, h = self._w, self._h
			
			local function out(x, y, s, z)
				if s == 0 then
					return false
				elseif s == 1 then
					-- https://i.imgur.com/uvhJnv9.png
					local x, y = math.abs(x / z), math.abs(y / z)
					
					if x > 1 or y > 1 then return false end
					
					local x, y = x - 1, y - 1
					if math.sqrt(x * x + y * y) < 1 then return false end
					
					return true
				else
					return math.abs(x) / z + math.abs(y) / z < 1
				end
			end
			
			if out(cx,     cy,     stl, ztl) then return false end
			if out(cx - w, cy,     str, ztr) then return false end
			if out(cx - w, cy - h, sbr, zbr) then return false end
			if out(cx,     cy - h, sbl, zbl) then return false end
			
			return true
		end,
		
		------------------------------
		
		onDraw = function(self, w, h)
			render.setColor(self.mainColor)
			render.drawRect(0, 0, w, h)
		end
	},
	
	----------------------------------------
	
	properties = {
		cornerStyle = {
			set = function(self, tl, tr, br, bl)
				if type(l) == "table" then
					self._corner_style = {tl = tl.tl, tr = tl.tr, br = tl.br, bl = tl.bl}
				else
					self._corner_style = {tl = tl, tr = tr or tl, br = br or tl, bl = bl or tl}
				end
				
				self:_changed(true)
			end,
			
			get = function(self)
				local t = self._corner_style
				local d = self._theme.cornerStyle
				
				return t.tl or d, t.tr or d, t.br or d, t.bl or d
			end
		},
		
		cornerSize = {
			set = function(self, tl, tr, br, bl)
				if type(l) == "table" then
					self._corner_size = {tl = tl.tl, tr = tl.tr, br = tl.br, bl = tl.bl}
				else
					self._corner_size = {tl = tl, tr = tr or tl, br = br or tl, bl = bl or tl}
				end
				
				self:_changed(true)
			end,
			
			get = function(self)
				local t = self._corner_size
				local d = self._theme.cornerSize
				
				if self._clamp_corner_size then
					d = math.min(d, self._w / 2, self._h / 2)
				end
				
				return t.tl or d, t.tr or d, t.br or d, t.bl or d
			end
		},
		
		clampCorner = {
			set = function(self, state)
				self._clamp_corner_size = state
				
				self:_changed()
			end,
			
			get = function(self)
				return self._clamp_corner_size
			end
		},
		
		------------------------------
		
		mainColor = {
			set = function(self, color)
				self._main_color = color
				
				self:_changed(true)
			end,
			
			get = function(self)
				local clr = self._main_color
				return clr and (type(clr) == "string" and self._theme[clr] or clr) or self._theme.primaryColor
			end
		}
	}
	
}