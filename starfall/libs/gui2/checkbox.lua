local GUI = GUI

local circle = {}
for i = 1, 32 do
	local rad = i / 16 * math.pi
	circle[i] = {x = -math.sin(rad) / 2, y = math.cos(rad) / 2}
end

local pill = {}
for i = 0, 16 do
	local rad = i / 16 * math.pi
	pill[i + 1] = {x = -math.sin(rad) / 2 + 0.5, y = math.cos(rad) / 2 + 0.5}
end
for i = 17, 32 do
	local rad = i / 16 * math.pi
	pill[i] = {x = -math.sin(rad) / 2 + 1.5, y = math.cos(rad) / 2 + 0.5}
end


return {
	inherit = "label",
	constructor = function(self)
		self.style = 1
		
		self:_setTextHeight()
		self:_createBoxPoly()
	end,
	
	----------------------------------------
	
	data = {
		_background_color = false,
		_active_color = false,
		_inactive_color = false,
		_hover_color = false,
		
		_draw_background = true,
		_animation_speed = false,
		_text_alignment_x = 0,
		
		_state = false,
		_box_poly = nil,
		
		------------------------------
		
		_createBoxPoly = function(self)
			local stl, str, sbr, sbl = self:getCornerStyle()
			local ztl, ztr, zbr, zbl = self:getCornerSize()
			local h = self._h / 2
			local poly = {}
			
			-- Top Left
			if stl == 0 then
				table.insert(poly, {x = -h, y = -h})
			else
				for i = 0, 9, stl == 1 and 1 or 9 do
					local rad = i / 18 * math.pi
					table.insert(poly, {x = ztl - math.cos(rad) * ztl - h, y = ztl - math.sin(rad) * ztl - h})
				end
			end
			
			-- Top Right
			if str == 0 then
				table.insert(poly, {x = h, y = -h})
			else
				for i = 9, 18, str == 1 and 1 or 9 do
					local rad = i / 18 * math.pi
					table.insert(poly, {x = h - ztr - math.cos(rad) * ztr, y = ztr - math.sin(rad) * ztr - h})
				end
			end
			
			-- Bottom Right
			if sbr == 0 then
				table.insert(poly, {x = h, y = h})
			else
				for i = 18, 27, sbr == 1 and 1 or 9 do
					local rad = i / 18 * math.pi
					table.insert(poly, {x = h - zbr - math.cos(rad) * zbr, y = h - zbr - math.sin(rad) * zbr})
				end
			end
			
			-- Bottom Left
			if sbl == 0 then
				table.insert(poly, {x = -h, y = h})
			else
				for i = 27, 36, sbl == 1 and 1 or 9 do
					local rad = i / 18 * math.pi
					table.insert(poly, {x = zbl - math.cos(rad) * zbl - h, y = h - zbl - math.sin(rad) * zbl})
				end
			end
			
			self._box_poly = poly
		end,
		
		_sizeChanged = function(self, ow, oh)
			if oh ~= self._h then
				self:_createBoxPoly()
			end
		end,
		
		------------------------------
		
		_styles = {
			{
				_think = function(self, dt)
					local anim_speed = dt * self.animationSpeed
					
					self:_animationUpdate("hover", self._hovering, anim_speed, self._draw_background)
					self:_animationUpdate("state", self._state, anim_speed, self._draw_background)
				end,
				
				onDraw = function(self, w, h)
					render.setMaterial()
					
					-- Background
					if self._draw_background then
						render.setColor(self.backgroundColor)
						render.drawRect(0, 0, w, h)
					end
					
					-- Pill
					local m = Matrix()
					m:setTranslation(Vector(h * 0.1, h * 0.1))
					m:setScale(Vector(h * 0.8))
					render.pushMatrix(m)
					render.setColor(GUI.lerpColor(self.inactiveColor, self.mainColor, self:getAnimation("state")))
					render.drawPoly(pill)
					render.popMatrix()
					
					-- Knob
					local m = Matrix()
					m:setTranslation(Vector(h * self:getAnimation("state") + h / 2, h / 2))
					m:setScale(Vector(h))
					render.pushMatrix(m)
					render.setColor(GUI.lerpColor(self.activeColor, self.hoverColor, self:getAnimation("hover")))
					render.drawPoly(circle)
					render.popMatrix()
					
					-- Text
					local ax, ay = self._text_alignment_x, self._text_alignment_y
					local th = self._text_height
					local tox, toy = self:getTextOffset()
					
					render.setFont(self.font)
					render.setColor(self.textColor)
					render.drawText(ax == 0 and h * 2 + tox or (ax == 1 and (w - h * 2) / 2 + h * 2 or w - tox), ay == 3 and toy or (ay == 1 and ((self._h - self._text_height) / 2) or h - th - toy), self._text, ax)
				end
			},
			
			{
				_think = function(self, dt)
					local anim_speed = dt * self.animationSpeed
					
					self:_animationUpdate("hover", self._hovering, anim_speed, self._draw_background)
					self:_animationUpdate("state", self._state, anim_speed, self._draw_background)
				end,
				
				onDraw = function(self, w, h)
					render.setMaterial()
					
					-- Background
					if self._draw_background then
						render.setColor(self.backgroundColor)
						render.drawRect(0, 0, w, h)
					end
					
					-- Knob
					local hover = self:getAnimation("hover")
					
					local m = Matrix()
					m:setTranslation(Vector(h / 2, h / 2))
					render.pushMatrix(m)
					render.setColor(GUI.lerpColor(self.activeColor, self.hoverColor, hover))
					render.drawPoly(self._box_poly)
					render.popMatrix()
					
					m:setScale(Vector(math.max(0, 1 - self:getAnimation("state") - hover * 0.1)))
					render.pushMatrix(m)
					render.setColor(self.inactiveColor)
					render.drawPoly(self._box_poly)
					render.popMatrix()
					
					-- Text
					local ax, ay = self._text_alignment_x, self._text_alignment_y
					local th = self._text_height
					local tox, toy = self:getTextOffset()
					
					render.setFont(self.font)
					render.setColor(self.textColor)
					render.drawText(ax == 0 and h + tox or (ax == 1 and (w - h) / 2 + h or w - tox), ay == 3 and toy or (ay == 1 and ((self._h - self._text_height) / 2) or h - th - toy), self._text, ax)
				end
			}
		},
		
		------------------------------
		
		_think = function(self, dt)
			
		end,
		
		_press = function(self)
			self._state = not self._state
			
			self:onClick()
			self:onChange(self._state)
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
		onHoverBegin = function(self) end,
		onHoverEnd = function(self) end,
		onHover = function(self) end,
		onChange = function(self, state) end
	},
	
	----------------------------------------
	
	properties = {
		_is_visibly_translucent = {
			-- Not that you should ever parent anything to a slider, but just incase it has been done for some reason
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
				return clr and (type(clr) == "string" and self._theme[clr] or clr) or self._theme.secondaryColorDark
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
		
		inactiveColor = {
			set = function(self, color)
				self._inactive_color = color
				
				self:_changed(true)
			end,
			
			get = function(self)
				local clr = self._inactive_color
				return clr and (type(clr) == "string" and self._theme[clr] or clr) or self._theme.primaryColorLight
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
		
		------------------------------
		
		state = {
			set = function(self, state)
				self._state = state
				
				self:_changed(true)
			end,
			
			get = function(self)
				return self._state
			end
		}
	}
	
}