--@client
--@include ../lib/object/3dscreen2.lua

Screen = require("../lib/object/3dscreen2.lua")

screen_main = Screen(chip():getPos() + Vector(0, 0, 50), Angle(0, 0, 45), Vector(40, 40))
screen_mirror = Screen(chip():getPos() + Vector(50, 0, 50), Angle(0, 0, 45), Vector(40, 40))
screen_secondairy = Screen(chip():getPos() + Vector(-80, 0, 50), Angle(0, 0, 45), Vector(40, 80))

--[[
	static functions:
		Screen.new( pos[vector], ang[angle], size[vector] ) (same as Screen())
		Screen.canCreate( ) (same as holograms.canSpawn)
		Screen.screensLeft( ) (same as holograms.hologramsLeft)
	
	methods:
		SCREEN:destroy( ) (destroys the screen and clears up used resources)
		SCREEN:setPos( pos[vector] ) (sets the pos of the screen)
		SCREEN:setAngles( ang[angle] ) (sets the angle of the screen)
		SCREEN:setSize( size[vector] ) (sets the size of the screen)
		SCREEN:setParent( ent[entity] or nil, attachment[number i think? same as ENTITY:setParent] or nil ) (sets the parent of the screen or unparents if nil)
		SCREEN:mirror( screen[screen] or nil ) (will display the same as given screen or stops mirroring if nil is given)
		SCREEN:setEnabled( state[boolean] ) (will enable or disable the rendering of the screen)
		SCREEN:setClear( state[boolean] ) (should the screens rendertarget be cleared every drawcall)
		SCREEN:setClearColor( color[color] ) (sets the clear color, can be transparent) (same as render.setBackgroundColor)
		SCREEN:setRender( render[function] ) (a function which will be called to draw the screen)
	
	
	if you need to do shit to the holo its accessable with
		SCREEN.holo
	
	material, mesh and other data is available the same way
]]

screen_main:setParent(chip())
screen_mirror:setParent(chip())
screen_secondairy:setParent(chip())

screen_main:setRender(function()
	render.setColor(Color((timer.curtime() * 80) % 360, 1, 1):hsvToRGB())
	render.drawRect(240 + math.sin(timer.curtime() * 4) * 100, 240 + math.sin(timer.curtime()) * 100, 32, 32)
end)

screen_mirror:mirror(screen_main)

screen_secondairy:setClear(false)
screen_secondairy:setRender(function()
	render.setColor(Color((timer.curtime() * 80) % 360, 1, 1):hsvToRGB())
	
	local x, y = render.cursorPos()
	if x then
		render.drawRect(x - 4, y - 4, 8, 8)
	end
end)