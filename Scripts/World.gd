extends Spatial

onready var terrain = get_node("Terrain")

# for loading 3D mesh
#onready var 3DModel = preload("res://Assets/Pine.tres")
onready var billboardModel = preload("res://Scenes/Tree.tscn")
# TODO: load size from json
onready var billboardSize = 20

var world_min
var world_max

var originRange
var pixelSize
var size
var pixel_scale
var splits

# will have to add height scale somehow
# also only works for 10m at the moment
func createWorld(server, port, settings):
	
	if settings.has('DHM'):
		var terrain_data = create_terrain(server,port,settings)
		
		
		if settings.has('trees'):
			# place trees with json coordinates (XZ), on the surface (Y)
			createTrees(server, port, settings)
		
		if settings.has('buildings'):
			createBuildings(server, port, settings)
	else:
		ErrorPrompt.show("no digital height map")


func create_terrain(server, port, settings):
	var metadata = 0
	
	var dhm_settings = settings["DHM"]
	var dhmName = dhm_settings["filename"]
	splits = 5
	if dhm_settings.has("splits"):
		splits = int(dhm_settings["splits"])
	var skip = 9
		
	for p in range(0,splits * splits):
		# option for test cases: loading only part of the raster
		# add a second parameter (lower than splits, e.g. loadLimiter(splits,2))
		if p in loadLimiter(splits): 
			# load json with data for single part of terrain
			# examples of json fragments: 
				# "{"Data": [[447.6022644042969, 451.6047668457031,..."
				# ""Metadata": {"PixelSize": [10.0, -10.0], "OriginRange":..."
			# example for showing json in browser: 
				# http://127.0.0.1:8000/dhm/?filename=DTM_10x10_UTM_30km.tif&splits=5&skip=9&part=0
			var jsonTerrain = ServerConnection.getJson(server,"/raster/dhm/?filename=%s&splits=%d&skip=%d&part=%d" % [dhmName, splits, skip, p], port)
			if not jsonTerrain.has("Error"):
				# height (Y) data saved row after row in 1-dimentional array
				var dataset = terrain.jsonTerrain(jsonTerrain)
				
				# load and save metadata if not done yet
				if (metadata != 1):
					originRange = terrain.jsonTerrainOrigin(jsonTerrain)
					pixelSize = terrain.jsonTerrainPixel(jsonTerrain)
					size = terrain.jsonTerrainDimensions(jsonTerrain)[0]
					pixel_scale = pixelSize[0]
					
					world_min = terrain.calculate_origin(size,splits,0,pixel_scale)
					world_max = world_min + (terrain.calculate_origin(size,splits,splits + 1,pixel_scale) - world_min) * splits
					metadata = 1
					
				# call funtion to build a mesh (single part of terrain)
				terrain.createTerrain(dataset, size, 1, pixel_scale, splits, p, dhmName, dhm_settings)
			else:
				ErrorPrompt.show("could not load part of the terrain", jsonTerrain["Error"])
				logger.warning("could not load part %d" % p)
	return {"size": size, "originRange": originRange, "pixelScale": pixel_scale, "splits": splits}

func createTrees(server, port, settings):
	
	var terrain_settings = settings["trees"]
	var multiplier = 1
	if terrain_settings.has("tree_multiplier"):
		multiplier = terrain_settings.tree_multiplier
	var filename = terrain_settings["filename"]
	# load json with XZ coordinates for single tree
	# settings: 
		# filename - name of shp
		# multiplier - 1 (all data) or less than 1 (part of all data)
		#recalc - true if trees placed also on the boarder of shp
	# example of json fragment: 
		# "{"model": "eiche1", "coord": [597599.9999999994, 5385567.762951786]}"
	# example for showing json in browser: 
		# http://127.0.0.1:8000/assetpos?filename=forest_areas&tree_multiplier=0.00001&recalc=true
	var dict = ServerConnection.getJson(server,"/assetpos/?filename=%s&tree_multiplier=%f&recalc=true" % [filename,multiplier],port)
	if dict == null:
		ErrorPrompt.show("Could not load tree data")
	elif dict.has("Error"):
		ErrorPrompt.show("Could not load tree data", dict["Error"])
	else:
		var model
		var position = Vector3()
		
		# read json data
		for i in range(dict["Data"].size()):
			# read art of tree
			model = dict["Data"][i]["model"] 
			
			position = realWorldToLocalWorld(dict["Data"][i]["coord"])
			
			# find the Y coordinate on the surface
			position.y = 0
			var space_state = get_world().direct_space_state
			var result = space_state.intersect_ray(position, position + Vector3(0,1000,0))
			#TODO might want to scale the up vector to max height so that no trees are left out in higher terrain
			var parent = self
			if not result.empty():
				position = result.position
				parent = result.collider.get_parent()
			
			# TODO: add different models/textures
			var tree = billboardModel.instance()
			tree.name = "Tree%d" % i
			parent.add_child(tree)
			tree.global_transform.origin = position

func createBuildings(server, port, settings):
	var building_settings = settings["buildings"]
	
	var dict = ServerConnection.getJson(server, "/buildings/?filename=%s" % building_settings['filename'],port)
	if dict == null:
		ErrorPrompt.show("Could not load building data")
	elif dict.has("Error"):
		ErrorPrompt.show("Could not load building data", dict["Error"])
	else:
		
		for b in dict['Data']:
			
			for i in range(b['coordinates'].size()):
				for j in range(b['coordinates'][i].size()):
					#logger.debug(b['coordinates'][i][j])
					b['coordinates'][i][j] = realWorldToLocalWorld(b['coordinates'][i][j])
			
			var building = load("res://Scenes/Building.tscn")
			building = building.instance()
			add_child(building)
			building.init(b)
			
	pass

	
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

func realWorldToLocalWorld(coord):
	var v = Vector3()
	
	# read XZ coordinates
	v.x = coord[0]
	v.z = coord[1]
	
	# recalculate for Godot coordinates
	v.x = (v.x-originRange[0])-(pixel_scale)*size*splits/2
	v.z = (originRange[1]-v.z)-(pixel_scale)*size*splits/2
	v.y = 0
	
	return v