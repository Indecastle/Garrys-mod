local net = table.copy(net)
local math = math

----------------------------------------

local lookup_write, lookup_read, lookup_type

lookup_write = {
	-- Generic table
	[0] = function(tbl)
		net.writeUInt(table.count(tbl), 12) -- Only use 10 bits, cuz who is gonna send more than 4096 entries in a table, noone right... right?
		for k, v in pairs(tbl) do
			net.writeSimple(k)
			net.writeSimple(v)
		end
	end,
	
	-- Itteratable table
	[1] = function(tbl)
		net.writeUInt(#tbl, 12)
		for _, v in ipairs(tbl) do
			net.writeSimple(v)
		end
	end,
	
	-- Bool
	[2] = net.writeBool,
	
	-- String
	[3] = net.writeString,
	
	-- Float
	[4] = net.writeFloat,
	
	-- < 2^8 uint
	[5] = function(n)
		net.writeUInt(n, 8)
	end,
	
	-- < 2^16 uint
	[6] = function(n)
		net.writeUInt(n, 16)
	end,
	
	-- < 2^32 uint
	[7] = function(n)
		net.writeUInt(n, 32)
	end,
	
	-- < 2^7 int
	[8] = function(n)
		net.writeInt(n, 8)
	end,
	
	-- < 2^15 int
	[9] = function(n)
		net.writeInt(n, 16)
	end,
	
	-- < 2^31 int
	[10] = function(n)
		net.writeInt(n, 32)
	end,
	
	-- Vector
	[11] = function(vec)
		net.writeFloat(vec.x)
		net.writeFloat(vec.y)
		net.writeFloat(vec.z)
	end,
	
	-- Angle
	[12] = function(ang)
		net.writeFloat(ang.p)
		net.writeFloat(ang.y)
		net.writeFloat(ang.r)
	end,
	
	-- Entity
	[13] = function(ent)
		net.writeUInt(ent:entIndex(), 13)
	end,
	
	-- Player
	[14] = function(ply)
		net.writeUInt(ply:entIndex(), 7)
	end,
	
	-- nil
	[15] = function()
		
	end,
}

lookup_read = {
	-- Generic table
	[0] = function(tbl)
		local tbl = {}
		for _ = 1, net.readUInt(12) do
			tbl[net.readSimple()] = net.readSimple()
		end
		
		return tbl
	end,
	
	-- Itteratable table
	[1] = function(tbl)
		local tbl = {}
		for i = 1, net.readUInt(12) do
			tbl[i] = net.readSimple()
		end
		
		return tbl
	end,
	
	-- Bool
	[2] = net.readBool,
	
	-- String
	[3] = net.readString,
	
	-- Float
	[4] = net.readFloat,
	
	-- < 2^8 uint
	[5] = function(n)
		return net.readUInt(8)
	end,
	
	-- < 2^16 uint
	[6] = function()
		return net.readUInt(16)
	end,
	
	-- < 2^32 uint
	[7] = function()
		return net.readUInt(32)
	end,
	
	-- < 2^7 int
	[8] = function()
		return net.readInt(8)
	end,
	
	-- < 2^15 int
	[9] = function()
		return net.readInt(16)
	end,
	
	-- < 2^31 int
	[10] = function()
		return net.readInt(32)
	end,
	
	-- Vector
	[11] = function()
		return Vector(net.readFloat(), net.readFloat(), net.readFloat())
	end,
	
	-- Angle
	[12] = function()
		return Angle(net.readFloat(), net.readFloat(), net.readFloat())
	end,
	
	-- Entity
	[13] = function()
		-- Return entity if valid, id otherwise
		local id = net.readUInt(13)
		local ent = entity(id)
		return isValid(ent) and ent or id
	end,
	
	-- Player
	[14] = function()
		-- Return entity if valid, id otherwise
		local id = net.readUInt(7)
		local ent = entity(id)
		return isValid(ent) and ent or id
	end,
	
	-- nil
	[15] = function()
		return nil
	end,
}

lookup_type = {
	table = function(var)
		-- Return 1 if the table is itteratable, 0 otherwise
		return table.count(var) == #var and 1 or 0
	end,
	boolean = function(var) return 2 end,
	string = function(var) return 3 end,
	number = function(var)
		-- Float
		if math.floor(var) ~= var then return 4 end
		
		-- Is unsigned
		if var >= 0 then
			return var < 2^8 and 5 or (var < 2^16 and 6 or 7)
		end
		
		-- Is signed
		local var = math.abs(var)
		return var < 2^7 and 8 or (var < 2^15 and 9 or 10)
	end,
	Vector = function(var) return 11 end,
	Angle = function(var) return 12 end,
	Entity = function(var) return 13 end,
	Player = function(var) return 14 end,
	["nil"] = function(var) return 15 end,
}

----------------------------------------

do
	
	function net.writeSimple(var)
		local type_id = lookup_type[type(var)](var)
		
		net.writeUInt(type_id, 4)
		lookup_write[type_id](var)
	end
	
	function net.readSimple()
		return lookup_read[net.readUInt(4)]()
	end
	
end

----------------------------------------

return net