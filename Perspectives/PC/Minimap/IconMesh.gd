extends MeshInstance

# might not be the optimal solution
var SCALE_FACTOR_SMALL = Settings.get_setting("minimap-icons", "scale_factor_small")
var SCALE_FACTOR_BIG =  Settings.get_setting("minimap-icons", "scale_factor_big")


func _ready():
	GlobalSignal.connect("minimap_icon_resize", self, "adjust_size")


# rescales the icon so that it's size fits the current zoom level
func adjust_size(new_zoom, minimap_status):
	if not minimap_status == 'none':
		var s = new_zoom * (SCALE_FACTOR_SMALL if minimap_status == 'small' else SCALE_FACTOR_BIG)
		transform = Transform().scaled(Vector3(s, 1, s))