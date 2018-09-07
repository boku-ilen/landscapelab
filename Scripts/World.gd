tool
extends Spatial

onready var terrain = get_node("Terrain")
#onready var mesh = get_node("MeshInstance")
#onready var multimesh = get_node("MultiMeshInstance")
#var testMesh = preload("res://Objects/cube.tres")

func createWorld(jsonTerrain, size, resolution):

	#load data and create surface
	#var terrainPath = "res://dhm_3000.json"
	#var originSize = 30000
	#var size = 3000
	#var resolution = 300
	
	#var terrainPath = "res://300.json"
	#var originSize = 3000

	var dataset = []
	dataset = terrain.jsonTerrain(jsonTerrain)
		
	#TODO: normalize dataset height-data: data/((max-min)/(real.max-real.min))
	#for now scale = 1000 (dependent on dataset)
	var scale = 1000
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


