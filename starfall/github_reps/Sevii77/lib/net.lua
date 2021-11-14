local net = net
local networking = {
	packet_types = {},
	names = {},
	names_id = {},
	names_r = {},
	names_r_id = {},
	receives = {},
	request_receivers = {},
	requests = {}
}

for k, v in pairs(net) do
	if string.find(k, "read") or string.find(k, "write") then
		networking[k] = v
	end
end

----------------------------------------

function networking.registerPacketType(packet_type, write, read)
	networking.packet_types[packet_type] = {
		write = write,
		read = read
	}
end

function networking.registerNetworkName(network_name, packet_type)
	local id = table.count(networking.names)
	
	networking.names_id[id] = {
		pt = networking.packet_types[packet_type],
		name = network_name
	}
	
	networking.names[network_name] = {
		pt = networking.packet_types[packet_type],
		id = id
	}
end

function networking.registerRequestName(network_name)
	local id = table.count(networking.names_r)
	
	networking.names_r_id[id] = network_name
	networking.names_r[network_name] = id
end

function networking.send(network_name, data, ply, unreliable)
	local n = networking.names[network_name]
	
	assert(n, "Tried to network with invalid network name " .. network_name)
	
	net.start("")
	net.writeBool(false)
	net.writeUInt(n.id, 5)
	n.pt.write(data)
	net.send(ply, unreliable)
end

function networking.receive(network_name, func)
	networking.receives[networking.names[network_name].id] = func
end

function networking.setupRequest(network_name, func)
	networking.request_receivers[networking.names_r[network_name]] = func
end

function networking.request(network_name, callback, ply)
	local id = networking.names_r[network_name]
	
	net.start("")
	net.writeBool(true)
	net.writeUInt(id, 5)
	net.writeBool(false)
	net.send(ply)
	
	networking.requests[id] = {
		callback = callback,
		ply = ply
	}
end

----------------------------------------

net.receive("", function(bits, ply)
	if not net.readBool() then -- Normal
		local id = net.readUInt(5)
		local data = networking.names_id[id].pt.read()
		
		if networking.receives[id] then
			networking.receives[id](data, ply, bits) -- 29 cost without anything written
		end
	else -- Request
		local id = net.readUInt(5)
		
		if net.readBool() then -- Is it a response
			local request = networking.requests[id]
			
			if request and request.ply == ply then
				request.callback(bits, ply)
				
				networking.requests[id] = nil
			end
		else
			if networking.request_receivers[id] then
				net.start("")
				net.writeBool(true)
				net.writeUInt(id, 5)
				net.writeBool(true)
				networking.request_receivers[id](ply, bits)
				net.send(ply)
			end
		end
	end
end)

----------------------------------------

return networking