local atlas = {}

----------------------------------------

function atlas.addAtlas(path)
	for k, v in pairs(require(path)) do
		atlas[k] = v
	end
	
	return atlas
end

----------------------------------------

return atlas