extends Spatial

#
# Attach this scene to the MousePoint scene. It will give an indicator on where the
# mouse cursor in the world is currently placed. 
#

onready var world = get_tree().get_root().get_node("Main/TileHandler") # Required for getting exact ground positions
onready var cursor = get_node("RayCast")
onready var player = get_tree().get_root().get_node("Main/Perspectives/FirstPersonPC")

var RAY_LENGTH = Settings.get_setting("item-spawner", "camera-ray-length") # Distance that will be checked for collision with the ground

var particle = preload("res://Perspectives/PC/MouseFeedback/Particle.tscn")

var teleport_mode : bool = false


func _ready():
	cursor.cast_to = Vector3(0, 0, -RAY_LENGTH)
	
	GlobalSignal.connect("teleport", self, "_set_teleport_mode")
	particle = particle.instance()
	get_tree().get_root().add_child(particle)


func _process(delta):
	if cursor.is_colliding():
		particle.translation = world.get_ground_coords(cursor.get_collision_point())


# This callback is called whenever any input is registered
func _input(event):
	if teleport_mode:
		if event.is_action_pressed("teleport"):
			_teleport_player()
			teleport_mode = false


func _set_teleport_mode():
	teleport_mode = !teleport_mode


func _teleport_player():
	player.translation = world.get_ground_coords(cursor.get_collision_point())