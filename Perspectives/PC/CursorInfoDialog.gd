extends Window

# Popup dialog for displaying info about whatever is at the mouse cursor, e.g. the distance to the
# cursor in the 3D world or (in the future) information about the object that was clicked checked.


# Set the text of the distance label
func set_distance(distance):
	$Distance/DistanceValue.text = str(distance)


# Make the popup appear directly to the right of the mouse cursor
func popup_at_mouse_position():
	position = get_viewport().get_mouse_position() - Vector2.RIGHT * size.x
	popup()
