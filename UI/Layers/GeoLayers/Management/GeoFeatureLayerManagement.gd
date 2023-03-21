extends HBoxContainer

var geo_feature_layer: GeoFeatureLayer

var add_actions := {
	"GeoPoint": EditingAction.new(
		func(event: InputEvent, cursor, state: Dictionary):
			var point: GeoPoint = geo_feature_layer.create_feature()
			point.set_vector3(cursor.get_cursor_world_position())),
		
	"GeoLine": EditingAction.new(
		func(event: InputEvent, cursor, state: Dictionary):
			var line: GeoLine
			if "GeoLine" in state:
				line = state["GeoLine"]
			else:
				line = geo_feature_layer.create_feature()
				state["GeoLine"] = line
			line.add_point(cursor.get_cursor_world_position())
			print(line.get_curve3d()),
		func(event: InputEvent, cursor, state: Dictionary): 
			state.clear()),
		
	"GeoPolygon": EditingAction.new(
		func(event: InputEvent, cursor, state: Dictionary):
			var vector_array: PackedVector2Array
			if "GeoPolygonVertices" in state:
				vector_array = state["GeoPolygonVertices"]
			else: 
				vector_array = PackedVector2Array()
				state["GeoPolygonVertices"] = vector_array
			var pos = cursor.get_cursor_world_position()
			vector_array.append(Vector2(pos.x, pos.z)),
		func(event: InputEvent, cursor, state: Dictionary):
			if "GeoPolygonVertices" in state:
				print(state["GeoPolygonVertices"])
				var polygon: GeoPolygon = geo_feature_layer.create_feature()
				polygon.set_outer_vertices(state["GeoPolygonVertices"]))
}


func set_buttons_active(are_active: bool):
	for child in get_children():
		if child is Button:
			child.disabled = not are_active
