--@server

-- https://github.com/nrlulz/ACF/pull/331

-- Mobility
local engine = acf.createMobility(chip():getPos() + Vector(0, 0, 50), Angle(), "3.3L-V4", true)
local gearbox = acf.createMobility(chip():getPos() + Vector(-50, 0, 45), Angle(0, 90, 0), "6-Speed, Inline, Small", true, {
	-- We define gears here, if we don't do it it will use default values
	0.15,
	0.3,
	0.45,
	0.6,
	0.75,
	-0.2,
	[-1] = 0.7
})
local fueltank = acf.createFuelTank(chip():getPos() + Vector(0, 0, 30), Angle(), "Tank_4x4x2", "Diesel", true)
local wheel = prop.create(chip():getPos() + Vector(-100, 0, 45), Angle(0, 90, 0), "models/sprops/trans/wheel_b/t_wheel30.mdl", false)

constraint.ballsocketadv(gearbox, wheel, 0, 0, gearbox:worldToLocal(wheel:getPos()), Vector(), 0, 0, Vector(-180, -0.1, -0.1), Vector(180, 0.1, 0.1), Vector(), false, false)

engine:acfLinkTo(gearbox)
engine:acfLinkTo(fueltank)
gearbox:acfLinkTo(wheel)

engine:acfSetActive(true)
engine:acfSetThrottle(100)
fueltank:acfSetActive(true)
fueltank:acfRefuelDuty(true)

--printTable(acf.getMobilitySpecs("3.3L-V4"))
-- Weaponry, on a timer because else we hit the burst limit
timer.simple(1, function()
	local gun = acf.createGun(chip():getPos() + Vector(100, 0, 50), Angle(), "100mm Cannon", true)
	local ammo = acf.createAmmo(chip():getPos() + Vector(100, 0, 30), Angle(), "Ammo2x4x4", "100mm Cannon", "HEAT", true, {
		-- Doesn't matter than we put high valus here, internally it will handle this and make sense of it somehow like in the acfmenu
		propellantLength = 10000,
		projectileLength = 10000,
		heFillerVolume = 10000,
		crushConeAngle = 10,
		tracer = true
	})
	
	gun:acfLinkTo(ammo)
	gun:acfFire(1)
	
	ammo:acfSetActive(true)
end)
