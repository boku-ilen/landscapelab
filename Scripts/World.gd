tool
extends Spatial

onready var terrain = get_node("Terrain")
#onready var mesh = get_node("MeshInstance")
#onready var multimesh = get_node("MultiMeshInstance")
#var testMesh = preload("res://Objects/cube.tres")

func createWorld(jsonTerrain, size, resolution):
	
	#TODO: load PixelSize from .py
	#TODO: load originRange from .py

	var dataset = []
	dataset = terrain.jsonTerrain(jsonTerrain)
		
	var scale = 100 #TODO: check if scale=pixelSize*res_size and set properly
	var terrainMesh = terrain.createTerrain(dataset, size, resolution, scale)

	#save surface for placing objects
	var meshPosition = terrain.get_terrain(terrainMesh)
	#print("mesh: ", meshPosition)

	#place a mesh object
	#mesh.set_translation(meshPosition[randi() % meshPosition.size()])

	#place multiMesh objects
	#multimesh.createMultiMesh(testMesh, meshPosition, 10) #meshToCopy, surface, count

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


