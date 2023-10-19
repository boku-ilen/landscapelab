extends VBoxContainer


@export var shift_coordinates_x := 500
@export var shift_coordinates_y := 500


@export var camera_2d: Camera2D : 
	set(new_camera_2d):
		camera_2d = new_camera_2d
		$VBox/ZoomContainer.camera_2d = new_camera_2d
		
		$VBox/GridContainer/Right.pressed.connect(func(): 
			camera_2d.change_offset_and_emit(Vector2(shift_coordinates_x, 0)))
		$VBox/GridContainer/Left.pressed.connect(func(): 
			camera_2d.change_offset_and_emit(Vector2(-shift_coordinates_x, 0)))
		$VBox/GridContainer/Up.pressed.connect(func():
			camera_2d.change_offset_and_emit(Vector2(0, -shift_coordinates_y)))
		$VBox/GridContainer/Down.pressed.connect(func():
			camera_2d.change_offset_and_emit(Vector2(0, shift_coordinates_y)))


func _ready():
	$SetVisible.toggled.connect(func(toggled): $VBox.visible = !toggled)
