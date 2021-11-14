local GUI = GUI

local tri = {
	{x = 0, y = 0},
	{x = -1, y = 0},
	{x = 0, y = -1}
}
local rect = {
	{x =  0.5, y =  0.5},
	{x = -0.5, y =  0.5},
	{x = -0.5, y = -0.5},
	{x =  0.5, y = -0.5}
}

return {
	inherit = "container",
	constructor = function(self)
		self._inner = self._gui:create("base", self)
		self._inner.translucent = true
		self._inner.dock = GUI.DOCK.FILL
		
		self:_setTextHeight()
		self:_sizeChanged()
	end,
	
	----------------------------------------
	
	data = {
		_title_bar_color = false,
		_title_color = false,
		
		_title = "",
		_title_font = false,
		_title_alignment_x = 1,
		_title_alignment_y = 1,
		_title_height = 20,
		
		_min_x = 50,
		_min_y = 50,
		_dragcorner_size = 10,
		_dragbar_size = 3,
		_animation_speed = false,
		_resize_fps = 0,
		_resize_overlay = true,
		
		_dragable = true,
		_closeable = true,
		_resizeable = true,
		_collapse_on_close = false,
		
		_true_height = 0,
		_inner = false,
		_grab = false,
		_closed = false,
		_text_height = 0,
		_close_hovering = false,
		
		_dt = 0,
		_domove = false,
		
		------------------------------
		
		_calculateInner = function(self)
			self._inner:setDockMargin(0, self._title_height, 0, 0)
		end,
		
		_setTextHeight = function(self)
			render.setFont(self.titleFont)
			
			local _, h = render.getTextSize("")
			self._text_height = h
		end,
		
		_sizeChanged = function(self)
			self:_calculateInner()
			
			self._true_height = self._h
		end,
		
		------------------------------
		
		_think = function(self, dt)
			self._dt = self._dt + dt
			
			if self._dt >= 1 / self._resize_fps then
				self._domove = true
				self._dt = 0
			end
			
			if self._domove then
				local x, y = self._gui:getCursorPos(self.parent)
				local g = self._grab or self._lastgrab
				
				if x and g then
					if g.move then
						local nx = math.floor(x - g.x)
						local ny = math.floor(y - g.y)
						
						if nx ~= self._x or ny ~= self._y then
							self.x = nx
							self.y = ny
							
							self:onDrag()
						end
					else
						local nw = math.max(self._min_x, math.floor(x - self._x + g.x))
						local nh = math.max(self._min_y, math.floor(y - self._y + g.y))
						
						if nw ~= self._w or nh ~= self._h then
							if g.size then
								self.w = nw
								self.h = nh
							elseif g.sizex then
								self.w = nw
							elseif g.sizey then
								self.h = nh
							end
							
							self:onResize()
						end
					end
				end
				
				self._lastgrab = nil
				self._domove = false
			end
			
			self:_animationUpdate("close_hover", self._close_hovering, dt * self.animationSpeed, true)
			
			if self._collapse_on_close then
				local changed, progress = self:_animationUpdate("collapse", self._closed, dt * self.animationSpeed, not self._closed)
				
				if changed then
					self._h = math.lerp(progress, self._true_height, self._title_height)
					self._size.y = self._h
					
					if progress == 1 then
						self._inner.enabled = false
					elseif not self._closed and not self._inner.enabled then
						self._inner.enabled = true
					end
					
					self._calculate_bounding = true
					self:_calculateInner()
					self:_updateDockingParent()
					self:_changed()
				end
			end
		end,
		
		_press = function(self)
			local x, y = self._gui:getCursorPos(self)
			
			if y < self._title_height then
				if x > self._w - self._title_height and self._closeable then
					if not self:onClose() then
						if self._collapse_on_close then
							self._closed = not self._closed
						else
							self:remove()
						end
					end
				elseif self._dragable then
					self._grab = {move = true, x = x, y = y}
					self:_cursorMode(GUI.CURSORMODE.DRAGGING)
				end
			elseif self._resizeable and not self._closed then
				local ox, oy = self._w - x, self._h - y
				local b = self._dragbar_size
				
				if self._w - x + self._h - y <= self._dragcorner_size then
					self._grab = {size = true, x = ox, y = oy}
					self:_cursorMode(GUI.CURSORMODE.RESIZE)
				elseif y > self._h - b then
					self._grab = {sizey = true, x = ox, y = oy}
					self:_cursorMode(GUI.CURSORMODE.RESIZEY)
				elseif x > self._w - b then
					self._grab = {sizex = true, x = ox, y = oy}
					self:_cursorMode(GUI.CURSORMODE.RESIZEX)
				end
			end
			
			self:focus()
		end,
		
		_release = function(self)
			if self._grab then
				self._lastgrab = self._grab
				self._grab = false
				self._domove = true
				self:_cursorMode(GUI.CURSORMODE.NORMAL)
			end
		end,
		
		_hover = function(self)
			local x, y = self._gui:getCursorPos(self)
			
			if x > self._w - self._title_height and y < self._title_height then
				self._close_hovering = true
				self:_cursorMode(GUI.CURSORMODE.CLICKABLE)
			elseif self._close_hovering then
				self._close_hovering = false
				self:_cursorMode(GUI.CURSORMODE.NORMAL)
			end
		end,
		
		_hoverEnd = function(self)
			if self._close_hovering then
				self._close_hovering = false
				self:_cursorMode(GUI.CURSORMODE.NORMAL)
			end
		end,
		
		------------------------------
		
		onDraw = function(self, w, h)
			local th = self._title_height
			local th2 = th / 2
			local tw = self._closeable and w - th or w
			
			render.setColor(self.titleBarColor)
			render.drawRect(0, 0, w, th)
			
			render.setColor(self.mainColor)
			render.drawRect(0, th, w, h - th)
			
			-- Resize corner
			if self._resizeable then
				local m = Matrix()
				m:setTranslation(Vector(w, h))
				m:setScale(Vector(self._dragcorner_size))
				
				render.pushMatrix(m)
				render.setColor(self.titleBarColor)
				render.drawPoly(tri)
				render.popMatrix()
			end
			
			-- Titlebar text
			local ax, ay = self._title_alignment_x, self._title_alignment_y
			
			render.setFont(self.titleFont)
			render.setColor(self.titleColor)
			render.drawSimpleText(ax == 0 and 0 or (ax == 1 and tw / 2 or tw), ay == 3 and 0 or (ay == 1 and th2 or th), self._title, ax, ay)
			
			-- Close button
			if self._closeable then
				local th = self._text_height
				local s = Vector(th / 12, th)
				local a = self._closed and 90 or (self._close_hovering and math.sin(self:getAnimation("close_hover") * math.pi / 2) * 90 or math.cos(self:getAnimation("close_hover") * math.pi / 2) * 90)
				local c = self:getAnimation("collapse") * (45 - (math.sin(self:getAnimation("close_hover")) * 20 * self:getAnimation("collapse")))
				
				local m = Matrix()
				m:setTranslation(Vector(w - th2, th2))
				m:setAngles(Angle(0, 45 + a - c, 0))
				m:setScale(s)
				render.pushMatrix(m)
				render.drawPoly(rect)
				render.popMatrix()
				
				m:setScale(Vector(1, 1))
				m:setAngles(Angle(0, 135 + a + c, 0))
				m:setScale(s)
				render.pushMatrix(m)
				render.drawPoly(rect)
				render.popMatrix()
			end
		end,
		
		onPostDraw = function(self, w, h)
			if not self._resize_overlay then return end
			
			local x, y = self._gui:getCursorPos(self.parent)
			local g = self._grab
			
			if x and g then
				local dx, dy, dw, dh = self._x, self._y, w, h
				
				if g.move then
					dx = math.floor(x - g.x)
					dy = math.floor(y - g.y)
				else
					local nw = math.max(self._min_x, math.floor(x - self._x + g.x))
					local nh = math.max(self._min_y, math.floor(y - self._y + g.y))
					
					if nw ~= self._w or nh ~= self._h then
						if g.size then
							dw = nw
							dh = nh
						elseif g.sizex then
							dw = nw
						elseif g.sizey then
							dh = nh
						end
					end
				end
				
				render.setRGBA(255, 255, 255, 20)
				render.drawRect(dx, dy, dw, dh)
			end
		end,
		
		onDrag = function(self) end,
		onClose = function(self) --[[retrun true to supress the default removal of the element]] end,
		onResize = function(self) end
		
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
				return clr and (type(clr) == "string" and self._theme[clr] or clr) or self._theme.primaryColorLight
			end
		},
		
		titleBarColor = {
			set = function(self, color)
				self._title_bar_color = color
				
				self:_changed(true)
			end,
			
			get = function(self)
				local clr = self._title_bar_color
				return clr and (type(clr) == "string" and self._theme[clr] or clr) or self._theme.primaryColorDark
			end
		},
		
		titleColor = {
			set = function(self, color)
				self._title_color = color
				
				self:_changed(true)
			end,
			
			get = function(self)
				local clr = self._title_color
				return clr and (type(clr) == "string" and self._theme[clr] or clr) or self._theme.primaryTextColor
			end
		},
		
		------------------------------
		
		title = {
			set = function(self, text)
				self._title = text
				
				self:_changed(true)
			end,
			
			get = function(self)
				return self._title
			end
		},
		
		titleFont = {
			set = function(self, font)
				self._title_font = font
				
				self:_setTextHeight()
				self:_changed(true)
			end,
			
			get = function(self)
				return self._title_font or self._theme.font
			end
		},
		
		titleAlignmentX = {
			set = function(self, x)
				self._title_alignment_x = x
				
				self:_changed(true)
			end,
			
			get = function(self)
				return self._title_alignment_x
			end
		},
		
		titleAlignmentY = {
			set = function(self, y)
				self._title_alignment_y = y
				
				self:_changed(true)
			end,
			
			get = function(self)
				return self._title_alignment_y
			end
		},
		
		titleAlignment = {
			set = function(self, x, y)
				self._title_alignment_x = x
				self._title_alignment_y = y
				
				self:_changed(true)
			end,
			
			get = function(self)
				return self._title_alignment_x, self._title_alignment_y
			end
		},
		
		titleHeight = {
			set = function(self, value)
				self._title_height = value
				
				self:_changed(true)
				self:_calculateInner()
			end,
			
			get = function(self)
				return self._title_height
			end
		},
		
		------------------------------
		
		animationSpeed = {
			set = function(self, value)
				self._animation_speed = value
			end,
			
			get = function(self)
				return self._animation_speed or self._theme.animationSpeed
			end
		},
		
		resizeFPS = {
			set = function(self, value)
				self._resize_fps = value
			end,
			
			get = function(self)
				return self._resize_fps
			end
		},
		
		resizeOverlay = {
			set = function(self, value)
				self._resize_overlay = value
			end,
			
			get = function(self)
				return self._resize_overlay
			end
		},
		
		dragcornerSize = {
			set = function(self, value)
				self._dragcorner_size = value
			end,
			
			get = function(self)
				return self._dragcorner_size
			end
		},
		
		dragbarSize = {
			set = function(self, value)
				self._dragbar_size = value
			end,
			
			get = function(self)
				return self._dragbar_size
			end
		},
		
		minSizeX = {
			set = function(self, x)
				self._min_x = x
			end,
			
			get = function(self)
				return self._min_x
			end
		},
		
		minSizeY = {
			set = function(self, y)
				self._min_y = y
			end,
			
			get = function(self)
				return self._min_y
			end
		},
		
		minSize = {
			set = function(self, x, y)
				if y then
					self._min_x = x
					self._min_y = y
				else
					self._min_x = x.x
					self._min_y = x.y
				end
			end,
			
			get = function(self)
				return self._min_x, self._min_y
			end
		},
		
		------------------------------
		
		dragable = {
			set = function(self, state)
				self._dragable = state
			end,
			
			get = function(self)
				return self._dragable
			end
		},
		
		closeable = {
			set = function(self, state)
				self._closeable = state
			end,
			
			get = function(self)
				return self._closeable
			end
		},
		
		resizeable = {
			set = function(self, state)
				self._resizeable = state
			end,
			
			get = function(self)
				return self._resizeable
			end
		},
		
		collapseOnClose = {
			set = function(self, state)
				self._collapse_on_close = state
			end,
			
			get = function(self)
				return self._collapse_on_close
			end
		},
		
		------------------------------
		
		inner = {
			get = function(self)
				return self._inner
			end
		}
	}
	
}