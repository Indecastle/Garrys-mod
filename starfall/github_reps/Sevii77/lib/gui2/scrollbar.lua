local GUI = GUI

return {
	inherit = "container",
	constructor = function(self)
		
	end,
	
	----------------------------------------
	
	data = {
		_handle_color = false,
		_handle_active_color = false,
		_handle_hover_color = false,
		
		_animation_speed = false,
		_dynamic_handle_size = true,
		_handle_size = 10,
		_content_size = 1,
		
		_progress = 0,
		_value = 0,
		_horizontal = false,
		_holding = false,
		_hovering = false,
		_grabpos = false,
		_handle_poly = nil,
		
		------------------------------
		
		_createHandlePoly = function(self)
			local stl, str, sbr, sbl = self:getCornerStyle()
			local ztl, ztr, zbr, zbl = self:getCornerSize()
			ztl, ztr, zbr, zbl = ztl / 2, ztr / 2, zbr / 2, zbl / 2
			local poly = {}
			local w, h
			
			if self._horizontal then
				w, h = self._handle_size / 2 - self._h / 4, self._h / 2 - self._h / 4
			else
				w, h = self._w / 2 - self._w / 4, self._handle_size / 2 - self._w / 4
			end
			
			-- Top Left
			if stl == 0 then
				table.insert(poly, {x = -w, y = -h})
			else
				for i = 0, 9, stl == 1 and 1 or 9 do
					local rad = i / 18 * math.pi
					table.insert(poly, {x = ztl - math.cos(rad) * ztl - w, y = ztl - math.sin(rad) * ztl - h})
				end
			end
			
			-- Top Right
			if str == 0 then
				table.insert(poly, {x = w, y = -h})
			else
				for i = 9, 18, str == 1 and 1 or 9 do
					local rad = i / 18 * math.pi
					table.insert(poly, {x = w - ztr - math.cos(rad) * ztr, y = ztr - math.sin(rad) * ztr - h})
				end
			end
			
			-- Bottom Right
			if sbr == 0 then
				table.insert(poly, {x = w, y = h})
			else
				for i = 18, 27, sbr == 1 and 1 or 9 do
					local rad = i / 18 * math.pi
					table.insert(poly, {x = w - zbr - math.cos(rad) * zbr, y = h - zbr - math.sin(rad) * zbr})
				end
			end
			
			-- Bottom Left
			if sbl == 0 then
				table.insert(poly, {x = -w, y = h})
			else
				for i = 27, 36, sbl == 1 and 1 or 9 do
					local rad = i / 18 * math.pi
					table.insert(poly, {x = zbl - math.cos(rad) * zbl - w, y = h - zbl - math.sin(rad) * zbl})
				end
			end
			
			self._handle_poly = poly
		end,
		
		_sizeChanged = function(self)
			self._horizontal = self._w > self._h
			
			self:_createHandlePoly()
		end,
		
		------------------------------
		
		_think = function(self, dt, cx, cy)
			local anim_speed = dt * self.animationSpeed
			
			self:_animationUpdate("hover", self._hovering, anim_speed, true)
			self:_animationUpdate("hold", self._holding, anim_speed, true)
			
			-- Scroll
			if self._dynamic_handle_size then
				local last = self._handle_size
				self._handle_size = self._horizontal and math.min(self._w, self._w / self._content_size * self._w) or math.min(self._h, self._h / self._content_size * self._h)
				
				if last ~= self._handle_size then
					self:_createHandlePoly()
					self:_changed(true)
				end
			end
			
			if cx and self._holding then
				if self._horizontal then
					local last = self._value
					self._progress = math.clamp(((cx - (self.grabpos or 0)) - self._handle_size / 2) / (self._w - self._handle_size), 0, 1)
					self._value = math.floor(self._progress * math.max(0, self._content_size - self._w))
					
					if last ~= self._value then
						self:onChange(self._value)
						self:_changed(true)
					end
				else
					local last = self._value
					self._progress = math.clamp(((cy - (self.grabpos or 0)) - self._handle_size / 2) / (self._h - self._handle_size), 0, 1)
					self._value = math.floor(self._progress * math.max(0, self._content_size - self._h))
					
					if last ~= self._value then
						self:onChange(self._value)
						self:_changed(true)
					end
				end
			end
		end,
		
		_press = function(self)
			self._holding = true
			
			local x, y = self._gui:getCursorPos(self)
			if x then
				if self._horizontal then
					local p = self._value / math.max(1, self._content_size - self._w) * (self._w - self._handle_size)
					
					if x > p and x < p + self._handle_size then
						self.grabpos = x - p - self._handle_size / 2
					end
				else
					local p = self._value / math.max(1, self._content_size - self._h) * (self._h - self._handle_size)
					
					if y > p and y < p + self._handle_size then
						self.grabpos = y - p - self._handle_size / 2
					end
				end
			end
			
			self:onClick()
		end,
		
		_release = function(self)
			self._holding = false
			self._grabpos = false
			
			self:onRelease()
		end,
		
		_hover = function(self)
			self:onHover()
		end,
		
		_hoverStart = function(self)
			self._hovering = true
			
			self:_cursorMode(GUI.CURSORMODE.CLICKABLE, GUI.CURSORMODE.NORMAL)
			self:onHoverBegin()
		end,
		
		_hoverEnd = function(self)
			self._hovering = false
			
			self:_cursorMode(GUI.CURSORMODE.NORMAL, GUI.CURSORMODE.CLICKABLE)
			self:onHoverEnd()
		end,
		
		
		------------------------------
		
		onDraw = function(self, w, h)
			render.setMaterial()
			
			base()
			
			local m = Matrix()
			if self._horizontal then
				m:setTranslation(Vector(self._value / math.max(1, self._content_size - self._w) * (w - self._handle_size) + self._handle_size / 2, h / 2))
			else
				m:setTranslation(Vector(w / 2, self._value / math.max(1, self._content_size - self._h) * (h - self._handle_size) + self._handle_size / 2))
			end
			render.pushMatrix(m)
			render.setColor(GUI.lerpColor(GUI.lerpColor(self.handleColor, self.handleHoverColor, self:getAnimation("hover")), self.handleActiveColor, self:getAnimation("hold")))
			render.drawPoly(self._handle_poly)
			render.popMatrix()
			
			-- render.setColor(GUI.lerpColor(self.handleColor, self.handleHoverColor, self:getAnimation("hover")))
			-- render.drawRect(0, self._value / math.max(1, self._content_size - self._h) * (h - self._handle_size), w, self._handle_size)
		end,
		
		onClick = function(self) end,
		onHold = function(self) end,
		onRelease = function(self) end,
		onHoverBegin = function(self) end,
		onHoverEnd = function(self) end,
		onHover = function(self) end,
		onChange = function(self, value) end
	},
	
	----------------------------------------
	
	properties = {
		mainColor = {
			set = function(self, color)
				self._main_color = color
				
				self:_changed(true)
			end,
			
			get = function(self)
				local clr = self._main_color
				return clr and (type(clr) == "string" and self._theme[clr] or clr) or self._theme.primaryColorDark
			end
		},
		
		handleColor = {
			set = function(self, color)
				self._handle_color = color
				
				self:_changed(true)
			end,
			
			get = function(self)
				local clr = self._handle_color
				return clr and (type(clr) == "string" and self._theme[clr] or clr) or self._theme.secondaryColor
			end
		},
		
		handleActiveColor = {
			set = function(self, color)
				self._handle_active_color = color
				
				self:_changed(true)
			end,
			
			get = function(self)
				local clr = self._handle_active_color
				return clr and (type(clr) == "string" and self._theme[clr] or clr) or self._theme.secondaryColorDark
			end
		},
		
		handleHoverColor = {
			set = function(self, color)
				self._handle_hover_color = color
				
				self:_changed(true)
			end,
			
			get = function(self)
				local clr = self._handle_hover_color
				return clr and (type(clr) == "string" and self._theme[clr] or clr) or self._theme.secondaryColorLight
			end
		},
		
		------------------------------
		
		animationSpeed = {
			set = function(self, value)
				self._animation_speed = value
			end,
			
			get = function(self)
				return self._animation_speed or self._theme.animationSpeed
			end
		},
		
		dynamicHandleSize = {
			set = function(self, state)
				self._dynamic_handle_size = state
			end,
			
			get = function(self)
				return self._dynamic_handle_size
			end
		},
		
		handleSize = {
			set = function(self, value)
				self._handle_size = value
				
				self:_createHandlePoly()
				self:_changed(true)
			end,
			
			get = function(self)
				return self._handle_size
			end
		},
		
		contentSize = {
			set = function(self, value)
				self._content_size = value
				
				if self._horizontal then
					self._value = math.floor(self._progress * math.max(0, self._content_size - self._w))
				else
					self._value = math.floor(self._progress * math.max(0, self._content_size - self._h))
				end
				
				self:onChange(self._value)
				self:_changed(true)
			end,
			
			get = function(self)
				return self._content_size
			end
		},
		
		------------------------------
		
		value = {
			set = function(self, value)
				self._value = value
				self._progress = value / math.max(0.0001, self._content_size - (self._horizontal and self._w or self._h))
				
				self:_changed(true)
			end,
			
			get = function(self)
				return self._value
			end
		}
	}
	
}