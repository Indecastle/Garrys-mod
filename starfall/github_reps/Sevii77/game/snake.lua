--@name Snake pro
--@author Sevii
--@client

local res = 16
local length = 4
local speed = 0.1

----------------------------------------

local def_length = length
local grid, snake, snake_dir, snake_dir_new, apple, do_render

function reset()
	grid = {}
	snake = {}
	snake_dir = {x = 1, y = 0}
	snake_dir_new = {x = 1, y = 0}
	apple = {}
	do_render = false
	length = def_length
	
	for x = 0, res - 1 do
		grid[x] = {}
		
		for y = 0, res - 1 do
			grid[x][y] = 0
		end
	end
	
	for i = 1, length do
		local x, y = res / 2 - i, res / 2
		
		grid[x][y] = 1
		table.insert(snake, {x = x, y = y})
	end
	
	spawnApple()
end

function spawnApple()
	local x, y = math.random(0, res - 1), math.random(0, res - 1)
	
	if grid[x][y] ~= 0 then
		spawnApple()
	else
		apple = {x = x, y = y}
		grid[x][y] = 2
	end
end

----------------------------------------

reset()

render.createRenderTarget("")

local function think()
	do_render = true
	
	snake_dir.x = snake_dir_new.x
	snake_dir.y = snake_dir_new.y
	local x, y = snake[1].x + snake_dir.x, snake[1].y + snake_dir.y
	
	if x == res then
		x = 0
	elseif x == -1 then
		x = res - 1
	elseif y == res then
		y = 0
	elseif y == -1 then
		y = res - 1
	end
	
	if grid[x][y] == 1 then
		return reset()
	elseif grid[x][y] == 0 then
		local ass = snake[#snake]
		snake[#snake] = nil
		grid[ass.x][ass.y] = 0
	else
		spawnApple()
	end
	
	grid[x][y] = 1
	table.insert(snake, 1, {x = x, y = y})
end

timer.create("think", speed, 0, think)

hook.add("render", "", function()
	if do_render then
		render.selectRenderTarget("")
		render.clear(Color(0, 0, 0, 0))
		
		render.setRGBA(100, 255, 140, 255)
		for _, pos in pairs(snake) do
			render.drawRect(pos.x, pos.y, 1, 1)
		end
		
		render.setRGBA(255, 100, 140, 255)
		render.drawRect(apple.x, apple.y, 1, 1)
		
		render.selectRenderTarget()
		
		do_render = false
	end
	
	render.setFilterMin(1)
	render.setFilterMag(1)
	render.setRGBA(255, 255, 255, 255)
	render.setRenderTargetTexture("")
	render.drawTexturedRect(0, 0, 512 * (1024 / res), 512 * (1024 / res))
end)

hook.add("inputPressed", "", function(key)
	local up    = key == KEY.UP
	local down  = key == KEY.DOWN
	local left  = key == KEY.LEFT
	local right = key == KEY.RIGHT
	
	if not up and not down and not left and not right then return end
	
	local x = (1 - math.abs(snake_dir.x)) * ((right and 1 or 0) - (left and 1 or 0))
	local y = (1 - math.abs(snake_dir.y)) * ((down and 1 or 0) - (up and 1 or 0))
	
	if x + y == 0 then return end
	
	snake_dir_new.x = x
	snake_dir_new.y = y
end)
