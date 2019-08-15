extends Spatial

#
# Attach this scene to the MousePoint scene. It will give an indicator on where the
# mouse cursor in the world is currently placed. 
#

onready var world = get_tree().get_root().get_node("Main/TileHandler") # Required for getting exact ground positions
onready var cursor = get_node("RayCast")

var RAY_LENGTH = Settings.get_setting("item-spawner", "camera-ray-length") # Distance that will be checked for collision with the ground

export(Mesh) var particle_highlight_position

func _ready():
	cursor.cast_to = Vector3(0, 0, -RAY_LENGTH)

func _process(delta):
	if cursor.is_colliding():
		particle_highlight_position.translation = world.get_ground_coords(cursor.get_collision_point())


# This callback is called whenever any input is registered
func _input(event):
	pass