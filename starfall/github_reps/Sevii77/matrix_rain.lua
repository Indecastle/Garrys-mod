--@name Matrix Rain
--@author Sevii
--@client

local size = 8
local fall_mul = 4
local decay_mul = 4
local frequency = 20
local color = Color(0, 255, 65)

----------------------------------------

local time = 0
local delay = 1 / frequency
local droplets = {}
local font = render.createFont("Roboto Mono", size)

render.createRenderTarget("")
hook.add("render", "", function()
	local delta = timer.frametime()
	
	-- Spawn new droplets
	time = time - delta
	
	while time <= 0 do
		time = time + delay
		
		table.insert(droplets, {
			x = math.random(0, 512 / size),
			y = 0
		})
	end
	
	-- Handle droplets
	render.selectRenderTarget("")
	render.setColor(color)
	render.setFont(font)
	render.setFilterMin(1)
	render.setFilterMag(1)
	
	local drop = delta * fall_mul
	
	local new = {}
	for _, droplet in pairs(droplets) do
		local y = droplet.y + drop
		
		if y < 512 / size then
			local yr = math.round(y)
			local char = droplet.char
			
			if yr ~= droplet.yr then
				char = string.char(math.random(34, 128))
			end
			
			table.insert(new, {
				x = droplet.x,
				y = y,
				yr = yr,
				char = char
			})
			
			render.drawSimpleText(droplet.x * size, yr * size, char)
		end
	end
	droplets = new
	
	-- RT
	render.setRGBA(0, 0, 0, delta * decay_mul * 255)
	render.drawRect(0, 0, 1024, 1024)
	
	render.selectRenderTarget()
	render.setRenderTargetTexture("")
	render.setRGBA(255, 255, 255, 255)
	render.drawTexturedRect(0, 0, 1024, 1024)
end)
