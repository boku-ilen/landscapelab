extends AutoIconButton


var pos_manager: PositionManager


func _ready():
	connect("pressed", Screencapture, "screenshot")
