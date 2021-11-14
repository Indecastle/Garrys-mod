import bpy, struct, base64
from bpy_extras.io_utils import ExportHelper
from bpy.props import StringProperty, BoolProperty, EnumProperty
from bpy.types import Operator
import bpy.path

# ------------------------------

class ByteArray():
	def __init__(self):
		self.array = bytearray()
	
	def writeU(self, n, c = 1):
		self.array += (n).to_bytes(c, byteorder = "little")
	
	def write(self, n, c = 1):
		self.array += (n).to_bytes(c, byteorder = "little", signed = True)
	
	def writeString(self, s):
		self.array += bytes(s + "\x00", "utf-8")
	
	def writeFloat(self, *f):
		self.array += struct.pack(str(len(f)) + "f", *f)
	
	def writeBytes(self, b):
		self.array += b

# ------------------------------

def encode(context, path, embed_textures):
	# with open(path, "w") as file:
	# 	for obj in context.selected_objects:
	# 		data = obj.data
			
	# 		file.write(str(obj.location))
	# 		for vert in data.vertices:
	# 			pos = vert.co
				
	# 			file.write("{},{},{}\n".format(pos.x, pos.y, pos.z))
	
	with open(path, "wb") as file:
		content = ByteArray()
		objects = context.selected_objects
		
		# SBM Version
		content.writeU(0)
		
		# Material count
		materials = {}
		material_list = {}
		i = 0
		for obj in objects:
			material_list[obj] = {}
			
			for mat in obj.material_slots:
				materials[i] = mat.material
				material_list[obj][mat] = i
				
				# has_albedo = "Image Texture" in mat.material.node_tree.nodes and mat.material.node_tree.nodes["Image Texture"].image != None
				# has_normal = False
				
				# if "Image Texture" in mat.material.node_tree.nodes and mat.material.node_tree.nodes["Image Texture"].image != None:
				# 	with open(mat.material.node_tree.nodes["Image Texture"].image.filepath_raw, "rb") as f:
				# 		albedos[i] = f.read()
				# 		# binary = f.read()
				# 		# print(len(binary), len(base64.b64encode(binary)))
				
				i += 1
		content.writeU(i)
		
		# Materials
		for _, mat in materials.items():
			has_albedo = "Image Texture" in mat.node_tree.nodes and mat.node_tree.nodes["Image Texture"].image != None
			has_normal = False
			
			content.writeU(
				# No transparency currently
				# No lit or unlit difference currently
				
				(has_albedo and 4 or 0) +
				(embed_textures and 8 or 0) +
				
				(has_normal and 16 or 0) +
				(embed_textures and 32 or 0)
			, 2)
			
			content.writeString(mat.name)
			
			if has_albedo:
				if embed_textures:
					texture = None
					with open(bpy.path.abspath(mat.node_tree.nodes["Image Texture"].image.filepath_raw), "rb") as f:
						texture = f.read()
					
					# print(len(texture))
					# content.writeU(len(texture), 4)
					# content.writeBytes(texture)
					content.writeString("data:image/png;base64," + str(base64.b64encode(texture), "utf-8"))
				else:
					spl = mat.node_tree.nodes["Image Texture"].image.filepath.split("/")
					
					content.writeString(spl[-1])
			
			if has_normal:
				# Todo
				pass
		
		# Object count
		content.writeU(len(objects))
		
		# Objects
		for obj in objects:
			# Flags
			content.writeU(0x3)
			
			# Name
			content.writeString(obj.name)
			
			# Position
			content.writeFloat(obj.location.x, obj.location.y, obj.location.z)
			
			# Rotation
			content.writeFloat(obj.rotation_euler.x, obj.rotation_euler.y, obj.rotation_euler.z)
			
			# Scale
			content.writeFloat(obj.scale.x, obj.scale.y, obj.scale.z)
			
			#map blender vertices (position, normal) and uv to our vertex representation (position, normal and uv)
			seenVertices = {}
			seenVertexList = []
			def registerVertex(vertex, uv = None):
				key = ((vertex.co.x, vertex.co.y, vertex.co.z), (vertex.normal.x, vertex.normal.y, vertex.normal.z), (uv[0], uv[1]))
				index = seenVertices.get(key)
				if index is None:
					seenVertexList.append((vertex, uv))
					index = len(seenVertices)
					seenVertices[key] = index
				return index
				
			# Create segments
			segments = {}
			for face in obj.data.polygons:
				if not face.material_index in segments:
					segments[face.material_index] = []
				
				vertMap = {} #account for UV within face
				for vert_idx, loop_idx in zip(face.vertices, face.loop_indices):
					uv_coords = obj.data.uv_layers.active.data[loop_idx].uv
					vertMap[vert_idx] = registerVertex(obj.data.vertices[vert_idx], (uv_coords.x, uv_coords.y))
					print("face idx: %i, vert idx: %i, uvs: %f, %f" % (face.index, vert_idx, uv_coords.x, uv_coords.y))
					
				vertices = face.vertices
				for i in range(2, len(vertices)):
					segments[face.material_index].append((vertMap[vertices[0]], vertMap[vertices[i - 1]], vertMap[vertices[i]]))
				
			# Vertex count
			vertices = seenVertexList
			content.writeU(len(vertices), 4)
			
			# Vertices
			for vertex, uv in vertices:
				content.writeFloat(vertex.co.x, vertex.co.y, vertex.co.z)
				content.writeFloat(vertex.normal.x, vertex.normal.y, vertex.normal.z)
				content.writeFloat(uv[0], uv[1])
			
			# Segment count
			materials = obj.material_slots
			content.writeU(len(materials))
			
			# Write created segments
			for mat, vertices in segments.items():
				content.writeU(material_list[obj][materials[mat]] + 1)
				content.writeU(len(vertices), 4)
				
				for vertex in vertices:
					content.writeU(vertex[0], 2)
					content.writeU(vertex[1], 2)
					content.writeU(vertex[2], 2)
		
		file.write(content.array)
	
	return {"FINISHED"}

class SBMExporter(Operator, ExportHelper):
	bl_idname = "sbm.exporter"
	bl_label = "SBM Export"
	filename_ext = ".sbm"
	
	filter_glob: StringProperty(
		default = "*.sbm",
		options = {"HIDDEN"},
		maxlen = 255,  # Max internal buffer length, longer would be clamped.
	)
	
	embed_textures: BoolProperty(
        name = "Embed Textures",
        description = "Include the albedo and normal map for the materials in the file instead of their local paths",
        default = True,
    )
	
	def execute(self, context):
		return encode(context, self.filepath, self.embed_textures)

# ------------------------------

def menu_export(self, context):
	self.layout.operator(SBMExporter.bl_idname, text = "SBM (.sbm)")

def register():
	bpy.utils.register_class(SBMExporter)
	bpy.types.TOPBAR_MT_file_export.append(menu_export)

def unregister():
	bpy.utils.unregister_class(SBMExporter)
	bpy.types.TOPBAR_MT_file_export.remove(menu_export)


# ------------------------------

if __name__ == "__main__":
	register()
	
	bpy.ops.sbm.exporter("INVOKE_DEFAULT")
	
	#unregister()