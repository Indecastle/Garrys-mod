--@name Door Creator
--@author Sevii (https://steamcommunity.com/id/dadamrival/)
--@server

--[[
	Be sure to remove the collider before saving
]]

-- Enable to only make the collider and nothing else, this allows for easy adjustment making to the collider
local build_mode = false

-- Health of the hinge before it breaks, 0 to be unable to break
local hinge_health = 50

-- Hinge rotation angles
local hinge_min = Vector(-0.01, -0.01, -0.01)
local hinge_max = Vector( 70,   0.01,  0.01)

-- Now uses hinge entity weight -- -Weight of the collider
--local collider_weight = 30
-- Should drag be enabled
local collider_drag = false
-- The physical material of the collider
local collider_phys_material = "metal"
-- Table containing tables containing vertices, a collider can have multiple parts but each part must be convex
local collider_vertices = {
	{
		Vector( 0,   0,  26.7),
		Vector(20,  -1,  26.7),
		Vector(38,  -9,  23.7),
		Vector( 0,   0, -23.2),
		Vector(20,  -1, -23.2),
		Vector(38,  -9, -20.2),
		
		Vector( 0,  -2,  26.7),
		Vector( 0,  -2, -23.2),
		Vector(38, -11,  23.7),
		Vector(38, -11, -20.2),
	}
}

----------------------------------------

function create()
	hook.add("think", "create", function()
		if not prop.canCreateCustom() then return end
		
		hook.remove("think", "create")
		
		local base = wire.ports.Base
		local hinge = wire.ports.Hinge
		
		local collider = prop.createCustom(hinge:getPos(), hinge:getAngles(), collider_vertices, true)
		--collider:setMass(collider_weight)
		collider:setMass(hinge:getMass())
		collider:setPhysMaterial(collider_phys_material)
		
		local hinge_pos = base:worldToLocal(hinge:getPos())
		local hinge_ang = base:worldToLocalAngles(hinge:getAngles())
		constraint.ballsocketadv(base, collider, 0, 0, hinge_pos, collider:worldToLocal(hinge:getPos()), 0, 0, hinge_min, hinge_max, Vector(), false, true)
		
		if build_mode then return end
		
		hinge:setParent(collider)
		
		----------------------------------------
		
		local function reset()
			hinge:setParent(nil)
			hinge:setFrozen(true)
			hinge:setPos(base:localToWorld(hinge_pos))
			hinge:setAngles(base:localToWorldAngles(hinge_ang))
			
			-- Needs to be done cuz children visually unparent but are still parented
			local function reparentChildren(ent)
				for _, child in pairs(ent:getChildren()) do
					child:setParent(ent)
					reparentChildren(child)
				end
			end
			reparentChildren(hinge)
		end
		
		hook.add("entityRemoved", "", function(ent)
			if ent ~= collider then return end
			
			reset()
		end)
		
		hook.add("removed", "", reset)
		
		----------------------------------------
		
		if hinge_health > 0 then
			hook.add("EntityTakeDamage", "", function(target, _, _, amount)
				if target ~= hinge then return end
				
				hinge_health = hinge_health - amount
				
				if hinge_health <= 0 then
					constraint.breakAll(collider)
				end
			end)
		end
	end)
end

----------------------------------------

wire.adjustInputs({"Base", "Hinge"}, {"ENTITY", "ENTITY"})

if wire.ports.Base:isValid() then
	create()
else
	hook.add("input", "", function(name, value)
		if name == "Base" and value:isValid() then
			create()
			
			hook.remove("input", "")
		end
	end)
end
