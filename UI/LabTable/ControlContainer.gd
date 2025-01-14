extends VBoxContainer


signal recenter(center)

@export var shift_relative_x := 0.3
@export var shift_relative_y := 0.3
@export var camera_2d: Camera2D : 
	set(new_camera_2d):
		camera_2d = new_camera_2d
		zoom_container.camera_2d = new_camera_2d
		
		# Shift relative to the current viewport size on button clicks
		right.pressed.connect(func():
			var shift_abs = (Vector2(camera_2d.get_viewport().size) / camera_2d.zoom).x * shift_relative_x
			camera_2d.add_offset_and_emit(Vector2(shift_abs, 0)))
		left.pressed.connect(func():
			var shift_abs = (Vector2(camera_2d.get_viewport().size) / camera_2d.zoom).x * shift_relative_x
			camera_2d.add_offset_and_emit(Vector2(-shift_abs, 0)))
		up.pressed.connect(func():
			var shift_abs = (Vector2(camera_2d.get_viewport().size) / camera_2d.zoom).y * shift_relative_y
			camera_2d.add_offset_and_emit(Vector2(0, -shift_abs)))
		down.pressed.connect(func():
			var shift_abs = (Vector2(camera_2d.get_viewport().size) / camera_2d.zoom).y * shift_relative_y
			camera_2d.add_offset_and_emit(Vector2(0, shift_abs)))
		center.pressed.connect(func():
			if player_sprite:
				camera_2d.set_offset_and_emit(player_sprite.position)
				camera_2d.set_zoom_level(14)
		)
		overview_zoom_button.pressed.connect(func():
			camera_2d.set_offset_and_emit(Vector2.ZERO)
			camera_2d.set_zoom_level(11)
		)
@export var overview_camera: Camera2D

@export var player_sprite: Node2D

@export_group("Control Nodes")
@export var overview_zoom_button: Button
@export var zoom_container: Container
@export var grid_container: Container
@export var subviewport_container: Container
@export_subgroup("Shift Controls")
@export var left: Button
@export var right: Button
@export var up: Button
@export var down: Button
@export var center: Button


func _ready():
	#visibility_button.toggled.connect(func(toggled):
		#for control in [zoom_container, grid_container, subviewport_container]:
			#control.visible = !toggled
		#visibility_button.texture_name = "m_open" if toggled else "m_close"
	#)
	overview_camera.recenter.connect(func(center): recenter.emit(center))


func _gui_input(event):
	overview_camera._input(event)
