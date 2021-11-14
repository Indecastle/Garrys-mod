-- Advanced meshes

--[[
	TODO:
	make mesh.getEntityMeshes support:
		skins
		bodygroup mask
		bumpmap
]]

local mesh = mesh

----------------------------------------

-- Returns a table of tables which contain the texture, color and vertices
--[[function mesh.getEntityMeshes(ents)
	local vertices = {}
	
	for _, ent in pairs(ents) do
		local color = ent:getColor()
		
		for _, data in pairs(mesh.getModelMeshes(ent:getModel(), 0, 0)) do
			local texture = material.getString(data.material, "$basetexture")
			local id = texture .. "_" .. tostring(color)
			
			vertices[id] = vertices[id] or {
				texture = texture,
				color = color,
				vertices = {}
			}
			
			for _, vertex in pairs(data.triangles) do
				table.insert(vertices[id].vertices, vertex)
			end
		end
	end
	
	return vertices
end]]

function mesh.getEntityVertices(ents, center)
	local vertices = {}
	
	if not center then
		center = Vector()
		
		for _, ent in pairs(ents) do
			center = center + ent:getPos()
		end
		
		center = center / #ents
	end
	
	for _, ent in pairs(ents) do
		local ent_pos = ent:getPos() - center
		local ent_ang = ent:getAngles()
		
		for _, data in pairs(mesh.getModelMeshes(ent:getModel(), 0, 0)) do
			for _, vertex in pairs(data.triangles) do
				local pos = Vector(vertex.pos.x, vertex.pos.y, vertex.pos.z)
				pos:rotate(ent_ang)
				pos = pos + ent_pos
				
				local normal = Vector(vertex.normal.x, vertex.normal.y, vertex.normal.z)
				normal:rotate(ent_ang)
				
				table.insert(vertices, {
					pos = pos,
					normal = normal,
					u = vertex.u,
					v = vertex.v
				})
			end
		end
	end
	
	return vertices
end

----------------------------------------

return mesh