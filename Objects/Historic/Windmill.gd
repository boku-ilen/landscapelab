@tool
extends Node3D

@onready var cap = $Windmill_Dutch_Tower/Windmill_Dutch_Cap
@onready var rotor = $Windmill_Dutch_Tower/Windmill_Dutch_Cap/Windmill_Dutch_Rotor

var wind_speed = 30.0
var wind_direction = 90.0

const wind_speed_multiplier = 0.02

var weather_manager: WeatherManager :
	get:
		return weather_manager
	set(new_weather_manager):
		# FIXME: Seems like there's a condition where this is called once with a null
		# weather manager. Not necessarily a problem since it's called again correctly
		# later, but feels like it shouldn't be necessary.
		if not new_weather_manager:
			return
		
		weather_manager = new_weather_manager
		
		_apply_new_wind_speed(weather_manager.wind_speed)
		weather_manager.wind_speed_changed.connect(_apply_new_wind_speed)
		
		_apply_new_wind_direction(weather_manager.wind_direction)
		weather_manager.wind_direction_changed.connect(_apply_new_wind_direction)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_apply_new_wind_speed(wind_speed)
	_apply_new_wind_direction(wind_direction)


func _apply_new_wind_speed(new_wind_speed):
	wind_speed = new_wind_speed


func _apply_new_wind_direction(new_wind_direction):
	wind_direction = -new_wind_direction
	cap.rotation.y = deg_to_rad(wind_direction)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if delta > 0.8: return  # Avoid skipping
	if is_inside_tree():
		rotor.transform.basis = rotor.transform.basis.rotated(Vector3.FORWARD, -wind_speed * wind_speed_multiplier * delta)
