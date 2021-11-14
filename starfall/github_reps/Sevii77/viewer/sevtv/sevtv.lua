--@name Sev.tv
--@author Sevii
--@client
--@include ../../lib/gui2.lua

local ip = "https://sevii.dev/api/streamer/"

local font = {
	err = render.createFont("Trebuchet", 40, 350, true),
	list_title = render.createFont("Trebuchet", 30, 350, true),
	list_small = render.createFont("Trebuchet", 25, 350, true)
}

local GUI = require("../../lib/gui2.lua")
local gui = GUI(512, 512)

----------------------------------------

function getallstreams()
	http.get(ip .. "streams", function(data)
		gui:destroy()
		gui = GUI(512, 512)
		
		if data[1] == "{" then
			data = json.decode(data)
			
			local scrollframe = gui:create("scrollframe")
			scrollframe:setSize(512, 512)
			scrollframe.dockMargin = 5
			scrollframe.scrollbarY = true
			
			local content = gui:create("container")
			content:setSize(512, 512)
			content.dock = GUI.DOCK.FILL
			content.dockPadding = 5
			content.cornerStyle = 0
			scrollframe.content = content
			
			if table.count(data) == 0 then
				local label = gui:create("label", content)
				label.dock = GUI.DOCK.TOP
				label.h = 60
				label.text = "There are currently no active streams"
			else
				for view_id, stream_data in pairs(data) do
					local button = gui:create("button", content)
					button.h = 80
					button.dock = GUI.DOCK.TOP
					button.dockMargin = 5
					button.text = ""
					button.onClick = function(self)
						stream(view_id)
					end
					
					local title = gui:create("label", button)
					title.dock = GUI.DOCK.TOP
					title.textWrapping = true
					title.text = stream_data.name
					title.font = font.list_title
					title.h = title.textHeight
					title.textAlignmentX = 0
					title.textAlignmentY = 3
					title.textOffsetX = 10
					title.translucent = true
					title.mainColor = Color(0, 0, 0, 0)
					
					local name = gui:create("label", button)
					name.w = 300
					name.dock = GUI.DOCK.LEFT
					name.text = stream_data.streamer_name
					name.textAlignmentX = 0
					name.textOffsetX = 10
					name.translucent = true
					name.mainColor = Color(0, 0, 0, 0)
					
					local viewers = gui:create("label", button)
					viewers.w = 100
					viewers.dock = GUI.DOCK.RIGHT
					viewers.text = stream_data.viewers .. " Viewers"
					viewers.textAlignmentX = 2
					viewers.textOffsetX = 10
					viewers.translucent = true
					viewers.mainColor = Color(0, 0, 0, 0)
				end
			end
			
			local button = gui:create("button", content)
			button.h = 60
			button.dock = GUI.DOCK.TOP
			button.dockMargin = 5
			button.text = "Refresh"
			button.onClick = function()
				if not http.canRequest() then return end
				
				getallstreams()
			end
		else
			gui:destroy()
			gui = GUI(512, 512)
			
			local text = gui:create("text")
			text:setPos(256, 220)
			text.text = string.match(data, "<body>([%w%p%s%c]+)</body>")
			text.font = font.err
			
			local retry = gui:create("button")
			retry:setPos(216, 350)
			retry:setSize(80, 30)
			retry.text = "Retry"
			retry.onClick = function()
				if not http.canRequest() then return end
				
				getallstreams()
			end
		end
	end, function(err)
		local text = gui:create("label")
		text:setPos(256, 220)
		text.text = err
		text.font = fonr.err
		
		local retry = gui:create("button")
		retry:setPos(216, 350)
		retry:setSize(80, 30)
		retry.text = "Retry"
		retry.onClick = function()
			if not http.canRequest() then return end
			
			getallstreams()
		end
	end)
end

function stream(view_id)
	gui:destroy()
	gui = GUI(512, 512)
	
	local sheet, sheet2
	local next = 0
	
	local viewdata = {
		fps = 1,
		width = 1,
		height = 1,
		sheet_id = 0,
		viewers = 0,
		name = "",
		streamer_name = "",
		err = nil,
		max_x = 1,
		max_y = 1,
		frames_per_sheet = 1,
		frame = 0,
	}
	
	local function loadnewsheet()
		if sheet then
			render.destroyRenderTarget(sheet:getName() .. "$basetexture")
			sheet:destroy()
		end
		
		sheet = sheet2
		sheet2 = material.create("UnlitGeneric")
		sheet2:setTextureURL("$basetexture", ip .. view_id .. "/" .. viewdata.sheet_id)
	end
	
	local function updateviewdata(simple)
		http.get(ip .. view_id, function(data)
			if data[1] == "{" then
				data = json.decode(data)
				
				if data.error then
					viewdata.err = data.error
				else
					viewdata.viewers = data.viewers
					
					if not simple then
						viewdata.fps = data.fps
						viewdata.width = data.width
						viewdata.height = data.height
						viewdata.sheet_id = data.current_sheet_id
						viewdata.name = data.name
						viewdata.streamer_name = data.streamer_name
						viewdata.max_x = math.floor(1024 / data.width)
						viewdata.max_y = math.floor(1024 / data.height)
						viewdata.frames_per_sheet = viewdata.max_x * viewdata.max_y
						
						next = timer.curtime() + 1 / data.fps
					end
				end
			else
				viewdata.err = string.match(data, "<body>([%w%p%s%c]+)</body>")
			end
		end, function(err)
			viewdata.err = err
		end)
	end
	
	updateviewdata()
	
	-- TODO: make gui
	hook.add("think", "stream", function()
		if next == 0 then return end
		
		while timer.curtime() >= next do
			next = next + 1 / viewdata.fps
			viewdata.frame = viewdata.frame + 1
			
			if viewdata.frame >= viewdata.frames_per_sheet then
				viewdata.sheet_id = viewdata.sheet_id + 1
				viewdata.frame = 0
				loadnewsheet()
				
				if viewdata.sheet_id % 5 == 0 then
					updateviewdata(true)
				end
			end
		end
	end)
	
	hook.add("render", "stream", function()
		if viewdata.err then
			render.drawSimpleText(256, 256, viewdata.err, 1, 1)
			
			return 
		end
		
		render.setMaterial(sheet)
		local u, v = (viewdata.frame % viewdata.max_x) * viewdata.width / 1024, math.floor(viewdata.frame / viewdata.max_x) * viewdata.height / 1024
		render.drawTexturedRectUV(0, 0, 512 * math.min(1, viewdata.width / viewdata.height), 512 * math.min(1, viewdata.height / viewdata.width), u, v, u + (viewdata.width / 1024), v + (viewdata.height / 1024))
		
		render.setRGBA(50, 50, 50, 100)
		render.drawRect(0, 490, 512, 22)
		
		render.setRGBA(255, 255, 255, 255)
		render.drawSimpleText(506, 501, viewdata.viewers .. " Viewers", 2, 1)
		
		-- render.drawTexturedRect(0, 256, 256, 256)
		-- render.setMaterial(sheet2)
		-- render.drawTexturedRect(256, 256, 256, 256)
	end)
end

function start()
	getallstreams()
	
	hook.add("render", "", function()
		gui:think()
		gui:render()
		gui:renderCursor()
	end)
end

----------------------------------------

local perms = {
	"render.screen",
	"material.create",
	"material.urlcreate",
	"http.get"
}

local has = true
for _, perm in pairs(perms ) do
	if not hasPermission(perm) then
		has = false
		
		break
	end
end

if has then
	start()
else
	setupPermissionRequest(perms, "Do it", true)
	
	if hasPermission("render.screen") then
		hook.add("render", "request", function()
			render.drawSimpleText(256, 256, "Press E to tune into Sev.tv", 1, 1)
		end)
	end
	
	hook.add("permissionrequest", "", function()
		if permissionRequestSatisfied() then
			start()
			
			hook.remove("permissionrequest", "")
			hook.remove("render", "request")
		end
	end)
end
