--@name Plattyfall
--@author Sevii
--@include ../lib/object/3dscreen.lua

----------------------------------------

local settings = {
	cells = 8,
	scale = 120,
	time = 2.5,
	jump_range = 3
}

----------------------------------------

Screen = require("../lib/object/3dscreen.lua")

----------------------------------------

local p = chip():getPos()
local h = 20
local h2 = h / 2
local s = settings.scale
local s2 = s / 2
local cc = Color(0, 0, 0, 0)

local board = Screen(p + Vector(0, 0, h), Angle(), Vector(s)):setClearColor(cc):setParent(chip())
local side = Screen(p + Vector(s2, 0, h2), Angle(0, 90, 90), Vector(s, h, 1)):setClearColor(cc):setParent(chip())
Screen(p + Vector(-s2, 0, h2), Angle(0, -90, 90), Vector(s, h, 1)):setClearColor(cc):mirror(side):setParent(chip())
Screen(p + Vector(0, s2, h2), Angle(0, 180, 90), Vector(s, h, 1)):setClearColor(cc):mirror(side):setParent(chip())
Screen(p + Vector(0, -s2, h2), Angle(0, 0, 90), Vector(s, h, 1)):setClearColor(cc):mirror(side):setParent(chip())

----------------------------------------

if SERVER then
	
	local game = {}
	
	local function sendData(ply)
		net.start("data")
		
		net.writeUInt(settings.cells, 5)
		for x, cells in pairs(game.cells) do
			for y, cell in pairs(cells) do
				net.writeBool(cell)
			end
		end
		
		net.writeUInt(game.p1 and game.p1:getUserID() or 0, 12)
		net.writeUInt(game.p1p.x, 5)
		net.writeUInt(game.p1p.y, 5)
		
		net.writeUInt(game.p2 and game.p2:getUserID() or 0, 12)
		net.writeUInt(game.p2p.x, 5)
		net.writeUInt(game.p2p.y, 5)
		
		net.send(ply)
	end
	
	local function reset()
		game = {
			cells = {},
			p1 = nil,
			p2 = nil,
			p1p = Vector(),
			p2p = Vector()
		}
		
		game.p2p = Vector(settings.cells - 1)
		for x = 0, settings.cells - 1 do
			game.cells[x] = {}
			
			for y = 0, settings.cells - 1 do
				game.cells[x][y] = true
			end
		end
		
		net.start("reset")
		net.send()
		
		sendData()
	end
	reset()
	
	local function startRound()
		net.start("round")
		net.send()
		
		timer.simple(7 + settings.time, function()
			local p1 = not game.cells[game.p1p.x][game.p1p.y]
			local p2 = not game.cells[game.p2p.x][game.p2p.y]
			
			if p1 and p2 then
				net.start("win")
				net.writeUInt(3, 2)
				net.send()
			elseif p1 then
				net.start("win")
				net.writeUInt(2, 2)
				net.send()
			elseif p2 then
				net.start("win")
				net.writeUInt(1, 2)
				net.send()
			else
				startRound()
			end
			
			if p1 or p2 then
				timer.simple(10, reset)
			end
			
			sendData()
		end)
	end
	
	----------------------------------------
	
	net.receive("data", function(_, ply)
		sendData(ply)
	end)
	
	net.receive("join", function(_, ply)
		if game.p1 == ply or game.p2 == ply then return end
		
		if not game.p1 then
			game.p1 = ply
			
			net.start("join")
			net.writeBool(true)
			net.writeUInt(ply:getUserID(), 12)
			net.send()
			
			--startRound()
		elseif not game.p2 then
			game.p2 = ply
			
			net.start("join")
			net.writeBool(false)
			net.writeUInt(ply:getUserID(), 12)
			net.send()
			
			startRound()
		end
	end)
	
	net.receive("move", function(_, ply)
		if game.p1 == ply then
			game.p1p = Vector(net.readUInt(5), net.readUInt(5))
		elseif game.p2 == ply then
			game.p2p = Vector(net.readUInt(5), net.readUInt(5))
		end
	end)
	
	net.receive("drop", function(_, ply)
		if game.p1 ~= ply and game.p2 ~= ply then return end
		
		game.cells[net.readUInt(5)][net.readUInt(5)] = false
	end)
	
else
	
	local game = {}
	
	local font = {
		time = render.createFont("Roboto", 150, 600, true, false, true),
		round = render.createFont("Roboto", 80, 600, true, false, true),
		name = render.createFont("Roboto", 40, 600, true, false, true)
	}
	
	----------------------------------------
	
	local function reset()
		game = {
			cells = {},
			p1 = nil,
			p2 = nil,
			p1p = Vector(),
			p2p = Vector(),
			
			player = 0,
			
			time_left = 0,
			next_round = 0,
			round = 0,
			
			target = Vector(-1, -1),
			on_screen = false,
			drop_mode = false,
	   }
	end
	reset()
	
	net.receive("data", function()
		settings.cells = net.readUInt(5)
		for x = 0, settings.cells - 1 do
			game.cells[x] = {}
			
			for y = 0, settings.cells - 1 do
				game.cells[x][y] = net.readBool()
			end
		end
		
		local p1 = net.readUInt(12)
		if p1 ~= 0 then
			game.p1 = player(p1)
			
			if game.p1 == player() then
				game.player = 1
			end
		end
		game.p1p = Vector(net.readUInt(5), net.readUInt(5))
		
		local p2 = net.readUInt(12)
		if p2 ~= 0 then
			game.p2 = player(p2)
			
			if game.p2 == player() then
				game.player = 2
			end
		end
		game.p2p = Vector(net.readUInt(5), net.readUInt(5))
	end)
	
	net.receive("join", function()
		if net.readBool() then
			game.p1 = player(net.readUInt(12))
			
			if game.p1 == player() then
				game.player = 1
			end
		else
			game.p2 = player(net.readUInt(12))
			
			if game.p2 == player() then
				game.player = 2
			end
		end
	end)
	
	net.receive("round", function()
		game.round = game.round + 1
		game.next_round = 5
		game.curmode = 0
	end)
	
	net.receive("win", function()
		local state = net.readUInt(2)
		if state == 3 then
			game.win = "Draw"
		elseif state == 2 then
			game.win = game.p2:getName() .. " has won"
		elseif state == 1 then
			game.win = game.p1:getName() .. " has won"
		end
	end)
	
	net.receive("reset", reset)
	
	net.start("data")
	net.send()
	
	----------------------------------------
	
	board:setRender(function()
		local m = Matrix()
		m:setTranslation(Vector(6, 6))
		
		render.pushMatrix(m)
		
		-----
		
		local c = settings.cells
		local cs = 500 / c
		
		-- Cursor pos
		local target = Vector(-1, -1)
		local cx, cy = render.cursorPos()
		
		if cx and cx > 0 and cx < 511 and cy > 0 and cy < 511 then
			if game.player ~= 0 then
				target = Vector(math.floor(cx / cs), math.floor(cy / cs))
			end
			
			game.on_screen = true
		else
			game.on_screen = false
		end
		
		game.target = target
		
		-- Board
		local s = cs * 0.8
		local sp = cs * 0.1
		
		render.setRGBA(200, 200, 200, 100)
		render.drawRect(0, 0, 512, 512)
		
		for x, cells in pairs(game.cells) do
			for y, cell in pairs(cells) do
				if cell then
					if target.x == x and target.y == y and game.time_left > 0 then
						if game.curmode == 1 then
							render.setRGBA(255, 100, 70, 255)
						elseif game.curmode == 0 then
							render.setRGBA(70, 255, 100, 255)
						end
					else
						render.setRGBA(30, 30, 30, 255)
					end
					
					render.drawRect(x / c * 500 + sp, y / c * 500 + sp, s, s)
				end
			end
		end
		
		-- Player 1
		local m = Matrix()
		m:setTranslation(Vector(game.p1p.x * cs + cs / 2, game.p1p.y * cs + cs / 2))
		m:setAngles(Angle(0, timer.curtime() * 100, 0))
		
		render.pushMatrix(m)
		--render.setRGBA(30, 30, 30, 255)
		--render.drawRect(-cs * 0.3, -cs * 0.3, cs * 0.6, cs * 0.6)
		render.setColor(game.player == 1 and Color(0, 255, 0) or (game.player == 2 and Color(255, 0, 0) or Color(0, 0, 255)))
		render.drawRect(-cs * 0.3 + 2, -cs * 0.3 + 2, cs * 0.6 - 4, cs * 0.6 - 4)
		render.popMatrix()
		
		-- Player 2
		local m = Matrix()
		m:setTranslation(Vector(game.p2p.x * cs + cs / 2, game.p2p.y * cs + cs / 2))
		m:setAngles(Angle(0, timer.curtime() * -100, 0))
		
		render.pushMatrix(m)
		--render.setRGBA(30, 30, 30, 255)
		--render.drawRect(-cs * 0.3, -cs * 0.3, cs * 0.6, cs * 0.6)
		render.setColor(game.player == 2 and Color(0, 255, 0) or (game.player == 1 and Color(255, 0, 0) or Color(255, 130, 0)))
		render.drawRect(-cs * 0.3 + 2, -cs * 0.3 + 2, cs * 0.6 - 4, cs * 0.6 - 4)
		render.popMatrix()
		
		-- Move Square
		if game.curmode == 0 and target.x ~= -1 and game.time_left > 0 then
			local ppos = game.player == 1 and game.p1p or game.p2p
			local dir = target - ppos
			local len = dir:getLength()
			if len > settings.jump_range then
				render.setRGBA(255, 100, 70, 255)
				render.drawTexturedRectRotated(target.x * cs + cs / 2, target.y * cs + cs / 2, cs, 4, 45)
				render.drawTexturedRectRotated(target.x * cs + cs / 2, target.y * cs + cs / 2, cs, 4, 135)
			end
			
			-- Move line
			local pos = (target + ppos) / 2 * cs
			local len = len * cs
			
			render.setRGBA(90, 60, 255, 255)
			render.drawTexturedRectRotated(pos.x + cs / 2, pos.y + cs / 2, len, 8, math.atan2(dir.y, dir.x) / math.pi * 180)
		end
		
		-----
		
		render.popMatrix()
		
		-- Cursor
		if cx then
			render.setRGBA(255, 255, 255, 255)
			render.drawRect(cx - 2, cy - 2, 4, 4)
		end
	end)
	
	side:setRender(function()
		if game.p1 and game.p2 then
			render.setFont(font.time)
			if game.win then
				render.setRGBA(70, 255, 100, 255)
				render.drawSimpleText(512, 256, game.win, 1, 1)
			else
				render.setColor(game.time_left > 0 and Color(70, 255, 100) or Color(255, 100, 70))
				local str = tostring(math.round(math.max(0, game.time_left > 0 and game.time_left or game.next_round), 1))
				render.drawSimpleText(512, 256, str .. (str[2] == "." and "" or ".0"), 1, 1)
			end
			
			render.setFont(font.round)
			render.drawSimpleText(512, 456, "Round " .. game.round, 1, 1)
			
			render.setFont(font.name)
			render.setRGBA(255, 255, 255, 255)
			render.drawSimpleText(512, 56, "vs", 1, 1)
			render.setColor(game.player == 1 and Color(0, 255, 0) or (game.player == 2 and Color(255, 0, 0) or Color(0, 0, 255)))
			render.drawSimpleText(488, 56, game.p1:getName(), 2, 1)
			render.setColor(game.player == 2 and Color(0, 255, 0) or (game.player == 1 and Color(255, 0, 0) or Color(255, 130, 0)))
			render.drawSimpleText(536, 56, game.p2:getName(), 0, 1)
		else
			render.setFont(font.round)
			render.drawSimpleText(512, 256, "vs", 1, 1)
			
			render.setFont(font.time)
			render.setColor(game.player == 1 and Color(0, 255, 0) or (game.player == 2 and Color(255, 0, 0) or Color(0, 0, 255)))
			render.drawSimpleText(512, 190, game.p1 and game.p1:getName() or "E or M1 to join", 1, 1)
			render.setColor(game.player == 2 and Color(0, 255, 0) or (game.player == 1 and Color(255, 0, 0) or Color(255, 130, 0)))
			render.drawSimpleText(512, 342, game.p2 and game.p2:getName() or "E or M1 to join", 1, 1)
		end
	end)
	
	----------------------------------------
	
	hook.add("think", "", function()
		local delta = timer.frametime()
		
		game.time_left = game.time_left - delta
		
		local new = game.next_round - delta
		if new < 0 and game.next_round > 0 then
			game.time_left = settings.time
		end
		game.next_round = new
	end)
	
	hook.add("inputPressed", "", function(key)
		if key == KEY.E or key == 107 then
			if game.player == 0 and game.on_screen then
				net.start("join")
				net.send()
			elseif game.time_left > 0 and game.target.x ~= -1 then
				if game.curmode == 1 then
					net.start("drop")
					net.writeUInt(game.target.x, 5)
					net.writeUInt(game.target.y, 5)
					net.send()
					
					game.curmode = 2
				elseif game.curmode == 0 then
					local dir = game.target - (game.player == 1 and game.p1p or game.p2p)
					local len = dir:getLength()
					if len <= settings.jump_range then
						net.start("move")
						net.writeUInt(game.target.x, 5)
						net.writeUInt(game.target.y, 5)
						net.send()
						
						game.curmode = 1
					end
				end
			end
		end
	end)
	
end
