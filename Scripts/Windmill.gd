tool
extends Spatial

#
# A windmill which acts according to a specified wind direction and speed.
#

onready var Blades = get_node("Blades")

export(float) var speed = 1 # Rotation speed in radians
export(Vector2) var wind_direction = Vector2(1, 1) setget set_wind_direction, get_wind_direction

# Saves the specified wind direction and updates the model's rotation - called whenever the exported wind_direction is changed
func set_wind_direction(var dir):
	wind_direction = dir
	update_rotation()
	
# Returns the current wind direction which this windmill has saved
func get_wind_direction():
	return wind_direction

# Correctly orients the model depending on the public wind_direction - automatically called when the wind direction is changed
func update_rotation():
	var direction = get_wind_direction()
	look_at(Vector3(direction.x, 0, direction.y), transform.basis.y) # Makes the model face the wind direction (model forward direction is the opposite of the wind forward direction)

# Updates the rotation of the blades to make them rotate with the exported speed variable
func _physics_process(delta):
	Blades.transform.basis = Blades.transform.basis.rotated(Vector3(0, 0, 1), speed * delta)
	
# TODO: The wind_direction could be automatically set using signals at some point