extends Spatial
class_name LayerRenderer


# Dependency comes from the LayerRenderers-Node which should always be above in the tree
var layer: Layer


func _ready():
	layer.connect("visibility_changed", self, "set_visible")
