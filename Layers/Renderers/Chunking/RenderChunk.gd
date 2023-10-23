extends Node3D
class_name RenderChunk

var position_diff := Vector3.ZERO
var changed := false
var is_high_quality := false
var size: float


# Functions to override
func override_increase_quality(): pass
func override_decrease_quality(): pass
func override_build(center_x, center_y): pass
func override_apply(): pass


func _ready():
	visible = false


func increase_quality():
	is_high_quality = true
	
	override_increase_quality()


func decrease_quality():
	is_high_quality = false
	
	override_decrease_quality()


func build(center_x, center_y):
	center_x += position.x + position_diff.x
	center_y -= position.z + position_diff.z
	
	override_build(center_x, center_y)
	
	changed = true

func apply():
	override_apply()
	
	visible = true
	changed = false
