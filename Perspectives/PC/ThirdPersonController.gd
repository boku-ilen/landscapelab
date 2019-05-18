extends KinematicBody

var MAX_DISTANCE_TO_GROUND = Settings.get_setting("third-person", "max-distance-to-ground")
var START_DISTANCE_TO_GROUND = Settings.get_setting("third-person", "start_height")
var MOUSE_ZOOM_SPEED = Settings.get_setting("third-person", "mouse-zoom-speed")
var mouse_sensitivity = Settings.get_setting("third-person", "mouse-sensitivity")

var dragging : bool = false
var rotating : bool = false
var current_distance_to_ground

onready var ground_check_ray = get_node("GroundCheckRay")
onready var mousepoint = get_node("ThirdPersonCamera/MousePoint")


func _ready():
	Offset.connect("shift_world", self, "shift")
	
	translation.y = START_DISTANCE_TO_GROUND


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT: 
			if event.pressed:
				dragging = true
			else:
				dragging = false
		elif event.button_index == BUTTON_RIGHT:
			if event.pressed:
				rotating = true
			else: 
				rotating = false
				
		elif event.button_index == BUTTON_WHEEL_UP: # Move down when scrolling up
			move_and_collide(get_forward() * -MOUSE_ZOOM_SPEED)
			
		elif event.button_index == BUTTON_WHEEL_DOWN: # Move up when scrolling down
			move_and_collide(get_forward() * MOUSE_ZOOM_SPEED)
		
		current_distance_to_ground = clamp(current_distance_to_ground, 0, MAX_DISTANCE_TO_GROUND)
		
	elif event is InputEventMouseMotion:
		if dragging:
			move_and_collide(-Vector3(event.relative.x, 0, event.relative.y) * current_distance_to_ground / 600)
		if rotating:
			rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
			rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))
			

# Returns the vector which is used as 'forward' for movement. It is an anverage of where the mouse is pointing
# and where 'down' is for this node.
func get_forward():
	return (transform.basis.y + mousepoint.transform.basis.z).normalized()


func _process(delta):
	current_distance_to_ground = translation.y
	PlayerInfo.update_player_pos(translation)


func shift(delta_x, delta_z):
	PlayerInfo.add_player_pos(Vector3(delta_x, 0, delta_z))
	
	translation.x += delta_x
	translation.z += delta_z
