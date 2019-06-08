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

const UP = Vector3(0, 1, 0)
const RIGHT = Vector3(1, 0, 0)


func _ready():
	Offset.connect("shift_world", self, "shift")
	
	translation.y = START_DISTANCE_TO_GROUND


func _input(event):
	if !PlayerInfo.is_follow_enabled:
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
				var mouseMovement = Vector3(event.relative.x, 0, event.relative.y)
				
				# The movement should be relative to our current rotation around the UP axis, otherwise dragging left
				#  always makes us move towards the global left vector, which doesn't feel like dragging anymore
				mouseMovement = mouseMovement.rotated(UP, rotation.y)
				
				move_and_collide(-mouseMovement * current_distance_to_ground / 600)
			if rotating:
				# For the left/right rotation, we use the global 'up' vector, as this should be consistent regardless
				#  of the rotation of the node. For up/down however, we use the local 'right' vector, since we always
				#  want to go up or down relative to our current rotation.
				# Imagine a real tripod - the big pole in the middle is the global 'up' vector, the part with the handle
				#  is our local 'right' vector.
				global_rotate(UP, deg2rad(-event.relative.x * mouse_sensitivity))
				global_rotate(transform.basis.x, deg2rad(-event.relative.y * mouse_sensitivity))
			


# Returns the vector which is used as 'forward' for movement. It is an anverage of where the mouse is pointing
# and where 'down' is for this node.
func get_forward():
	return (UP).normalized()


func _process(delta):
	current_distance_to_ground = translation.y
	if !PlayerInfo.is_follow_enabled: 
		PlayerInfo.update_player_pos(translation)
	else:
		translation.x = PlayerInfo.get_engine_player_position().x
		translation.z = PlayerInfo.get_engine_player_position().z


func shift(delta_x, delta_z):
	if !PlayerInfo.is_follow_enabled:
		PlayerInfo.add_player_pos(Vector3(delta_x, 0, delta_z))
	
	translation.x += delta_x
	translation.z += delta_z
