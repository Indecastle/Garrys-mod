local GUI = GUI

local circle = {}
for i = 1, 32 do
	local rad = i / 16 * math.pi
	circle[i] = {x = -math.sin(rad) / 2, y = math.cos(rad) / 2}
end


return {
	inherit = "label",
	constructor = function(self)
		self.style = 1
		
		self:_setTextHeight()
		self:_createShapePoly()
	end,
	
	----------------------------------------
	
	data = {
		_background_color = false,
		_active_color = false,
		_hover_color = false,
		
		_text = "%s",
		_draw_background = true,
		_animation_speed = false,
		_min = 0,
		_max = 1,
		_round = 2,
		_bar_size = 4,
		
		_value = 0,
		_progress = 0,
		_holding = false,
		_horizontal = true,
		_shape_poly = nil,
		
		------------------------------
		
		_createShapePoly = function(self)
			local stl, str, sbr, sbl = self:getCornerStyle()
			local ztl, ztr, zbr, zbl = self:getCornerSize()
			local w, h = self._w / 2, self._h / 2
			local poly = {}
			
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
			
			self._shape_poly = poly
		end,
		
		_sizeChanged = function(self)
			self._horizontal = self._w > self._h
			
			self:_createShapePoly()
		end,
		
		------------------------------
		
		_updateProgress = function(self)
			self._progress = (self._value - self._min) / (self._max - self._min)
		end,
		
		------------------------------
		
		_styles = {
			{
				_think = function(self, dt, cx, cy)
					local anim_speed = dt * self.animationSpeed
					
					self:_animationUpdate("hover", self._hovering, anim_speed, true)
					self:_animationUpdate("hold", self._holding, anim_speed, self._draw_background)
					
					if self._holding then
						if cx then
							local last = self._progress
							local progress = math.clamp(self._horizontal and ((cx - self._h / 2) / (self._w - self._h)) or (((self._h - cy) - self._w / 2) / (self._h - self._w)), 0, 1)
							self._value = math.round(progress * (self._max - self._min) + self._min, self._round)
							self:_updateProgress()
							
							if self._progress ~= last then
								self:onChange(self._value)
								self:_changed(self._draw_background)
							end
						end
						
						self:onHold()
					end
				end,
				
				onDraw = function(self, w, h)
					render.setMaterial()
					
					-- Background
					if self._draw_background then
						render.setColor(self.backgroundColor)
						render.drawRect(0, 0, w, h)
					end
					
					-- Bar
					local p = self._progress
					
					if self._horizontal then
						local bh = self._bar_size
						local bw = w - h + bh
						local bo = (h - bh) / 2
						
						render.setColor(self.activeColor)
						render.drawRect(bo, bo, bw * p, bh)
						
						render.setColor(self.mainColor)
						render.drawRect(bo + bw * p, bo, bw * (1 - p), bh)
					else
						local bh = self._bar_size
						local bw = h - w + bh
						local bo = (w - bh) / 2
						
						render.setColor(self.activeColor)
						render.drawRect(bo, bo + bw * (1 - p), bh, bw * p)
						
						render.setColor(self.mainColor)
						render.drawRect(bo, bo, bh, bw * (1 - p))
					end
					
					-- Knob
					local m = Matrix()
					m:setTranslation(self._horizontal and Vector((w - h) * p + h / 2, h / 2) or Vector(w / 2, (h - w) * (1 - p) + w / 2))
					m:setScale(Vector(self._horizontal and h or w))
					render.pushMatrix(m)
					render.setColor(GUI.lerpColor(self.activeColor, self.hoverColor, self:getAnimation("hover")))
					render.drawPoly(circle)
					render.popMatrix()
				end,
			},
			
			
			{
				_think = function(self, dt, cx, cy)
					local anim_speed = dt * self.animationSpeed
					
					self:_animationUpdate("hover", self._hovering, anim_speed, true)
					self:_animationUpdate("hold", self._holding, anim_speed, true)
					
					if self._holding then
						if cx then
							local last = self._progress
							local progress = math.clamp(self._horizontal and (cx / self._w) or ((self._h - cy) / self._h), 0, 1)
							self._value = math.round(progress * (self._max - self._min) + self._min, self._round)
							self._progress = (self._value - self._min) / (self._max - self._min)
							
							if self._progress ~= last then
								self:onChange(self._value)
								self:_changed(true)
							end
						end
						
						self:onHold()
					end
				end,
				
				onDraw = function(self, w, h)
					render.setMaterial()
					
					-- Bar
					local p = self._progress
					local hover = self:getAnimation("hover")
					local hcp = math.min(0.1, hover * 0.2)
					local clr = GUI.lerpColor(self.activeColor, self.hoverColor, hover)
					
					if hover > 0 then
						render.setColor(clr)
						if self._horizontal then
							render.drawRect(w * p, 0, w * (1 - p), h)
						else
							render.drawRect(0, 0, w, h * (1 - p))
						end
					end
					
					local m = Matrix()
					m:setTranslation(Vector(w / 2, h / 2))
					m:setScale(Vector(1 - hcp * (self._horizontal and (h / w) or 1), 1 - hcp * (self._horizontal and 1 or (w / h))))
					render.pushMatrix(m)
					render.setColor(self.mainColor)
					render.drawPoly(self._shape_poly)
					render.popMatrix()
					
					render.setColor(clr)
					if self._horizontal then
						render.drawRect(0, 0, w * p, h)
					else
						render.drawRect(0, h * (1 - p), w, h * p)
					end
					
					-- Text
					local ax, ay = self._text_alignment_x, self._text_alignment_y
					local th = self._text_height
					local tox, toy = self:getTextOffset()
					
					render.setFont(self.font)
					render.setColor(self.textColor)
					render.drawText(ax == 0 and tox or (ax == 1 and w / 2 or w - tox), ay == 3 and toy or (ay == 1 and ((self._h - self._text_height) / 2) or h - th - toy), string.format(self._text, self._value), ax)
				end
			}
		},
		
		------------------------------
		
		_think = function(self, dt, cx, cy)
			
		end,
		
		_press = function(self)
			self:onClick()
			
			self._holding = true
		end,
		
		_release = function(self)
			self:onRelease()
			
			self._holding = false
		end,
		
		_hover = function(self)
			self:onHover()
		end,
		
		_hoverStart = function(self)
			self:onHoverBegin()
			
			self:_cursorMode(GUI.CURSORMODE.CLICKABLE, GUI.CURSORMODE.NORMAL)
			self._hovering = true
		end,
		
		_hoverEnd = function(self)
			self:onHoverEnd()
			
			self:_cursorMode(GUI.CURSORMODE.NORMAL, GUI.CURSORMODE.CLICKABLE)
			self._hovering = false
		end,
		
		------------------------------
		
		onDraw = function(self, w, h)
			
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
		_is_visibly_translucent = {
			-- Not that you should ever parent anything to a checkbox, but just incase it has been done for some reason
			get = function(self)
				return not self._draw_background
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
				return clr and (type(clr) == "string" and self._theme[clr] or clr) or self._theme.primaryColorLight
			end
		},
		
		backgroundColor = {
			set = function(self, color)
				self._main_color = color
				
				self:_changed(true)
			end,
			
			get = function(self)
				local clr = self._background_color
				return clr and (type(clr) == "string" and self._theme[clr] or clr) or self._theme.primaryColorDark
			end
		},
		
		activeColor = {
			set = function(self, color)
				self._active_color = color
				
				self:_changed(true)
			end,
			
			get = function(self)
				local clr = self._active_color
				return clr and (type(clr) == "string" and self._theme[clr] or clr) or self._theme.secondaryColor
			end
		},
		
		hoverColor = {
			set = function(self, color)
				self._hover_color = color
				
				self:_changed(true)
			end,
			
			get = function(self)
				local clr = self._hover_color
				return clr and (type(clr) == "string" and self._theme[clr] or clr) or self._theme.secondaryColorLight
			end
		},
		
		------------------------------
		
		drawBackground = {
			set = function(self, state)
				self._draw_background = state
				
				self:_changed(state)
			end,
			
			get = function(self)
				return self._draw_background
			end
		},
		
		animationSpeed = {
			set = function(self, value)
				self._animation_speed = value
			end,
			
			get = function(self)
				return self._animation_speed or self._theme.animationSpeed
			end
		},
		
		min = {
			set = function(self, min)
				self._min = min or 0
				self:_updateProgress()
				
				self:_changed(true)
			end,
			
			get = function(self)
				return self._min
			end
		},
		
		max = {
			set = function(self, max)
				self._max = max or 1
				self:_updateProgress()
				
				self:_changed(true)
			end,
			
			get = function(self)
				return self._max
			end
		},
		
		range = {
			set = function(self, min, max)
				self._min = min or 0
				self._max = max or 1
				self:_updateProgress()
				
				self:_changed(true)
			end,
			
			get = function(self)
				return self._min, self._max
			end
		},
		
		round = {
			set = function(self, round)
				self._round = round
				self:_updateProgress()
				
				-- self:_changed(true)
			end,
			
			get = function(self)
				return self._round
			end
		},
		
		barSize = {
			set = function(self, value)
				self._bar_size = value
				
				self:_changed(true)
			end,
			
			get = function(self)
				return self._bar_size
			end
		},
		
		------------------------------
		
		value = {
			set = function(self, value)
				self._value = math.round(value, self._round)
				self:_updateProgress()
				
				self:_changed(true)
			end,
			
			get = function(self)
				return self._value
			end
		},
		
		------------------------------
		
		progress = {
			get = function(self)
				return self._progress
			end
		}
	}
	
}