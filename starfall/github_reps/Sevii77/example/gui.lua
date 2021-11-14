--@name GUI Example
--@client
--@include ../lib/gui.lua

local gui = require("../lib/gui.lua")

gui.registerElement("betterbutton", "button" --[[here we inherit from button so we can make our own better button without making it all in itself]], {
	settings = {
		text = "Better Button",
		size = Vector(100, 20)
	}, onClick = function(self)
		if self.hovering then
			self.pos = self.pos + Vector(math.random(-self.size.x, self.size.x), math.random(-self.size.y, self.size.y))
			self.onClick(self)
		end
	end
})

--This is so we can do gui.button(parent) instead of gui.create("button", button)
gui.createConstructors(--[[pass true in here to make global constructors: Button(parent) ]])

----------

local container = gui.create("container")
container.pos = Vector(12, 0)
container.size = Vector(288, 1536)

local scrollbar = gui.create("scrollbar")
scrollbar.pos = Vector(0, 0)
scrollbar.size = Vector(12, 512)
scrollbar.contentLength = 1536
scrollbar.onChange = function(self, scrollLength)
	container.pos.y = -scrollLength
end

local button = gui.button(container)
button:setPos(Vector(50, 50))
button:setSize(Vector(140, 40))
button:setText("hello there")
function button:drawOver(size)
	render.setColor(self.colorBorder)
	
	render.drawRect(-2, -2, 4, 4)
	render.drawRect(size.x - 2, -2, 4, 4)
	render.drawRect(-2, size.y - 2, 4, 4)
	render.drawRect(size.x - 2, size.y - 2, 4, 4)
end

local label = gui.create("label", container)
label.pos = Vector(50, 100)
label.size = Vector(140, 40)

local betterbutton = gui.betterbutton(container)
betterbutton.pos = Vector(50, 200)
betterbutton.size = Vector(200, 60)
betterbutton.textAllignment = 2
betterbutton.onClick = function(self)
	label.text = tostring(betterbutton:getPos())
end

local checkbox = gui.create("checkbox", container)
checkbox.pos = Vector(50, 150)
checkbox.size = Vector(140, 30)

for i = 0, 4 do
	local frame = gui.create("frame", container)
	frame.pos = Vector(50 + i*20, 300 + i*20)
	frame.colorBorder = Color(i/4*300, 1, 1):hsvToRGB()
	
	local label = gui.create("label", frame)
	label.size = Vector(50, 30)
end



local textcontainer = gui.create("container", container)
textcontainer.pos = Vector(10, 520)
textcontainer.size = Vector(260, 1000)
textcontainer.draw = function(self, size)
	render.setColor(Color(150, 60, 50))
	render.drawRect(0, 0, size.x, size.y)
end

local text = gui.create("text", textcontainer)
text:fill()
text.allignmentX = 2
text.allignmentY = 1
text.text = [[Not him old music think his found enjoy merry. Listening acuteness dependent at or an. Apartments thoroughly unsatiable terminated sex how themselves. She are ten hours wrong walls stand early. Domestic perceive on an ladyship extended received do. Why jennings our whatever his learning gay perceive. Is against no he without subject. Bed connection unreserved preference partiality not unaffected. Years merit trees so think in hoped we as. 

Now seven world think timed while her. Spoil large oh he rooms on since an. Am up unwilling eagerness perceived incommode. Are not windows set luckily musical hundred can. Collecting if sympathize middletons be of of reasonably. Horrible so kindness at thoughts exercise no weddings subjects. The mrs gay removed towards journey chapter females offered not. Led distrusts otherwise who may newspaper but. Last he dull am none he mile hold as. 

No in he real went find mr. Wandered or strictly raillery stanhill as. Jennings appetite disposed me an at subjects an. To no indulgence diminution so discovered mr apartments. Are off under folly death wrote cause her way spite. Plan upon yet way get cold spot its week. Almost do am or limits hearts. Resolve parties but why she shewing. She sang know now how nay cold real case.]]

-----Right side-----
local container = gui.create("container")
container.pos = Vector(300, 0)
container.size = Vector(200, 1024*8)

local scrollbar = gui.create("scrollbar")
scrollbar.pos = Vector(500, 0)
scrollbar.size = Vector(12, 512)
scrollbar.contentLength = 1024*8
scrollbar.onChange = function(self, scrollLength)
	container.pos.y = -scrollLength
end

local slidervalue = gui.create("label", container)
slidervalue.pos = Vector(50, 80)

local slider = gui.create("slider", container)
slider.pos = Vector(50, 50)
slider.round = 2.5
slider.min = -10
slider.max = 10
slider.onChange = function(self, value)
	slidervalue.text = tostring(value)
end

local textentry = gui.create("textentry", container)
textentry.pos = Vector(50, 150)

local buttongrid = gui.create("buttongrid", container)
buttongrid.pos = Vector(20, 200)
buttongrid.size = Vector(170, math.huge)
buttongrid.buttonSize = Vector(50, 30)
buttongrid.spacing = Vector(10, 10)
buttongrid.onClick = function(self, index) print("btton " .. index) end
for i = 1, 1000 do
	buttongrid:addButton(tostring(i))
end

----------

hook.add("render", "", function()
	render.setBackgroundColor(Color(100, 160, 220))
	
	gui.think()
	gui.render()
	--gui.debug()
end)