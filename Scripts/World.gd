tool
extends Spatial

onready var terrain = get_node("Terrain")
#onready var mesh = get_node("MeshInstance")
#onready var multimesh = get_node("MultiMeshInstance")
#var testMesh = preload("res://Objects/cube.tres")

func createWorld(dhmName, splits, size, resolution, jsonForestTrees):
	var meshPosition = []
	var originRange = []
	var pixelSize = []
	
	for p in range(0,splits * splits):
		#if p in [0,1,2,10,11,12,20,21,22]: #uncomment this and indent everything else in the for loop to only load a 3x3 raster
		var jsonTerrain = ServerConnection.getJson("http://127.0.0.1","/dhm/?filename=%s&splits=%d&part=%d" % [dhmName, splits, p],8000)
		
		var dataset = terrain.jsonTerrain(jsonTerrain)
		originRange.append(terrain.jsonTerrainOrigin(jsonTerrain))
		pixelSize.append(terrain.jsonTerrainPixel(jsonTerrain))
		
		var scale = 10 #TODO: check if scale=pixelSize*res_size and set properly
		var terrainMesh = terrain.createTerrain(dataset, size, resolution, scale, splits, p)
		
		#save surface for placing objects
		meshPosition.append(terrain.get_terrain(terrainMesh))
	#print("mesh: ", meshPosition)

	#create new nodes (mesh)
	createTrees(meshPosition, size, jsonForestTrees, originRange[0], pixelSize[0], splits)

	#place a mesh object
	#mesh.set_translation(meshPosition[randi() % meshPosition.size()])

	#place multiMesh objects
	#multimesh.createMultiMesh(testMesh, meshPosition, 10) #meshToCopy, surface, count

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

func createTrees(surface, size, dict, originRange, pixelSize, splits): # + textures
	
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
		#!!!
		#TODO:
			#check if XZ included on surface (in case some polygons are bigger then dhm)
			#find real position.y on the surface for XZ coordinates!
		
		#var sx = floor(position.x / size)
		#var sy = floor(position.y / size)
		#var sID = sx * splits + sy
		#position.y = surface[sID][randi() % surface.size()].y #random Y from the surface
		position.y = 0
		var space_state = get_world().direct_space_state
		var result = space_state.intersect_ray(position, position + Vector3(0,100,0))
		if not result.empty():
			position = result.position
		
		#if (position.x > 150): #testing, all cases for current suface should be checked
		#	position.x = 150
		
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
