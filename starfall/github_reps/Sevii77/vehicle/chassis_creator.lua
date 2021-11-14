--@name Chassis Creator
--@author Sevii
--@server

-- Enable to only make the collider and nothing else, this allows for easy adjustment making to the collider
local build_mode = false

-- Settings of the steering, a table containing multiple steering ball data
local steering_ball = {{
	inverted = true, -- Invert the steering
	max = { -- key is velocity, value is max steering angle, if car velocity is under the velocity that steering angle will be used, if not check the next in list, if none match lat one is used, velocity in units per second
		[500] = 40,
		[501] = 20
	},
	speed = { -- key is velocity, value is steering speed, works same as max, speed in degrees per second
		[0] = 70
	}
}}

-- Table containing wheelindex as index and steering ball index as value
local wheel_steering = {
	[1] = 1,
	[2] = 1
}

local spring_width = 0 -- Width of the suspension constraints
local spring_max = 20 -- Can be table to set each wheels value seperatly, Low values can lead to spring getting stuck
local spring_constant = 30000 -- Can be table to set each wheels value seperatly
local spring_damping = 1100 -- Can be table to set each wheels value seperatly
local spring_length = 0 -- Can be table to set each wheels value seperatly, Extra length added, Can be changed dynamicly via inputs with the name SpringLengths

-- Now uses base entity weight --- Weight of the collider / base prop
-- local collider_weight = 150
-- Should drag be enabled
local collider_drag = false
-- The physical material of the collider
local collider_phys_material = "metal"
-- Table containing tables containing vertices, a collider can have multiple parts but each part must be convex
local collider_vertices = {
	{ -- Base
		Vector(-34, -27, -2),
		Vector( 34, -27, -2),
		Vector(-34,  27, -2),
		Vector( 34,  27, -2),
		
		Vector(-34, -66, 1),
		Vector( 34, -66, 1),
		Vector(-34,  65, 1),
		Vector( 34,  65, 1),
	},
	
	--[[{ -- Front
		Vector(-34, -66, 1),
		Vector( 34, -66, 1),
		Vector(-34, -21, 1),
		Vector( 34, -21, 1),
		
		Vector(-34, -66, 28),
		Vector( 34, -66, 28),
		Vector(-34, -40, 32),
		Vector( 34, -40, 32),
		Vector(-34, -21, 32),
		Vector( 34, -21, 32),
	},]]
	{ -- Front
		Vector(-34, -66, 1),
		Vector( 34, -66, 1),
		Vector(-34, -21, 1),
		Vector( 34, -21, 1),
		
		Vector(-34, -66, 21),
		Vector( 34, -66, 21),
		Vector(-34, -21, 31),
		Vector( 34, -21, 31),
	},
	
	--[[{ -- Windshield
		Vector(-27, -27, 30),
		Vector( 27, -27, 30),
		Vector(-27, -21, 30),
		Vector( 27, -21, 30),
		
		Vector(-27, -20, 60),
		Vector( 27, -20, 60),
		Vector(-27, -14, 60),
		Vector( 27, -14, 60),
	},]]
	{ -- Windshield Top
		Vector(-27, -20, 57),
		Vector( 27, -20, 57),
		Vector(-27, -15, 59),
		Vector( 27, -15, 59),
		
		Vector(-27, -20, 61),
		Vector( 27, -20, 61),
		Vector(-27, -15, 62),
		Vector( 27, -15, 62),
	},
	
	{ -- Windshield Right
		Vector(-27, -27, 31),
		Vector(-23, -27, 31),
		Vector(-27, -22, 31),
		Vector(-23, -22, 31),
		
		Vector(-27, -20, 57),
		Vector(-23, -20, 57),
		Vector(-27, -15, 59),
		Vector(-23, -15, 59),
	},
	
	{ -- Windshield Left
		Vector( 27, -27, 31),
		Vector( 23, -27, 31),
		Vector( 27, -22, 31),
		Vector( 23, -22, 31),
		
		Vector( 27, -20, 57),
		Vector( 23, -20, 57),
		Vector( 27, -15, 59),
		Vector( 23, -15, 59),
	},
	
	{ -- Back inner
		Vector(-24,  45, 1),
		Vector( 24,  45, 1),
		Vector(-24,  39, 1),
		Vector( 24,  39, 1),
		
		Vector(-24,  45, 31),
		Vector( 24,  45, 31),
		Vector(-24,  39, 31),
		Vector( 24,  39, 31),
	},
	
	{ -- Back Floor
		Vector(-24,  45, 1),
		Vector( 24,  45, 1),
		Vector(-24,  65, 1),
		Vector( 24,  65, 1),
		
		Vector(-24,  45, 10.3),
		Vector( 24,  45, 10.3),
		Vector(-24,  65, 10.3),
		Vector( 24,  65, 10.3),
	},
	
	{ -- Back
		Vector(-24,  69, 1),
		Vector( 24,  69, 1),
		Vector(-24,  65, 1),
		Vector( 24,  65, 1),
		
		Vector(-24,  69, 26),
		Vector( 24,  69, 26),
		Vector(-24,  65, 26),
		Vector( 24,  65, 26),
	},
	
	{ -- Back Right
		Vector(-34,  69, 1),
		Vector(-24,  69, 1),
		Vector(-34,  21, 1),
		Vector(-24,  21, 1),
		
		Vector(-34,  69, 31),
		Vector(-24,  69, 31),
		Vector(-34,  21, 31),
		Vector(-24,  21, 31),
	},
	
	{ -- Back Left
		Vector( 34,  69, 1),
		Vector( 24,  69, 1),
		Vector( 34,  21, 1),
		Vector( 24,  21, 1),
		
		Vector( 34,  69, 31),
		Vector( 24,  69, 31),
		Vector( 34,  21, 31),
		Vector( 24,  21, 31),
	}
}

----------------------------------------

wire.adjustInputs({"Base", "Wheels", "SpringLengths", "A", "D", "SteerspeedMul"}, {"ENTITY", "ARRAY", "ARRAY", "NUMBER", "NUMBER", "NUMBER"})
wire.adjustOutputs({"Collider"}, {"ENTITY"})

local base = wire.ports.Base
if not base or not base:isValid() then return end

local wheels = wire.ports.Wheels
local e = Vector()

----------------------------------------
-- Collider

local collider = prop.createCustom(base:getPos(), base:getAngles(), collider_vertices, true)
--collider:setMass(collider_weight)
collider:setMass(base:getMass())
collider:enableDrag(collider_drag)
collider:setPhysMaterial(collider_phys_material)

wire.ports.Collider = collider

if build_mode then return end

-- Move Welds
local welds = {}
for _, ent in pairs(base:getAllConstrained({Weld = true})) do
	if ent ~= base then
		constraint.weld(collider, ent, 0, 0, 0, false)
		
		table.insert(welds, ent)
	end
end

base:setParent(collider)

----------------------------------------
-- Steering balls

local steering_balls = {}

for i, _ in pairs(steering_ball) do
	table.insert(steering_balls, prop.create(chip():getPos() + Vector(0, 0, i * 6), collider:getAngles(), "models/sprops/geometry/sphere_6.mdl", true))
	
	steering_ball[i].ang = 0
end

hook.add("think", "steering", function()
	local velocity = collider:getVelocity():getLength()
	local a, d = wire.ports.A, wire.ports.D
	local steer_mul = d - a
	
	for i, data in pairs(steering_ball) do
		local ball = steering_balls[i]
		
		local target_ang = 0
		if steer_mul ~= 0 then
			local i, c = 1, table.count(data.max)
			for vel, ang in pairs(data.max) do
				if i == c or velocity < vel then
					target_ang = ang
					
					break
				end
				
				i = i + 1
			end
		end
		
		local steering_speed = 0
		local i, c = 1, table.count(data.speed)
		for vel, speed in pairs(data.speed) do
			if i == c or velocity < vel then
				steering_speed = speed
				
				break
			end
			
			i = i + 1
		end
		
		if wire.ports.SteerspeedMul > 0 then
			steering_speed = steering_speed * wire.ports.SteerspeedMul
		end
		
		local dist = target_ang * steer_mul - data.ang
		local ang = data.ang + dist * math.min(1, timer.frametime() * (steering_speed / math.max(0.0001, math.abs(dist)))) --math.clamp(data.ang + steer_mul * steering_speed * timer.frametime(), -target_ang, target_ang)
		
		if not ball:isPlayerHolding() then
			ball:setAngles(collider:localToWorldAngles(Angle(0, ang * (data.inverted and -1 or 1), 0)))
			ball:setFrozen(true)
		end
		
		steering_ball[i].ang = ang
	end
end)

----------------------------------------
-- Suspension

local smax = type(spring_max) == "table"
local scon = type(spring_constant) == "table"
local sdam = type(spring_damping) == "table"
local slen = type(spring_length) == "table"

for i, wheel in pairs(wheels) do
	local w  = collider:worldToLocal(wheel:getPos())
	local t1 = collider:worldToLocal(wheel:localToWorld(Vector(-20, -spring_max * 5, 0  )))
	local t2 = collider:worldToLocal(wheel:localToWorld(Vector( 20, -spring_max * 5, 0  )))
	local t3 = collider:worldToLocal(wheel:localToWorld(Vector(  0,   0, 100)))
	
	constraint.nocollide(wheel, collider, 0, 0)
	constraint.rope(i * 3 - 2, collider, wheel, 0, 0, t1, e, (w - t1):getLength(), 0, 0, spring_width, "cable/cable", true)
	constraint.rope(i * 3 - 1, collider, wheel, 0, 0, t2, e, (w - t2):getLength(), 0, 0, spring_width, "cable/cable", true)
	constraint.rope(i * 3,     collider, wheel, 0, 0,  w, e, smax and spring_max[i] or spring_max, 0, 0, spring_width, "cable/cable", false)
	constraint.elastic(i,      collider, wheel, 0, 0, t3, e, scon and spring_constant[i] or spring_constant, sdam and spring_damping[i] or spring_damping, 0, spring_width, false)
	constraint.ballsocketadv(wheel_steering[i] and steering_balls[wheel_steering[i]] or collider, wheel, 0, 0, e, e, 0, 0, Vector(-180, -0.1, -0.1), Vector(180, 0.1, 0.1), e, true, false)
	
	if slen and spring_length[i] ~= 0 or spring_length ~= 0 then
		constraint.setElasticLength(i, collider, 100 + (slen and spring_length[i] or spring_length))
	end
	
	wheels[i] = {
		ent = wheel,
		pos = w,
		ang = base:worldToLocalAngles(wheel:getAngles())
	}
end

----------------------------------------
-- Suspension length

--[[local last_lengths = {}
for i = 1, #wheels do
	last_lengths[i] = 0
end

hook.add("Think", "suspension_length", function()
	--for i, length in pairs(spring_length) do
	for i, length in pairs(wire.ports.SpringLengths) do
		local last = last_lengths[i]
		
		if last ~= length then
			constraint.setElasticLength(i, collider, 100 + length)
		end
		
		last_lengths[i] = length
	end
end)]]

hook.add("input", "suspension_length", function(name, value)
	if name ~= "SpringLength" then
		for i, length in pairs(wire.ports.SpringLengths) do
			constraint.setElasticLength(i, collider, 100 + length)
		end
	end
end)

----------------------------------------
-- Cleanup on remove

local function reset()
	base:setParent(nil)
	base:setFrozen(true)
	
	-- Needs to be done cuz children visually unparent but are still parented
	local function reparentChildren(ent)
		for _, child in pairs(ent:getChildren()) do
			child:setParent(ent)
			reparentChildren(child)
		end
	end
	reparentChildren(base)
	
	for i, ent in pairs(welds) do
		if not ent or not ent:isValid() then
			print("Welded entity " .. i .. "(" .. tostring(ent) .. ") weld not applied, entity doesn't exist")
			
			continue
		end
		
		constraint.weld(base, ent, 0, 0, 0, false)
	end
	
	for i, wheel in pairs(wheels) do
		if not wheel.ent or not wheel.ent:isValid() then
			print("Wheel " .. i .. " constraints not applied, wheel doesn't exist")
			
			continue
		end
		
		wheel.ent:setFrozen(true)
		wheel.ent:setPos(base:localToWorld(wheel.pos))
		wheel.ent:setAngles(base:localToWorldAngles(wheel.ang))
	end
end

hook.add("entityRemoved", "", function(ent)
	if ent ~= collider then return end
	
	hook.remove("think", "steering")
	
	reset()
end)

hook.add("removed", "", reset)
