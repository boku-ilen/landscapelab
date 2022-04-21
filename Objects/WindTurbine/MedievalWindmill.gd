extends Spatial

#
# A windmill which acts according to a specified wind direction and speed.
#

onready var rotor = get_node("Mesh/Rotor")

export(float) var speed = 0.1 # Rotation speed in radians
export(float) var wind_direction = 0 setget set_wind_direction, get_wind_direction # Rotation of wind in degrees

export var mesh_hub_height := 135
export var mesh_rotor_diameter := 100

# Minimum height and diameter for features where this attribute is 0
export var min_hub_height := 50
export var min_rotor_diameter := 35

export(Vector3) var forward_for_rotation = Vector3(1, 0, 0)

var weather_manager: WeatherManager setget set_weather_manager
var feature
var render_info


func set_weather_manager(new_weather_manager):
	# FIXME: Seems like there's a condition where this is called once with a null
	# weather manager. Not necessarily a problem since it's called again correctly
	# later, but feels like it shouldn't be necessary.
	if not new_weather_manager:
		return
	
	weather_manager = new_weather_manager
	
	_apply_new_wind_speed(weather_manager.wind_speed)
	weather_manager.connect("wind_speed_changed", self, "_apply_new_wind_speed")
	
	_apply_new_wind_direction(weather_manager.wind_direction)
	weather_manager.connect("wind_direction_changed", self, "_apply_new_wind_direction")


func _apply_new_wind_speed(wind_speed):
	speed = wind_speed / 15.0


func _apply_new_wind_direction(wind_direction):
	set_wind_direction(-wind_direction)


func _ready():
	# Orient the windmill according to the scenario's wind direction
	# This assumes that a wind direction of 90° means that the wind is blowing from west to east.
	# FIXME: Should be set from the outside (e.g. using another layer)
	set_wind_direction(315.0)
	
	# If is_inside_tree() in set_wind_direction() returned false, we need to catch up on
	#  setting the wind direction now.
	update_rotation()
	
	# Randomize speed a little
	speed += (randf() - 0.5) * (speed * 0.5)
	
	# Start at a random rotation
	rotor.transform.basis = rotor.transform.basis.rotated(forward_for_rotation, randf() * PI * 2.0)

# Saves the specified wind direction and updates the model's rotation
# Called whenever the exported wind_direction is changed
func set_wind_direction(var dir):
	wind_direction = dir
	
	if is_inside_tree():
		update_rotation()


# Returns the current wind direction which this windmill has saved
func get_wind_direction():
	return wind_direction


# Correctly orients the model depending on the public wind_direction - automatically called when the wind direction is changed
func update_rotation():
	var direction = get_wind_direction()
	rotation_degrees.y = direction


# Updates the rotation of the rotor to make them rotate with the exported speed variable
func _process(delta):
	if delta > 0.8: return  # Avoid skipping
	if is_inside_tree():
		rotor.transform.basis = rotor.transform.basis.rotated(forward_for_rotation, -speed * delta)
