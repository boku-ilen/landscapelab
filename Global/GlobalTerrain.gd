extends Spatial

#
# Can be added as a Singleton to have one instance of the Terrain globally.
#


var terrain_scene = preload("res://World/LODTerrain/TerrainScene/Terrain.tscn")


func _ready():
	GlobalSignal.connect("game_started", self, "_activate_terrain")


# Called automatically when the game is started to add the terrain scene as a child.
# Must only be called once.
func _activate_terrain():
	add_child(terrain_scene.instance())


func show_terrain():
	if not has_node("Terrain"):
		logger.warning("Attempted to show terrain, but it's not active yet! Has the game not started?")
	
	get_node("Terrain").visible = true


func hide_terrain():
	if not has_node("Terrain"):
		logger.warning("Attempted to hide terrain, but it's not active yet! Has the game not started?")
	
	get_node("Terrain").visible = false
