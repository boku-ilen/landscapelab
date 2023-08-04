extends Node3D


@export var enabled := false : 
	set(is_enabled):
		enabled = is_enabled
		if has_node("Timer"):
			if enabled:
				get_node("Timer").start()
			else:
				get_node("Timer").stop()
@export var time_interval_from := 0.1
@export var time_interval_to := 10


@onready var light = $MeshInstance3d/LightNing
@onready var lightning_mesh = $MeshInstance3d
@onready var line: Line2D = $MeshInstance3d/SubViewport/Line2d
@onready var timer = $Timer

var center_node: Node3D 


func _ready():
	timer.timeout.connect(_on_timer_timeout)
	if enabled: timer.start()


func _create_lightning_branch(num_segments: int):
	line.clear_points()
	line.add_point(Vector2(50, 0))
	$MeshInstance3d/SubViewport/Sprite2D.position = Vector2(50, 6)
	for i in range(num_segments):
		var point_before = line.points[i]
		line.add_point(Vector2(_sample_gaussian(0.5) + point_before.x * randf(), _sample_gaussian(0.8) + point_before.y))
#	$MeshInstance3d/SubViewport/Sprite2D2.position = line.get_point_position(num_segments)


# Approximate via  central limit theorem (Irwin-Hall)
func _sample_gaussian(stdev_multiplier: float):
	var approx_gauss = 12
	for i in range(12):
		approx_gauss -= randf() 
	
	return approx_gauss / stdev_multiplier


func _animate_():
	self.light.look_at(center_node.position)
	
	var tween_lighting = create_tween()
	var tween_light = create_tween()
	
	for i in range(randf_range(3, 6)):
		var time_light_on = randf_range(.05, .1)
		var time_light_off = randf_range(.05, .1)
		
		var energy_light_on = randf_range(.4, 1.)
		var energy_light_off = randf_range(.0, .5)
		
		tween_lighting.tween_property(self.line, "default_color:a", energy_light_off, time_light_off)
		tween_lighting.tween_property(self.line, "default_color:a", energy_light_on, time_light_on)
		
		tween_light.tween_property(self.light, "light_energy", energy_light_off, time_light_off)
		tween_light.tween_property(self.light, "light_energy", energy_light_on, time_light_on)
	
	tween_light.tween_property(self.light, "light_energy", 0.0, 5.1)
	tween_lighting.tween_property(self.line, "default_color:a", 0.0, 5.1)


func fire():
	_create_lightning_branch(30)
	$MeshInstance3d.position = center_node.position + Vector3(randi_range(-3000, 3000), 0, randi_range(-3000, 3000))
	_animate_()


func _on_timer_timeout():
	fire()
	timer.wait_time = randf_range(time_interval_from, time_interval_to)
