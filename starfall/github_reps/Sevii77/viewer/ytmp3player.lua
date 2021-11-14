--@name YT MP3 Player
--@author Sevii
--@include ../lib/gui2.lua

--[[
	
	TODO:
	- optimize it holy shit is it expensive the way it currently sets
	  the time of new bass objects or of those when changing the time
	
]]

local server = "https://sevii.dev/api/ytmp3/%s"
local settings = {
	volume = 1,
	mindist = 1000,
	maxdist = 1200
}

if SERVER then
	
	local video_id
	
	hook.add("playerSay", "", function(ply, text)
		local cmds = string.split(text, " ")
		
		if string.sub(text, 1, 4) ~= ".yt " then return end
		
		video_id = nil
		local id = string.match(cmds[2], "[%w_-]+$")
		
		net.start("download")
		net.writeString(id)
		net.send(owner())
		
		net.start("loading")
		net.writeString(id)
		net.send()
	end)
	
	net.receive("request", function(_, ply)
		if video_id then
			net.start("id")
			net.writeString(video_id)
			net.send(ply)
		end
	end)
	
	net.receive("download", function(_, ply)
		if ply ~= owner() then return end
		
		video_id = net.readString()
		
		net.start("id")
		net.writeString(video_id)
		net.send()
	end)
	
	net.receive("err", function(_, ply)
		if ply ~= owner() then return end
		
		net.start("err")
		net.writeString(net.readString())
		net.writeString(net.readString())
		net.send()
	end)
	
else
	
	local curaudios = {}
	local status, video_id = "Nothing", "Playing"
	
	local time_slider
	local boom = {val = 0, x = 0, y = 0}
	
	----------------------------------------
	
	GUI = require("../lib/gui2.lua")
	local gui = GUI(512, 512)
	
	do
		local frame = gui:create("frame")
		frame.pos = Vector(56, 56)
		frame.size = Vector(400, 400)
		frame.closeable = false
		frame.minSize = Vector(200, 150)
		
		local volume = gui:create("slider", frame.inner)
		volume.mainColor = "primaryColorDark"
		local normal_color = volume.activeColor
		local red = Color(220, 60, 80)
		volume.pos = Vector(0, 0)
		volume.height = 25
		volume.dock = GUI.DOCK.TOP
		volume.style = 2
		volume.cornerStyle = 0
		volume.text = "Volume %s"
		volume.min = 0
		volume.max = 11
		volume.round = 1
		volume.value = settings.volume
		volume.onChange = function(self, val)
			settings.volume = val / 11 * 10
			
			if not video_id then return end
			
			local want = math.ceil((val - 10) * 19)
			local add = want - #curaudios
			
			if add > 0 then
				play(video_id, add, true)
			elseif add < 0 then
				for i = math.max(want, 2), #curaudios do
					if curaudios[i] and type(curaudios[i]) == "Bass" and isValid(curaudios[i]) then
						curaudios[i]:destroy()
					end
					
					curaudios[i] = nil
				end
			end
			
			local v = math.max(0, val - 10)
			local clr = normal_color * (1 - v) + red * v
			self.activeColor = clr
			self.hoverColor = clr * 1.2
			
			time_slider.activeColor = clr
			time_slider.hoverColor = clr * 1.2
		end
		
		local time = gui:create("slider", frame.inner)
		time.mainColor = "primaryColorDark"
		time.height = 10
		time.dock = GUI.DOCK.BOTTOM
		time.style = 2
		time:setCornerStyle(0, 0, 2, 1)
		time:setCornerSize(0, 0, 10, 5)
		time.text = "Time %i"
		time.onChange = function(self, val)
			local audio = curaudios[1]
			if not audio or type(audio) ~= "Bass" or not isValid(audio) then return end
			if val > audio:getLength() then return end
			
			for _, audio in pairs(curaudios) do
				if not audio or type(audio) ~= "Bass" or not isValid(audio) then continue end
				
				local id = tostring(audio)
				timer.create(id, 0, 0.5, function()
					if not audio or type(audio) ~= "Bass" or not isValid(audio) then timer.stop(id) return timer.remove(id) end
					
					audio:setTime(val)
					
					if audio:getTime() >= val then
						timer.stop(id)
						timer.remove(id)
					end
				end)
			end
		end
		
		local vis = gui:create("container", frame.inner)
		vis.dock = GUI.DOCK.FILL
		vis.onDraw = function(self, w, h) end
		vis.onPostDraw = function(self, w, h)
			local m = Matrix()
			m:setTranslation(self.globalPos + Vector(boom.x, boom.y))
			render.pushMatrix(m)
			
			-----
			
			boom.val = math.max(0, boom.val - timer.frametime() * 70)
			
			-----
			
			local audio = curaudios[1]
			if audio and type(audio) == "Bass" and isValid(audio) then
				local bw = w / 64
				local fft = audio:getFFT(4)
				
				if #fft >= 64 then
					local avg2 = 0
					for i = 8, 16 do
						avg2 = avg2 + fft[i] / 10
					end
					boom.val = math.max(boom.val, math.max(0, avg2 - 0.06) * 200)
					
					
					render.setColor(gui.theme.primaryColorDark)
					for i = math.floor(time.progress * 63), 63 do
						local height = fft[i + 1] * h
						render.drawRect(i * bw, h - height, bw, height)
					end
					
					render.setColor(time.activeColor)
					for i = 0, math.ceil(time.progress * 63) do
						local height = fft[i + 1] * h
						render.drawRect(i * bw, h - height, math.min(1, time.progress * 64 - i) * bw, height)
					end
				end
				
				time_slider.value = audio:getTime()
			end
			
			render.setRGBA(255, 255, 255, 255)
			
			local text = tostring(status) .. " " ..tostring(video_id)
			local _, th = render.getTextSize(text)
			render.drawText(w / 2, h / 2 - th / 2, text, 1, 1)
			
			render.popMatrix()
			
			-----
			
			boom.x = math.rand(-1, 1) * boom.val
			boom.y = math.rand(-1, 1) * boom.val
		end
		
		time_slider = time
	end
	
	----------------------------------------
	
	function play(id, count, add)
		if not add then
			for _, audio in pairs(curaudios) do
				if type(audio) ~= "Bass" then continue end
				
				audio:stop()
				if isValid(audio) then
					audio:destroy()
				end
			end
			
			curaudios = {}
			status = "Playing"
			video_id = id
		end
		
		local done_count = 0
		for i2 = 1, count do
			local i = #curaudios + 1
			curaudios[i] = true
			
			local id = tostring(math.random())
			hook.add("think", id, function()
				if bass.soundsLeft() == 0 then return end
				hook.remove("think", id)
				
				bass.loadURL(string.format(server, video_id), "3d noblock noplay", function(snd, a, b)
					if not snd then
						status = "Error:"
						video_id = tostring(a) .. " " .. tostring(b)
						
						return
					end
					
					curaudios[i] = snd
					curaudios[i]:setLooping(true)
					
					if add then
						-- curaudios[i]:play()
						-- curaudios[i]:setTime(curaudios[1]:getTime())
						
						-- print(curaudios[i]:getTime(), curaudios[1]:getTime())
						
						local id = tostring(snd)
						-- hook.add("think", id, function()
						timer.create(id, 0, 0.5, function()
							if not snd or type(snd) ~= "Bass" or not isValid(snd) then timer.stop(id) return timer.remove(id) end
							
							local tsnd = curaudios[1]
							if not tsnd or type(tsnd) ~= "Bass" or not isValid(tsnd) then timer.stop(id) return timer.remove(id) end
							
							local tt = tsnd:getTime()
							snd:setTime(tt)
							
							if snd:getTime() >= tt then
								timer.stop(id)
								timer.remove(id)
								
								snd:play()
							end
						end)
					else
						done_count = done_count + 1
						if done_count == count then
							for _, audio in pairs(curaudios) do
								if not audio or type(audio) ~= "Bass" or not isValid(audio) then continue end
								
								audio:play()
							end
							
							time_slider.max = curaudios[1]:getLength()
							time_slider.value = 0
						end
					end
				end)
			end)
		end
	end
	
	----------------------------------------
	
	local function dothink()
		local pos = player():getPos()
		local dist = (pos - chip():getPos()):getLength()
		local volume = math.max(0, 1 - math.max(0, dist - settings.mindist) / (settings.maxdist - settings.mindist)) * settings.volume
		
		for _, audio in pairs(curaudios) do
			if not audio or type(audio) ~= "Bass" or not isValid(audio) then continue end
			
			audio:setPos(pos)
			audio:setVolume(volume)
		end
	end
	
	local function dorender()
		render.setBackgroundColor(Color(0, 0, 0, 0))
		
		gui:think()
		gui:render(boom.x, boom.y)
	end
	
	local function load()
		net.start("request")
		net.send()
		
		net.receive("loading", function()
			video_id = net.readString()
			status = "Loading"
		end)
		
		net.receive("id", function()
			play(net.readString(), 1 + math.max(1, math.ceil((settings.volume - 10) * 19)))
		end)
		
		net.receive("err", function()
			status = "Error playing " .. net.readString() .. ":\n" .. net.readString() .. "\n\n" .. status
		end)
		
		hook.add("think", "", dothink)
		hook.add("render", "", dorender)
	end
	
	----------------------------------------
	
	if player() == owner() then
		net.receive("download", function()
			local video_id = net.readString()
			
			http.get(string.format(server, video_id), function(data)
				xpcall(function()
					res = json.decode(data)
					
					net.start("err")
					net.writeString(video_id)
					net.writeString(res.error)
					net.send()
				end, function()
					net.start("download")
					net.writeString(video_id)
					net.send()
				end)
			end, function(err)
				net.start("err")
				net.writeString(video_id)
				net.writeString(err)
				net.send()
			end)
		end)
	end
	
	----------------------------------------
	
	local perms = {
		"render.screen",
		"bass.loadURL",
		"sound.create",
		"sound.modify"
	}
	
	local has = true
	for _, perm in pairs(perms) do
		if not hasPermission(perm) then
			has = false
			
			break
		end
	end
	
	if has then
		load()
	else
		setupPermissionRequest(perms, "do it pussboi", true)
		
		if hasPermission("render.screen") then
			hook.add("render", "perms", function()
				render.drawSimpleText(256, 256, "Press e to listen to epic songs", 1, 1)
			end)
		end
		
		hook.add("permissionrequest", "perms", function()
			if permissionRequestSatisfied() then
				hook.remove("permissionrequest", "perms")
				hook.remove("render", "perms")
				
				load()
			end
		end)
	end
	
end