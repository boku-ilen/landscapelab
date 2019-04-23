extends CheckButton


func _ready():
	var map = get_parent().get_node("Map")
	pressed = map.map_follow
	self.connect("toggled", map, "set_map_mode")
