local type_ = type
function type(obj)
	local t = type_(obj)
	
	return t == "table" and obj.__type or t
end

------------------------------

local type = type
local assert = assert
local rawset = rawset
local setmetatable = setmetatable

local classes = {}

return {
	function(class_type, inherit, data)
		if not data then
			data = inherit
			inherit = nil
		end
		
		if not data then
			data = class_type
			class_type = nil
		end
			
		
		local class_type = class_type or data.type
		local inherit = inherit or data.inherit
		
		--assert(data.constructor, "Class doesnt have a constructor")
		if not data then error("Class doesnt have any data", 2) end
		if not class_type then error("Class doesnt have a type", 2) end
		if classes[class_type] then error("Class " .. class_type .. " already exists", 2) end
		
		------------------------------
		
		if inherit then
			local typ = type(inherit)
			local inherit = classes[typ == "string" and inherit or typ]
			
			if not inherit then error("Inherit is a invalid class", 2) end
			
			--[[
				TODO: inherit stuff here
			]]
		end
		
		------------------------------
		
		local object = data.data and table.copy(data.data) or {}
		
		if data.properties then
			local properties = data.properties
			local func_properties = {}
			local set_properties = {}
			
			for k, v in pairs(properties) do
				local typ = type(v)
				
				if typ == "function" then
					func_properties[k] = v
				elseif typ == "table" then
					if v.get then
						func_properties[k] = v.get
					end
					
					if v.set then
						set_properties[k] = v.set
					end
				end
				
				object[k] = v
			end
			
			object.__index = function(self, key)
				if func_properties[key] then
					return func_properties[key](self)
				end
				
				return object[key]
			end
			
			object.__newindex = function(self, key, value)
				if set_properties[key] then
					return set_properties[key](self, value)
				end
				
				assert(not properties[key], class_type .. "." .. key .. " is read only")
				rawset(self, key, value)
			end
		else
			object.__index = object
		end
		
		object.__type = class_type
		
		------------------------------
		
		local constructor = data.constructor
		local class = data.static_data or {}
		
		class.__call = function(_, ...)
			local obj = setmetatable({}, object)
			
			for k, v in pairs(data.data) do
				if type(v) == "table" then
					rawset(obj, k, table.copy(v))
				end
			end
			
			constructor(obj, ...)
			
			return obj
		end
		
		if data.static_properties then
			local properties = data.static_properties
			local func_properties = {}
			
			for k, v in pairs(properties) do
				if type(v) == "function" then
					func_properties[k] = v
				end
				
				class[k] = v
			end
			
			class.__index = function(self, key)
				if func_properties[key] then
					return func_properties[key]()
				elseif class[key] then
					return class[key]
				end
				
				return nil
			end
			
			class.__newindex = function(self, key, value)
				if properties[key] then return end
				
				rawset(self, key, value)
			end
		else
			class._index = class
		end
		
		classes[class_type] = data
		
		return setmetatable({}, class)
	end,

	function(obj, check, level)
		local typ = type(obj)
		
		if typ ~= check then
			error("Type mismatch (Expected " .. check .. ", got " .. typ .. ") in function " .. debugGetInfo(3, "n").name, level or 4)
		end
	end
}