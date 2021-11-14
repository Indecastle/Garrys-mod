--@include ./noise/simplex2d.lua
--@include ./noise/simplex3d.lua

--[[
    All outputs are [-1, 1]
]]

return {
    simplex2d = require("./noise/simplex2d.lua"),
    simplex3d = require("./noise/simplex3d.lua")
}