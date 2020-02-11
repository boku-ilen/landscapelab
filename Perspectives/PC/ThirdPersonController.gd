extends AbstractPlayer

#
# This scene handles a basic third person controller with dragging around the map.
#

var MAX_DISTANCE_TO_GROUND = Settings.get_setting("third-person", "max-distance-to-ground")
var START_DISTANCE_TO_GROUND = Settings.get_setting("third-person", "start_height")
var MOUSE_ZOOM_SPEED = Settings.get_setting("third-person", "mouse-zoom-speed")

onready var mousepoint = get_node("ThirdPersonCamera/MousePoint")

const UP = Vector3(0, 1, 0)
const RIGHT = Vector3(1, 0, 0)


func _ready():
	translation.y = START_DISTANCE_TO_GROUND


func _handle_viewport_input(event):
	if event.is_action_pressed("zoom_out"): # Move down when scrolling up
		get_tree().set_input_as_handled()
		move_and_collide(get_forward() * -MOUSE_ZOOM_SPEED)
		
		translation.y = clamp(translation.y, 0, MAX_DISTANCE_TO_GROUND)
		has_moved = true
		
	elif event.is_action_pressed("zoom_in"): # Move up when scrolling down
		get_tree().set_input_as_handled()
		move_and_collide(get_forward() * MOUSE_ZOOM_SPEED)
		
		translation.y = clamp(translation.y, 0, MAX_DISTANCE_TO_GROUND)
		has_moved = true
		
	elif event is InputEventMouseMotion:
		if dragging:
			var mouseMovement = Vector3(event.relative.x, 0, event.relative.y)
			
			# The movement should be relative to our current rotation around the UP axis, otherwise dragging left
			#  always makes us move towards the global left vector, which doesn't feel like dragging anymore
			mouseMovement = mouseMovement.rotated(Vector3.UP, rotation.y)
			
			move_and_collide(-mouseMovement * translation.y / 600)  # FIXME: hardcoded value
			
		if rotating:
			get_tree().set_input_as_handled()
			
			# For the left/right rotation, we use the global 'up' vector, as this should be consistent regardless
			#  of the rotation of the node. For up/down however, we use the local 'right' vector, since we always
			#  want to go up or down relative to our current rotation.
			# Imagine a real tripod - the big pole in the middle is the global 'up' vector, the part with the handle
			#  is our local 'right' vector.
			global_rotate(UP, deg2rad(-event.relative.x * mouse_sensitivity))
			global_rotate(transform.basis.x, deg2rad(-event.relative.y * mouse_sensitivity))
		
		has_moved = true
		return true


# Returns the vector which is used as 'forward' for movement. It is an anverage of where the mouse is pointing
# and where 'down' is for this node.
func get_forward():
	return (UP).normalized()


func _process(delta):
	var on_ground = WorldPosition.get_position_on_ground(translation)
	if translation.y < on_ground.y:
		var distance = on_ground.y - translation.y
		translation.y += distance + 30
