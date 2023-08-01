extends Node3D

@export var eye_path: NodePath

@onready var light = $MeshInstance3d/LightNing
@onready var lightning_mesh = $MeshInstance3d
@onready var line: Line2D = $MeshInstance3d/SubViewport/Line2d
@onready var timer = $MeshInstance3d/SubViewport/Line2d/Timer


func _ready():
	timer.timeout.connect(_on_timer_timeout)


func _create_lightning_branch(num_segments: int):
	line.clear_points()
	line.add_point(Vector2(6, 0))
	for i in range(num_segments):
		var point_before = line.points[i]
		line.add_point(Vector2(_sample_gaussian(0.5) + point_before.x * randf(), _sample_gaussian(0.8) + point_before.y))


# Approximate via  central limit theorem (Irwin-Hall)
func _sample_gaussian(stdev_multiplier: float):
	var approx_gauss = 12
	for i in range(12):
		approx_gauss -= randf() 
	
	return approx_gauss / stdev_multiplier


func _animate_():
	var eye: Node3D = get_node(eye_path)
	
	self.light.look_at(eye.position)
	
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
	
	tween_light.tween_property(self.light, "light_energy", 0.0, 0.1)
	tween_lighting.tween_property(self.line, "default_color:a", 0.0, 0.1)


func fire():
	_create_lightning_branch(30)
	$MeshInstance3d.position += Vector3(randi_range(-300, 300), 0, randi_range(-300, 300))
	_animate_()


func _on_timer_timeout():
	fire()
	timer.wait_time = randi_range(1, 4)
