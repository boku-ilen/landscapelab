extends Spatial

var MAX_DISTANCE_TO_GROUND = Settings.get_setting("third-person", "max-distance-to-ground")
var MOUSE_ZOOM_SPEED = Settings.get_setting("third-person", "mouse-zoom-speed")

var dragging : bool = false
var current_distance_to_ground

onready var ground_check_ray = get_node("GroundCheckRay")
	
func _ready():
	PlayerInfo.connect("shift_world", self, "shift")
	
	current_distance_to_ground = MAX_DISTANCE_TO_GROUND

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == 1: # Left click
			if event.pressed:
				dragging = true
			else:
				dragging = false
				
		elif event.button_index == BUTTON_WHEEL_UP:
			current_distance_to_ground -= MOUSE_ZOOM_SPEED
			
		elif event.button_index == BUTTON_WHEEL_DOWN:
			current_distance_to_ground += MOUSE_ZOOM_SPEED
		
		current_distance_to_ground = clamp(current_distance_to_ground, 0, MAX_DISTANCE_TO_GROUND)
		
	elif event is InputEventMouseMotion:
		if dragging:
			translation -= Vector3(event.relative.x, 0, event.relative.y) * current_distance_to_ground / 600
			
func _process(delta):
	translation.y = current_distance_to_ground
	PlayerInfo.update_player_pos(translation)
	
func shift(delta):
	PlayerInfo.add_player_offset(delta.x, delta.z)
	PlayerInfo.add_player_pos(delta)
	
	translation.x += delta.x
	translation.z += delta.z