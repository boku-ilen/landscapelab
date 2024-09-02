@tool
extends MeshInstance3D


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


@export var rotation_damping := 3.0
@export var velocity_damping := 0.5
@export var wave_timer_min := 5.0
@export var wave_timer_max := 8.0
@export var wind_speed := 30.0

var time_passed = 0.0
var velocity = 0.0
var time_to_next_wave = 1.0
var time_passed_since_wave = 0.0
var current_acceleration_addition = 0.0


func _ready():
	rotation = Vector3.ZERO


func _physics_process(delta):
	time_passed += delta
	time_passed_since_wave += delta
	
	var acceleration = -rotation_damping * (rotation.z) - velocity * velocity_damping
	
	if time_passed > time_to_next_wave + wave_timer_min:
		time_passed_since_wave = 0.0
		time_passed = 0.0
		current_acceleration_addition = sign(randf() - 0.5) * randf_range(wind_speed / 4.0, wind_speed / 2.0)
		time_to_next_wave = randf_range(wave_timer_min, wave_timer_max)
	
	if time_passed < time_to_next_wave / 2.0:
		acceleration += sin((time_passed_since_wave / (time_to_next_wave / 2.0)) * PI) * current_acceleration_addition * delta
	
	velocity += acceleration * delta
	rotation.z += velocity * delta


func _apply_new_wind_speed(new_wind_speed):
	wind_speed = new_wind_speed
