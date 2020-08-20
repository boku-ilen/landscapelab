extends ViewportContainer


onready var camera = get_node("RecordingViewport/DollyCamera")


func _ready():
	UISignal.connect("toggle_imaging_view", self, "toggle_camera")


func toggle_camera():
		visible = !visible
		
		if visible:
			# FIXME: Ugly... but 0 doesn't move it to the beginning of the path
			camera.path_follow.offset = 0.0001
