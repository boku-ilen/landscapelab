extends Node3D

#
# A windmill which acts according to a specified wind direction and speed.
#

@onready var rotor = get_node("Mesh/Rotor")

# Rotation speed in radians
@export var speed: float = 0.1

# Rotation of wind in degrees
@export var wind_direction: float = 0 :
	get:
		return wind_direction # TODOConverter40 Copy here content of get_wind_direction
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of set_wind_direction 

@export var mesh_hub_height := 135
@export var mesh_rotor_diameter := 100

# Minimum height and diameter for features where this attribute is 0
@export var min_hub_height := 50
@export var min_rotor_diameter := 35

@export var forward_for_rotation: Vector3 = Vector3(1, 0, 0)

var weather_manager: WeatherManager :
	get:
		return weather_manager # TODOConverter40 Non existent get function 
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of set_weather_manager
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
	weather_manager.connect("wind_speed_changed",Callable(self,"_apply_new_wind_speed"))
	
	_apply_new_wind_direction(weather_manager.wind_direction)
	weather_manager.connect("wind_direction_changed",Callable(self,"_apply_new_wind_direction"))


func _apply_new_wind_speed(wind_speed):
	speed = wind_speed / 15.0


func _apply_new_wind_direction(wind_direction):
	set_wind_direction(-wind_direction)


func _ready():
	# Orient the windmill according to the scenario's wind direction
	# This assumes that a wind direction of 90° means that the wind is blowing from west to east.
	# FIXME: Should be set from the outside (e.g. using another layer)
	set_wind_direction(315.0)
	
	# If is_inside_tree() in set_wind_direction() returned false, we need to catch up checked
	#  setting the wind direction now.
	update_rotation()
	
	# Randomize speed a little
	speed += (randf() - 0.5) * (speed * 0.5)
	
	# Start at a random rotation
	rotor.transform.basis = rotor.transform.basis.rotated(forward_for_rotation, randf() * PI * 2.0)
	
	if feature and render_info and render_info is Layer.WindTurbineRenderInfo:
		var height_attribute_name = render_info.height_attribute_name
		var diameter_attribute_name = render_info.diameter_attribute_name
		
		var height = max(float(feature.get_attribute(height_attribute_name)), min_hub_height)
		var diameter = max(float(feature.get_attribute(diameter_attribute_name)), min_rotor_diameter)
		
		set_hub_height(height)
		set_rotor_diameter(diameter)


# Saves the specified wind direction and updates the model's rotation
# Called whenever the exported wind_direction is changed
func set_wind_direction(dir):
	wind_direction = dir
	
	if is_inside_tree():
		update_rotation()


# Returns the current wind direction which this windmill has saved
func get_wind_direction():
	return wind_direction


# Correctly orients the model depending checked the public wind_direction - automatically called when the wind direction is changed
func update_rotation():
	var direction = get_wind_direction()
	rotation.y = direction


# Updates the rotation of the rotor to make them rotate with the exported speed variable
func _process(delta):
	if delta > 0.8: return  # Avoid skipping
	if is_inside_tree():
		rotor.transform.basis = rotor.transform.basis.rotated(forward_for_rotation, -speed * delta)


func set_hub_height(height: float):
	$Mesh/Mast.scale = Vector3.ONE * (height / mesh_hub_height)
	$Mesh/Rotor.position.y = height
	$Mesh/Hub.position.y = height
	


func set_rotor_diameter(diameter: float):
	$Mesh/Rotor.scale.z = diameter / mesh_rotor_diameter
	$Mesh/Rotor.scale.y = diameter / mesh_rotor_diameter
	
	$Mesh/Hub.scale.z = diameter / mesh_rotor_diameter
	$Mesh/Hub.scale.y = diameter / mesh_rotor_diameter


func apply_daytime_change(is_daytime: bool):
	# During daytime, the light should not be blinking
	if is_daytime:
		$BlinkAnimationPlayer.stop()
		$BlinkAnimationPlayer.seek(0, true)
		$Mesh/Hub/Blink.visible = false
	else:
		$Mesh/Hub/Blink.visible = true
		$BlinkAnimationPlayer.play("Blink")
	
	$Mesh/Hub/Blink.visible = not is_daytime
