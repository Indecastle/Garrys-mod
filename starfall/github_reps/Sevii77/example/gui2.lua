--@name GUI2 Example
--@author Sevii
--@include ../lib/gui2.lua
--@client

local text_block = "Satisfied conveying an dependent contented he gentleman agreeable do be. Warrant private blushes removed an in equally totally if. Delivered dejection necessary objection do mr prevailed. Mr feeling do chiefly cordial in do. Water timed folly right aware if oh truth. Imprudence attachment him his for sympathize. Large above be to means. Dashwood do provided stronger is. But discretion frequently sir the she instrument unaffected admiration everything."
local debug_rendering = false
local direct_rendering = false

------------------------------

local GUI = require("../lib/gui2.lua")
local gui = GUI(512, 512)

-- Use this for hud
--local w, h = render.getGameResolution()
--local gui = GUI(w, h)

do -- Basic example
	local body = gui:create("frame")
	body.pos = Vector(4, 56)
	body.size = Vector(250, 250)
	body.title = "Fancy Example"
	body.collapseOnClose = true
	body.minSize = Vector(150, 250)
	
	do
		local page = gui:create("base", body.inner)
		page.h = 50
		page.dock = GUI.DOCK.TOP
		
		-- Text
		local s = ""
		for k, v in pairs(string.split(text_block, " ")) do
			s = s .. v .. (k % 10 == 0 and "\n" or " ")
		end
		
		local text = gui:create("text", page)
		text.text = s
		text:setAlignment(0, 3)
	end
	
	do
		local page = gui:create("container", body.inner)
		page.dock = GUI.DOCK.FILL
		page:setCornerStyle(2, 0, 2, 1)
		page:setCornerSize(20, 0, 10, 5)
		
		do -- Top colorslider
			local grid = gui:create("grid", page)
			grid.h = 30
			grid.dock = GUI.DOCK.TOP
			grid.spacing = Vector(0, 0)
			grid:setItemCount(2, 1)
			
			local slider = gui:create("slider")
			slider.style = 2
			slider.max = 360
			slider.round = 0
			slider.mainColor = "secondaryColorDark"
			slider:setCornerStyle(2, 0, 0, 0)
			slider:setCornerSize(20, 0, 0, 0)
			grid:addItem(slider)
			slider.onChange = function(self, value)
				gui.theme.secondaryColor      = Color(value, 0.6, 0.6):hsvToRGB()
				gui.theme.secondaryColorLight = Color(value, 0.4, 0.6):hsvToRGB()
				gui.theme.secondaryColorDark  = Color(value, 0.6, 0.4):hsvToRGB()
				gui:forceRedraw()
			end
			
			local label = gui:create("label")
			label.text = "Color"
			label.cornerStyle = 0
			grid:addItem(label)
		end
		
		do -- Bottom theme bar
			local bar = gui:create("label", page)
			bar.h = 30
			bar.text = "Themes"
			bar.textAlignmentX = 0
			bar:setCornerStyle(0, 0, 2, 1)
			bar:setCornerSize(0, 0, 10, 5)
			bar.dock = GUI.DOCK.BOTTOM
			
			local light, dark, art
			
			art = gui:create("button", bar)
			art.w = 50
			art.dock = GUI.DOCK.RIGHT
			art.text = "Art"
			art.toggle = true
			art.cornerSize = 10
			art:setCornerStyle(0, 0, 2, 0)
			art.onClick = function(self)
				local function rndclr()
					return Color(math.random() * 255, math.random() * 255, math.random() * 255)
				end
				
				gui.theme = {
					primaryColor        = rndclr(),
					primaryColorLight   = rndclr(),
					primaryColorDark    = rndclr(),
					primaryTextColor    = rndclr(),
					
					secondaryColor      = rndclr(),
					secondaryColorLight = rndclr(),
					secondaryColorDark  = rndclr(),
					secondaryTextColor  = rndclr(),
				}
				
				dark.state = false
				light.state = false
			end
			
			dark = gui:create("button", bar)
			dark.w = 50
			dark.dock = GUI.DOCK.RIGHT
			dark.text = "Dark"
			dark.toggle = true
			dark.state = true
			dark.cornerStyle = 0
			dark.onClick = function(self)
				gui.theme = "dark"
				
				art.state = false
				light.state = false
			end
			
			light = gui:create("button", bar)
			light.w = 50
			light.dock = GUI.DOCK.RIGHT
			light.text = "Light"
			light.toggle = true
			light.cornerSize = 15
			light:setCornerStyle(2, 0, 0, 0)
			light.onClick = function(self)
				gui.theme = "light"
				
				art.state = false
				dark.state = false
			end
		end
		
		do -- Main grid
			local scrollframe = gui:create("scrollframe", page)
			scrollframe.dock = GUI.DOCK.FILL
			scrollframe.scrollbarY = true
			
			local grid = gui:create("grid")
			-- grid.w = 100
			grid.dock = GUI.DOCK.FILL
			grid:setDockMargin(10, 10, 10, 10)
			grid.spacing = Vector(0, 0)
			grid.itemCountX = 1
			grid.itemScalingY = false
			grid.itemHeight = 20
			scrollframe.content = grid
			
			do -- Debug checkbox
				local debug = gui:create("checkbox")
				debug.style = 2
				debug.text = "Debug Rendering"
				debug.textOffsetX = 5
				debug.state = debug_rendering
				debug:setCornerStyle(1, 1, 0, 0)
				grid:addItem(debug)
				debug.onChange = function(self, state)
					debug_rendering = state
				end
				
				local direct = gui:create("checkbox")
				direct.style = 2
				direct.text = "Direct Rendering"
				direct.textOffsetX = 5
				direct.state = direct_rendering
				direct.cornerStyle = 0
				grid:addItem(direct)
				direct.onChange = function(self, state)
					direct_rendering = state
				end
				
				local bg = gui:create("button")
				bg.text = "Enable Background"
				bg.toggle = true
				bg.state = true -- True because default of checkbox is true
				bg.cornerStyle = 0
				grid:addItem(bg)
				bg.onClick = function(self)
					debug.drawBackground = self.state
					direct.drawBackground = self.state
					
					if self.state then
						bg:setCornerStyle(0, 0, 0, 0)
					elseif debug.style == 1 then
						bg:setCornerStyle(1, 1, 0, 0)
					else
						bg:setCornerStyle(0, 1, 0, 0)
					end
				end
				
				local style = gui:create("button")
				style.text = "Style 1"
				style:setCornerStyle(0, 0, 0, 0)
				grid:addItem(style)
				style.onClick = function(self)
					debug.style = 1
					direct.style = 1
					
					if not bg.state then
						bg:setCornerStyle(1, 1, 0, 0)
					end
				end
				
				local style2 = gui:create("button")
				style2.text = "Style 2"
				style2:setCornerStyle(0, 0, 1, 1)
				grid:addItem(style2)
				style2.onClick = function(self)
					debug.style = 2
					direct.style = 2
					
					if not bg.state then
						bg:setCornerStyle(0, 1, 0, 0)
					end
				end
			end
			
			-- Add a spacer
			grid:addItem(gui:create("base"))
			
			do -- Slider showcase
				local slider = gui:create("slider")
				slider.style = 2
				slider.min = 10
				slider.max = 30
				slider.round = 0
				slider.value = grid.itemHeight
				slider.text = "Debug Rendering"
				slider:setCornerStyle(1, 1, 0, 0)
				grid:addItem(slider)
				slider.onChange = function(self, value)
					grid.itemHeight = value
					grid.h = grid.contentHeight
					scrollframe:contentSizeChanged()
				end
				
				local label = gui:create("label")
				label.text = "Grid Item Height"
				label:setCornerStyle(0, 0, 0, 0)
				grid:addItem(label)
				
				local bg = gui:create("button")
				bg.text = "Enable Background"
				bg.state = true -- True because default of slider is true
				bg.toggle = true
				bg:setCornerStyle(0, 0, 0, 0)
				grid:addItem(bg)
				bg.onClick = function(self)
					slider.drawBackground = self.state
					
					if self.state then
						label:setCornerStyle(0, 0, 0, 0)
					else
						label:setCornerStyle(1, 1, 0, 0)
					end
				end
				
				local style = gui:create("button")
				style.text = "Style 1"
				style:setCornerStyle(0, 0, 0, 0)
				grid:addItem(style)
				style.onClick = function(self)
					slider.style = 1
					
					if not slider.drawBackground then
						label:setCornerStyle(1, 1, 0, 0)
					end
				end
				
				local style2 = gui:create("button")
				style2.text = "Style 2"
				style2:setCornerStyle(0, 0, 1, 1)
				grid:addItem(style2)
				style2.onClick = function(self)
					slider.style = 2
					label:setCornerStyle(0, 0, 0, 0)
				end
			end
			
			grid.h = grid.contentHeight
			scrollframe:contentSizeChanged()
		end
	end
end

do -- Bidirection scrolling + other stuff
	local body = gui:create("frame")
	body.pos = Vector(4, 310)
	body.size = Vector(250, 146)
	body.title = "2D Scrollframe"
	body.collapseOnClose = true
	body.minSize = Vector(150, 100)
	
	local scrollframe = gui:create("scrollframe", body.inner)
	scrollframe.dock = GUI.DOCK.FILL
	scrollframe:setDockMargin(5, 5, 5, 5)
	scrollframe.scrollbarX = true
	scrollframe.scrollbarX:setCornerStyle(0, 0, 1, 1)
	scrollframe.scrollbarY = true
	scrollframe.scrollbarY:setCornerStyle(0, 1, 1, 0)
	
	do
		local content = gui:create("container")
		content.size = Vector(400, 400)
		content.dock = GUI.DOCK.FILL
		content.cornerStyle = 0
		scrollframe.content = content
		
		local vertical_slider = gui:create("slider", content)
		vertical_slider.size = Vector(20, 60)
		
		local vertical_slider = gui:create("slider", content)
		vertical_slider.pos = Vector(20, 0)
		vertical_slider.size = Vector(20, 60)
		vertical_slider.style = 2
		vertical_slider.round = 1
		
		for i = 1, 10 do
			local button = gui:create("button", content)
			button.pos = Vector(i * 30 + 30)
			button.text = tostring(i)
			
			fancy = button
		end
	end
end

do -- Docking
	local body = gui:create("frame")
	body.pos = Vector(258, 56)
	body.size = Vector(250, 200)
	body.title = "Docking"
	body.collapseOnClose = true
	body.minSize = Vector(150, 100)
	
	local holder = gui:create("base", body.inner)
	holder.dock = GUI.DOCK.FILL
	holder:setDockMargin(5, 5, 5, 5)
	
	do
		local left = gui:create("button", holder)
		left.w = 30
		left.text = "left"
		left.dock = GUI.DOCK.LEFT
		
		local right = gui:create("button", holder)
		right.w = 30
		right.text = "right"
		right.dock = GUI.DOCK.RIGHT
		
		local top = gui:create("button", holder)
		top.h = 20
		top.text = "top"
		top.dock = GUI.DOCK.TOP
		
		local bottom = gui:create("button", holder)
		bottom.h = 20
		bottom.text = "bottom"
		bottom.dock = GUI.DOCK.BOTTOM
		
		local fill = gui:create("button", holder)
		fill.text = "fill"
		fill.dock = GUI.DOCK.FILL
	end
end

do -- Grid
	local body = gui:create("frame")
	body.pos = Vector(258, 260)
	body.size = Vector(250, 196)
	body.title = "Grid"
	body.collapseOnClose = true
	body.minSize = Vector(150, 100)
	
	local grid = gui:create("grid", body.inner)
	grid.itemSize = Vector(50, 50)
	grid.dock = GUI.DOCK.FILL
	grid:setDockMargin(5, 5, 5, 5)
	
	for i = 1, 10 do
		local button = gui:create("button")
		button.text = tostring(i)
		grid:addItem(button)
	end
end

------------------------------

hook.add("render", "", function()
	--render.setBackgroundColor(Color(0, 0, 0, 0))
	
	gui:think()
	
	if direct_rendering then
		gui:renderDirect()
	else
		gui:render()
	end
	
	gui:renderCursor()
	
	if debug_rendering then
		gui:renderDebug()
	end
	if mask_rendering then
		gui:renderMasks()
	end
	
	render.setRGBA(255, 255, 255, 255)
	render.drawSimpleText(0, 0, tostring(math.round(quotaAverage() * 1000000)))
	render.drawSimpleText(0, 20, tostring(math.round(ramAverage() / 1024)) .. " KiB")
	
	render.drawSimpleText(512, 0, tostring(gui._focus_object and gui._focus_object.object), 2)
end)

--[[hook.add("drawHUD", "", function()
	gui:think()
	gui:renderHUD()
	gui:renderCursor(10)
	
	if debug_rendering then
		gui:renderDebug()
	end
	if mask_rendering then
		gui:renderMasks()
	end
	
	render.setRGBA(255, 255, 255, 255)
	render.drawSimpleText(0, 35, tostring(math.round(quotaAverage() * 1000000)))
end)]]


