--@name Coroutine example
--@client

render.createRenderTarget("unique_id")

-- Create a coroutine, basicly a thread that can be yielded and continued whenever you want
local cor = coroutine.create(function()
    -- Loop through 1 - 1024 on both x and y
    for x = 1, 1024 do
        for y = 1, 1024 do
            -- Set color to random
            render.setRGBA(math.random(0, 256), math.random(0, 256), math.random(0, 256), 255)
            
            -- Draw a pixel
            render.drawRect(x, y, 1, 1)
            
            -- Check if we almost hit 80% of the quota limit, if we did, yield the coroutine
            -- (note that we use total, since the quota limit is shared across all owned starfalls)
            if quotaTotalAverage() / quotaMax() > 0.80 then
                -- Yield the coroutine, allowing us to continue from here at a later point
                coroutine.yield()
            end
        end
    end
    
    -- We finished, return true so that we know we finished
    return true
end)

-- Draw to the rt
hook.add("render", "render_to_rt", function()
    render.selectRenderTarget("unique_id")
    
    -- If the result from coroutine.resume is true, we can stop running it
    -- coroutine.resume resumes our coroutine, duh
    if coroutine.resume(cor) then
        hook.remove("render", "render_to_rt")
    end
    
    -- Reset render target back to none
    render.selectRenderTarget()
    -- Color also
    render.setRGBA(255, 255, 255, 255)
end)

-- Render the rt to the screen
hook.add("render", "rt_render", function()
    render.setRenderTargetTexture("unique_id")
    render.drawTexturedRect(0, 0, 512, 512)
end)