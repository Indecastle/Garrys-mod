--@name GUI2 Docs Beta
--@author Sevii
--@include ../lib/gui2.lua
--@include ../lib/syntax_lua.lua
--@client

--[[
SF.DefaultEnvironment.debugGetLocal = function(func, index)
	if type(func) ~= "function" then SF.ThrowTypeError("function", SF.GetType(func), 2) end
	if type(index) ~= "number" then SF.ThrowTypeError("number", SF.GetType(index), 2) end
	
	return debug.getlocal(func, index)
end
]]

do
if not debugGetLocal then
	local f = render.createFont("DejaVu Sans Mono", 12, 400, true)
	hook.add("render", "", function()
		render.setFont(f)
		render.drawText(0, 0, [[Ths require getlocal, hasnt been added (yet) to sf so add it yourself :)

SF.DefaultEnvironment.debugGetLocal = function(func, index)
	if type(func) ~= "function" then SF.ThrowTypeError("function", SF.GetType(func), 2) end
	if type(index) ~= "number" then SF.ThrowTypeError("number", SF.GetType(index), 2) end
	
	return debug.getlocal(func, index)
end]])
	end)
	
	return
end

----------------------------------------

local GUI = require("../lib/gui2.lua")
local syntax = require("../lib/syntax_lua.lua")

local gui = GUI(512, 512)
gui:setFpsLimit(30)

local files = {}
for k, v in pairs(getScripts()) do
	files["SF:" .. k] = string.split(v, "\n")
end

local font = {
	title = render.createFont("Trebuchet", 50, 600, true),
	head = render.createFont("Trebuchet", 25, 600, true)
}

----------------------------------------

GUI.registerElement("codeview", {
	inherit = "label",
	constructor = function(self)
	
	end,
	
	data = {
		_colors = syntax.colorTable,
		_texts = {},
		_font = render.createFont("DejaVu Sans Mono", 12, 350, true),
		_text_alignment_x = 0,
		_text_alignment_y = 3,
		
		_doSyntax = function(self)
			self._texts = syntax.color(self._text)
		end,
		
		onDraw = function(self, w, h)
			render.setColor(self.mainColor)
			render.drawRect(0, 0, w, h)
			
			render.setFont(self._font)
			for k, v in pairs(self._texts) do
				render.setColor(self._colors[k])
				render.drawText(0, 0, v)
			end
		end
	},
	
	properties = {
		text = {},
		
		mainColor = {
			set = function(self, color)
				self._main_color = color
				
				self:_changed(true)
			end,
			
			get = function(self)
				local clr = self._main_color
				return clr and (type(clr) == "string" and self._theme[clr] or clr) or self._theme.primaryColor
			end
		},
		
		code = {
			set = function(self, text)
				self._text_raw = text
				
				self:_changed()
				self:_wrapText()
				self:_doSyntax()
				self.h = self._text_height
			end,
			
			get = function(self)
				return self._text
			end
		},
		
		font = {
			set = function(self, font)
				self._font = font
				
				self:_changed()
				self:_wrapText()
				self:_doSyntax()
				self.h = self._text_height
			end,
			
			get = function(self)
				return self._font or self._theme.font
			end
		}
	}
})

----------------------------------------

local function getFunctionParams(func)
	local params = {}
	
	for i = 1, math.huge do
		local param = debugGetLocal(func, i)
		
		if not param then break end
		
		params[i] = param
	end
	
	return params
end

local function getSourceCode(linebegin, lineend, file)
	local code = ""
	for i = linebegin, lineend do
		code = code .. string.replace(files[file][i], "\t", "|") .. (i ~= lineend and "\n" or "")
	end
	
	return code
end

----------------------------------------

--[[local text = gui:create("text")
text:setAlignment(0, 3)
text.font = render.createFont("DejaVu Sans Mono", 16, 400, true)

local t = ""

for elem_name, data in pairs(GUI.elements) do
	t = t .. elem_name .. "\n"
	
	for name, val in pairs(data.raw.properties) do
		t = t .. name .. "\n"
		
		if type(val) == "function" then
			t = t .. string.format("    get %s(%s) > unknown\n", name, table.concat(getFunctionParams(val), ", "))
			
			local info = debugGetInfo(val)
			t = t .. string.format("        %d-%d %s\n", info.linedefined, info.lastlinedefined, info.short_src)
		elseif type(val) == "table" then
			if val.set then
				t = t .. string.format("    set %s(%s) > unknown\n", name, table.concat(getFunctionParams(val.set), ", "))
				
				local info = debugGetInfo(val.set)
				t = t .. string.format("        %d-%d %s\n", info.linedefined, info.lastlinedefined, info.short_src)
			end
			
			if val.get then
				t = t .. string.format("    get %s(%s) > unknown\n", name, table.concat(getFunctionParams(val.get), ", "))
				
				local info = debugGetInfo(val.get)
				t = t .. string.format("        %d-%d %s\n", info.linedefined, info.lastlinedefined, info.short_src)
			end
		end
	end
	
	t = t .. "\n\n"
end

text.text = t]]

----------------------------------------

local element_data = {}
local element_pages = {}

for elem_name, data in pairs(GUI.elements) do
	element_data[elem_name] = {
		inherit = data.inherit_name,
		properties = {}
	}
	
	local size = 0
	local page = gui:create("container")
	page.size = Vector(400, 9999)
	page.enabled = false
	
	local title = gui:create("text", page)
	title.font = font.title
	title.text = elem_name
	title:setDockMargin(0, 30, 0, 0)
	title.dock = GUI.DOCK.TOP
	size = size + 30 + title.h
	
	if data.inherit_name then
		local inherit = gui:create("text", page)
		inherit.text = "inherits from: " .. data.inherit_name
		inherit.dock = GUI.DOCK.TOP
		size = size + inherit.h
	end
	
	local header = gui:create("text", page)
	header.font = font.head
	header.text = "Properties"
	header.alignmentX = 0
	header:setDockMargin(20, 30, 0, 10)
	header.dock = GUI.DOCK.TOP
	size = size + 40 + header.h
	
	for name, val in pairs(data.raw.properties) do
		element_data[elem_name].properties[name] = {}
		
		local segment = gui:create("container", page)
		segment.h = 999
		segment.mainColor = "primaryColorDark"
		segment:setDockMargin(10, 10, 20, 10)
		segment.dock = GUI.DOCK.TOP
		local ssize = 0
		
		local f = gui:create("text", segment)
		f.text = name
		f.alignmentX = 0
		f:setDockMargin(5, 5, 5, 5)
		f.dock = GUI.DOCK.TOP
		ssize = ssize + 10 + f.h
		
		if type(val) == "function" then
			--[[local info = debugGetInfo(val)
			element_data[elem_name].properties[name].get = {
				params = getFunctionParams(val),
				source = {
					linestart = info.linedefined,
					lineend = info.lastlinedefined,
					file = info.short_src
				}
			}]]
		elseif type(val) == "table" then
			if val.set then
				local info = debugGetInfo(val.set)
				element_data[elem_name].properties[name].set = {
					params = getFunctionParams(val.set),
					source = {
						linestart = info.linedefined,
						lineend = info.lastlinedefined,
						file = info.short_src
					}
				}
				
				local params = table.concat(getFunctionParams(val.set), ", ")
				local f = gui:create("text", segment)
				f.text = string.format("set\n    %s(%s)\n    %s(%s)", name, params, "set" .. string.upper(name[1]) .. string.sub(name, 2), params)
				f.alignmentX = 0
				f:setDockMargin(30, 0, 0, 0)
				f.dock = GUI.DOCK.TOP
				ssize = ssize + f.h
				
				local source = gui:create("codeview", segment)
				source:setDockMargin(30, 0, 30, 0)
				source.dock = GUI.DOCK.TOP
				source.code = string.format("-- Source: %d-%d %s\n", info.linedefined, info.lastlinedefined, info.short_src) .. getSourceCode(info.linedefined, info.lastlinedefined, info.short_src)
				ssize = ssize + source.h
			end
			
			if val.get then
				local info = debugGetInfo(val.get)
				element_data[elem_name].properties[name].get = {
					params = getFunctionParams(val.get),
					source = {
						linestart = info.linedefined,
						lineend = info.lastlinedefined,
						file = info.short_src
					}
				}
				
				local params = table.concat(getFunctionParams(val.get), ", ")
				local f = gui:create("text", segment)
				f.text = string.format("get\n    %s(%s)\n    %s(%s)", name, params, "get" .. string.upper(name[1]) .. string.sub(name, 2), params)
				f.alignmentX = 0
				f:setDockMargin(30, 0, 0, 0)
				f.dock = GUI.DOCK.TOP
				ssize = ssize + f.h
				
				local source = gui:create("codeview", segment)
				source:setDockMargin(30, 0, 30, 0)
				source.dock = GUI.DOCK.TOP
				source.code = string.format("-- Source: %d-%d %s\n", info.linedefined, info.lastlinedefined, info.short_src) .. getSourceCode(info.linedefined, info.lastlinedefined, info.short_src)
				ssize = ssize + source.h
				
				--[[local params = table.concat(getFunctionParams(val.get), ", ")
				local f = gui:create("text", page)
				f.text = string.format("get\n    %s(%s)\n    %s(%s)", name, params, "get" .. string.upper(name[1]) .. string.sub(name, 2), params)
				f.alignmentX = 0
				f:setDockMargin(30, 0, 0, 0)
				f.dock = GUI.DOCK.TOP
				size = size + f.h]]
			end
		end
		
		segment.h = ssize + 10
		size = size + 20 + segment.h
	end
	
	--print(elem_name, size, title.size)
	page.h = size-- + 50
	element_pages[elem_name] = page
end

----------------------------------------

local page_frame = gui:create("scrollframe")
page_frame.pos = Vector(112, 0)
page_frame.size = Vector(400, 512)
page_frame.scrollbarY = true

do
	local sidebar_frame = gui:create("scrollframe")
	sidebar_frame.size = Vector(112, 512)
	sidebar_frame.scrollbarY = true
	
	local content = gui:create("container")
	sidebar_frame.content = content

	local elements_header = gui:create("button", content)
	elements_header.h = 20
	elements_header.text = "Elements"
	elements_header.toggle = true
	elements_header:setCornerStyle(1, 1, 0, 0)
	elements_header.dock = GUI.DOCK.TOP
	
	local spacer = gui:create("base", content)
	spacer.h = 1
	spacer.dock = GUI.DOCK.TOP
	spacer.onDraw = function(self, w, h)
		render.setRGBA(220, 220, 220, 255)
		render.drawRect(0, 0, w, h)
	end
	
	local elements = gui:create("grid", content)
	elements.dock = GUI.DOCK.TOP
	elements.itemHeight = 20
	elements:setSpacing(0, 0)
	elements.itemCountX = 1
	elements.itemScalingY = false
	elements_header.onAnimationChange = function(self, anim, value)
		if anim == "click" then
			elements.h = elements.contentHeight * (1 - value)
			sidebar_frame:contentSizeChanged()
		end
	end
	
	local last
	for elem, data in pairs(element_data) do
		local elem = elem
		local button = gui:create("button")
		button.text = elem
		button.cornerStyle = 0
		button.textAlignmentX = 0
		elements:addItem(button)
		button.onClick = function(self)
			if page_frame.content then
				page_frame.content.enabled = false
			end
			
			element_pages[elem].enabled = true
			page_frame.scrollbarY.value = 0
			page_frame.content = element_pages[elem]
			gui:forceRedraw()
		end
		
		last = button
	end
	last:setCornerStyle(0, 0, 2, 0)
	
	elements.h = elements.contentHeight
	content.h = math.max(512, elements.h + 20)
	sidebar_frame:contentSizeChanged()
end

----------------------------------------

hook.add("render", "", function()
	gui:think()
	gui:render()
	gui:renderCursor()
	--gui:renderDebug(true)
	
	
	render.setRGBA(255, 255, 255, 255)
	render.drawSimpleText(0, 0, tostring(math.round(quotaAverage() * 1000000)))
end)
end
