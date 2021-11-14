local GUI = GUI

return {
	constructor = function(self)
		self._pos = Vector()
		self._size = Vector(30, 30)
	end,
	
	----------------------------------------
	
	data = {
		_gui = true, -- Set in the core when created
		_theme = true, -- Set in the core when created
		
		_is_visibly_translucent = true, -- Setting this to true means that it will never be used as a starting point to redraw from, setting it to false while not fully drawing can lead to ghosting.
		_enabled = true,
		_translucent = false, -- Allow mouse rays to pass through
		_visible = true,
		
		_pos = true,
		_x = 0,
		_y = 0,
		
		_size = true,
		_w = 30,
		_h = 30,
		
		-- Originals, unaffected by docking scaling
		_ow = 0,
		_oh = 0,
		
		_first = true,
		_cells = {},
		_cells_last = {},
		
		------------------------------
		
		__tostring = function(self)
			-- return string.format("%s (%d %d; %dx%d; %s)", self.parent or "()", self._x, self._y, self._w, self._h, self.__type)
			
			local c = 0
			local p = self.parent
			while p do
				c = c + 1
				p = p.parent
			end
			
			return string.format("%d (%d %d; %dx%d; %s)", c, self._x, self._y, self._w, self._h, self.__type)
		end,
		
		------------------------------
		
		remove = function(self)
			local gui = self._gui
			
			for child, child_object in pairs(gui._object_refs[self].children) do
				child:remove()
			end
			
			gui._remove_queue[self] = true
		end,
		
		focus = function(self)
			self._gui:focus(self)
		end,
		
		------------------------------
		
		_sizeChanged = function(self, ow, oh)
			-- Called by base, can be overwritten so you dont have to overwrite all 3 size properties
		end,
		
		_posChanged = function(self, ox, oy)
			-- Called by base, can be overwritten so you dont have to overwrite all 3 pos properties
		end,
		
		------------------------------
		
		_calculate_global_pos = true,
		_calculateGlobalPos = function(self)
			local object = self._gui._object_refs[self]
			local x, y = self._x, self._y
			
			local p = self.parent
			while p do
				x = x + p._x
				y = y + p._y
				
				p = p.parent
			end
			
			object.global_pos_last = self._first and Vector(x, y) or object.global_pos
			object.global_pos = Vector(x, y)
			
			self._calculate_cells = true
			
			for i, child in pairs(object.order) do
				child:_calculateGlobalPos()
			end
		end,
		
		_calculate_bounding = true,
		_calculateBounding = function(self)
			local object = self._gui._object_refs[self]
			local x, y, w, h = self._x, self._y, self._w, self._h
			local px, py, pw, ph = 0, 0, 0, 0
			
			local p = self.parent
			if p then
				local b = self._gui._object_refs[p].bounding
				px, py, pw, ph = b.x, b.y, b.x2, b.y2
			else
				pw, ph = self._gui._w, self._gui._h
			end
			
			local b = {
				x = math.max(px, x) - x,
				y = math.max(py, y) - y,
				x2 = math.min(pw, x + w) - x,
				y2 = math.min(ph, y + h) - y
			}
			
			self._visible = b.x < w and b.y < h and b.x2 > 0 and b.y2 > 0
			object.bounding_last = self._first and b or object.bounding
			object.bounding = b
			
			self._calculate_cells = true
			
			for i, child in pairs(object.order) do
				child:_calculateBounding()
			end
		end,
		
		_calculate_cells = false,
		_calculateCells = function(self)
			self._cells_last = self._cells
			
			local p = self.parent
			local cells, cs = self._gui._cells, self._gui._cell_size
			for _, cell in pairs(self._cells) do
				table.remove(cells[cell.x][cell.y], table.keyFromValue(cells[cell.x][cell.y], self))
				-- local tbl = p and cells[x][y].refs[p].children or cells[x][y].objs
				-- table.remove(tbl, table.keyFromValue(tbl, self))
			end
			self._cells = {}
			
			local object = self._gui._object_refs[self]
			if self._visible and self._enabled then
				local b = object.bounding
				local xo, yo = object.global_pos.x, object.global_pos.y
				local miy, may = math.floor((b.y + yo) / cs), math.floor((b.y2 + yo) / cs)
				for x = math.floor((b.x + xo) / cs), math.floor((b.x2 + xo) / cs) do
					for y = miy, may do
						cells[x] = cells[x] or {}
						cells[x][y] = cells[x][y] or {}
						table.insert(cells[x][y], self)
						-- cells[x][y] = cells[x][y] or {refs = {}, objs = {}}
						-- table.insert(p and cells[x][y].refs[p].children or cells[x][y].objs, {
						-- 	obj = self,
						-- 	children = {}
						-- })
						-- cells[x][y].refs[self] = cells[x][y].objs[#cells[x][y].objs]
						table.insert(self._cells, {x = x, y = y})
					end
				end
			end
		end,
		
		-- _calculateVisible = function(self)
		-- 	local x, y, w, h = self._x, self._y, self._w, self._h
		-- 	local pw, ph
		-- 	local p = self.parent
			
		-- 	if p then
		-- 		pw, ph = p._w, p._h
		-- 	else
		-- 		pw, ph = self._gui._w, self._gui._h
		-- 	end
			
		-- 	self._visible = x < pw and y < ph and x + w > 0 and y + h > 0
		-- end,
		
		------------------------------
		-- Styles
		
		_styles = {},
		_style_index = 0,
		
		addStyle = function(self, style)
			table.insert(self._styles, style)
		end,
		
		------------------------------
		--- Animations
		
		_animations = {},
		
		getAnimation = function(self, name)
			return self._animations[name] or 0
		end,
		
		_animationUpdate = function(self, name, state, amount)
			local anim = self._animations[name] or 0
			local changed = false
			
			if state then
				if anim < 1 then
					anim = math.min(1, anim + amount)
					changed = true
					
					self:onAnimationChange(name, anim)
					self:_changed()
				end
			elseif anim > 0 then
				anim = math.max(0, anim - amount)
				changed = true
				
				self:onAnimationChange(name, anim)
				self:_changed()
			end
			
			self._animations[name] = anim
			
			return changed, anim
		end,
		
		------------------------------
		-- Docking
		-- enum list available through GUI.DOCK
		
		_dock = {
			type = 0,
			margin = {l = 0, t = 0, r = 0, b = 0},
			padding = {l = 0, t = 0, r = 0, b = 0}
		},
		
		_updateDockingParent = function(self)
			if self._dock.type == 0 then return end
			
			local parent = self.parent
			if parent then
				parent:_updateDocking()
				-- self._update_docking = true
			else
				self:_updateDocking()
				-- self._update_docking = true
			end
		end,
		
		-- _update_docking = false,
		_updateDocking = function(self)
			-- Children resize and stuff
			local dock = self._dock
			local sx, sy, sw, sh = dock.padding.l, dock.padding.t, self._w - dock.padding.l - dock.padding.r, self._h - dock.padding.t - dock.padding.b
			
			local children = self.children
			for i = #children, 1, -1 do
				local child = children[i]
				local dock = child._dock
				
				local dt = dock.type
				if dt ~= 0 then
					local ox, oy, ow, oh = child._x, child._y, child._w, child._h
					local l, t, r, b = dock.margin.l, dock.margin.t, dock.margin.r, dock.margin.b
					local x, y, w, h
					
					-- Dock stuff
					if dt == 1 then
						-- FILL
						x, y, w, h = sx + l, sy + t, sw - l - r, sh - t - b
						sw, sy = 0, 0
					elseif dt == 2 then
						-- LEFT
						x, y, w, h = sx + l, sy + t, math.min(sw - l - r, ow), sh - t - b
						sx, sw = sx + w + l + r, sw - w - l - r
					elseif dt == 3 then
						-- RIGHT
						y, w, h = sy + t, math.min(sw - l - r, ow), sh - t - b
						x = sx + sw - w
						sw = sw - w - l - r
					elseif dt == 4 then
						-- TOP
						x, y, w, h = sx + l, sy + t, sw - l - r, math.min(sh - t - b, oh)
						sy, sh = sy + h + t + b, sh - h - t - b
					elseif dt == 5 then
						-- BOTTOM
						x, w, h = sx + l, sw - l - r, math.min(sh - t - b, oh)
						y = sy + sh - h
						sh = sh - h - t - b
					end
					
					-- Margin
					-- x = x + l
					-- y = y + t
					-- w = w - l - r
					-- h = h - t - b
					
					-- Apply
					if x ~= ox or y ~= oy then
						child._pos.x = x
						child._pos.y = y
						child._x = x
						child._y = y
						
						child._calculate_global_pos = true
						child._calculate_bounding = true
						-- child:_calculateGlobalPos()
						-- child:_calculateBounding()
						child:_posChanged()
						child:_changed()
					end
					
					w = math.max(child._ow, w)
					h = math.max(child._oh, h)
					
					-- For some reason w and ow are always the same? i dont understand
					--if w ~= ow or h ~= oh then
						child._size.x = w
						child._size.y = h
						child._w = w
						child._h = h
						
						child._calculate_bounding = true
						-- child:_calculateBounding()
						child:_sizeChanged()
						child:_updateDocking()
						-- child:_changed()
					--end
					
					if sw == 0 or sh == 0 then
						break
					end
				end
			end
		end,
		
		------------------------------
		
		_changed = function(self, simple)
			self._gui:_changed(self, simple)
			
			--[[
				called whenever it needs to be redrawn
				
				simple: redraw the current element only, dont clear anything
			]]
		end,
		
		_cursorMode = function(self, mode, from)
			local gui = self._gui
			if gui._cursor_mode == from or from == nil then
				gui._cursor_mode = mode
			end
			
			--[[
				Call this to set the new mode of the cursor
				from: the mode the cursor must be in in order to be allowed to change, nil for any
				
				enum list available through GUI.CURSORMODE
			]]
		end,
		
		_draw = function(self, dt)
			self:onDraw(self._w, self._h)
			self:onDrawOver(self._w, self._h)
		end,
		
		_postdraw = function(self, dt)
			self:onPostDraw(self._w, self._h)
		end,
		
		_think = function(self, dt, cx, cy)
			
		end,
		
		_postthink = function(self)
			-- Used to only do things once, for example instead of calling something directly from setters set a flag to do it once
			local object = self._gui._object_refs[self]
			
			if self._calculate_global_pos then
				self._calculate_global_pos = false
				self:_calculateGlobalPos()
			else
				object.global_pos_last = object.global_pos
			end
			
			if self._calculate_bounding then
				self._calculate_bounding = false
				self:_calculateBounding()
			else
				object.bounding_last = object.bounding
			end
			
			if self._calculate_cells then
				self._calculate_cells = false
				self:_calculateCells()
			end
			
			-- if self._update_docking then
			-- 	self._update_docking = false
			-- 	self:_updateDocking()
			-- end
			
			self._first = false
		end,
		
		_press = function(self)
			
		end,
		
		_pressRight = function(self)
			
		end,
		
		_pressDouble = function(self)
			
		end,
		
		_release = function(self)
			
		end,
		
		_releaseRight = function(self)
			
		end,
		
		_hover = function(self, dt)
			
		end,
		
		_hoverStart = function(self)
			
		end,
		
		_hoverEnd = function(self)
			
		end,
		
		------------------------------
		
		onDraw = function(self, w, h) end,
		onDrawOver = function(self, w, h) end,
		onPostDraw = function(self, w, h) end,
		onAnimationChange = function(self, anim, value) end
	},
	
	----------------------------------------
	
	-- No need to have stuff like :setPos in data, since those will be auto generated from properties
	properties = {
		enabled = {
			set = function(self, state)
				self._enabled = state
				
				self:_changed()
			end,
			
			get = function(self)
				return self._enabled
			end
		},
		
		translucent = {
			set = function(self, state)
				self._translucent = state
			end,
			
			get = function(self)
				return self._translucent
			end
		},
		
		parent = {
			set = function(self, parent)
				local obj = self
				local self = self._gui
				local object = self._object_refs[obj]
				if object.parent then
					local parent_object = self._object_refs[object.parent]
					parent_object.children[obj] = nil
					
					for i, o in pairs(parent_object.order) do
						if o == obj then
							table.remove(parent_object.order, i)
							
							break
						end
					end
				else
					self._objects[obj] = nil
					
					for i, o in pairs(self._render_order) do
						if o == obj then
							table.remove(self._render_order, i)
							
							break
						end
					end
				end
				
				if parent then
					self._object_refs[parent].children[obj] = object
					table.insert(self._object_refs[parent].order, 1, obj)
				else
					self._objects[obj] = object
					table.insert(self._render_order, 1, obj)
				end
				
				object.parent = parent
				
				-- self._gui._parent_queue[self] = parent
			end,
			
			get = function(self)
				return self._gui._object_refs[self].parent
			end
		},
		
		children = {
			get = function(self)
				local tbl = {}
				for _, obj in pairs(self._gui._object_refs[self].order) do
					table.insert(tbl, obj)
				end
				
				return tbl
			end
		},
		
		------------------------------
		
		globalPos = {
			get = function(self)
				return self._gui._object_refs[self].global_pos
			end
		},
		
		globalX = {
			get = function(self)
				return self._gui._object_refs[self].global_pos.x
			end
		},
		
		globalY = {
			get = function(self)
				return self._gui._object_refs[self].global_pos.y
			end
		},
		
		pos = {
			set = function(self, x, y)
				local ox, oy = self._x, self._y
				
				if y then
					self._pos.x = x
					self._pos.y = y
					self._x = x
					self._y = y
				else
					self._pos = x
					self._x = x.x
					self._y = x.y
				end
				
				self._calculate_global_pos = true
				self._calculate_bounding = true
				-- self:_calculateGlobalPos()
				-- self:_calculateBounding()
				self:_posChanged(ox, oy)
				self:_changed()
			end,
			
			get = function(self)
				return self._pos
			end
		},
		
		x = {
			set = function(self, x)
				local ox = self._x
				
				self._pos.x = x
				self._x = x
				
				self._calculate_global_pos = true
				self._calculate_bounding = true
				-- self:_calculateGlobalPos()
				-- self:_calculateBounding()
				self:_posChanged(ox, self._y)
				self:_changed()
			end,
			
			get = function(self)
				return self._x
			end
		},
		
		y = {
			set = function(self, y)
				local oy = self._y
				
				self._pos.y = y
				self._y = y
				
				self._calculate_global_pos = true
				self._calculate_bounding = true
				-- self:_calculateGlobalPos()
				-- self:_calculateBounding()
				self:_posChanged(self._x, oy)
				self:_changed()
			end,
			
			get = function(self)
				return self._y
			end
		},
		
		------------------------------
		
		size = {
			set = function(self, w, h)
				local ow, oh = self._w, self._h
				
				if h then
					self._size.x = w
					self._size.y = h
					self._w = w
					self._h = h
					self._ow = w
					self._oh = h
				else
					self._size = w
					self._w = w.x
					self._h = w.y
					self._ow = w.x
					self._oh = w.y
				end
				
				self._calculate_bounding = true
				-- self:_calculateBounding()
				self:_sizeChanged(ow, oh)
				self:_updateDockingParent()
				self:_changed(self._w >= ow and self._h >= oh)
			end,
			
			get = function(self)
				return self._size
			end
		},
		
		w = {
			set = function(self, w)
				local ow = self._w
				
				self._size.x = w
				self._w = w
				self._ow = w
				
				self._calculate_bounding = true
				-- self:_calculateBounding()
				self:_sizeChanged(ow, self._h)
				self:_updateDockingParent()
				self:_changed(w >= ow)
			end,
			
			get = function(self)
				return self._w
			end
		},
		
		h = {
			set = function(self, h)
				local oh = self._h
				
				self._size.y = h
				self._h = h
				self._oh = h
				
				self._calculate_bounding = true
				-- self:_calculateBounding()
				self:_sizeChanged(self._w, oh)
				self:_updateDockingParent()
				self:_changed(h >= oh)
			end,
			
			get = function(self)
				return self._h
			end
		},
		
		------------------------------
		
		style = {
			set = function(self, style_id)
				self._style_index = style_id
				
				for k, v in pairs(self._styles[style_id]) do
					self[k] = v
				end
				
				self:_changed()
			end,
			
			get = function(self)
				return self._style_index
			end
		},
		
		------------------------------
		
		dock = {
			set = function(self, dock_type)
				self._dock.type = dock_type
				
				self:_updateDockingParent()
			end,
			
			get = function(self)
				return self._dock.type
			end
		},
		
		dockMargin = {
			set = function(self, l, t, r, b)
				if type(l) == "table" then
					self._dock.margin = {l = l.l, t = l.t, r = l.r, b = l.b}
				elseif b then
					self._dock.margin = {l = l, t = t, r = r, b = b}
				else
					self._dock.margin = {l = l, t = l, r = l, b = l}
				end
				
				self:_updateDockingParent()
			end,
			
			get = function(self)
				local t = self._dock.margin
				
				return t.l, t.t, t.r, t.b
			end
		},
		
		dockPadding = {
			set = function(self, l, t, r, b)
				if type(l) == "table" then
					self._dock.padding = {l = l.l, t = l.t, r = l.r, b = l.b}
				elseif b then
					self._dock.padding = {l = l, t = t, r = r, b = b}
				else
					self._dock.padding = {l = l, t = l, r = l, b = l}
				end
				
				self:_updateDocking()
				-- self._update_docking = true
			end,
			
			get = function(self)
				local t = self._dock.padding
				
				return t.l, t.t, t.r, t.b
			end
		}
	}
	
}