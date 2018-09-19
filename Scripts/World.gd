tool
extends Spatial

onready var terrain = get_node("Terrain")
#onready var mesh = get_node("MeshInstance")
#onready var multimesh = get_node("MultiMeshInstance")
#var testMesh = preload("res://Objects/cube.tres")

func createWorld(dhmName, splits, jsonForestTrees):
	var meshPosition = []
	var originRange = []
	var pixelSize = []
	var size
	
	for p in range(0,splits * splits):
		if p in loadLimiter(splits): #adding a second parameter which is lower than splits (e.g. loadLimiter(splits,2)) will prompt the program to only load part of the raster (which is useful in test cases)
			var jsonTerrain = ServerConnection.getJson("http://127.0.0.1","/dhm/?filename=%s&splits=%d&part=%d" % [dhmName, splits, p],8000)
			
			var dataset = terrain.jsonTerrain(jsonTerrain)
			originRange.append(terrain.jsonTerrainOrigin(jsonTerrain))
			pixelSize.append(terrain.jsonTerrainPixel(jsonTerrain))
			size = terrain.jsonTerrainDimensions(jsonTerrain)[0]
			var resolution = size
			
			var scale = 10 #TODO: check if scale=pixelSize*res_size and set properly
			var terrainMesh = terrain.createTerrain(dataset, size, resolution, scale, splits, p)
			
			#save surface for placing objects
			meshPosition.append(terrain.get_terrain(terrainMesh))
	#print("mesh: ", meshPosition)

	#create new nodes (mesh)
	createTrees(size, jsonForestTrees, originRange[0], pixelSize[0], splits)

	#place a mesh object
	#mesh.set_translation(meshPosition[randi() % meshPosition.size()])

	#place multiMesh objects
	#multimesh.createMultiMesh(testMesh, meshPosition, 10) #meshToCopy, surface, count

# this function is just for testing purposes
# it returns an array of split-indices that includes only a fraction of all indices
# that way loading time is reduced when testing
#TODO definately remove in final release
func loadLimiter(splits, include = splits):
	if include >= splits or splits < 0:
		return range(splits * splits)
	
	var ret = []
	for z in range(include):
		for x in range(include):
			ret.append(x + z * splits)
	return ret

func createTrees(size, dict, originRange, pixelSize, splits): # + textures
	
	var scale = 10 #testing (pixelSize x res_size)
	#var mesh = load("res://Pine.tres") # for 3D
	
	#create billboard meshes with texture on both sides
	var mesh1 = createBillboardMesh(1)
	var mesh2 = createBillboardMesh(2)
	
	var model #art of a tree
	var position = Vector3()
	
	for i in range(dict["Data"].size()):
		model = dict["Data"][i]["model"] 
		position.x = dict["Data"][i]["coord"][0]
		position.z = dict["Data"][i]["coord"][1]
		position.x = (position.x-originRange[0])/scale-size/2
		position.z = (originRange[1]-position.z)/scale-size/2
		
		position.y = 0
		var space_state = get_world().direct_space_state
		var result = space_state.intersect_ray(position, position + Vector3(0,100,0))
		#TODO might want to scale the up vector to max height so that no trees are left out in higher terrain
		if not result.empty():
			position = result.position
		
		
		#TODO: if possible - merge following meshes (now there are two meshes for two billboard sides)
		var newMesh = MeshInstance.new()
		add_child(newMesh)
		newMesh.set_mesh(mesh1)
		newMesh.set("translation", position)
		
		var newMesh2 = MeshInstance.new()
		add_child(newMesh2)
		newMesh2.set_mesh(mesh2)
		newMesh2.set("translation", position)

func createBillboardMesh(count):
	var surfTool = SurfaceTool.new()
	var material = SpatialMaterial.new()
	surfTool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surfTool.set_material(material)

	material.flags_unshaded = true;
	material.flags_transparent = true;
	material.flags_albedo_tex_force_srgb = true;
	material.params_billboard_mode = 2;
	material.albedo_texture = load("res://Tree.tres") #art of a tree should be set by model
	
	var size = 2;
	if (count == 1):
		billboard1site(surfTool, size)
	elif (count == 2):
		billboard2site(surfTool, size)
	
	var mesh = surfTool.commit()
	return(mesh)
	
func billboard1site(surfTool, size):
	surfTool.add_uv(Vector2(0, 0));
	surfTool.add_vertex(Vector3(0, 2*size,  0))
	surfTool.add_uv(Vector2(1, 1));
	surfTool.add_vertex(Vector3( 2*size,  0,  0))
	surfTool.add_uv(Vector2(1, 0));
	surfTool.add_vertex(Vector3( 2*size, 2*size,  0))
	surfTool.add_uv(Vector2(0, 0));
	surfTool.add_vertex(Vector3(0, 2*size,  0))
	surfTool.add_uv(Vector2(0, 1));
	surfTool.add_vertex(Vector3(0,  0,  0))
	surfTool.add_uv(Vector2(1, 1));
	surfTool.add_vertex(Vector3( 2*size,  0,  0))
	
func billboard2site(surfTool, size):
	surfTool.add_uv(Vector2(0, 0));
	surfTool.add_vertex(Vector3(2*size, 2*size,  0))
	surfTool.add_uv(Vector2(1, 1));
	surfTool.add_vertex(Vector3( 0,  0,  0))
	surfTool.add_uv(Vector2(1, 0));
	surfTool.add_vertex(Vector3( 0, 2*size,  0))
	surfTool.add_uv(Vector2(0, 0));
	surfTool.add_vertex(Vector3(2*size, 2*size,  0))
	surfTool.add_uv(Vector2(0, 1));
	surfTool.add_vertex(Vector3(2*size,  0,  0))
	surfTool.add_uv(Vector2(1, 1));
	surfTool.add_vertex(Vector3( 0,  0,  0))
