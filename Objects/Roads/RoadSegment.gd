class_name RoadSegment
extends MeshInstance3D


var feature


func _ready():
	LIDOverlay.updated.emit()
	visibility_changed.connect(func(): LIDOverlay.updated.emit())


func set_segment_start_end(start_transform, end_transform):
	material_override.set_shader_parameter("start", start_transform)
	material_override.set_shader_parameter("end", end_transform)


# To be implemented by derived classes
func setup(new_feature):
	pass
