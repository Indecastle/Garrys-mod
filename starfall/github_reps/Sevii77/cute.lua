--@name Cuties
--@author Sevii

local count = 50
local jump_delay = 2
local volume = 0.5

local size = 7
local offset = Vector()
local img = "https://u.teknik.io/vzisz.png"

-- local size = 12
-- local offset = Vector(0, 0, 20)
-- local img = "https://u.teknik.io/Q0PCw.png"

local sounds = {
	"https://u.teknik.io/ZqXJ1.ogg",
	"https://u.teknik.io/6z7mf.ogg",
	"https://u.teknik.io/K0qEc.ogg",
	"https://u.teknik.io/q3nHb.ogg",
	
	"https://u.teknik.io/ZqXJ1.ogg",
	"https://u.teknik.io/6z7mf.ogg",
	"https://u.teknik.io/K0qEc.ogg",
	"https://u.teknik.io/q3nHb.ogg",
	
	"https://u.teknik.io/ZqXJ1.ogg",
	"https://u.teknik.io/6z7mf.ogg",
	"https://u.teknik.io/K0qEc.ogg",
	"https://u.teknik.io/q3nHb.ogg",
	
	"https://u.teknik.io/ZqXJ1.ogg",
	"https://u.teknik.io/6z7mf.ogg",
	"https://u.teknik.io/K0qEc.ogg",
	"https://u.teknik.io/q3nHb.ogg",
	
	"https://u.teknik.io/ZqXJ1.ogg",
	"https://u.teknik.io/6z7mf.ogg",
	"https://u.teknik.io/K0qEc.ogg",
	"https://u.teknik.io/q3nHb.ogg",
}

----------------------------------------

if SERVER then
	
	local ents = {}
	
	hook.add("think", "", function()
		local time = timer.curtime()
		
		while prop.canSpawn() and #ents < count do
			local ent = prop.create(chip():localToWorld(Vector(0, 0, 24)), Angle(), "models/sprops/cuboids/height24/size_1/cube_24x24x24.mdl", true)
			ent:enableMotion(true)
			ent:setColor(Color(0, 0, 0, 0))
			
			table.insert(ents, {
				ent = ent,
				next_jump = time + math.random() * jump_delay
			})
			
			net.start("")
			net.writeUInt(1, 8)
			net.writeUInt(ent:entIndex(), 13)
			net.send()
		end
		
		local new = {}
		for _, ent in pairs(ents) do
			if isValid(ent.ent) then table.insert(new, ent) end
			
			if time >= ent.next_jump then
				ent.next_jump = time + math.rand(jump_delay * 0.8, jump_delay * 1.2)
				
				local target = find.byClass("player")
				local p = ent.ent:getPos()
				table.sort(target, function(a, b)
					return (a:getPos() - p):getLength() <  (b:getPos() - p):getLength()
				end)
				target = target[1]
				
				local power = math.max(3000, (target:getPos() - p):getLength() * 20)
				ent.ent:applyForceCenter(((target:getPos() - p):getNormalized() + Vector(0, 0, 1)) * power)
			end
		end
		ents = new
	end)
	
	net.receive("", function(_, ply)
		net.start("")
		net.writeUInt(#ents, 8)
		for _, ent in pairs(ents) do
			net.writeUInt(ent.ent:entIndex(), 13)
		end
		net.send(ply)
	end)
	
else
	
	local ents = {}
	
	----------------------------------------
	
	for i, url in pairs(sounds) do
		bass.loadURL(url, "3d noblock noplay", function(snd)
			if snd then
				sounds[i] = snd
				sounds[i]:setLooping(true)
			end
		end)
	end
	
	local mat = material.create("UnlitGeneric")
	mat:setInt("$flags", 0x0100 + 0x0010 + 0x2000)
	mat:setTextureURL("$basetexture", img)
	
	local p1 = {pos = Vector(-3, -3, 0), normal = Vector(0, 0, 1), u = 0, v = 1}
	local p2 = {pos = Vector( 3, -3, 0), normal = Vector(0, 0, 1), u = 1, v = 1}
	local p3 = {pos = Vector( 3,  3, 0), normal = Vector(0, 0, 1), u = 1, v = 0}
	local p4 = {pos = Vector(-3,  3, 0), normal = Vector(0, 0, 1), u = 0, v = 0}
	local m = mesh.createFromTable({p2, p1, p4, p3, p2, p4})
	
	----------------------------------------
	
	net.start("")
	net.send()
	
	net.receive("", function()
		for i = 1, net.readUInt(8) do
			local id = net.readUInt(13)
			
			if not ents[id] then
				local holo = holograms.create(Vector(), Angle(), "models/sprops/cuboids/height06/size_1/cube_6x6x6.mdl")
				holo:setMesh(m)
				holo:setMeshMaterial(mat)
				holo:setRenderBounds(Vector(-size * 3), Vector(size * 3))
				
				ents[id] = {
					holo = holo,
					next_sound = timer.curtime() + math.rand(5, 10),
					pause_sound = 0
				}
			end
		end
	end)
	
	----------------------------------------
	
	hook.add("think", "", function()
		local time = timer.curtime()
		
		for id, data in pairs(ents) do
			local ent = entity(id)
			
			if not isValid(ent) then continue end
			
			local p = ent:getPos() + offset
			
			-- sprite
			local m = Matrix()
			m:setScale(Vector(size))
			m:setAngles((p - eyePos()):getAngle())
			m:rotate(Angle(0, -90, 90))
			
			data.holo:setPos(p)
			data.holo:setRenderMatrix(m)
			
			-- sound
			if time > data.next_sound then
				data.sound = table.random(sounds)
				
				if type(data.sound) == "string" then
					data.sound = nil
					
					continue
				end
				
				data.sound:setTime(0)
				data.sound:play()
				data.sound:setPos(ent:getPos())
				
				local pitch = math.rand(0.9, 1.1)
				data.sound:setPitch(pitch)
				data.sound:setVolume(volume * math.rand(0.8, 1.2))
				
				data.next_sound = time + math.rand(3, 6)
				data.pause_sound = time + data.sound:getLength() * pitch - timer.frametime() * 2
			end
			
			if data.sound and data.pause_sound and data.pause_sound <= time then
				data.sound:pause()
				data.pause_sound = nil
			end
		end
	end)
	
end
