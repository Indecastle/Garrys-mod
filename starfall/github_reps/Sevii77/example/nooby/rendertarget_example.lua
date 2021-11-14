--@name Rendertarget example
--@client

-- Create the rt
render.createRenderTarget("unique_id")

hook.add("render", "", function()
    -- Select our rendertarget that we want to draw onto
    render.selectRenderTarget("unique_id")
    
    -- Since we now in the context of the rt its 1024x1024
    -- get a fancy random hsv color
    render.setColor(Color(math.random() * 360, math.random(), 1):hsvToRGB())
    
    -- Draw a random pixel
    render.drawRect(math.random(0, 1023), math.random(0, 1023), 1, 1)
    
    -- Now we done drawing to it, lets get back to normal context
    render.selectRenderTarget()
    
    -- Set the draw texture to our rt to actually render it
    render.setRenderTargetTexture("unique_id")
    
    -- We want nice and sharp rendering, so we set the render filter
    render.setFilterMin(1)
    render.setFilterMag(1)
    
    -- Set color back to white
    render.setRGBA(255, 255, 255, 255)
    
    -- Notice how its 512x512
    render.drawTexturedRect(0, 0, 512, 512)
    
end)