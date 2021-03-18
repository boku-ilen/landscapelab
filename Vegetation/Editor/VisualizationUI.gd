extends ViewportContainer


func _ready():
	$CameraButtons/GroundViewButton.connect("pressed", self, "_change_camera_view", [2])
	$CameraButtons/CanopyViewButton.connect("pressed", self, "_change_camera_view", [20, -20])
	$CameraButtons/AirViewButton.connect("pressed", self, "_change_camera_view", [50, -45])


func _change_camera_view(height, angle=0):
	$Viewport/Visualization/ClickDragCamera.translation.y = height
	$Viewport/Visualization/ClickDragCamera.rotation_degrees.x = angle
