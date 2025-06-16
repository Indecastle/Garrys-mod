--@name SafeNet
--@author Jacbo

-- To include add this to the top of your file (remove the space between --@ and include):
-- --@ include https://raw.githubusercontent.com/Jacbo1/Public-Starfall/main/SafeNet/safeNet.lua as SafeNet
-- local net = require("SafeNet")

-- Documentation can be found at https://github.com/Jacbo1/Public-Starfall/tree/main/SafeNet
-- This library acts as a replacement for the native net library with full backwards compatibility plus new additional functions.
-- It essentially "streams" all messages too large to send on the current tick.
-- Instead of using actual streams though, it splits the normal messages into pieces and networks them as strings (reading and writing these strings is handled by SafeNet).
-- This means you can "stream" from client to server and server to client at the same time.
-- It also prevents your chips from ever crashing due to the "net burst limit exceeded" error (caused by attempting to send a net message and running out of bandwidth).

-- Messages are sent and received in the order they are queued via safeNet.send().
-- safeNet.readEntity(callback) and stringStream:readEntity(callback) now utilize the NetworkEntityCreated hook to wait for the entity to become fully valid before running the cllback.

-- Messages can also have a prefix before the actual message name. This is useful for libraries to help avoid overlapping message names in implementing code.
-- safeNet.start(prefix or nil)
-- safeNet.receive(name, callback or nil, prefix or nil)
-- The default prefix is "snm"

-- There is also a useful "init" function that allows you to easily handle client initializations.
-- You call it on client/server whenever you are ready and the server side version will run a callback for each time it is called on a client.
-- The server will queue client inits until "safeNet.init()" is used on the server (Note: the function does actually have required parameters).
-- The client side version will run a callback when it receives a response from the server.
-- The parameters to this client callback are what the server side version returns in its callback.
-- There is an example implementation on the GitHub page.

-- There is a special synchronized variables table at safeNet.syncVars.
-- This table is automatically synchronized between all clients and the server.
-- Clients will automatically fetch this table during initialization.
-- There is an example of this on the GitHub page.


-- Might protect against the implementing code globally setting net to safeNet
local net = net

-- This is the bytes per second cap
local BPS = 1024 * 1024 * 10
local timeout = 10
local bitsForMessageLength = 16
--[[do
    local netBurstLimit = 10000 -- Get this from net.getBytesLeft()
    bitsForMessageLength = math.ceil(math.log(netBurstLimit + 1, 2) + 1)
end]]
    
local curReceive, curSend, curSendName, curPrefix

--safeNet object
local bit_rshift = bit.rshift
local bit_lshift = bit.lshift
local string_char = string.char
local string_sub = string.sub
local string_byte = string.byte
local string_find = string.find
local string_replace = string.replace
local table_insert = table.insert
local table_remove = table.remove
local null_char = string_char(0)
local waitForEntities = true
local bit_band = bit.band
local math_abs = math.abs
safeNet = {}

local sends = {}
local streaming = false
local canceling = false
local cancelQueue = false

function safeNet.setTimeout(newTimeout) timeout = newTimeout end

-- Sets the bytes per second cap
function safeNet.setBPS(newBPS) BPS = newBPS end

function safeNet.start(name, prefix)
    curPrefix = prefix or "snm"
    curSend = safeNet.stringstream()
    curSendName = name
end

-- Writes a boolean
function safeNet.writeBool(bool)
    curSend:write(bool and "1" or "0")
end

-- Reads a boolean
function safeNet.readBool()
    return curReceive:read(1) ~= "0"
end

-- Writes up to 8 booleans using the same size as 1 bool
function safeNet.writeBools(...)
    local int = 0
    local args = {...}
    for i = 0, #args-1 do
        int = int + (args[i+1] and bit_lshift(1, i) or 0)
    end
    curSend:writeInt8(int)
end

-- Reads up to 8 booleans using the same size as 1 bool
function safeNet.readBools(count)
    local int = curReceive:readUInt8()
    local bools = {}
    for i = 0, count-1 do
        bools[i+1] = (bit_and(int, bit_lshift(1, i)) ~= 0)
    end
    return unpack(bools)
end

-- Writes a char
function safeNet.writeChar(c)
    curSend:write(c)
end

-- Reads a char
function safeNet.readChar()
    return curReceive:read(1)
end

-- Writes a color
-- hasAlpha defaults to true
function safeNet.writeColor(color, hasAlpha)
    curSend:writeInt8(color[1])
    curSend:writeInt8(color[2])
    curSend:writeInt8(color[3])
    if hasAlpha == nil or hasAlpha then
        curSend:writeInt8(color[4])
    end
end

-- Reads a color
-- hasAlpha defaults to true
function safeNet.readColor(hasAlpha)
    return Color(
        curReceive:readUInt8(),
        curReceive:readUInt8(),
        curReceive:readUInt8(), 
        (hasAlpha == nil or hasAlpha) and curReceive:readUInt8() or nil)
end

-- Writes an 8 bit int
-- -127 to 128
function safeNet.writeInt8(num) curSend:writeInt8(num) end
-- 0 to 255
safeNet.writeUInt8 = safeNet.writeInt8

-- Reads an unsigned 8 bit int
-- 0 to 255
function safeNet.readUInt8()
    return curReceive:readUInt8()
end

-- Reads a signed 8 bit int
-- -127 to 128
function safeNet.readInt8()
    return curReceive:readInt8()
end

-- Writes a 16 bit int
-- -32767 to 32768
function safeNet.writeInt16(num) curSend:writeInt16(num) end
-- 0 to 65535
safeNet.writeUInt16 = safeNet.writeInt16

-- Reads an unsigned 16 bit int
-- 0 to 65535
function safeNet.readUInt16()
    return curReceive:readUInt16()
end

-- Reads a signed 16 bit int
-- -32767 to 32768
function safeNet.readInt16()
    return curReceive:readInt16()
end

-- Writes a 24 bit int
-- -8388607 to 8388608
function safeNet.writeInt24(num) curSend:writeInt24(num) end
-- 0 to 16777215
safeNet.writeUInt24 = safeNet.writeInt24

-- Reads an unsigned 24 bit int
-- 0 to 16777215
function safeNet.readUInt24()
    return curReceive:readUInt24()
end

-- Reads a signed 24 bit int
-- -8388607 to 8388608
function safeNet.readInt24()
    return curReceive:readInt24()
end

-- Writes a 32 bit int
-- -2147483647 to 2147483648
function safeNet.writeInt32(num) curSend:writeInt32(num) end
-- 0 to 4294967295
safeNet.writeUInt32 = safeNet.writeInt32

-- Reads an unsigned 32 bit int
-- 0 to 4294967295
function safeNet.readUInt32(num)
    return curReceive:readUInt32()
end

-- Reads a signed 32 bit int
-- -2147483647 to 2147483648
function safeNet.readInt32()
    return curReceive:readInt32()
end

-- Writes an int (compatibility function)
-- Use one of the other writeInt functions instead
function safeNet.writeInt(num, bits)
    if bits <= 8 then curSend:writeInt8(num)
    elseif bits <= 16 then curSend:writeInt16(num)
    elseif bits <= 24 then curSend:writeInt24(num)
    else curSend:writeInt32(num) end
end
safeNet.writeUInt = safeNet.writeInt

-- Reads a signed int (compatibility function)
-- Use one of the other readInt functions instead
function safeNet.readInt(bits)
    if bits <= 8 then return curReceive:readInt8()
    elseif bits <= 16 then return curReceive:readInt16()
    elseif bits <= 24 then return curReceive:readInt24()
    else return curReceive:readInt32() end
end

-- Reads an unsigned int (compatibility function)
-- Use one of the other readUInt functions instead
function safeNet.readUInt(bits)
    if bits <= 8 then return curReceive:readUInt8()
    elseif bits <= 16 then return curReceive:readUInt16()
    elseif bits <= 24 then return curReceive:readUInt24()
    else return curReceive:readUInt32() end
end

-- Writes an entity
function safeNet.writeEntity(ent)
    curSend:writeEntity(ent)
end

-- Reads an entity
-- If cb is provided it will wait to safely load the entity like with net.readEntity(callback)
-- cb is optional
function safeNet.readEntity(cb)
    return curReceive:readEntity(cb)
end

-- Writes a hologram
safeNet.writeHologram = safeNet.writeEntity

-- Reads a hologram
-- callback is optional. Functions the same as net.readEntity(callback)
function safeNet.readHologram(cb)
    if cb then
        curReceive:readEntity(function(ent)
            if ent and ent:isValid() then
                cb(ent:toHologram())
            else
                cb(ent)
            end
        end)
    else
        return curReceive:readEntity():toHologram()
    end
end

-- Writes a "bit" (mainly here for compatibility)
function safeNet.writeBit(b)
    curSend:write(b == 0 and "0" or "1")
end

-- Reads a "bit" (mainly here for compatibility)
function safeNet.readBit(b)
    return curReceive:read(1) == "0" and 0 or 1
end

-- Writes up to 8 bits using the same size as 1 bit
function safeNet.writeBits(...)
    local int = 0
    local args = {...}
    for i = 0, #args-1 do
        int = int + ((args[i+1] ~= 0) and bit_lshift(1, i) or 0)
    end
    --curSend:writeInt8((a and 1 or 0) + (b and 2 or 0) + (c and 4 or 0) + (d and 16 or 0))
    curSend:writeInt8(int)
end

-- Reads up to 8 bits using the same size as 1 bit
function safeNet.readBits(count)
    local int = curReceive:readUInt8()
    local bits = {}
    for i = 0, count-1 do
        bits[i+1] = (bit_and(int, bit_lshift(1, i)) ~= 0) and 1 or 0
    end
    return unpack(bits)
end

-- Writes a float
function safeNet.writeFloat(num)
    curSend:writeFloat(num)
end

-- Reads a float
function safeNet.readFloat()
    return curReceive:readFloat()
end

-- Writes a double
function safeNet.writeDouble(num)
    curSend:writeDouble(num)
end

-- Reads a double
function safeNet.readDouble()
    return curReceive:readDouble()
end

-- Writes a vector
function safeNet.writeVector(vec)
    curSend:writeFloat(vec[1])
    curSend:writeFloat(vec[2])
    curSend:writeFloat(vec[3])
end

-- Reads a vector
function safeNet.readVector()
    return Vector(curReceive:readFloat(), curReceive:readFloat(), curReceive:readFloat())
end

-- Writes a vector with doubles
function safeNet.writeVectorDouble(vec)
    curSend:writeDouble(vec[1])
    curSend:writeDouble(vec[2])
    curSend:writeDouble(vec[3])
end

-- Reads a vector with doubles
function safeNet.readVectorDouble()
    return Vector(curReceive:readDouble(), curReceive:readDouble(), curReceive:readDouble())
end

-- Writes an angle
function safeNet.writeAngle(ang)
    curSend:writeFloat(ang[1])
    curSend:writeFloat(ang[2])
    curSend:writeFloat(ang[3])
end

-- Reads an angle
function safeNet.readAngle()
    return Angle(curReceive:readFloat(), curReceive:readFloat(), curReceive:readFloat())
end

-- Writes an angle with doubles
function safeNet.writeAngleDouble(ang)
    curSend:writeDouble(ang[1])
    curSend:writeDouble(ang[2])
    curSend:writeDouble(ang[3])
end

-- Reads an angle with doubles
function safeNet.readAngleDouble()
    return Angle(curReceive:readDouble(), curReceive:readDouble(), curReceive:readDouble())
end

-- Writes a quaternion
function safeNet.writeQuat(quat)
    curSend:writeDouble(quat[1])
    curSend:writeDouble(quat[2])
    curSend:writeDouble(quat[3])
    curSend:writeDouble(quat[4])
end

-- Reads a quaternion
function safeNet.readQuat()
    return Quaternion(curReceive:readDouble(), curReceive:readDouble(), curReceive:readDouble(), curReceive:readDouble())
end

-- Writes a matrix
function safeNet.writeMatrix(matrix)
    for row = 1, 4 do
        for col = 1, 4 do
            curSend:writeDouble(matrix:getField(row, col))
        end
    end
end

-- Reads a matrix
function safeNet.readMatrix()
    local matrix = {}
    for row = 1, 4 do
        local rowt = {}
        for col = 1, 4 do
            table.insert(rowt, curReceive:readDouble())
        end
        table.insert(matrix, rowt)
    end
    return Matrix(matrix)
end

-- Writes a string
-- USE WRITEDATA IF STRING CONTAINS \0
function safeNet.writeString(str)
    curSend:writeString(str)
end

-- Reads a string
function safeNet.readString()
    return curReceive:readString()
end

-- Writes a specified amount of data
-- Byte length optional
function safeNet.writeData(str, bytes)
    if bytes then curSend:write(string_sub(str, 1, bytes))
    else curSend:write(str) end
end

-- Reads a specified amount of data
function safeNet.readData(bytes)
    return curReceive:read(bytes)
end

-- Same as safeNet.writeData() but does not require a length
function safeNet.writeData2(str)
    curSend:writeInt32(#str)
    curSend:write(str)
end

-- Same as safeNet.readData() but does not require a length
function safeNet.readData2()
    local length = curReceive:readUInt32()
    return curReceive:read(length)
end

-- Writes a "stream" (mainly here for compatibility)
-- Use writeString() or writeData() instead
-- DO NOT USE NULL CHARS
safeNet.writeStream = safeNet.writeData2

-- Reads a "stream" (mainly here for compatibility)
-- Use readString() or readData() instead
-- DO NOT USE NULL CHARS
function safeNet.readStream(cb)
    cb(curReceive:readData2())
end

-- Writes the entire received stringstream for bouncing messages off of server/client to client/server
function safeNet.writeReceived()
    curSend:write(curReceive:getString())
end

-- Writes an object(s)
-- Accepts varargs
function safeNet.writeType(...)
    local count = select("#", ...)
    curSend:writeInt8(count)
    local args = {...}
    for i = 1, count do
        curSend:writeType(args[i])
    end
end

-- Writes a table
function safeNet.writeTable(t, doubleVectors, doubleAngles)
    curSend:writeInt8(1)
    curSend:writeType(t, nil, nil, doubleVectors, doubleAngles)
end

-- Reads an object
-- If called with no inputs it will try to isntantly read
-- Else it will use a coroutine and a callback
-- maxQuota can be nil and will default to math.min(quotaMax() * 0.5, 0.004)
-- Returns varargs or runs the callback with varargs
function safeNet.readType(cb, maxQuota, doubleVectors, doubleAngles)
    local count = curReceive:readUInt8()
    if count > 0 then
        local i = 0
        local recurse
        if cb then
            local results = {}
            recurse = function()
                if i >= count then
                    cb(unpack(results, 1, count))
                    return
                end
                curReceive:readType(function(result)
                    i = i + 1
                    table_insert(results, result)
                    recurse()
                end, maxQuota, doubleVectors, doubleAngles)
            end
            recurse()
        else
            recurse = function()
                i = i + 1
                if i <= count then
                    return curReceive:readType(nil, nil, doubleVectors, doubleAngles), recurse()
                end
            end
            return recurse()
        end
    elseif cb then
        cb()
    end
end

-- Reads a table
safeNet.readTable = safeNet.readType

local encode, decode, encodeCoroutine, decodeCoroutine
local queuedEntities = {}
hook.add("NetworkEntityCreated", "SafeNet NetworkEntityCreated", function(ent)
    local cb = queuedEntities[ent]
    if cb then
        cb(ent)
        queuedEntities[ent] = nil
    end
end)

function safeNet.extend(stringStream)
    local oldReadEntity = stringStream.readEntity
    
    function stringStream:readEntity(cb)
        if cb then
            oldReadEntity(self, function(ent)
                if ent and ent:isValid() then
                    cb(ent)
                    return
                end
                
                queuedEntities[ent] = cb
            end)
            return
        end
        
        return oldReadEntity(self)
    end
    
    function stringStream:writeData2(str)
        self:writeInt32(#str)
        self:write(str)
    end
    
    function stringStream:readData2()
        local len = self:readUInt32()
        return self:read(len)
    end
    
    function stringStream:writeBool(b)
        self:write(b and "1" or "0")
    end
    
    function stringStream:readBool()
        return self:read(1) ~= "0"
    end

    -- Writes a signed 24 bit int
    -- -8388607 to 8388608
    function stringStream:writeInt24(num)
        if num < 0 then num = num + 16777216 end
        self:write(string_char(num%0x100, bit_rshift(num, 8)%0x100, bit_rshift(num, 16)%0x100))
    end
    
    -- Reads an unsigned 24 bit int
    -- 0 to 16777215
    function stringStream:readUInt24()
        local a, b, c = string_byte(self:read(3), 1, 3)
        return (a or 0) + (b or 0)*0x100 + (c or 0)*0x10000
    end

    -- Reads a signed 24 bit int
    -- -8388607 to 8388608
    function stringStream:readInt24()
        local a, b, c = string_byte(self:read(3), 1, 3)
        a = (a or 0) + (b or 0)*0x100 + (c or 0)*0x10000
        if a > 8388608 then return a - 16777216 end
        return a
    end
    
    function stringStream:writeVector(v)
        self:writeFloat(v[1])
        self:writeFloat(v[2])
        self:writeFloat(v[3])
    end
    
    function stringStream:readVector()
        return Vector(self:readFloat(), self:readFloat(), self:readFloat())
    end
    
    function stringStream:writeVectorDouble(v)
        self:writeDouble(v[1])
        self:writeDouble(v[2])
        self:writeDouble(v[3])
    end
    
    function stringStream:readVectorDouble()
        return Vector(self:readDouble(), self:readDouble(), self:readDouble())
    end
    
    function stringStream:writeAngle(ang)
        self:writeFloat(ang[1])
        self:writeFloat(ang[2])
        self:writeFloat(ang[3])
    end
    
    function stringStream:readAngle()
        return Angle(self:readFloat(), self:readFloat(), self:readFloat())
    end
    
    function stringStream:writeAngleDouble(ang)
        self:writeDouble(ang[1])
        self:writeDouble(ang[2])
        self:writeDouble(ang[3])
    end
    
    function stringStream:readAngleDouble()
        return Angle(self:readDouble(), self:readDouble(), self:readDouble())
    end
    
    function stringStream:writeColor(c, hasAlpha)
        -- hasAlpha defaults to true
        self:writeInt8(c[1])
        self:writeInt8(c[2])
        self:writeInt8(c[3])
        if hasAlpha == nil or hasAlpha then
            self:writeInt8(c[4])
        end
    end
    
    function stringStream:readColor(c, hasAlpha)
        -- hasAlpha defaults to true
        return Color(
            self:readUInt8(),
            self:readUInt8(),
            self:readUInt8(), 
            (hasAlpha == nil or hasAlpha) and self:readUInt8() or nil)
    end
    
    function stringStream:writeHologram(ent)
        self:writeEntity(ent)
    end
    
    -- Callback is optional
    function stringStream:readHologram(cb)
        if cb then
            self:readEntity(function(ent)
                if ent and ent:isValid() then
                    cb(ent:toHologram())
                else
                    cb(ent)
                end
            end)
        end
        return self:readEntity():toHologram()
    end
    
    -- Writes a quaternion
    function stringStream:writeQuat(quat)
        self:writeDouble(quat[1])
        self:writeDouble(quat[2])
        self:writeDouble(quat[3])
        self:writeDouble(quat[4])
    end

    -- Reads a quaternion
    function stringStream:readQuat()
        return Quaternion(self:readDouble(), self:readDouble(), self:readDouble(), self:readDouble())
    end

    -- Writes a VMatrix
    function stringStream:writeMatrix(matrix)
        for row = 1, 4 do
            for col = 1, 4 do
                self:writeDouble(matrix:getField(row, col))
            end
        end
    end

    -- Reads a VMatrix
    function stringStream:readMatrix()
        local matrix = {}
        for row = 1, 4 do
            local rowt = {}
            for col = 1, 4 do
                table.insert(rowt, self:readDouble())
            end
            table.insert(matrix, rowt)
        end
        return Matrix(matrix)
    end

    -- Writes an object
    -- If called with just an object it will try to isntantly write
    -- Else it will use a coroutine and a callback
    -- maxQuota can be nil and will default to math.min(quotaMax() * 0.5, 0.004)
    function stringStream:writeType(obj, cb, maxQuota, doubleVectors, doubleAngles)
        if cb then
            maxQuota = maxQuota or math.min(quotaMax() * 0.5, 0.004)
            local running = false
            local encode2 = coroutine.wrap(function()
                encode(obj, self, maxQuota, doubleVectors, doubleAngles)
                cb()
                return true
            end)
            running = true
            if encode2() ~= true then
                local name = "encode " .. math.rand(0,1)
                running = false
                hook.add("think", name, function()
                    if not running then
                        running = true
                        if encode2() == true then
                            hook.remove("think", name)
                        end
                        running = false
                    end
                end)
            end
        else
            encode(obj, self, nil, doubleVectors, doubleAngles)
        end
    end

    -- Reads an object
    -- If called with no inputs it will try to isntantly read
    -- Else it will use a coroutine and a callback
    -- maxQuota can be nil and will default to math.min(quotaMax() * 0.5, 0.004)
    function stringStream:readType(cb, maxQuota, doubleVectors, doubleAngles)
        if cb then
            maxQuota = maxQuota or math.min(quotaMax() * 0.5, 0.004)
            local running = false
            local decode2 = coroutine.wrap(function()
                cb(decode(self, maxQuota, doubleVectors, doubleAngles))
                return true
            end)
            running = true
            if decode2() ~= true then
                local name = "decode " .. math.rand(0,1)
                running = false
                hook.add("think", name, function()
                    if not running then
                        running = true
                        if decode2() == true then
                            hook.remove("think", name)
                        end
                        running = false
                    end
                end)
            end
        else
            return decode(self, nil, doubleVectors, doubleAngles)
        end
    end
    
    return stringStream
end

-- Creates and extends a StringStream
function safeNet.stringstream(stream, i, endian)
    return safeNet.extend(bit.stringstream(stream, i, endian))
end
-- Here for typos :) use the function above
safeNet.stringStream = safeNet.stringstream

-- Writes a StringStream
function safeNet.writeStringStream(stream)
    curSend:write(stream:getString())
end

-- Elseifs have been found faster in general than a lookup table seemingly only when mapping to functions in SF
encode = function(obj, stream, maxQuota, doubleVectors, doubleAngles)
    while maxQuota and cpuUsed() >= maxQuota do coroutine.yield() end
    local type = type(obj)
    if type == "table" then
        stream:write("T")
        local seq = table.isSequential(obj)
        stream:write(seq and "1" or "0")
        if seq then
            -- Sequential
            stream:writeInt32(#obj)
            for _, var in ipairs(obj) do
                encode(var, stream, maxQuota, doubleVectors, doubleAngles)
            end
            return
        end
        
        -- Nonsequential
        stream:writeInt32(#table.getKeys(obj))
        for key, var in pairs(obj) do
            encode(key, stream, maxQuota, doubleVectors, doubleAngles)
            encode(var, stream, maxQuota, doubleVectors, doubleAngles)
        end
        return
    end
    
    if type == "number" then
        if obj % 1 == 0 then
            -- Int
            local abs = math_abs(obj)
            
            if abs < 128 then
                -- 8 bits
                stream:write("8")
                stream:writeInt8(obj)
                return
            end
            
            if abs < 32768 then
                -- 16 bits
                stream:write("1")
                stream:writeInt16(obj)
                return
            end
            
            if abs < 8388608 then
                -- 24 bits
                stream:write("2")
                stream:writeInt24(obj)
                return
            end
            
            if abs < 2147483648 then
                -- 32 bits
                stream:write("3")
                stream:writeInt32(obj)
                return
            end
        end
        
        -- Double
        stream:write("D")
        stream:writeDouble(obj)
        return
    end
    
    if type == "string" then
        stream:write("S")
        stream:writeData2(obj)
        return
    end
    
    if type == "boolean" then
        stream:write("B")
        stream:write(obj and "1" or "0")
        return
    end
    
    if type == "Vector" then
        stream:write("V")
        if doubleVectors then
            stream:writeVectorDouble(obj)
            return
        end
        
        stream:writeVector(obj)
        return
    end
    
    if type == "Angle" then
        stream:write("A")
        if doubleAngles then
            stream:writeAngleDouble(obj)
            return
        end
        
        stream:writeAngle(obj)
        return
    end
    
    if type == "Color" then
        stream:write("C")
        stream:writeInt8(obj[1])
        stream:writeInt8(obj[2])
        stream:writeInt8(obj[3])
        stream:writeInt8(obj[4])
        return
    end
    
    if type == "Entity" or type == "Player" or type == "Vehicle" or type == "Weapon" or type == "Npc" or type == "p2m" then
        stream:write("E")
        stream:writeInt16(obj:isValid() and obj:entIndex() or -1)
        return
    end
    
    if type == "Hologram" then
        stream:write("H")
        stream:writeInt16(obj:isValid() and obj:entIndex() or -1)
        return
    end
    
    if type == "Quaternion" then
        stream:write("Q")
        stream:writeDouble(obj[1])
        stream:writeDouble(obj[2])
        stream:writeDouble(obj[3])
        stream:writeDouble(obj[4])
        return
    end
    
    if type == "VMatrix" then
        stream:write("M")
        for row = 1, 4 do
            for col = 1, 4 do
                stream:writeDouble(obj:getField(row, col))
            end
        end
        return
    end
    
    if type == "nil" then
        stream:write("N")
        return
    end
    
    stream:write("0")
end

-- Elseifs have been found faster in general than a lookup table seemingly only when mapping to functions
decode = function(stream, maxQuota, doubleVectors, doubleAngles)
    while maxQuota and cpuUsed() >= maxQuota do coroutine.yield() end
    local type = stream:read(1)
    if type == "T" then
        local seq = stream:read(1) ~= "0"
        local count = stream:readUInt32()
        local t = {}
        if seq then
            -- Sequential table
            for i = 1, count do
                table_insert(t, decode(stream, maxQuota, doubleVectors, doubleAngles))
            end
            return t
        end
        
        -- Nonsequential table
        for i = 1, count do
            t[decode(stream, maxQuota, doubleVectors, doubleAngles)] = decode(stream, maxQuota, doubleVectors, doubleAngles)
        end
        return t
    end
    
    if type == "8" then return stream:readInt8() end
    if type == "1" then return stream:readInt16() end
    if type == "2" then return stream:readInt24() end
    if type == "3" then return stream:readInt32() end
    if type == "D" then return stream:readDouble() end
    if type == "S" then return stream:readData2() end
    if type == "B" then return stream:read(1) ~= "0" end
    if type == "V" then return doubleVectors and stream:readVectorDouble() or stream:readVector() end
    if type == "A" then return doubleAngles and stream:readAngleDouble() or stream:readAngle() end
    if type == "C" then return Color(stream:readUInt8(), stream:readUInt8(), stream:readUInt8(), stream:readUInt8()) end
    if type == "E" then return entity(stream:readUInt16()) end
    if type == "H" then return entity(stream:readUInt16()):toHologram() end
    if type == "Q" then return Quaternion(stream:readDouble(), stream:readDouble(), stream:readDouble(), stream:readDouble()) end
    if type == "M" then
        local matrix = {}
        for row = 1, 4 do
            local rowt = {}
            for col = 1, 4 do
                table_insert(rowt, stream:readDouble())
            end
            table_insert(matrix, rowt)
        end
        return Matrix(matrix)
    end
    if type == "N" then return nil end
end

----------------------------------------

--{name, data, length, unreliable, targets}

local receiveWrapper
-- If func is nil, deletes the safeNet.receive() wrapper
-- Otherwise it sets the function to run the callback through
-- Intended for libraries that need to overwrite the receive callback
-- Wrapper function is called with (callback, message size, ply)
function safeNet.wrapReceive(func)
    receiveWrapper = func
end

local bytesLeft = 0
local netTime

local function cancelStream()
    local stream = sends[1]
    if not stream then
        cancelQueue = false
        return
    end
    canceling = true
    local name = stream[1]
    local maxSize = math.min(bytesLeft - #name, net.getBytesLeft() - #name - 15)
    if maxSize <= 0 then return end
    bytesLeft = bytesLeft - #name
    local plys = stream[5]
    if SERVER and plys then
        local ply = plys[#plys]
        if ply and ply:isValid() and ply:isPlayer() then
            net.start(name)
            net.writeBool(true)
            net.send(ply, stream[4])
        end
        table.remove(plys)
        if #plys == 0 then
            table.remove(sends, 1)
            canceling = false
        end
    else
        net.start(name)
        net.writeBool(true)
        net.send(nil, stream[4])
        table.remove(sends, 1)
        canceling = false
    end
    cancelQueue = false
end

local function network()
    if cancelQueue then
        cancelStream()
        if cancelQueue then return end
    end
    local stream = sends[1]
    while stream do
        local first = not stream[8]
        streaming = true
        local size = stream[3]
        local name = stream[1]
        local maxSize = math.min(bytesLeft - #name, net.getBytesLeft() - #name - 15)
        if maxSize <= 0 then return end
        stream[8] = true
        
        if type(stream[5]) == "table" then
            local i = 1
            local targets = stream[5]
            while i <= #targets do
                local ply = targets[i]
                if not ply or not ply:isValid() or not ply:isPlayer() then
                    table_remove(targets, i)
                    continue
                end
                i = i + 1
            end
        end
        
        if size <= maxSize then
            --Last partition
            bytesLeft = bytesLeft - size - #name
            net.start(name)
            net.writeBool(first)
            net.writeBool(false)
            net.writeBool(true)
            net.writeUInt(size, bitsForMessageLength)
            net.writeData(stream[2], size)
            net.writeBool(stream[9])
            net.send(stream[5], stream[4])
            table.remove(sends, 1)
            streaming = false
        else
            --Not last partition
            bytesLeft = bytesLeft - maxSize - #name
            net.start(name)
            net.writeBool(first)
            net.writeBool(false)
            net.writeBool(false)
            net.writeUInt(maxSize, bitsForMessageLength)
            net.writeData(string.sub(stream[2], 1, maxSize), maxSize)
            net.send(stream[5], stream[4])
            stream[2] = string.sub(stream[2], maxSize+1)
            stream[3] = stream[3] - maxSize
            stream[7] = true
            return
        end
        stream = sends[1]
    end
end

hook.add("think", "SafeNet", function()
    local time = timer.systime()
    if netTime then
        bytesLeft = math.round((time - netTime) * BPS)
    end
    netTime = time
    network()
end)

function safeNet.receive(name, cb, prefix)
    prefix = prefix or "snm"
    local name2 = prefix .. name
    if cb then
        local data = ""
        local receiving = false
        net.receive(name2, function(_, ply)
            local timeout2
            if ply then timeout2 = math.max(ply:getPing() / 500, timeout)
            else timeout2 = timeout end
            if timer.exists("sn stream timeout " .. name2) then
                timer.adjust("sn stream timeout " .. name2, timeout2)
            else
                timer.create("sn stream timeout " .. name2, timeout2, 1, function()
                    data = ""
                end)
            end
            local first = net.readBool()
            if first then receiving = true end
            local cancel = net.readBool()
            if cancel then
                data = ""
                timer.remove("sn stream timeout " .. name2)
                return
            end
            local last = net.readBool()
            if receiving then
                local length = net.readUInt(bitsForMessageLength)
                data = data .. net.readData(length)
                if last then
                    if net.readBool() then
                        data = bit.decompress(data)
                    end
                    timer.remove("sn stream timeout " .. name2)
                    curReceive = safeNet.stringstream(data)
                    if receiveWrapper then
                        receiveWrapper(cb, #data, ply)
                    else
                        cb(#data, ply)
                    end
                    data = ""
                end
            end
            if last then receiving = false end
        end)
    else
        net.receive(name2)
    end
end

local netID = 1

function safeNet.send(targets, unreliable, compress)
    local name = curPrefix .. curSendName
    local data = curSend:getString()
    local length = #data
    if compress then
        local s = bit.compress(curSend:getString())
        if s then
            data = s
            length = #data
        else
            compress = false
        end
    end
    table.insert(sends, {name, data, length, unreliable, targets, netID, nil, nil, compress or false})
    curSend = nil
    network()
    netID = netID + 1
    return netID - 1
end

-- Cancels a specific stream
-- Returns true if cancelled and false if not
function safeNet.cancel(ID)
    for i, send in ipairs(sends) do
        if send[6] == ID then
            if send[7] then
                -- Cancel this (this should only happen for the first element)
                cancelQueue = true
                cancelStream()
            else table.remove(sends, i) end
            return true
        end
    end
    return false
end

function safeNet.cancelAll()
    if sends[7] then
        cancelQueue = true
        local remove = table.remove
        for i = 1, #sends-1 do
            remove(sends)
        end
    else sends = {} end
end

function safeNet.isSending()
    return sends[1] ~= nil
end

------------------------------------------------------------------

-- Variable synchronization
-- safeNet.syncVars.yourVariableName = { abc = 123 }
-- print(safeNet.syncVars.yourVariableName)
--    Creates a variable that is synchronized across the server and all clients.
--    Setting the value automatically synchronizes the variable. It will only
--    network new values.
-- safeNet.resyncVar(key)
--    Forces the variable's current value to be sent out to the server and clients.
--    The key is the variable name.
-- safeNet.addSyncVarCallback(key, callback) or safeNet.addSyncVarCallback(key, name, callback)
--    Adds a callback that is run when the variable changes.
-- safeNet.removeSyncVarCallback(key) or safeNet.removeSyncVarCallback(key, name)
--    Removes the callback that is run when the variable changes.

local deepEquals
deepEquals = function(a, b)
    local typea = type(a)
    local typeb = type(b)
    if typea ~= typeb then return false end

    if typea == 'table' then
        local keysa = table.getKeys(a)
        local keysb = table.getKeys(b)
        if #keysa ~= #keysb then return false end
        
        if (not table.isSequential(a) or not table.isSequential(b)) and not deepEquals(keysa, keysb) then
            -- Keys don't match
            return false
        end

        for k, v in pairs(a) do
            if not deepEquals(v, b[k]) then
                -- Value not equal
                return false
            end
        end

        return true
    end

    return a == b
end


local syncedVars = {}
local svars = {
    __index = function(_, key)
        return syncedVars[key]
    end,

    __newindex = function(_, key, value)
        local changed = not deepEquals(syncedVars[key], value)
        syncedVars[key] = value
        if changed then
            -- Value changed
            safeNet.resyncVar(key)
        end
    end
}

setmetatable(svars, svars)

local svarCallbacks = {}
local function runSyncVarCallbacks(key)
    local callbacks = svarCallbacks[key]
    if callbacks then
        -- Run change callbacks
        local value = syncedVars[key]
        for _, cb in pairs(callbacks) do
            cb(value)
        end
    end
end

safeNet.syncVars = svars
function safeNet.resyncVar(key, ply)
    -- Send out updated sync var value
    safeNet.start("snsvar", "")
    if SERVER then
        -- Write nil player
        if ply and ply:isValid() and ply:isPlayer() then
            safeNet.writeBool(true)
            safeNet.writeEntity(ply)
        else
            safeNet.writeBool(false)
        end
    end
    safeNet.writeString(key)
    safeNet.writeType(syncedVars[key])
    safeNet.send()
end

safeNet.receive("snsvar", function(_, ply)
    -- Receive updated sync var value
    if CLIENT and safeNet.readBool() and player() == safeNet.readEntity() then
        -- This clients ent the update so skip
        return
    end
    
    local key = safeNet.readString()
    local value = safeNet.readType()
    if deepEquals(syncedVars[key], value) then
        -- Same value
        return
    end
    
    syncedVars[key] = value
    runSyncVarCallbacks(key)
    
    if SERVER then
        -- Network new value to other clients
        safeNet.resyncVar(key, ply)
    end
end, "")

-- Sync var callbacks
-- Callbacks are called with (variable value)
function safeNet.addSyncVarCallback(key, name, callback)
    local realName = name
    if not callback then
        callback = name
        realName = ""
    end
    
    local tbl = svarCallbacks[key]
    if not tbl then
        svarCallbacks[key] = {}
        tbl = svarCallbacks[key]
    end
    
    tbl[realName] = callback
end

function safeNet.removeSyncVarCallback(key, name)
    name = name or ""
    
    local tbl = svarCallbacks[key]
    if not tbl then return end
    table.remove(tbl, name)
end

-- Get sync var values
if SERVER then
    safeNet.receive("snsvarinit", function(_, ply)
        safeNet.start("snsvarinit", "")
        safeNet.writeTable(syncedVars)
        safeNet.send(ply)
    end, "")
else -- CLIENT
    safeNet.start("snsvarinit", "")
    safeNet.send()
    
    safeNet.receive("snsvarinit", function()
        local vars = safeNet.readTable()
        for k, v in pairs(vars) do
            syncedVars[k] = v
            runSyncVarCallbacks(k)
        end
    end, "")
end

------------------------------------------------------------------

-- Initialization utilities
-- Useful for e.g. clients ping the server when are initialized or after doing something and the server responds immediately or after doing something itself
-- e.g. Clients ping the server and the server responds with a table of entities that it may or may not be able to spawn all at once
-- SERVER
--  safeNet.init(callback)
--      Retroactively responds to all queued pings from clients and will immediately respond to future pings
--      If a callback is provided, the arguments passed into it will be cb(ply, args ...)
--      and it will respond to the client and send back whatever is returned by the callback (can be vararg or not return anything)
-- CLIENT
--  safeNet.init(callback, args ...)
--      Pings the server with the varargs provided by args (they are optional)
--      If a callback is provided and is not nil, it will be called with cb(args ...) which will be the arguments returned from the server

if SERVER then
    local plyQueue = {}
    safeNet.receive("sninit", function(_, ply)
        local count = 0
        local function getCount(...)
            count = select("#", ...)
            return ...
        end
        table.insert(plyQueue, {ply, {getCount(safeNet.readType())}, count})
    end, "")
    
    local function respond(ply, ...)
        safeNet.start("sninit", "")
        safeNet.writeType(...)
        safeNet.send(ply, nil, false)
    end
    
    function safeNet.init(callback)
        for _, plySet in pairs(plyQueue) do
            local ply = plySet[1]
            if ply and ply:isValid() and ply:isPlayer() then
                if callback then
                    respond(ply, callback(ply, unpack(plySet[2], 1, plySet[3])))
                else
                    respond(ply)
                end
            end
        end
        
        safeNet.receive("sninit", function(_, ply)
            if ply and ply:isValid() and ply:isPlayer() then -- Chance that the client disconnected between sending the ping and the server receiving it
                if callback then
                    respond(ply, callback(ply, safeNet.readType()))
                else
                    respond(ply)
                end
            end
        end, "")
        
        plyQueue = nil
    end
else -- CLIENT
    -- Callback, args to send to server
    function safeNet.init(callback, ...)
        if callback then
            safeNet.receive("sninit", function()
                callback(safeNet.readType())
            end, "")
        end
        
        safeNet.start("sninit", "")
        safeNet.writeType(...)
        safeNet.send(nil, nil, false)
    end
end

return safeNet