--  DDDDDDDDDDDDD      EEEEEEEEEEEEEEEEEEEEEE     OOOOOOOOO             GGGGGGGGGGGGG 333333333333333   
--  D::::::::::::DDD   E::::::::::::::::::::E   OO:::::::::OO        GGG::::::::::::G3:::::::::::::::33 
--  D:::::::::::::::DD E::::::::::::::::::::E OO:::::::::::::OO    GG:::::::::::::::G3::::::33333::::::3
--  DDD:::::DDDDD:::::DEE::::::EEEEEEEEE::::EO:::::::OOO:::::::O  G:::::GGGGGGGG::::G3333333     3:::::3
--    D:::::D    D:::::D E:::::E       EEEEEEO::::::O   O::::::O G:::::G       GGGGGG            3:::::3
--    D:::::D     D:::::DE:::::E             O:::::O     O:::::OG:::::G                          3:::::3
--    D:::::D     D:::::DE::::::EEEEEEEEEE   O:::::O     O:::::OG:::::G                  33333333:::::3 
--    D:::::D     D:::::DE:::::::::::::::E   O:::::O     O:::::OG:::::G    GGGGGGGGGG    3:::::::::::3  
--    D:::::D     D:::::DE:::::::::::::::E   O:::::O     O:::::OG:::::G    G::::::::G    33333333:::::3 
--    D:::::D     D:::::DE::::::EEEEEEEEEE   O:::::O     O:::::OG:::::G    GGGGG::::G            3:::::3
--    D:::::D     D:::::DE:::::E             O:::::O     O:::::OG:::::G        G::::G            3:::::3
--    D:::::D    D:::::D E:::::E       EEEEEEO::::::O   O::::::O G:::::G       G::::G            3:::::3
--  DDD:::::DDDDD:::::DEE::::::EEEEEEEE:::::EO:::::::OOO:::::::O  G:::::GGGGGGGG::::G3333333     3:::::3
--  D:::::::::::::::DD E::::::::::::::::::::E OO:::::::::::::OO    GG:::::::::::::::G3::::::33333::::::3
--  D::::::::::::DDD   E::::::::::::::::::::E   OO:::::::::OO        GGG::::::GGG:::G3:::::::::::::::33 
--  DDDDDDDDDDDDD      EEEEEEEEEEEEEEEEEEEEEE     OOOOOOOOO             GGGGGG   GGGG 333333333333333   
--  
--  DaDam's Engine Of GUI (DEOG) A starfall DEOG engine

--[[
	TODO:
	remake whole lib with backwards compatability (mostly)
	to lazy to rewrite atm
]]

local gui = {
	elements = {},
	leftClickButtons = {[107] = true, [15] = true}, --Leftclick and E by default
	rightClickButtons = {[108] = true}, --Rightclick by default
	doubleClickTime = 0.5,
	visabilityUpdate = 0.1,
	nextVisabilityUpdate = 0,
	useServerPlayerSay = true
}

local net = net

if SERVER then
	if net.dataReceive then
		hook.add("playerSay", "", function(ply, text)
			if not gui.useServerPlayerSay then return end
			
			net.sendData("lib_gui", text, ply)
		end)
	else
		hook.add("playerSay", "", function(ply, text)
			if not gui.useServerPlayerSay then return end
			
			net.start("lib_gui")
			net.writeString(text)
			net.send(ply)
		end)
	end
	
	return
end


local removeBuffer = {}
local objects = {}
local cursorPos
local buttonsDown = {
	leftButtons = {},
	rightButtons = {},
	last = 0
}

--[[
	TODO:
	
	add arrows to scrollbar
]]

local defaultFont = render.createFont("roboto", 18, 800)
local defaultSettings = {
	enabled = true,
	pos = Vector(),
	size = Vector(100, 30),
	childOffset = Vector(),
	onScreen = false,
	solid = true
}
local defaultMethods = {
	focus = function(self)
		local data = gui.getCoreData(self)
		
		if data.parent then
			local parent = gui.getCoreData(data.parent)
			
			for k, v in pairs(parent.children) do
				if v.panel == self then
					table.remove(parent.children, k)
					table.insert(parent.children, data)
				end
			end
		else
			for k, v in pairs(objects) do
				if v.panel == self then
					table.remove(objects, k)
					table.insert(objects, data)
				end
			end
		end
	end,
	fill = function(self)
		local data = gui.getCoreData(self)
		
		self.pos = Vector(0, 0)
		
		if data.parent then
			self.size = data.parent.size
		else
			self.size = Vector(512, 512)
		end
	end
}

------------------------------

local function drawRoundedRect(cornersize, quality, x, y, w, h)
	local poly = {}
	
	local function corner(x, y, ang)
		for i = 0, quality - 1 do
			local rad = math.rad(ang + i / (quality - 1) * 90)
			
			table.insert(poly, {
				x = x + math.cos(rad) * cornersize,
				y = y + math.sin(rad) * cornersize
			})
		end
	end
	
	corner(x + cornersize, y + cornersize, 180)
	corner(x + w - cornersize, y + cornersize, 270)
	corner(x + w - cornersize, y + h - cornersize, 0)
	corner(x + cornersize, y + h - cornersize, 90)
	
	render.drawPoly(poly)
end

local function removeObject(data)
	for i, v in pairs(data.children) do
		removeObject(v)
	end
	
	if data.parent then
		for i, v in pairs(gui.getCoreData(data.parent).children) do
			if v.panel == data.panel then
				table.remove(gui.getCoreData(data.parent).children, i)
				
				break
			end
		end
	else
		for i, v in pairs(objects) do
			if v.panel == data.panel then
				table.remove(objects, i)
				
				break
			end
		end
	end
end

------------------------------

hook.add("inputPressed", "lib_gui", function(key)
	if not cursorPos or cursorPos == -1 then return end
	
	if gui.leftClickButtons[key] then
		if timer.curtime() - buttonsDown.last < gui.doubleClickTime then
			gui.callFunc("onDoubleClick")
		end
		
		buttonsDown.leftButtons[key] = true
		buttonsDown.last = timer.curtime()
		
		gui.callFunc("onClick")
	elseif gui.rightClickButtons[key] then
		buttonsDown.rightButtons[key] = true
		
		gui.callFunc("onRightClick")
	end
end)

hook.add("inputReleased", "lib_gui", function(key)
	if not cursorPos or cursorPos == -1 then return end
	
	if gui.leftClickButtons[key] then
		buttonsDown.leftButtons[key] = nil
		
		if table.count(buttonsDown.leftButtons) == 0 then
			gui.callFunc("onRelease")
		end
	elseif gui.rightClickButtons[key] then
		buttonsDown.rightButtons[key] = nil
		
		if table.count(buttonsDown.leftButtons) == 0 then
			gui.callFunc("onRightRelease")
		end
	end
end)

hook.add("playerChat", "lib_gui", function(ply, text)
	if gui.useServerPlayerSay or ply ~= player() then return end
	
	gui.callFunc("onChat", text)
end)

--[[timer.create("lib_gui", gui.visabilityUpdate, 0, function()
	local x, y = render.getResolution()
	
	if not x then return end
	
	for k, v in pairs(gui.getCorrectOrder()) do
		local pos = gui.getGlobalPos(v.obj.panel)
		
		v.obj.panel.onScreen = pos.y < y and pos.y + v.obj.panel.size.y > 0 and pos.x < x and pos.x + v.obj.panel.size.x > 0
	end
end)]]

if net.dataReceive then --DEOM2
	net.dataReceive("lib_gui", function(text)
		gui.callFunc("onChat", text)
	end)
else
	net.receive("lib_gui", function()
		gui.callFunc("onChat", net.readString())
	end)
end

------------------------------

function gui.getCursorPos(panel)
	return cursorPos.x == -1 and cursorPos or gui.getLocalPos(panel, cursorPos)
end

function gui.getCursorPosGlobal()
	return cursorPos
end

function gui.getGlobalPos(panel, offset)
	local parent = gui.getCoreData(panel).parent
	
	if not parent then
		return panel.pos + (offset and offset or Vector())
	else
		return gui.getGlobalPos(parent, panel.pos + (offset or Vector()) + parent.childOffset)
	end
end

function gui.getLocalPos(panel, pos)
	return pos - gui.getGlobalPos(panel)
end

function gui.isCursorOnPanel(panel)
	local point = cursorPos
	
	if point.x == -1 then return false end
	
	for k, v in pairs(gui.getCorrectOrder()) do
		if v.obj.panel.enabled and (v.obj.panel.solid or v.obj.panel == panel) and point.x > v.pos.x and point.y > v.pos.y and point.x < v.pos.x + v.obj.panel.size.x and point.y < v.pos.y + v.obj.panel.size.y then
			local parent = v.obj.parent
			while parent do
				if not parent.enabled then
					goto skip
				end
				
				parent = gui.getCoreData(parent).parent
			end
			
			return v.obj.panel == panel
		end
		
		::skip::
	end
	
	return false
end

function gui.isPointOnPanel(panel, point, min, max)
	local point = gui.getGlobalPos(panel, point)
	
	for k, v in pairs(gui.getCorrectOrder()) do
		if v.obj.panel == panel then
			if point.x > v.pos.x + min.x and point.y > v.pos.y + min.y and point.x < v.pos.x + max.x and point.y < v.pos.y + max.y then
				return true
			end
		else
			if v.obj.panel.solid and point.x > v.pos.x and point.y > v.pos.y and point.x < v.pos.x + v.obj.panel.size.x and point.y < v.pos.y + v.obj.panel.size.y then
				return false
			end
		end
	end
	
	return false
end

function gui.getCorrectOrder()
	local data = {}
	
	local function doObject(obj, offset)
		--if not obj.panel.enabled or not obj.panel.onScreen then return end
		
		table.insert(data, 1, {
			obj = obj,
			pos = offset + obj.panel.pos
		})
		
		if #obj.children > 0 then
			for i, v in pairs(obj.children) do
				doObject(v, offset + obj.panel.pos + obj.panel.childOffset)
			end
		end
	end
	
	for i, v in pairs(objects) do
		doObject(v, Vector())
	end
	
	return data
end

function gui.callFunc(func, ...)
	for k, v in pairs(gui.getCorrectOrder()) do
		--[[if v.functions[func] and v.panel.enabled then
			v.functions[func](v.panel)
		end]]
		if v.obj.panel.enabled and v.obj.panel.onScreen and gui.elements[v.obj.typ].functions[func] then
			gui.elements[v.obj.typ].functions[func](v.obj.panel, ...)
		end
	end
end

function gui.getCoreData(panel)
	for k, v in pairs(gui.getCorrectOrder()) do
		if v.obj.panel == panel then
			return v.obj
		end
	end
end

------------------------------

function gui.registerElement(name, inherit, data)
	if not data then
		data = inherit
		inherit = nil
		
		for k, v in pairs(defaultSettings) do
			if data.settings[k] == nil then
				data.settings[k] = v
			end
		end
	else
		if not gui.elements[inherit] then error("DEOG3: tried to register gui element with invalid inherit type of " .. inherit) end
		
		data.settings = data.settings or {}
		local newdata = table.copy(gui.elements[inherit].coredata)
		
		--Add data
		for name, v in pairs(data) do
			if type(v) == "function" then
				newdata[name] = v
			end
		end
		
		if data.settings then
			newdata.settings = newdata.settings or {}
			
			for name, v in pairs(data.settings) do
				newdata.settings[name] = v
			end
		end
		
		if data.methods then
			newdata.methods = newdata.methods or {}
			
			for name, v in pairs(data.methods) do
				newdata.methods[name] = v
			end
		end
		
		data = newdata
	end
	
	local functions = {}
	local panel = {}
	panel.__index = panel
	
	for name, v in pairs(data) do
		if type(v) == "function" then
			functions[name] = v
		end
	end
	
	if data.settings then
		for name, v in pairs(data.settings) do
			local lname = name
			
			if type(v) == "function" then
				panel[lname] = function(self, func) self[lname] = func end
			else
				local raisedName = string.upper(lname[1]) .. string.sub(lname, 2)
				
				panel["get" .. raisedName] = function(self) return self[lname] end
				panel["set" .. raisedName] = function(self, value) self[lname] = value end
			end
		end
	end
	
	if data.methods then
		for name, v in pairs(data.methods) do
			panel[name] = v
		end
	end
	
	for name, v in pairs(defaultMethods) do
		panel[name] = v
	end
	
	gui.elements[name] = {
		panel = panel,
		functions = functions,
		settings = data.settings,
		coredata = data
	}
end

function gui.create(typ, parent)
	if not gui.elements[typ] then error("DEOG3: tried to create invalid gui element type of " .. typ) end
	
	local paneltable = {}
	
	for k, v in pairs(gui.elements[typ].panel) do
		if type(v) == "table" then
			paneltable[k] = table.copy(v)
		else
			paneltable[k] = v
		end
	end
	
	local data = {
		panel = setmetatable({}, paneltable),
		typ = typ,
		--functions = {},
		children = {},
		parent = parent
	}
	
	--[[for name, func in pairs(gui.elements[typ].functions) do
		data.functions[name] = func
	end]]
	
	for name, v in pairs(gui.elements[typ].settings) do
		if type(v) ~= "table" then
			data.panel[name] = v
		else
			data.panel[name] = table.copy(v)
		end
	end
	
	function data.panel:remove()
		table.insert(removeBuffer, data)
	end
	
	if parent then
		table.insert(gui.getCoreData(parent).children, data)
	else
		table.insert(objects, data)
	end
	
	if gui.elements[typ].functions.onCreate then
		gui.elements[typ].functions.onCreate(data.panel)
	end
	
	return data.panel
end

function gui.createConstructors(global)
	if global then
		for typ, data in pairs(gui.elements) do
			_G[string.upper(typ[2]) .. string.sub(typ, 2)] = function(parent) return gui.create(typ, parent) end
		end
	else
		for typ, data in pairs(gui.elements) do
			gui[typ] = function(parent) return gui.create(typ, parent) end
		end
	end
end

function gui.think(x, y)
	if not x then
		x, y = render.cursorPos()
	end
	
	cursorPos = Vector(x or -1, y or -1)
	
	while #removeBuffer > 0 do
		removeObject(removeBuffer[1])
		
		table.remove(removeBuffer, 1)
	end
	
	gui.callFunc("onThink")
end

function gui.render()
	gui.nextVisabilityUpdate = gui.nextVisabilityUpdate - timer.frametime()
	if gui.nextVisabilityUpdate <= 0 then
		gui.nextVisabilityUpdate = gui.visabilityUpdate
		
		local x, y = render.getResolution()
		
		if not x then return end
		
		for k, v in pairs(gui.getCorrectOrder()) do
			local pos = gui.getGlobalPos(v.obj.panel)
			
			v.obj.panel.onScreen = pos.y < y and pos.y + v.obj.panel.size.y > 0 and pos.x < x and pos.x + v.obj.panel.size.x > 0
		end
	end
	
	local function renderObject(obj, offset)
		if not obj.panel.enabled or not obj.panel.onScreen then return end
		
		local pos = offset + obj.panel.pos
		local matrix = Matrix()
		matrix:setTranslation(Vector(pos.x, pos.y))
		
		render.pushMatrix(matrix)
			obj.panel.deog_render_matrix = matrix
			gui.elements[obj.typ].functions.onDraw(obj.panel)
		render.popMatrix(matrix)
		
		if #obj.children > 0 then
			for i, v in pairs(obj.children) do
				renderObject(v, offset + obj.panel.pos + obj.panel.childOffset)
			end
		end
	end
	
	for i, v in pairs(objects) do
		--if gui.getCoreData(v.panel).parent then continue end
		
		renderObject(v, Vector())
	end
end

--[[function gui.debug()
	render.setColor(Color(255, 0, 0))
	
	local function renderObject(obj, offset)
		local matrix = Matrix()
		matrix:setTranslation(offset + obj.panel.pos)
		render.pushMatrix(matrix)
			render.drawRectOutline(0, 0, obj.panel.size.x, obj.panel.size.y)
		render.popMatrix(matrix)
		
		if #obj.children > 0 then
			for i, v in pairs(obj.children) do
				renderObject(v, offset + obj.panel.pos + obj.panel.childOffset)
			end
		end
	end
	
	for i, v in pairs(objects) do
		if v.panel.parent then continue end
		
		renderObject(v, Vector())
	end
end]]

------------------------------

-----Text-----
gui.registerElement("text", {
	settings = {
		color = Color(50, 50, 50),
		font = defaultFont,
		text = "Text",
		wrap = true,
		allignmentX = 1,
		allignmentY = 1,
		wrapFunction = function(self)
			local text = ""
			local line = ""
			
			local function doWord(word)
				local w, h = render.getTextSize(line .. " " .. word)
				
				if w > self.size.x then
					text = text .. line .. "\n"
					line = word
				else
					line = line .. " " .. word
				end
			end
			
			for k, part in pairs(string.split(self.text, " ")) do
				local words = string.split(part, "\n")
				
				for k, word in pairs(words) do
					doWord(word)
					
					if k < #words then
						line = line .. "\n"
					end
				end
			end
			
			if line == "" then
				text = string.sub(text, 1, #text - 1)
			else
				text = text .. line
			end
			
			return text
		end,
		draw = function(self, size)
			render.setColor(self.color)
			render.setFont(self.font)
			render.drawText(self.allignmentX == 0 and 0 or (self.allignmentX == 1 and self.size.x/2 or self.size.x), self.allignmentY == 0 and 0 or (self.allignmentY == 1 and self._textOffset or self.size.y - self._textHeight), self._wrappedText, self.allignmentX)
		end,
		drawOver = function(self, size) end
	}, onDraw = function(self)
		if self.font ~= self._lastFont or self.text ~= self._lastText then
			if self.wrap then
				self._wrappedText = self.wrapFunction(self)
			else
				self._wrappedText = self.text
			end
			
			render.setFont(self.font)
			local w, h = render.getTextSize(self._wrappedText)
			
			self._textOffset = (self.size.y - h) / 2
			self._textHeight = h
			self._lastFont = self.font
			self._lastText = self.text
		end
		
		self.draw(self, self.size)
		self.drawOver(self, self.size)
	end
})

-----Container-----
gui.registerElement("container", {
	settings = {
		color = Color(220, 220, 220),
		colorBorder = Color(50, 50, 50),
		borderSize = 2,
		draw = function(self, size)
			render.setColor(self.colorBorder)
			render.drawRect(0, 0, size.x, size.y)
			
			render.setColor(self.color)
			render.drawRect(self.borderSize, self.borderSize, size.x - self.borderSize*2, size.y - self.borderSize*2)
		end,
		drawOver = function(self, size) end
	}, onDraw = function(self)
		self.draw(self, self.size)
		self.drawOver(self, self.size)
	end
})

-----Frame-----
gui.registerElement("frame", "container", {
	settings = {
		colorText = Color(220, 220, 220),
		size = Vector(100, 125),
		headSize = 25,
		font = defaultFont,
		title = "Frame",
		grabOffset = nil,
		draw = function(self, size)
			render.setColor(self.colorBorder)
			render.drawRect(0, 0, size.x, size.y)
			
			render.setColor(self.color)
			render.drawRect(self.borderSize, self.headSize, size.x - self.borderSize*2, size.y - self.borderSize - self.headSize)
			
			render.setColor(self.colorText)
			render.setFont(self.font)
			render.drawSimpleText(self.size.x/2, self.headSize/2, self.title, 1, 1)
		end,
		drawOver = function(self, size) end
	}, onCreate = function(self)
		self.closebutton = gui.create("button", self)
		--self.closebutton.pos = Vector(385, -24)
		--self.closebutton.size = Vector(23, 23)
		self.closebutton.text = "X"
		self.closebutton.onClick = function()
			self:remove()
		end
	end,
	onThink = function(self)
		if self.grabOffset then
			local cursor = gui.getCursorPos(self)
			
			if cursor.x ~= -1 then
				self.pos = self.pos + cursor - self.grabOffset
			end
		end
		
		self.childOffset = Vector(self.borderSize, self.headSize)
		
		if self.closebutton then
			self.closebutton.pos = Vector(self.size.x - self.borderSize - self.headSize + 1, -self.headSize + 1)
			self.closebutton.size = Vector(self.headSize - 2, self.headSize - 2)
		end
	end,
	onDraw = function(self)
		self.draw(self, self.size)
		self.drawOver(self, self.size)
	end,
	onClick = function(self)
		local cursor = gui.getCursorPos(self)
		
		if gui.isPointOnPanel(self, cursor, Vector(), Vector(self.size.x, self.headSize)) then
			self.grabOffset = cursor
		end
		
		if gui.isCursorOnPanel(self) then
			self:focus()
		end
	end,
	onRelease = function(self)
		self.grabOffset = nil
	end
})

-----Label-----
gui.registerElement("label", "container", {
	settings = {
		colorText = Color(50, 50, 50),
		font = defaultFont,
		text = "Label",
		textAllignment = 1,
		draw = function(self, size)
			render.setColor(self.colorBorder)
			render.drawRect(0, 0, size.x, size.y)
			
			render.setColor(self.color)
			render.drawRect(self.borderSize, self.borderSize, size.x - self.borderSize*2, size.y - self.borderSize*2)
			
			render.setColor(self.colorText)
			render.setFont(self.font)
			render.drawSimpleText(self.textAllignment == 0 and self._textOffset or (self.textAllignment == 1 and size.x/2 or size.x - self._textOffset), size.y/2, self.text, self.textAllignment, 1)
		end,
		drawOver = function(self, size) end
	}, onDraw = function(self)
		if self.font ~= self._lastFont then
			render.setFont(self.font)
			local w, h = render.getTextSize(" ")
			
			self._textOffset = (self.size.y - h) / 2
			self._lastFont = self.font
		end
		
		self.draw(self, self.size)
		self.drawOver(self, self.size)
	end
})

-----Button-----
gui.registerElement("button", "label", {
	settings = {
		colorHover = Color(200, 200, 200),
		colorClick = Color(170, 170, 170),
		text = "Button",
		hovering = false,
		mouseLeftDown = false,
		mouseRightDown = false,
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
		--[[draw = function(self, size)
			render.setColor(self.colorBorder)
			render.drawRect(0, 0, size.x, size.y)
			
			render.setColor((self.mouseLeftDown or self.mouseRightDown) and self.colorClick or (self.hovering and self.colorHover or self.color))
			render.drawRect(self.borderSize, self.borderSize, size.x - self.borderSize*2, size.y - self.borderSize*2)
			
			render.setColor(self.colorText)
			render.setFont(self.font)
			render.drawSimpleText(size.x/2, size.y/2, self.text, 1, 1)
		end,]]
		drawOver = function(self, size) end
	}, onThink = function(self)
		local lastHover = self.hovering
		self.hovering = gui.isCursorOnPanel(self)
		
		if lastHover ~= self.hovering then
			if self.hovering then
				self.onHoverBegin(self)
			else
				self.onHoverEnd(self)
			end
		elseif self.hovering then
			self.onHover(self)
		end
		
		if self.mouseLeftDown then
			self.onHold(self)
		end
		
		if self.mouseRightDown then
			self.onRightHold(self)
		end
	end,
	--[[onDraw = function(self)
		self.draw(self, self.size)
		self.drawOver(self, self.size)
	end,]]
	onClick = function(self)
		if self.hovering then
			self.mouseLeftDown = true
			self.onClick(self)
		end
	end,
	onRightClick = function(self)
		if self.hovering then
			self.mouseRightDown = true
			self.onRightClick(self)
		end
	end,
	onDoubleClick = function(self)
		if self.hovering then
			self.onDoubleClick(self)
		end
	end,
	onRelease = function(self)
		if self.mouseLeftDown then
			self.mouseLeftDown = false
			self.onRelease(self)
		end
	end,
	onRightRelease = function(self)
		if self.mouseRightDown then
			self.mouseRightDown = false
			self.onRightRelease(self)
		end
	end
})

-----Button Grid-----
gui.registerElement("buttongrid", "button", {
	settings = {
		size = Vector(210, math.huge),
		buttonSize = Vector(100, 30),
		spacing = Vector(5, 5),
		buttons = {},
		useScissorRect = false,
		text = nil,
		hovering = false,
		mouseLeftDown = false,
		mouseRightDown = false,
		maxX = 0,
		draw = function(self, index, pos, size)
			render.setColor(self.colorBorder)
			render.drawRect(pos.x, pos.y, size.x, size.y)
			
			render.setColor((self.mouseLeftDown == index or self.mouseRightDown == index) and self.colorClick or (self.hovering == index and self.colorHover or self.color))
			render.drawRect(pos.x + self.borderSize, pos.y + self.borderSize, size.x - self.borderSize*2, size.y - self.borderSize*2)
			
			render.setColor(self.colorText)
			render.setFont(self.font)
			render.drawSimpleText(pos.x + size.x/2, pos.y + size.y/2, self.buttons[index], 1, 1)
		end
	}, methods = {
		addButton = function(self, text)
			table.insert(self.buttons, text)
		end,
		getOccupiedSpace = function(self)
			local y = math.ceil(#self.buttons / self.maxX)
			
			return Vector(self.maxX * self.buttonSize.x + (self.maxX - 1) * self.spacing.x, y * self.buttonSize.y + (y - 1) * self.spacing.y)
		end
	}, onThink = function(self)
		local lastHover = self.hovering
		local pos = gui.getCursorPos(self)
		local size = self.buttonSize + self.spacing
		
		self.maxX = math.floor((self.size.x + self.spacing.x) / size.x)
		
		if gui.isCursorOnPanel(self) then
			if pos.x < 0 or pos.x > self.maxX * size.x then
				self.hovering = false
			else
				if pos.x % size.x > self.buttonSize.x or pos.y % size.y > self.buttonSize.y then
					self.hovering = false
				else
					self.hovering = 1 + math.floor(pos.x / size.x) + (math.floor(pos.y / size.y) * self.maxX)
					
					if self.hovering < 1 or self.hovering > #self.buttons then
						self.hovering = false
					end
				end
			end
		else
			self.hovering = false
		end
		
		if lastHover ~= self.hovering then
			if self.hovering then
				self.onHoverBegin(self, self.hovering)
			else
				self.onHoverEnd(self, lastHover)
			end
		elseif self.hovering then
			self.onHover(self, self.hovering)
		end
	end,
	onDraw = function(self)
		local gpos = gui.getGlobalPos(self)
		local size = self.buttonSize
		local sw, sh = render.getResolution()
		
		if self.useScissorRect then
			render.enableScissorRect(gpos.x, gpos.y, gpos.x + self.size.x, gpos.y + self.size.y)
		end
		
		for i = math.max(1, math.floor(-gpos.y / (size.y + self.spacing.y)) * self.maxX + 1), math.min(#self.buttons, math.floor((-gpos.y + sh + (size.y + self.spacing.y)) / (size.y + self.spacing.y)) * self.maxX) do
			local pos = Vector(((i - 1) % self.maxX) * (size.x + self.spacing.x), math.floor((i - 1) / self.maxX) * (size.y + self.spacing.y))
			
			self.draw(self, i, pos, size)
			self.drawOver(self, i, pos, size)
		end
		
		if self.useScissorRect then
			render.disableScissorRect()
		end
	end,
	onClick = function(self)
		if self.hovering then
			self.mouseLeftDown = self.hovering
			self.onClick(self, self.hovering)
		end
	end,
	onRightClick = function(self)
		if self.hovering then
			self.mouseRightDown = self.hovering
			self.onRightClick(self, self.hovering)
		end
	end,
	onDoubleClick = function(self)
		if self.hovering then
			self.onDoubleClick(self, self.hovering)
		end
	end,
	onRelease = function(self)
		if self.mouseLeftDown then
			self.onRelease(self, self.mouseLeftDown)
			self.mouseLeftDown = false
		end
	end,
	onRightRelease = function(self)
		if self.mouseRightDown then
			self.onRightRelease(self, self.mouseRightDown)
			self.mouseRightDown = false
		end
	end
})

-----Checkbox-----
gui.registerElement("checkbox", {
	settings = {
		color = Color(220, 220, 220),
		colorBorder = Color(50, 50, 50),
		colorOn = Color(30, 255, 110),
		colorOff = Color(190, 60, 30),
		borderSize = 2,
		state = false,
		anim = 0,
		onChange = function(self, state) end,
		draw = function(self, size)
			render.setColor(self.colorBorder)
			render.drawRect(0, 0, size.y, size.y)
			
			render.setColor(self.color)
			render.drawRect(self.borderSize, self.borderSize, size.y - self.borderSize*2, size.y - self.borderSize*2)
			
			local size = (self.size.y - self.borderSize*4) * self.anim
			local size2 = (self.size.y - self.borderSize*4) * (1 - self.anim) * 0.5
			render.setColor(self.colorOff * (1 - self.anim) + self.colorOn * self.anim)
			render.drawRect(self.borderSize*2 + size2, self.borderSize*2 + size2, size, size)
		end,
		drawOver = function(self, size) end
	}, onCreate = function(self)
		self.label = gui.create("label", self)
		self.label.text = "Checkbox"
		self.label.solid = false
		self.label.textAllignment = 0
	end,
	onThink = function(self)
		if self.state then
			if self.anim < 1 then
				self.anim = math.min(self.anim + timer.frametime()*7, 1)
			end
		elseif self.anim > 0 then
			self.anim = math.max(self.anim - timer.frametime()*7, 0)
		end
		
		if self.label then
			self.label.pos = Vector(self.size.y, 0)
			self.label.size = Vector(self.size.x - self.size.y, self.size.y)
		end
	end,
	onDraw = function(self)
		self.draw(self, self.size)
		self.drawOver(self, self.size)
	end,
	onClick = function(self)
		if gui.isCursorOnPanel(self) then
			self.state = not self.state
			self.onChange(self, self.state)
		end
	end
})

-----Text Entry-----
gui.registerElement("textentry", "label", {
	settings = {
		text = "",
		textEmpty = "textentry",
		selected = false,
		onClick = function(self) end,
		onChange = function(self, text) end,
		draw = function(self, size)
			render.setColor(self.colorBorder)
			render.drawRect(0, 0, size.x, size.y)
			
			render.setColor(self.color)
			render.drawRect(self.borderSize, self.borderSize, size.x - self.borderSize*2, size.y - self.borderSize*2)
			
			local isEmpty = self.text == ""
			render.setColor(isEmpty and Color(self.colorText.r, self.colorText.g, self.colorText.b, 100) or self.colorText)
			render.setFont(self.font)
			render.drawSimpleText(self._textOffset, size.y/2, isEmpty and self.textEmpty or self.text, 0, 1)
			
			if self.selected and math.round(timer.curtime())%2 == 1 then
				render.setColor(self.colorBorder)
				render.drawRect(self.borderSize*2, self.borderSize*2, self.borderSize, self.size.y - self.borderSize*4)
			end
		end,
	}, onDraw = function(self)
		if self.font ~= self._lastFont then
			render.setFont(self.font)
			local w, h = render.getTextSize(" ")
			
			self._textOffset = (self.size.y - h) / 2
			self._lastFont = self.font
		end
		
		self.draw(self, self.size)
		self.drawOver(self, self.size)
	end,
	onClick = function(self)
		if gui.isCursorOnPanel(self) then
			self.selected = true
			
			self.onClick(self)
		else
			self.selected = false
		end
	end,
	onChat = function(self, text)
		if self.selected then
			local s, e = string.find(text, "[ ]+")
			
			if s == 1 then
				text = string.sub(text, e + 1)
			end
			
			self.text = text
			self.selected = false
			
			self.onChange(self, text)
		end
	end
})

-----Slider-----
gui.registerElement("slider", "label", {
	settings = {
		colorOn = Color(30, 255, 110),
		colorOff = Color(190, 60, 30),
		size = Vector(100, 20),
		barSize = 10,
		round = 1,
		holding = false,
		value = 0,
		min = 0,
		max = 1,
		onChange = function(self, value) end,
		draw = function(self, size)
			local barSize = self.barSize
			render.setColor(self.colorBorder)
			drawRoundedRect(barSize/2, 3, self.size.y/2 - self.barSize/2, self.size.y/2 - self.barSize/2, self.size.x - self.size.y + self.barSize, barSize)
			
			local borderSize = self.borderSize
			render.setColor(self.colorOff)
			drawRoundedRect(barSize/2 - borderSize, 3, self.size.y/2 - self.barSize/2 + borderSize, self.size.y/2 - self.barSize/2 + borderSize, self.size.x - self.size.y + self.barSize - borderSize*2, barSize - borderSize*2)
			
			local valueScale = (self.value + math.abs(self.min)) / (self.max - self.min)
			render.setColor(self.colorOn)
			drawRoundedRect(barSize/2 - borderSize, 3, self.size.y/2 - self.barSize/2 + borderSize, self.size.y/2 - self.barSize/2 + borderSize, (self.size.x - self.size.y + self.barSize) * valueScale - borderSize*2, barSize - borderSize*2)
			
			render.setColor(self.colorBorder)
			drawRoundedRect(self.size.y/2, 5, valueScale * (self.size.x - self.size.y), 0, self.size.y, self.size.y)
			
			render.setColor(self.color)
			drawRoundedRect(self.size.y/2 - borderSize, 5, valueScale * (self.size.x - self.size.y) + borderSize, borderSize, self.size.y - borderSize*2, self.size.y - borderSize*2)
		end,
		drawOver = function(self, size) end
	}, onThink = function(self)
		if self.holding then
			local cursor = gui.getCursorPos(self)
			
			if cursor.x == -1 then return end
			
			local old = self.value
			
			self.value = math.clamp(math.round(((cursor.x - self.size.y/2) / (self.size.x - self.size.y) * (self.max - self.min) + self.min) / self.round) * self.round, self.min, self.max)
			
			if old ~= self.value then
				self.onChange(self, self.value)
			end
		end
	end,
	onDraw = function(self)
		self.draw(self, self.size)
		self.drawOver(self, self.size)
	end,
	onClick = function(self)
		if gui.isCursorOnPanel(self) then
			self.holding = true
		end
	end,
	onRelease = function(self)
		self.holding = false
	end
})

-----Box Slider-----
gui.registerElement("boxslider", "label", {
	settings = {
		colorOn = Color(30, 255, 110),
		colorOff = Color(190, 60, 30),
		size = Vector(100, 20),
		round = 1,
		holding = false,
		value = 0,
		min = 0,
		max = 1,
		onChange = function(self, value) end,
		draw = function(self, size)
			render.setColor(self.colorBorder)
			render.drawRect(0, 0, size.x, size.y)
			
			render.setColor(self.color)
			render.drawRect(self.borderSize, self.borderSize, size.x - self.borderSize*2, size.y - self.borderSize*2)
			
			local valueScale = (self.value + math.abs(self.min)) / (self.max - self.min)
			render.setColor(self.colorOn)
			render.drawRect(self.borderSize, self.borderSize, (size.x - self.borderSize*2) * valueScale, size.y - self.borderSize*2)
			
			render.setColor(self.colorOff)
			render.drawRect(self.borderSize + (size.x - self.borderSize*2) * valueScale, self.borderSize, math.ceil((size.x - self.borderSize*2) * (1 - valueScale)), size.y - self.borderSize*2)
		end,
		drawOver = function(self, size) end
	}, onThink = function(self)
		if self.holding then
			local cursor = gui.getCursorPos(self)
			
			if cursor.x == -1 then return end
			
			local old = self.value
			
			self.value = math.clamp(math.round((cursor.x / self.size.x * (self.max - self.min) + self.min) / self.round) * self.round, self.min, self.max)
			
			if old ~= self.value then
				self.onChange(self, self.value)
			end
		end
	end,
	onDraw = function(self)
		self.draw(self, self.size)
		self.drawOver(self, self.size)
	end,
	onClick = function(self)
		if gui.isCursorOnPanel(self) then
			self.holding = true
		end
	end,
	onRelease = function(self)
		self.holding = false
	end
})

-----Scrollframe-----
gui.registerElement("scrollframe", {
	settings = {
		slowdown = 7,
		vel = 0,
		solid = false,
		holding = false,
		lastCursorPos = Vector(),
		onChange = function(self, value) end
	}, onThink = function(self)
		local pos = gui.getCursorPos(self)
		
		if pos.x == -1 then
			self.holding = false
		end
		
		if self.holding then
			self.vel = pos.y - self.lastCursorPos.y
		end
		
		if self.vel ~= 0 then
			self.onChange(self, self.vel)
			
			self.vel = math.max(0, math.abs(self.vel) - timer.frametime() * self.slowdown) * (self.vel / math.abs(self.vel))
		end
		
		self.lastCursorPos = pos
	end,
	onDraw = function() end,
	onClick = function(self)
		self.holding = gui.isCursorOnPanel(self)
	end,
	onRelease = function(self)
		self.holding = false
	end
})

-----Scrollbar-----
--Credits oh please
gui.registerElement("scrollbar", "button", {
	settings = {
		size = Vector(15, 200),
		
		color = Color(220, 220, 220),
		colorBorder = Color(50, 50, 50),
		
		--colors of the actual draggable part of the scrollbar
		colorBar = Color(150, 150, 150),
		colorHover = Color(130, 130, 130),
		colorHoverBar = Color(110, 110, 110),
		colorClick = Color(90, 90, 90),
		
		borderSize = 2,
		isVertical = true,
		barContentLength = nil, --Automaticly set if nil
		contentLength = 200,
		scrollLength = 0, --Output
		
		--internal; used for drawing calculations
		hoveringBar = false,
		barGrabFrac = 0.5,
		dragging = false,
		
		onChange = function(self, scrollLength) end,
		draw = function(self, size)
			render.setColor(self.colorBorder)
			render.drawRect(0, 0, size.x, size.y)
			
			render.setColor(self.color)
			render.drawRect(self.borderSize, self.borderSize, size.x - self.borderSize*2, size.y - self.borderSize*2)
			
			local free, frac, barFrac, size = self:calcBar()
			
			if self.contentLength then
				if self.mouseLeftDown then render.setColor(self.colorClick)
				elseif self.hoveringBar then render.setColor(self.colorHoverBar) --TODO: ensure that self.hoveringBar must be false if self.hovering is false
				elseif self.hovering then render.setColor(self.colorHover)
				else render.setColor(self.colorBar) end
				
				if self.isVertical then
					render.drawRect(self.borderSize, size.y*frac + self.borderSize, size.x - self.borderSize*2, size.y*barFrac - self.borderSize*2)
				else
					render.drawRect(size.x*frac + self.borderSize, self.borderSize, size.x*barFrac - self.borderSize*2, size.y - self.borderSize*2)
				end
			end
		end,
		drawOver = function(self, size) end,
		onHover = function(self) end,
		onHoverEnd = function(self) end,
		calcBar = function(self)
			local barLength = self.barContentLength and self.barContentLength or (self.isVertical and self.size.y or self.size.x)
			local free = self.contentLength - barLength
			local frac = self.scrollLength / self.contentLength
			local barFrac = barLength / self.contentLength
			local size = self.size
			local length = self.isVertical and size.y or size.x
			
			if free <= 1e-3 then
				free = 0
				frac = 0
				barFrac = 1
			end
			
			return free, frac, barFrac, size, length
		end
	}, methods = {
		scroll = function(self, value)
			self.scrollLength = math.clamp(self.scrollLength + value, 0, self.contentLength - self.size.y)
			
			self.onChange(self, self.scrollLength)
		end
	}, onThink = function(self)
		local lastHover = self.hovering
		self.hovering = gui.isCursorOnPanel(self)
		
		if lastHover ~= self.hovering then
			if self.hovering then
				self.onHoverBegin(self)
			else
				self.hoveringBar = false
				self.onHoverEnd(self)
			end
		elseif self.hovering then
			local free,frac,barFrac,size = self:calcBar()
			local pos = gui.getCursorPos(self)
			local u = self.isVertical and (pos.y / self.size.y) or (pos.x / self.size.x)
			
			self.hoveringBar = frac <= u and u <= frac + barFrac
			self.onHover(self)
		end
		
		if self.dragging then
			local free,frac,barFrac,size,length = self:calcBar()
			local pos = gui.getCursorPos(self)
			
			if pos.x == -1 then return end
			
			local v = 1 - barFrac
			local u = self.isVertical and (pos.y / (self.size.y * v)) or (pos.x / (self.size.x * v))
			local offset = self.barGrabFrac * barFrac * self.contentLength
			
			local last = self.scrollLength
			self.scrollLength = math.clamp(u * free  - offset, 0, free)
			
			if last ~= self.scrollLength then
				self.onChange(self, self.scrollLength)
			end
			
			if self.contentLength ~= self.lastContentLength then
				self.mouseLeftDown = false
				self.dragging = false
			end
		end
		
		self.lastContentLength = self.contentLength
	end,
	onDraw = function(self)
		self.draw(self, self.size)
		self.drawOver(self, self.size)
	end,
	onClick = function(self)
		if self.hovering then
			self.mouseLeftDown = true
		end
		
		if gui.isCursorOnPanel(self) then
			local free, frac, barFrac, size = self:calcBar()
			local pos = gui.getCursorPos(self)
			local u = self.isVertical and (pos.y / self.size.y) or (pos.x / self.size.x)
			
			if frac <= u and u <= frac + barFrac then
				self.barGrabFrac = (u - frac) / barFrac
			else
				self.barGrabFrac = 0.5
			end
			
			self.dragging = true
		end
	end,
	onRelease = function(self)
		self.mouseLeftDown = false
		self.dragging = false
	end
})

------------------------------

return gui