extends Node3D


func on_frequency_changed(frequency):
	if frequency > 0.0:
		# Reset timer because it might be very large from a low frequency before
		get_node("Timer").wait_time = 0.5 
		get_node("Timer").start()
		# Higher frequency should result in lower wait time
		frequency_multiplier = remap(frequency, 0, 100, 3, 0.5)
		return
	
	get_node("Timer").stop()
@export var frequency := 0.0 :
	set(new_frequency): 
		frequency = new_frequency 
		on_frequency_changed(frequency)

# Factor with which spawn_interval is multiplied
var frequency_multiplier := 1.0

# Randomly choose a number (in seconds) in the interval for 
# spawning a new lightning 
@export var spawn_interval_from := 1.0
@export var spawn_interval_to := 10.0

# Distance between center and lightning
@export var min_distance := 500
@export var max_distance := 2000

# Gradient when the lightning is on/off (i.e. flickering)
@export var gradient_on: Gradient
@export var gradient_off: Gradient

func on_color_changed(val):
	if has_node("LightningMesh/LightNing"):
		get_node("LightningMesh/LightNing").light_color = color
	if has_node("LightningMesh"):
		get_node("LightningMesh").material_override.emission = color
	if has_node("LightningMesh/LitCloudMesh"):
		get_node("LightningMesh/LitCloudMesh").material_override.emission = color
		get_node("LightningMesh/LitCloudMesh").material_override.albedo = color
@export var color := Color.CORNFLOWER_BLUE : 
	set(val): 
		color = val
		on_color_changed(val)

# 0 => north, 90 => east, 180 => south, 270 => west 
@export var rot_degrees := 0.0 : 
	set(deg): rot_degrees = deg

@onready var light = $LightningMesh/LightNing
@onready var line: Line2D = $LightningMesh/SubViewport/Line2d

var center_node: Node3D 


func _ready():
	$Timer.timeout.connect(_on_timer_timeout)
	on_frequency_changed(frequency)
	on_color_changed(color)


# Repeating call of this function on timer timeout
func _on_timer_timeout():
	fire()
	var wait_time = randf_range(spawn_interval_from, spawn_interval_to) * frequency_multiplier
	
	$Timer.wait_time = wait_time


func fire():
	_position_lightning()
	_animate_()


func _animate_():
	# Rotate the light accordingly
	light.look_at(center_node.position)
	
	var tween_lighting = create_tween()
	var tween_light = create_tween()
	var tween_cloud = create_tween()
	
	# Simulate "flickering" of lightning
	for i in range(_sample_gaussian(2)):
		var time_light_on = randf_range(.05, .1)
		var time_light_off = randf_range(.02, .07)
		
		# Make lightnings in the far have a less light impact
		var dist_to_center = $LightningMesh.position.distance_to(center_node.position)
		var light_dimming_multiplier = remap(dist_to_center, min_distance, max_distance, 1.5, 0.5)
		var energy_light_on = randf_range(1., 5.)
		var energy_light_off = 0.15
		
		# Optimize performance by setting the viewport only visible when there are indeed visuals
		visible = true
		# Only in some cases let their be a real "lightning" otherwise "weather lights"
		if randf() > 0.75:
			_create_lightning_branch(randi_range(10, 50))
			tween_lighting.tween_property(line, "gradient", gradient_off, time_light_off)
			tween_lighting.tween_property(line, "gradient", gradient_on, time_light_on)
		else:
			# in case of weather lights the light should be dimmer
			light_dimming_multiplier *= 0.5
		
		tween_cloud.tween_property($LightningMesh/LitCloudMesh.material_override, 
			"albedo_color:a", 0, time_light_off)
		tween_cloud.tween_property($LightningMesh/LitCloudMesh.material_override, 
			"albedo_color:a", 1.25, time_light_on)
		
		tween_light.tween_property(
			light, "light_energy", energy_light_off * light_dimming_multiplier, time_light_off)
		tween_light.tween_property(
			light, "light_energy", energy_light_on * light_dimming_multiplier, time_light_on)
	
	# Reset to invisible
	tween_light.tween_property(light, "light_energy", 0.0, 0.2)
	tween_lighting.tween_property(line, "gradient", gradient_off, 0.2)
	await tween_cloud.tween_property($LightningMesh/LitCloudMesh.material_override, 
		"albedo_color:a", 0.0, 0.2).finished
	
	# Wait for anmiation to finish then set back to invisible
	visible = false


func _position_lightning():
	var rand_angle = randf_range(rot_degrees - 10, rot_degrees + 10)
	$LightningMesh.position = center_node.position + Vector3(
		0, 0, randi_range(-min_distance, -max_distance))
	$LightningMesh.position = center_node.position + \
		($LightningMesh.position - center_node.position).rotated(Vector3.UP, deg_to_rad(rand_angle))


func _create_lightning_branch(num_segments: int):
	line.clear_points()
	line.add_point(Vector2(250, 0))
	for i in range(num_segments):
		var point_before = line.points[i]
		line.add_point(Vector2(
			250 + _sample_gaussian(1.5) + (point_before.x - 250) * randf(), 
			_sample_gaussian(0.8) + point_before.y))


# Approximate a number via central limit theorem (Irwin Hall)
func _sample_gaussian(stdev_multiplier: float):
	# aprox gauss will be approximately 6
	var approx_gauss = 12
	for i in range(12):
		approx_gauss -= randf() 
	
	return approx_gauss / stdev_multiplier
