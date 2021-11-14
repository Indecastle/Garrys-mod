--@name B A L L S
--@author Sevii
--@client

local settings = {
    ballcount = 50,
    elasticity = {
        min = 0.8,
        max = 0.9
    },
    ballsize = {
        min = 40,
        max = 100
    }
}

------------------------------

local function m(a, b)
    return b * (a:dot(b) / b:dot(b))
end

local balls = {}

for i = 1, settings.ballcount do
    local size = math.random(settings.ballsize.min, settings.ballsize.max) / 2
    local pos
    
    while true do
        pos = Vector(math.random(size, 512 - size), math.random(size, 512 - size), math.random(size, 512 - size))
        
        local intersect = false
        for _, b in pairs(balls) do
            if b.pos:getDistance(pos) <= size + b.rad then
                intersect = true
                
                break
            end
        end
        
        if not intersect then
            break
        end
    end
    
    table.insert(balls, {
        pos = pos,
        vel = Vector(),
        rad = size,
        mass = 4 / 3 * math.pi * (size ^ 2),
        color = Color(math.random(0, 360), math.random() * 0.5 + 0.5, math.random() * 0.5 + 0.5):hsvToRGB(),
        elasticity = math.rand(settings.elasticity.min, settings.elasticity.max)
    })
end

hook.add("render", "", function()
    -- Physics
    local dt = timer.frametime()
    local e = render.getScreenEntity()
    local gravity = --[[Vector(0, 600, 0)]] e:getUp() * 600 + e:getVelocity() * dt * 5000 --+ e:getAngleVelocity():getUp() * dt * 5000
    
    for _, ball in pairs(balls) do
        ball.pos = ball.pos + ball.vel * dt
        ball.vel = ball.vel + gravity * dt
        
        -- World Collision
        local p, r, elasticity = ball.pos + ball.vel * dt, ball.rad, ball.elasticity
        if p.x < r or p.x > 512 - r then
            ball.vel.x = -ball.vel.x * elasticity
        end
        if p.y < r or p.y > 512 - r then
            ball.vel.y = -ball.vel.y * elasticity
        end
        if p.z < r or p.z > 512 - r then
            ball.vel.z = -ball.vel.z * elasticity
        end
        
        -- Ball Collision
        for _, b in pairs(balls) do
            if b ~= ball then
                local p2 = b.pos + b.vel * dt
                local dist = p:getDistance(p2)
                
                if dist <= ball.rad + b.rad then
                    local v1 = ball.vel + m(b.vel, p2 - p) - m(ball.vel, p - p2)
                    local v2 = b.vel + m(ball.vel, p2 - p) - m(b.vel, p - p2)
                    
                    ball.vel = v1 * elasticity
                    b.vel = v2 * b.elasticity
                end
            end
        end
    end
    
    -- Render
    render.enableDepth(true)
    render.setMaterial()
    
    render.setRGBA(200, 200, 200, 255)
    render.draw3DBox(Vector(256), Angle(), Vector(256), Vector(-256))
    
    for _, ball in pairs(balls) do
        render.setColor(ball.color)
        render.draw3DSphere(ball.pos, ball.rad, 12, 12)
    end
end)
