extends Node3D


@export var rotation_speed := 0.1


func _ready():
	$Pivot.rotation.y = randf_range(0.0, PI * 2.0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$Pivot.rotation.y -= rotation_speed * delta
