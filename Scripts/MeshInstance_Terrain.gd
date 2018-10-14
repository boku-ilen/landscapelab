tool
extends MeshInstance

onready var terrainPart = preload("res://Scenes/TerrainPart.tscn")
onready var ortofoto = preload("res://Assets/basemap18_UTM.png")

# build a mesh (single part of terrain)
func createTerrain(dataset, size,  height_scale, pixel_size, splits, part, dhmName):
	var origin = calculate_origin(size, splits, part, pixel_size)
	
	# call function to build a mesh
	var ret = create_mesh(dataset, origin, size,  height_scale, pixel_size, splits, part)
	var mesh = ret[0]
	var outer_borders = ret[1]
	
	var TerrainPart = terrainPart.instance()
	add_child(TerrainPart)
	var nname = "TerrainPart%d" % part
	TerrainPart.name = nname
	TerrainPart.set_mesh(mesh)
	TerrainPart.set_data(origin, outer_borders, dhmName, height_scale, splits, part)
	#create collider for camera control and vr teleport
	TerrainPart.create_trimesh_collision()
	
	return(mesh)


func create_mesh(arr_height, origin, size,  height_scale, pixel_size, splits, part):
	# calculate origin for ortofoto-part
	var uv_origin = Vector2(int(part / splits), part % splits) / splits
	
	# to build x pixels, it is x+1 points in a row needed
	# with +offset it is possible to 'jump' to the point below
	var offset = size + 1

	var mesh = Mesh.new()
	var surfTool = SurfaceTool.new()
	var material = SpatialMaterial.new()
	
	# material settings
	material.flags_unshaded = false;
	material.metallic = 0
	material.roughness = 1
	material.albedo_texture = ortofoto
	
	surfTool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surfTool.set_material(material)

	surfTool.add_smooth_group(true)
	surfTool.add_color(Color(1, 0, 0, 1))

	var uvarray = []
	var varray = []
	var outer_borders = 0
	
	var xLeft
	var xRight
	var zUp
	var zDown
	var yUpLeft
	var yUpRight
	var yDownRight
	var yDownLeft
	
	var height_idx = 0
	for z in range(size):
		for x in range(size):
			
			# calculate coordinates for triangles
			xLeft = x * pixel_size
			xRight = (x+1) * pixel_size
			zUp = z * pixel_size
			zDown = (z+1) * pixel_size
			yUpLeft = float(arr_height[(height_idx)]/height_scale)
			yUpRight = float(arr_height[(height_idx+1)]/height_scale)
			yDownRight = float(arr_height[((height_idx+1)+offset)]/height_scale)
			yDownLeft = float(arr_height[((height_idx)+offset)]/height_scale)
			
			# add coordinates for the first triangle
			varray.append(Vector3(xLeft, yUpLeft, zUp) + origin)
			varray.append(Vector3(xRight, yUpRight, zUp) + origin)
			varray.append(Vector3(xRight, yDownRight, zDown) + origin)
			
			# calculate coordinates for ortofoto-part
			uvarray.append(uv_origin + Vector2(x, z) / (size * splits))
			uvarray.append(uv_origin + Vector2(x+1, z) / (size * splits))
			uvarray.append(uv_origin + Vector2(x+1, z+1) / (size * splits))
			
			surfTool.add_triangle_fan(varray,uvarray)
			
			uvarray.clear()
			varray.clear()
			
			# add coordinates for the second triangle
			varray.append(Vector3(xLeft, yUpLeft, zUp) + origin)
			varray.append(Vector3(xRight, yDownRight, zDown) + origin)
			varray.append(Vector3(xLeft, yDownLeft, zDown) + origin)
			
			# calculate coordinates for ortofoto-part
			uvarray.append(uv_origin + Vector2(x, z) / (size * splits))
			uvarray.append(uv_origin + Vector2(x+1, z+1) / (size * splits))
			uvarray.append(uv_origin + Vector2(x, z+1) / (size * splits))
			
			surfTool.add_triangle_fan(varray,uvarray)
			
			var ob = Vector2(varray[0].x - origin.x, varray[0].z - origin.z)
			if ob.length() > outer_borders:
				outer_borders = ob.length()
			
			uvarray.clear()
			varray.clear()
			height_idx = height_idx + 1
		height_idx = height_idx + 1

	surfTool.generate_normals()
	surfTool.index()
	surfTool.commit(mesh)
	
	return [mesh, outer_borders]

# save mesh coordinates as 1-dimetional array with XYZ data
func get_terrain(mesh):
	var tool = MeshDataTool.new()
	var meshPosition = []
	tool.create_from_surface(mesh, 0)

	for i in range(0, tool.get_vertex_count()):
		var position = tool.get_vertex(i)		
		meshPosition.append(position)	
	return meshPosition

# save data from json
func jsonTerrain(dict):
	return dict["Data"][0]
			
func jsonTerrainOrigin(dict):
	return dict["Metadata"]["OriginRange"]
	
func jsonTerrainPixel(dict):
	return dict["Metadata"]["PixelSize"]
	
func jsonTerrainDimensions(dict):
	return dict["Metadata"]["ArrayDimensions"]

# calculates the origin of a terrain part based on the given data
func calculate_origin(size, splits, part, pixel_size):
	# calculate XZ origin (upper left corner)
	# set (0,0,0) in the middle
	var setMiddle = Vector3(-size * splits/2, 0, -size * splits/2)
	# set single part of terrain on the right possition
	var terrainPartPosition = Vector3(size * floor(part / splits),0,size * (part % splits))
	var origin = (setMiddle + terrainPartPosition) * pixel_size
	return origin