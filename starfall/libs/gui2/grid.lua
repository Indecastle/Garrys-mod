local GUI = GUI

return {
	inherit = "base",
	constructor = function(self)
		
	end,
	
	----------------------------------------
	
	data = {
		_items = {},
		
		_spacing_x = 5,
		_spacing_y = 5,
		_item_size_x = 10,
		_item_size_y = 10,
		_item_count_x = false,
		_item_count_y = false,
		_item_scaling_x = true,
		_item_scaling_y = true,
		
		_content_size_x = 0,
		_content_size_y = 0,
		
		------------------------------
		
		_applyGridding = function(self, start_index)
			local icx = self._item_count_x
			if icx then
				self._item_size_x = (self._w - self._spacing_x * (icx - 1)) / icx
			end
			
			local icy = self._item_count_y
			if icy then
				self._item_size_y = (self._h - self._spacing_y * (icy - 1)) / icy
			end
			
			local sx, sy = self._spacing_x, self._spacing_y
			local wc = math.floor((self._w + sx) / (self._item_size_x + sx))
			local hc = math.min(math.ceil(#self._items / wc), math.floor((self._h + sy) / (self._item_size_y + sy)))
			local w = self._item_scaling_x and (self._w - sx * (wc - 1)) / wc or self._item_size_x
			local h = self._item_scaling_y and (self._h - sy * (hc - 1)) / hc or self._item_size_y
			
			for i = start_index or 1, #self._items do
				local obj = self._items[i]
				local x, y = (i - 1) % wc * (w + sx), math.floor((i - 1) / wc) * (h + sy)
				
				obj.x = x
				obj.y = y
				obj.w = w
				obj.h = h
				
				self._content_size_x = x + w
				self._content_size_y = y + h
			end
		end,
		
		_sizeChanged = function(self)
			self:_applyGridding()
		end,
		
		------------------------------
		
		addItem = function(self, obj)
			for i, o in pairs(self._items) do
				if o == obj then return end
			end
			
			obj.parent = self
			
			table.insert(self._items, obj)
			
			self:_applyGridding(--[[#self._items]])
		end
	},
	
	----------------------------------------
	
	properties = {
		spacing = {
			set = function(self, x, y)
				if y then
					self._spacing_x = x
					self._spacing_y = y
				else
					self._spacing_x = x.x
					self._spacing_y = x.y
				end
				
				self:_applyGridding()
			end,
			
			get = function(self)
				return self._spacing_x, self._spacing_y
			end
		},
		
		
		spacingX = {
			set = function(self, x)
				self._spacing_x = x
				
				self:_applyGridding()
			end,
			
			get = function(self)
				return self._spacing_x
			end
		},
		
		
		spacingY = {
			set = function(self, y)
				self._spacing_y = y
				
				self:_applyGridding()
			end,
			
			get = function(self)
				return self._spacing_x
			end
		},
		
		------------------------------
		
		itemSize = {
			set = function(self, w, h)
				if h then
					self._item_size_x = w
					self._item_size_y = h
				else
					self._item_size_x = w.x
					self._item_size_y = w.y
				end
				
				self._item_count_x = false
				self._item_count_y = false
				
				self:_applyGridding()
			end,
			
			get = function(self)
				return self._item_size_x, self._item_size_y
			end
		},
		
		itemWidth = {
			set = function(self, w)
				self._item_size_x = w
				self._item_count_x = false
				
				self:_applyGridding()
			end,
			
			get = function(self)
				return self._item_size_x
			end
		},
		
		itemHeight = {
			set = function(self, h)
				self._item_size_y = h
				self._item_count_y = false
				
				self:_applyGridding()
			end,
			
			get = function(self)
				return self._item_size_y
			end
		},
		
		------------------------------
		
		itemCount = {
			set = function(self, x, y)
				self._item_count_x = x
				self._item_count_y = y
				
				self:_applyGridding()
			end,
			
			get = function(self)
				return self._item_count_x, self._item_count_y
			end
		},
		
		itemCountX = {
			set = function(self, x)
				self._item_count_x = x
				
				self:_applyGridding()
			end,
			
			get = function(self)
				return self._item_count_x
			end
		},
		
		itemCountY = {
			set = function(self, y)
				self._item_count_y = y
				
				self:_applyGridding()
			end,
			
			get = function(self)
				return self._item_count_y
			end
		},
		
		------------------------------
		
		itemScaling = {
			set = function(self, x, y)
				self._item_scaling_x = x
				self._item_scaling_y = y
				
				self:_applyGridding()
			end,
			
			get = function(self)
				return self._item_scaling_x, self._item_scaling_y
			end
		},
		
		itemScalingX = {
			set = function(self, x)
				self._item_scaling_x = x
				
				self:_applyGridding()
			end,
			
			get = function(self)
				return self._item_scaling_x
			end
		},
		
		itemScalingY = {
			set = function(self, y)
				self._item_scaling_y = y
				
				self:_applyGridding()
			end,
			
			get = function(self)
				return self._item_scaling_y
			end
		},
		
		------------------------------
		
		contentWidth = {
			get = function(self)
				return self._content_size_x
			end
		},
		
		contentHeight = {
			get = function(self)
				return self._content_size_y
			end
		}
	}
	
}