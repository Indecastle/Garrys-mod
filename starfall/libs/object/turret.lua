--@include ../class.lua

local class, checktype = unpack(require("./lib/class.lua"))

local Turret = class {
    type = "turret",
    
    constructor = function(self, pos, ang, pitch_pos, guns)
        self.pos = pos
        self.ang = ang
        self.yaw = 0
        self.yaw_min = -180
        self.yaw_max =  180
        self.pitch_pos = pitch_pos
        self.pitch = 0
        self.pitch_min = -90
        self.pitch_max =  90
        
        self.guns = {}
        for i, gun in pairs(guns) do
            local pos, ang = localToWorld(gun.pos, gun.ang, self.pitch_pos, Angle())
            local pos, ang = localToWorld(pos, ang, self.pos, ang)
            
            self.guns[i] = {
                local_pos = gun.pos,
                local_ang = gun.ang,
                pos = pos,
                ang = ang,
                ent = gun.ent
            }
        end
    end,
    
    ----------------------------------------
    
    data = {
        setPos = function(self, pos)
            self.pos = pos
        end,
        
        setAngles = function(self, ang)
            self.ang = ang
        end,
        
        setYawClamp = function(self, min, max)
            self.yaw_min = min
            self.yaw_max = max
        end,
        
        setPitchClamp = function(self, min, max)
            self.pitch_min = min
            self.pitch_max = max
        end,
        
        hasReachedYawLimit = function(self)
            return self.yaw == self.yaw_min or self.yaw_max
        end,
        
        hasReachedPitchLimit = function(self)
            return self.pitch == self.pitch_min or self.pitch_max
        end,
        
        aimAt = function(self, target_pos)
            local pp = localToWorld(self.pitch_pos, Angle(), self.pos, self.ang)
            local ang = (target_pos - pp):getAngle()
            local _, lang = worldToLocal(pp, ang, self.pos, self.ang)
            
            self.yaw = math.clamp(lang.yaw, self.yaw_min, self.yaw_max)
            self.pitch = math.clamp(lang.pitch, self.pitch_min, self.pitch_max)
            
            self:updateGunPosition()
        end,
        
        updateGunPosition = function(self)
            for i, gun in pairs(self.guns) do
                local pos, ang = localToWorld(gun.local_pos, gun.local_ang, self.pitch_pos, Angle(self.pitch, self.yaw, 0))
                local pos, ang = localToWorld(pos, ang, self.pos, self.ang)
                
                self.guns[i].pos = pos
                self.guns[i].ang = ang
            end
        end
    }
}

return Turret