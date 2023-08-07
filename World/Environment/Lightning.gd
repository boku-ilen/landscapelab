extends Node3D

func set_enabled(val):
	if has_node("Timer"):
		if enabled:
			get_node("Timer").start()
		else:
			get_node("Timer").stop()
@export var enabled := false : 
	set(val): 
		enabled = val 
		set_enabled(val)

# Randomly choose a number (in seconds) in the interval for 
# spawning a new lightning 
@export var spawn_interval_from := 0.5
@export var spawn_interval_to := 10.0

# Distance between center and lightning
@export var min_distance := 500
@export var max_distance := 2000

# Gradient when the lightning is on/off (i.e. flickering)
@export var gradient_on: Gradient
@export var gradient_off: Gradient

func set_color(val):
	if has_node("MeshInstance3d/LightNing"):
		get_node("MeshInstance3d/LightNing").light_color = color
	if has_node("MeshInstance3d"):
		get_node("MeshInstance3d").material_override.emission = color
@export var color: Color : 
	set(val): 
		color = val
		set_color(val)

# 0 => north, 90 => east, 180 => south, 270 => west 
@export var rot_degrees := 0.0 : 
	set(deg): rot_degrees = deg

@onready var light = $MeshInstance3d/LightNing
@onready var line: Line2D = $MeshInstance3d/SubViewport/Line2d

var center_node: Node3D 


func _ready():
	$Timer.timeout.connect(_on_timer_timeout)
	set_enabled(enabled)
	set_color(color)


func _create_lightning_branch(num_segments: int):
	line.clear_points()
	line.add_point(Vector2(0, 0))
	for i in range(num_segments):
		var point_before = line.points[i]
		line.add_point(Vector2(
			_sample_gaussian(1.5) + point_before.x * randf(), 
			_sample_gaussian(0.8) + point_before.y))


# Approximate a number via central limit theorem (Irwin Hall)
func _sample_gaussian(stdev_multiplier: float):
	# aprox gauss will be approximately 6
	var approx_gauss = 12
	for i in range(12):
		approx_gauss -= randf() 
	
	return approx_gauss / stdev_multiplier


func _animate_():
	# Rotate the light accordingly
	self.light.look_at(center_node.position)
	
	var tween_lighting = create_tween()
	var tween_light = create_tween()
	
	# Simulate "flickering" of lightning
	for i in range(randf_range(2, 5)):
		var time_light_on = randf_range(.05, .2)
		var time_light_off = randf_range(.15, .15)
		
		var dist_to_center = $MeshInstance3d.position.distance_to(center_node.position)
		var distance_multiplier = remap(dist_to_center, min_distance, max_distance, 1.5, 0.5)
		var energy_light_on = randf_range(1., 5.)
		
		tween_lighting.tween_property(line, "gradient", gradient_off, time_light_off)
		tween_lighting.tween_property(line, "gradient", gradient_on, time_light_on)
		
		tween_light.tween_property(
			light, "light_energy", 0.3 * distance_multiplier, time_light_off)
		tween_light.tween_property(
			light, "light_energy", energy_light_on * distance_multiplier, time_light_on)
	
	# Reset to invisible
	tween_light.tween_property(light, "light_energy", 0.0, 0.2)
	tween_lighting.tween_property(line, "gradient", gradient_off, 0.2)


func fire():
	_create_lightning_branch(randi_range(10, 50))
	var rand_angle = randf_range(rot_degrees - 10, rot_degrees + 10)
	$MeshInstance3d.position = center_node.position + Vector3(
		0, 0, randi_range(-min_distance, -max_distance))
	$MeshInstance3d.position = center_node.position + \
		($MeshInstance3d.position - center_node.position).rotated(Vector3.UP, deg_to_rad(rand_angle))
	_animate_()


# Repeating call of this function on timer timeout
func _on_timer_timeout():
	fire()
	$Timer.wait_time = randf_range(spawn_interval_from, spawn_interval_to)
