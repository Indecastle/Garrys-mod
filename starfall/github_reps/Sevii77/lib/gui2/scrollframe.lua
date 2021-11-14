local GUI = GUI

return {
	inherit = "base",
	constructor = function(self)
		self._inner = self._gui:create("base", self)
		self._inner.dock = GUI.DOCK.FILL
	end,
	
	----------------------------------------
	
	data = {
		_scrollbar_x = false,
		_scrollbar_y = false,
		_inner = false,
		_content = false,
		
		------------------------------
		
		_sizeChanged = function(self)
			self:contentSizeChanged()
		end,
		
		------------------------------
		
		contentSizeChanged = function(self)
			if not self._content then return end
			
			if self._scrollbar_x then
				self._scrollbar_x.contentSize = self._content._w + self._content._dock.margin.l + self._content._dock.margin.r
				self._scrollbar_x.enabled = self._scrollbar_x.contentSize > self._w
			end
			
			if self._scrollbar_y then
				self._scrollbar_y.contentSize = self._content._h + self._content._dock.margin.t + self._content._dock.margin.b
				self._scrollbar_y.enabled = self._scrollbar_y.contentSize > self._h
			end
			
			self._inner.w = self._w - ((self._scrollbar_y and self._scrollbar_y.enabled) and self._scrollbar_y._w or 0)
			self._inner.h = self._h - ((self._scrollbar_x and self._scrollbar_x.enabled) and self._scrollbar_x._h or 0)
			self._inner:_updateDocking()
			
			if self._scrollbar_x then
				self._scrollbar_x:onChange(self._scrollbar_x.value)
			end
			
			if self._scrollbar_y then
				self._scrollbar_y:onChange(self._scrollbar_y.value)
			end
		end
	},
	
	----------------------------------------
	
	properties = {
		scrollbarX = {
			set = function(self, x)
				if x then
					if type(x) == "gui:scrollbar" then
						self._scrollbar_x = x
					else
						self._scrollbar_x = self._gui:create("scrollbar", self)
						self._scrollbar_x.h = 10
					end
					
					self._scrollbar_x.dock = GUI.DOCK.BOTTOM
					self._scrollbar_x.onChange = function(_, value)
						if not self._content then return end
						
						self._content.x = -value + self._content._dock.margin.l
						self:_changed(true)
					end
					
					if self._scrollbar_y then
						self._scrollbar_y:setDockMargin(0, 0, 0, self._scrollbar_x.h)
					end
					
					self._inner.parent = self
				elseif self._scrollbar_x then
					self._scrollbar_x:remove()
					self._scrollbar_x = false
				end
			end,
			
			get = function(self)
				return self._scrollbar_x
			end
		},
		
		scrollbarY = {
			set = function(self, x)
				if x then
					if type(x) == "gui:scrollbar" then
						self._scrollbar_y = x
					else
						self._scrollbar_y = self._gui:create("scrollbar", self)
						self._scrollbar_y.w = 10
					end
					
					self._scrollbar_y.dock = GUI.DOCK.RIGHT
					self._scrollbar_y.onChange = function(_, value)
						if not self._content then return end
						
						self._content.y = -value + self._content._dock.margin.t
						self:_changed(true)
					end
					
					if self._scrollbar_x then
						self._scrollbar_x:setDockMargin(0, 0, self._scrollbar_y.w, 0)
					end
					
					self._inner.parent = self
				elseif self._scrollbar_y then
					self._scrollbar_y:remove()
					self._scrollbar_y = false
				end
			end,
			
			get = function(self)
				return self._scrollbar_y
			end
		},
		
		content = {
			set = function(self, object)
				if self._content then
					self._content.parent = nil
				end
				
				object.parent = self._inner
				
				if self._scrollbar_y then
					if not self._scrollbar_x then
						object.dock = GUI.DOCK.TOP
					end
				elseif self._scrollbar_x then
					object.dock = GUI.DOCK.LEFT
				else
					object.dock = GUI.DOCK.FILL
				end
				
				self._content = object
				
				self:contentSizeChanged()
			end,
			
			get = function(self)
				return self._content
			end,
		}
	}
	
}