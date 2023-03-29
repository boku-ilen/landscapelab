extends HBoxContainer

var geo_raster_layer: GeoRasterLayer

# TODO: add some kind of configuration window to circumvent hardcoded values
# FIXME: Geodot limitation
# FIXME: Handle case where the image is not a float => not possible
var terra_form_action = EditingAction.new(
	func(event: InputEvent, cursor, state: Dictionary):
		var pos = cursor.get_cursor_world_position()
		#583009.5, 394818.3
		geo_raster_layer.smooth_add_value_at_position(
			pos.x, -pos.z, 500.0, 20.0)
)

# TODO: add some kind of configuration window to circumvent hardcoded values
# FIXME: Geodot limitation
# FIXME: handle float vs. rgb images
var paint_action = EditingAction.new(
	func(event: InputEvent, cursor, state: Dictionary):
		var pos = cursor.get_cursor_world_position()
		geo_raster_layer.set_value_at_position(
			pos.x, -pos.z, Color(255, 0, 0)
		)
)

func set_buttons_active(are_active: bool):
	for child in get_children():
		if child is Button:
			child.disabled = not are_active
