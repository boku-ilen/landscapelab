extends Camera

#
# Basic minimap implementation which uses an orthographic camera placed above the player.
#

onready var ray = get_node("RayCast")
onready var marker = get_node("MeshInstance")
onready var done_button = get_node("Container/HBoxContainer/Button")


func _ready():
	GlobalSignal.connect("initiate_minimap_icon_resize", self, "relay_minimap_icon_resize")
	GlobalSignal.connect("request_minimap_icon_resize", self, "respond_to_minimap_icon_update_request")
	
	done_button.connect("pressed", self, "save_position_to_file")
	
	var initial_cam_height = translation.y
	global_transform.origin = PlayerInfo.get_engine_player_position() + Vector3(rand_range(-1000, 1000), 0, rand_range(-1000, 1000))
	global_transform.origin.y = initial_cam_height


func _input(event):
	if event is InputEventMouseMotion:
		# As this is an orthographic camera, set the origin of the ray cast to the projected origin
		# of the input as the ray will ALWAYS simply cast downwards.
		ray.global_transform.origin = project_ray_origin(event.position)
	elif event is InputEventMouseButton:
		if event.pressed:
			marker.global_transform.origin = ray.get_collision_point()


func save_position_to_file():
	var file = File.new()
	var filename = "user://distance-session%d.txt" % [Session.session_id]
	file.open(filename, File.WRITE)
	
	file.store_string("Marked position in engine: %s \n" % )
	file.store_string("Marked position in world: %s \n" % [Offset.to_world_coordinates(marker.global_transform.origin)])
	file.store_string("Actual position in engine: %s \n" % [PlayerInfo.get_engine_player_position()])
	file.store_string("Actual position in world: %s \n" % [PlayerInfo.get_true_player_position()])
	file.store_string("Resulting distance: %s meters" % [marker.global_transform.origin.distance_to(PlayerInfo.get_engine_player_position())])
	file.close()
