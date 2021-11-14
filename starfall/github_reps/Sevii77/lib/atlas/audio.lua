--@include ./core.lua

local atlas = require("./core.lua")
local audios = {}
local basssess = {}
local actives = {}

----------------------------------------

hook.add("think", "lib_atlas_audio", function()
	local new = {}
	for i, v in pairs(actives) do
		v.time = v.time + timer.frametime()
		
		if v.time >= v.end_time then
			v.sound:pause()
		else
			table.insert(new, v)
		end
	end
	actives = new
end)

----------------------------------------

function atlas.playAudio(id)
	assert(audios[id], "Audio with id of " .. id .. " doesn't exists")
	
	local audio = audios[id]
	
	local index = basssess[audio.bass].cur_index
	basssess[audio.bass].cur_index = (index % #basssess[audio.bass].sounds) + 1
	local sound = basssess[audio.bass].sounds[index]
	
	for i, v in pairs(actives) do
		if v.bass == audio.bass and v.index == index then
			table.remove(actives, i)
			
			break
		end
	end
	
	table.insert(actives, {
		bass = audio.bass,
		index = index,
		sound = sound,
		time = audios[id].start / 1000,
		end_time = (audios[id].start + audios[id].length) / 1000
	})
	
	sound:pause()
	sound:setTime(audios[id].start / 1000)
	sound:setVolume(1)
	sound:setPitch(1)
	sound:play()
	
	return sound
end

function atlas.registerAudio(url, flags, timestamps, cache_count)
	--[[
		timestamps example
		its always recommended to leave a short empty space between segments to have it not play a small part of the next segment
		miliseconds
		
		{
			["menu"] = {
				start = 0,
				length = 650
			},
			["click"] = {
				start = 750,
				length = 1500
			}
		}
	]]
	
	local bass_id = crc(url)
	
	for k, v in pairs(timestamps) do
		audios[k] = {
			start = v.start,
			length = v.length,
			bass = bass_id
		}
	end
	
	basssess[bass_id] = {
		cur_index = 1,
		sounds = {}
	}
	
	for i = 1, cache_count or 1 do
		bass.loadURL(url, flags .. " noplay", function(sound, err, err_name)
			assert(sound, "Audio with url of " .. url .. " Failed to load (" .. err .. " " .. err_name .. ")")
			
			--sound:setPos(chip():getPos())
			sound:setLooping(true)
			
			table.insert(basssess[bass_id].sounds, sound)
		end)
	end
end

----------------------------------------

return atlas