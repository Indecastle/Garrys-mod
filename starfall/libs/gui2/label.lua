local GUI = GUI

return {
	inherit = "container",
	constructor = function(self)
		
	end,
	
	----------------------------------------
	
	data = {
		_text_color = false,
		
		_text = "",
		_font = false,
		_text_alignment_x = 1,
		_text_alignment_y = 1,
		_text_offset_x = false,
		_text_offset_y = false,
		_text_wrap = false,
		
		_text_raw = "",
		_text_height = 0,
		
		------------------------------
		
		_wrapText = function(self, text)
			render.setFont(self.font)
			
			local str = ""
			local line = ""
			local _, height = render.getTextSize("")
			local text_height = 0
			
			for spacer, word in string.gmatch(text, "(%s*)(%S*)") do
				if string.find(spacer, "\n") then
					str = str .. line .. "\n"
					line = word
					
					text_height = text_height + height
				else
					local w, h = render.getTextSize(line .. spacer .. word)
					
					if w > self._w then
						if #str > 0 then
							str = str .. line .. "\n"
							line = word
							
							text_height = text_height + height
						else
							line = line .. spacer .. word
						end
					else
						line = line .. spacer .. word
					end
				end
			end
			
			if #line > 0 then
				str = str .. line
				
				text_height = text_height + height
			end
			
			return str, text_height
		end,
		
		_setTextHeight = function(self)
			render.setFont(self.font)
			
			local _, h = render.getTextSize(self._text)
			self._text_height = h
		end,
		
		------------------------------
		
		onDraw = function(self, w, h)
			base()
			
			local ax, ay = self._text_alignment_x, self._text_alignment_y
			local th = self._text_height
			local tox, toy = self:getTextOffset()
			
			render.setFont(self.font)
			render.setColor(self.textColor)
			render.drawText(ax == 0 and tox or (ax == 1 and w / 2 or w - tox), ay == 3 and toy or (ay == 1 and ((self._h - self._text_height) / 2) or h - th - toy), self._text, ax)
		end
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
		
		textColor = {
			set = function(self, color)
				self._text_color = color
				
				self:_changed(true)
			end,
			
			get = function(self)
				local clr = self._text_color
				return clr and (type(clr) == "string" and self._theme[clr] or clr) or self._theme.primaryTextColor
			end
		},
		
		------------------------------
		
		text = {
			set = function(self, text)
				self._text_raw = text
				
				self:_changed(true)
				
				if self._text_wrap then
					self._text, self._text_height = self:_wrapText(self._text_raw)
				else
					self._text = self._text_raw
					self:_setTextHeight()
				end
			end,
			
			get = function(self)
				return self._text
			end
		},
		
		font = {
			set = function(self, font)
				self._font = font
				
				self:_changed(true)
				
				if self._text_wrap then
					self._text, self._text_height = self:_wrapText(self._text_raw)
				else
					self:_setTextHeight()
				end
			end,
			
			get = function(self)
				return self._font or self._theme.font
			end
		},
		
		textAlignment = {
			set = function(self, x, y)
				self._text_alignment_x = x
				self._text_alignment_y = y
				
				self:_changed(true)
			end,
			
			get = function(self)
				return self._text_alignment_x, self._text_alignment_y
			end
		},
		
		textAlignmentX = {
			set = function(self, x)
				self._text_alignment_x = x
				
				self:_changed(true)
			end,
			
			get = function(self)
				return self._text_alignment_x
			end
		},
		
		textAlignmentY = {
			set = function(self, y)
				self._text_alignment_y = y
				
				self:_changed(true)
			end,
			
			get = function(self)
				return self._text_alignment_y
			end
		},
		
		textOffset = {
			set = function(self, x, y)
				if y then
					self._text_offset_x = x
					self._text_offset_y = y
				else
					self._text_offset_x = x.x
					self._text_offset_y = x.y
				end
				
				self:_changed()
			end,
			
			get = function(self)
				return self._text_offset_x or (self._text_alignment_x == 1 and (self._h - self._text_height) / 2 or 0), self._text_offset_y or (self._text_alignment_y == 1 and (self._h - self._text_height) / 2 or 0)
			end
		},
		
		textOffsetX = {
			set = function(self, value)
				self._text_offset_x = value
				
				self:_changed()
			end,
			
			get = function(self)
				return self._text_offset_x or (self._h - self._text_height) / 2
			end
		},
		
		textOffsetY = {
			set = function(self, value)
				self._text_offset_y = value
				
				self:_changed()
			end,
			
			get = function(self)
				return self._text_offset_y or (self._h - self._text_height) / 2
			end
		},
		
		textWrapping = {
			set = function(self, state)
				self._text_wrap = state
				
				self:_changed(true)
				self._text, self._text_height = self:_wrapText(self._text_raw)
			end,
			
			get = function(self)
				return self._text_wrap
			end
		},
		
		textHeight = {
			get = function(self)
				return self._text_height
			end
		}
	}
	
}