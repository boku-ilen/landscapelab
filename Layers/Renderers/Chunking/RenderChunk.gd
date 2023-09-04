extends Node3D
class_name RenderChunk

var position_diff_x
var position_diff_z
var changed := false
var is_upgraded := false
var size: float


# Functions to override
func override_upgrade(): pass
func override_downgrade(): pass
func override_build(center_x, center_y): pass
func override_apply(): pass


func _ready():
	visible = false


func upgrade():
	is_upgraded = true
	
	override_upgrade()


func downgrade():
	is_upgraded = false
	
	override_downgrade()


func build(center_x, center_y):
	center_x += position.x + position_diff_x
	center_y -= position.z - position_diff_z
	
	override_build(center_x, center_y)
	
	changed = true

func apply():
	override_apply()
	
	visible = true
	changed = false
