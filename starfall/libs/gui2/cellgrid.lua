-- Credits to Name for the main part

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
		_grid_size_x = 2,
		_grid_size_y = 2,
		
		------------------------------
		
		_applyGridding = function(self, start_index)
			
			for i = start_index or 1, #self._items do
				local obj_data = self._items[i]
				local obj = obj_data.obj
				
				local sx = (self._w - self._spacing_x * (self._grid_size_x - 1)) / self._grid_size_x
				local sy = (self._h - self._spacing_y * (self._grid_size_y - 1)) / self._grid_size_y
				
				obj._x = (obj_data.x - 1) * (sx + self._spacing_x)
				obj._y = (obj_data.y - 1) * (sy + self._spacing_y)
				obj._pos.x = obj._x
				obj._pos.y = obj._y
				obj:_posChanged(obj._x, obj._y, true)
				
				obj._w = sx * obj_data.w + self._spacing_x * (obj_data.w - 1)
				obj._h = sy * obj_data.h + self._spacing_y * (obj_data.h - 1)
				obj._size.x = obj._w
				obj._size.y = obj._h
				obj:_sizeChanged(obj._w, obj._h, true)
				
				obj._calculate_global_pos = true
				obj._calculate_bounding = true
				obj:_changed()
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
			
			local tbl = {
				obj = obj,
				posChanged = obj._posChanged,
				sizeChanged = obj._sizeChanged,
				x = obj.x,
				y = obj.y,
				w = obj.w,
				h = obj.h
			}
			
			obj._posChanged = function(o, ox, oy, internal)
				if not internal then
					tbl.x = o.x
					tbl.y = o.y
					
					self:_applyGridding()
				end
				
				tbl.posChanged(o, ox, oy)
			end
			
			obj._sizeChanged = function(o, ow, oh, internal)
				if not internal then
					tbl.w = o.w
					tbl.h = o.h
					
					self:_applyGridding()
				end
				
				tbl.sizeChanged(o, ow, oh)
			end
			
			table.insert(self._items, tbl)
			
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
		
		-------------------------------
		
		gridSize = {
			set = function(self, x, y)
				if y then
					self._grid_size_x = x
					self._grid_size_y = y
				else
					self._grid_size_x = x.x
					self._grid_size_y = x.y
				end
				
				self:_applyGridding()
			end,
			
			get = function(self)
				return self._grid_size_x, self._grid_size_y
			end
		},
		
		
		gridSizeX = {
			set = function(self, x)
				self._grid_size_x = x
				
				self:_applyGridding()
			end,
			
			get = function(self)
				return self._grid_size_x
			end
		},
		
		
		gridSizeY = {
			set = function(self, x)
				self._grid_size_y = x
				
				self:_applyGridding()
			end,
			
			get = function(self)
				return self._grid_size_y
			end
		},
	}
	
}
