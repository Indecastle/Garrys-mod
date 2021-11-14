local GUI = GUI

local circle = {}
for i = 1, 32 do
	local rad = i / 16 * math.pi
	circle[i] = {x = -math.sin(rad) / 2, y = math.cos(rad) / 2}
end

return {
	inherit = "label",
	constructor = function(self)
		
	end,
	
	----------------------------------------
	
	data = {
		_active_color = false,
		_hover_color = false,
		
		_toggle = false,
		_animation_speed = false,
		
		_hovering = false,
		_click_anim = false,
		_click = false,
		_click_right = false,
		_cursor = false,
		
		------------------------------
		
		_think = function(self, dt)
			local anim_speed = dt * self.animationSpeed
			
			self:_animationUpdate("hover", self._hovering, anim_speed, true)
			
			local _, p = self:_animationUpdate("click", self._click_anim, anim_speed, true)
			if p == 1 and not self._click and not self._click_right then
				self._click_anim = false
			end
		end,
		
		_press = function(self)
			self._click = not self._toggle and true or not self._click
			self._click_anim = true
			
			local x, y = self._gui:getCursorPos(self)
			self._cursor = Vector(x, y)
			
			self:onClick()
		end,
		
		_pressRight = function(self)
			self._click_right = true
			self._click_anim = true
			
			local x, y = self._gui:getCursorPos(self)
			self._cursor = Vector(x, y)
			
			self:onRightClick()
		end,
		
		_pressDouble = function(self)
			self:onDoubleClick()
		end,
		
		_release = function(self)
			if not self._toggle then
				self._click = false
			end
			
			self:onRelease()
		end,
		
		_releaseRight = function(self)
			self._click_right = false
			
			self:onRightRelease()
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
			-- Container
			render.setMaterial()
			
			local clr = GUI.lerpColor(self.mainColor, self.hoverColor, self:getAnimation("hover"))
			render.setColor(clr)
			render.drawRect(0, 0, w, h)
			
			-- Click anim
			local p = self:getAnimation("click")
			if p > 0 then
				local w, h = math.max(w - self._cursor.x, self._cursor.x) + 1, math.max(h - self._cursor.y, self._cursor.y) + 1
				local m = Matrix()
				m:setTranslation(self._cursor)
				m:setScale(Vector((self._click_anim and p or 1) * math.sqrt(w * w + h * h) * 2))
				
				render.pushMatrix(m)
				render.setColor(GUI.lerpColor(self.activeColor, clr, self._click_anim and 0 or (1 - p)))
				render.drawPoly(circle)
				render.popMatrix()
			end
			
			-- Text
			local ax, ay = self._text_alignment_x, self._text_alignment_y
			local th = self._text_height
			local tox, toy = self:getTextOffset()
			
			render.setFont(self.font)
			render.setColor(self.textColor)
			render.drawText(ax == 0 and tox or (ax == 1 and w / 2 or w - tox), ay == 3 and toy or (ay == 1 and ((self._h - self._text_height) / 2) or h - th - toy), self._text, ax)
		end,
		
		onClick = function(self) end,
		onRightClick = function(self) end,
		onDoubleClick = function(self) end,
		onHold = function(self) end,
		onRightHold = function(self) end,
		onRelease = function(self) end,
		onRightRelease = function(self) end,
		onHoverBegin = function(self) end,
		onHoverEnd = function(self) end,
		onHover = function(self) end,
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
				return clr and (type(clr) == "string" and self._theme[clr] or clr) or self._theme.secondaryColor
			end
		},
		
		activeColor = {
			set = function(self, color)
				self._active_color = color
				
				self:_changed(true)
			end,
			
			get = function(self)
				local clr = self._active_color
				return clr and (type(clr) == "string" and self._theme[clr] or clr) or self._theme.secondaryColorDark
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
		
		toggle = {
			set = function(self, state)
				self._toggle = state
			end,
			
			get = function(self)
				return self._toggle
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
				if self._toggle then
					self._click = state
					self._click_anim = state
					self._cursor = Vector(self._w / 2, self._h / 2)
				end
			end,
			
			get = function(self)
				return self._click
			end
		}
	}
	
}