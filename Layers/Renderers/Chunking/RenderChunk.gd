extends Node3D
class_name RenderChunk

var position_diff := Vector3.ZERO
var changed := false
var is_high_quality := false
var size: float


# Functions to override
func override_increase_quality(distance: float) -> bool: return false
func override_decrease_quality(distance: float) -> bool: return false
func override_can_increase_quality(distance: float) -> bool: return false
func override_build(center_x, center_y): pass
func override_apply(): pass


func _ready():
	visible = false


func can_increase_quality(distance: float) -> bool:
	return override_can_increase_quality(distance)


func increase_quality(distance: float) -> bool:
	is_high_quality = true
	
	return override_increase_quality(distance)


func decrease_quality(distance: float) -> bool:
	is_high_quality = false
	
	return override_decrease_quality(distance)


func build(center_x, center_y):
	center_x += position.x + position_diff.x
	center_y -= position.z + position_diff.z
	
	override_build(center_x, center_y)
	
	changed = true

func apply():
	override_apply()
	
	visible = true
	changed = false
