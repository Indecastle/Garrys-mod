local GUI = GUI

return {
	inherit = "base",
	constructor = function(self)
		self._spos = Vector()
	end,
	
	----------------------------------------
	
	data = {
		_text = "",
		_font = false,
		_color = false,
		_alignment_x = 1,
		_alignment_y = 1,
		
		_spos = true,
		_sx = 0,
		_sy = 0,
		
		------------------------------
		
		_updateBounds = function(self)
			render.setFont(self.font)
			local w, h = render.getTextSize(self._text)
			local ax, ay = self._alignment_x, self._alignment_y
			
			local x = self._sx - (ax == 0 and 0 or (ax == 1 and w / 2 or w))
			local y = self._sy - (ay == 3 and 0 or (ay == 1 and h / 2 or h))
			
			self._pos.x = x
			self._pos.y = y
			self._x = x
			self._y = y
			
			self._size.x = w
			self._size.y = h
			self._w = w
			self._h = h
		end,
		
		------------------------------
		
		onDraw = function(self, w, h)
			local ax = self._alignment_x
			
			render.setFont(self.font)
			render.setColor(self.color)
			render.drawText((ax == 0 and 0 or (ax == 1 and w / 2 or w)), 0, self.text, ax)
		end
	},
	
	----------------------------------------
	
	properties = {
		pos = {
			set = function(self, x, y)
				local ox, oy = self._x, self._y
				
				if y then
					self._spos.x = x
					self._spos.y = y
					self._sx = x
					self._sy = y
				else
					self._spos = x
					self._sx = x.x
					self._sy = x.y
				end
				
				self._calculate_global_pos = true
				self._calculate_bounding = true
				self:_updateBounds()
				self:_posChanged(ox, oy)
				self:_changed()
			end,
			
			get = function(self)
				return self._spos
			end
		},
		
		x = {
			set = function(self, x)
				local ox = self._x
				
				self._spos.x = x
				self._sx = x
				
				self._calculate_global_pos = true
				self._calculate_bounding = true
				self:_updateBounds()
				self:_posChanged(ox, self._y)
				self:_changed()
			end,
			
			get = function(self)
				return self._sx
			end
		},
		
		y = {
			set = function(self, y)
				local oy = self._y
				
				self._spos.y = y
				self._sy = y
				
				self._calculate_global_pos = true
				self._calculate_bounding = true
				self:_updateBounds()
				self:_posChanged(self._x, oy)
				self:_changed()
			end,
			
			get = function(self)
				return self._sy
			end
		},
		
		------------------------------
		
		size = {
			get = function(self)
				return self._size
			end
		},
		
		w = {
			get = function(self)
				return self._w
			end
		},
		
		h = {
			get = function(self)
				return self._h
			end
		},
		
		------------------------------
		
		text = {
			set = function(self, text)
				self._text = text
				
				self:_changed()
				self:_updateBounds()
			end,
			
			get = function(self)
				return self._text
			end
		},
		
		font = {
			set = function(self, font)
				self._font = font
				
				self:_changed()
				self:_updateBounds()
			end,
			
			get = function(self)
				return self._font or self._theme.font
			end
		},
		
		color = {
			set = function(self, color)
				self._color = color
				
				self:_changed()
			end,
			
			get = function(self)
				local clr = self._color
				return clr and (type(clr) == "string" and self._theme[clr] or clr) or self._theme.primaryTextColor
			end
		},
		
		alignmentX = {
			set = function(self, x)
				self._alignment_x = x
				
				self:_changed()
				self:_updateBounds()
			end,
			
			get = function(self)
				return self._alignment_x
			end
		},
		
		alignmentY = {
			set = function(self, y)
				self._alignment_y = y
				
				self:_changed()
				self:_updateBounds()
			end,
			
			get = function(self)
				return self._alignment_y
			end
		},
		
		alignment = {
			set = function(self, x, y)
				self._alignment_x = x
				self._alignment_y = y
				
				self:_changed()
				self:_updateBounds()
			end,
			
			get = function(self)
				return self._alignment_x, self._alignment_y
			end
		}
	}
	
}