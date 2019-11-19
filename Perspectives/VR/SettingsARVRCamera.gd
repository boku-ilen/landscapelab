extends ARVRCamera


var VIEW_DISTANCE = Settings.get_setting("player", "view-distance")

# Called when the node enters the scene tree for the first time.
func _ready():
	far = VIEW_DISTANCE
