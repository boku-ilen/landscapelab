extends Spatial
class_name ControllerTool

var controller_id: int
var origin: ARVROrigin setget set_origin


func set_origin(orig: ARVROrigin):
	origin = orig


func get_class(): return "ControllerTool"
