local set = settings.generation.terrain

return function(x, y)
	local scale = set.scale
	
	return noise.simplex2d(x * scale, y * scale) * 100 + 200
end