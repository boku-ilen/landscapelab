tool
extends Spatial

onready var terrain = get_node("Terrain")

# will have to add height scale somehow
# also only works for 10m at the moment
func createWorld(dhmName, splits, skip, jsonForestTrees):
	var meshPosition = []
	var originRange = []
	var pixelSize = []
	var size
	var pixel_scale
	var metadata = 0 #set 1 when metadata loaded
	
	for p in range(0,splits * splits):
		if p in loadLimiter(splits): #adding a second parameter which is lower than splits (e.g. loadLimiter(splits,2)) will prompt the program to only load part of the raster (which is useful in test cases)
			var jsonTerrain = ServerConnection.getJson("http://127.0.0.1","/dhm/?filename=%s&splits=%d&skip=%d&part=%d" % [dhmName, splits, skip, p],8000)
			
			var dataset = terrain.jsonTerrain(jsonTerrain)
			
			if (metadata != 1): #if not loaded yet
				originRange.append(terrain.jsonTerrainOrigin(jsonTerrain))
				pixelSize.append(terrain.jsonTerrainPixel(jsonTerrain))
				size = terrain.jsonTerrainDimensions(jsonTerrain)[0]
				
				pixel_scale = pixelSize[0][0] #TODO: check if set properly
				metadata = 1
				
			var terrainMesh = terrain.createTerrain(dataset, size, 1, pixel_scale, splits, p, dhmName)
			
			#save surface for placing objects
			meshPosition.append(terrain.get_terrain(terrainMesh))	
	
	createTrees(size, jsonForestTrees, originRange[0], pixel_scale, splits)

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

func createTrees(size, dict, originRange, pixel_scale, splits): # + textures

	#var mesh = load("res://Pine.tres") # for 3D
	
	#create billboard meshes with texture on both sides
	var mesh = createBillboardMesh()
	
	var model #art of a tree
	var position = Vector3()
	
	for i in range(dict["Data"].size()):
		model = dict["Data"][i]["model"] 
		position.x = dict["Data"][i]["coord"][0]
		position.z = dict["Data"][i]["coord"][1]
		
		position.x = (position.x-originRange[0])-(pixel_scale)*size*splits/2
		position.z = (originRange[1]-position.z)-(pixel_scale)*size*splits/2
		
		position.y = 0
		var space_state = get_world().direct_space_state
		var result = space_state.intersect_ray(position, position + Vector3(0,1000,0))
		#TODO might want to scale the up vector to max height so that no trees are left out in higher terrain
		var parent = self
		if not result.empty():
			position = result.position
			parent = result.collider.get_parent()
		
		
		var tree = preload("res://Scenes/Tree.tscn").instance()
		tree.name = "Tree%d" % i
		parent.add_child(tree)
		tree.set_model(mesh)
		tree.global_transform.origin = position

func createBillboardMesh():
	var surfTool = SurfaceTool.new()
	var material = SpatialMaterial.new()
	surfTool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surfTool.set_material(material)

	material.flags_unshaded = true;
	material.flags_transparent = true;
	material.flags_albedo_tex_force_srgb = true;
	material.params_billboard_mode = 2;
	material.albedo_texture = load("res://Tree.tres") #art of a tree should be set by model
	
	var size = 10;
	
	billboardsite(surfTool, size)
	
	var mesh = surfTool.commit()
	return(mesh)


func billboardsite(surfTool, size):
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
