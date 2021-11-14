# HoloText - 3D Text With Holograms

Library to allow creating 3D text using holograms **(REQIRES SPROPS)**  

## Getters and Setters:
| Getter                     | Setter                                 |
|----------------------------|----------------------------------------|
| `getPos()`                 | `setPos(vector)`                       |
| `getAngles()`              | `setAngles(angle)`                     |
| `getScale()`               | `setScale(vector)`                     |
| `getColour()`/`getColor()` | `setColour(colour)`/`setColor(colour)` |
| `getMaterial()`            | `setMaterial(string)`                  |
| `getText()`                | `setText(string)`                      |
| `getKerning()`             | `setKerning(number)`                   |
| `getSpaceWidth()`          | `setSpaceWidth(number)`                |
| `getLineHeight()`          | `setLineHeight(number)`                |  
  
## Example code:  
```lua
--@name HoloText Example
--@author Derpius
--@client

-- Import the class
--@include ./libs/holotext/main.txt
local HoloText = require("./libs/holotext/main.txt")

-- Create a text object
-- (constructor takes text, position, angles, scale, and colour, all of which are optional)
local text = HoloText:new("Loading.", chip():getPos() + chip():getUp() * 10, chip():getAngles())

-- Update the position and rotation of the text object each frame
hook.add("think", "updatetransform", function()
    -- as you can see the HoloText class provides methods for editing the transform like any other entity
    text:setPos(chip():getPos() + chip():getUp() * 10)
    text:setAngles(chip():getAngles())
end)

-- Create a timer that adds a loading effect to the text
local numDots = 1
timer.create("loadingDots", 1, 0, function()
    text:setText("Loading"..string.rep(".", numDots + 1))
    numDots = (numDots + 1) % 3
end)
```