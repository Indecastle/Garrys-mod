--@name Networking and Matrix example

if SERVER then
    
    hook.add("keyPress", "unique_id", function(ply, key)
        -- Check if the key is the use key
        if key == IN_KEY.USE then
            -- Start the net message with our network id
            net.start("unique_id")
            -- Write our player as entity
            net.writeEntity(ply)
            -- Write a bool to indicate that the key has been pressed
            net.writeBool(true)
            -- Send to all players (check helper for all args send can have)
            net.send()
        end
    end)
    
    hook.add("keyRelease", "unique_id", function(ply, key)
        -- Same as press just with a false as bool instead
        if key == IN_KEY.USE then
            net.start("unique_id")
            net.writeEntity(ply)
            net.writeBool(false)
            net.send()
        end
    end)
    
else
    
    -- Make a table to store use key downs of all players
    local use_downs = {}
    
    net.receive("unique_id", function()
        -- Read the entity and use it as key, then read the bool and store that
        use_downs[net.readEntity()] = net.readBool()
    end)
    
    -- Render hook
    hook.add("render", "unique_id", function()
        -- Loop through our players, using ipairs to loop through a iterateable table, could also just use pairs
        for i, ply in ipairs(find.allPlayers()) do
            -- Get the cursor pos of the player
            local x, y = render.cursorPos(ply)
            
            -- Check if x is valid, if it isnt it means the cursor isnt on screen
            
            if x then
                -- Create a matrix
                local m = Matrix()
                
                -- Translate it to x and y
                m:setTranslation(Vector(x, y))
                
                -- Rotate it
                m:setAngles(Angle(0, timer.curtime() * 100, 0))
                
                -- Now translate it, but not set translation (note, sin and cos are in radian, not degrees)
                m:translate(Vector(math.sin(timer.curtime()) * 20, 0, 0))
                
                -- Push out matrix onto the matrix stack
                render.pushMatrix(m)
                
                -- Draw what we want to draw
                local clr = team.getColor(ply:getTeam())
                
                -- Change darkness if use is down
                if use_downs[ply] then
                    clr = clr * 0.5
                end
                
                render.setColor(clr)
                
                -- Note that x and y are 0, it is because we are drawing relative to the matrix stack
                render.drawSimpleText(0, 0, ply:getName(), 1, 1)
                
                -- Pop out matrix from the stack
                render.popMatrix()
            end
        end
    end)
    
end
