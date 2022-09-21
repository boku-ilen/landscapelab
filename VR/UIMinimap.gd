extends Camera3D

#
# Basic minimap implementation which uses an orthographic camera placed above the player.
#

@onready var ray = get_node("RayCast3D")
@onready var marker = get_node("MeshInstance3D")
@onready var done_button = get_node("Container/HBoxContainer/Button")


func _ready():
	done_button.connect("pressed",Callable(self,"save_position_to_file"))
	
	var initial_cam_height = position.y
	global_transform.origin.y = initial_cam_height


func _input(event):
	if event is InputEventMouseMotion:
		# As this is an orthographic camera, set the origin of the ray cast to the projected origin
		# of the input as the ray will ALWAYS simply cast downwards.
		ray.global_transform.origin = project_ray_origin(event.position)
	elif event is InputEventMouseButton:
		if event.pressed:
			marker.global_transform.origin = ray.get_collision_point()
