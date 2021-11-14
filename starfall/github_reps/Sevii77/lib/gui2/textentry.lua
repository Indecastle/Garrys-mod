local GUI = GUI

return {
	inherit = "label",
	constructor = function(self)
		
	end,
	
	----------------------------------------
	
	data = {
		_text_default_color = false,
		
		_text_default = "",
		_text_alignment_x = 0,
		_text_alignment_y = 3,
		_text_wrap = true,
		
		_text_default_raw = "",
		_text_default_height = 0,
		
		------------------------------
		
		_think = function(self, dt)
			
		end,
		
		_press = function(self)
			self:onClick()
		end,
		
		_pressDouble = function(self)
			
		end,
		
		_release = function(self)
			self:onRelease()
		end,
		
		_hover = function(self, dt)
			self:onHover()
		end,
		
		_hoverStart = function(self)
			self:_cursorMode(GUI.CURSORMODE.WRITEABLE, GUI.CURSORMODE.NORMAL)
			self:onHoverBegin()
		end,
		
		_hoverEnd = function(self)
			self:_cursorMode(GUI.CURSORMODE.NORMAL, GUI.CURSORMODE.WRITEABLE)
			self:onHoverEnd()
		end,
		
		------------------------------
		
		onDraw = function(self, w, h)
			render.setColor(self.mainColor)
			render.drawRect(0, 0, w, h)
			
			local ax, ay = self._text_alignment_x, self._text_alignment_y
			local tox, toy = self:getTextOffset()
			
			render.setFont(self.font)
			if #self._text > 0 then
				local th = self._text_height
				
				render.setColor(self.textColor)
				render.drawText(ax == 0 and tox or (ax == 1 and w / 2 or w - tox), ay == 3 and toy or (ay == 1 and ((self._h - self._text_height) / 2) or h - th - toy), self._text, ax)
			else
				local th = self._text_default_height
				
				render.setColor(self.textDefaultColor)
				render.drawText(ax == 0 and tox or (ax == 1 and w / 2 or w - tox), ay == 3 and toy or (ay == 1 and ((self._h - self._text_default_height) / 2) or h - th - toy), self._text_default, ax)
			end
		end,
		
		onClick = function(self) end,
		onDoubleClick = function(self) end,
		onRelease = function(self) end,
		onHoverBegin = function(self) end,
		onHoverEnd = function(self) end,
		onHover = function(self) end,
	},
	
	----------------------------------------
	
	properties = {
		textDefaultColor = {
			set = function(self, color)
				self._text_default_color = color
				
				self:_changed()
			end,
			
			get = function(self)
				local clr = self._text_default_color
				return clr and (type(clr) == "string" and self._theme[clr] or clr) or self._theme.secondaryTextColor
			end
		},
		
		------------------------------
		
		textDefault = {
			set = function(self, text)
				self._text_default_raw = text
				
				self:_changed(true)
				
				if self._text_wrap then
					self._text_default, self._text_default_height = self:_wrapText(self._text_default_raw)
				else
					self._text_default = self._text_default_raw
					self:_setTextHeight()
				end
			end,
			
			get = function(self)
				return self._text_default
			end
		},
		
		textWrapping = {
			set = function(self, state)
				self._text_wrap = state
				
				self:_changed(true)
				self._text, self._text_height = self:_wrapText(self._text_raw)
				self._text_default, self._text_default_height = self:_wrapText(self._text_default_raw)
			end,
			
			get = function(self)
				return self._text_wrap
			end
		}
	}
	
}