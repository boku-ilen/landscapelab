extends Spatial
class_name LayerRenderer


# Dependency comes from the LayerRenderers-Node which should always be above in the tree
var layer: Layer

# Offset to use as the center position
var center := [0, 0]


func _ready():
	layer.connect("visibility_changed", self, "set_visible")


# Overload with the functionality to load new data, but not use (visualize) it yet. Run in a thread,
#  so watch out for thread safety!
func load_new_data():
	pass


# Overload with applying and visualizing the data. Not run in a thread.
func apply_new_data():
	pass
