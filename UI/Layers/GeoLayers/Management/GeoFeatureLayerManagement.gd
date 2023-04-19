extends HBoxContainer

var geo_feature_layer: GeoFeatureLayer

var point_add_action = EditingAction.new(
	func(event: InputEvent, cursor, state: Dictionary):
		var point: GeoPoint = geo_feature_layer.create_feature()
		point.set_vector3(cursor.get_cursor_world_position())
)
# FIXME: could this be a geodot issue?
var line_add_action = EditingAction.new(
	func(event: InputEvent, cursor, state: Dictionary):
		var curve_3d: Curve3D
		if "Curve3D" in state:
			print("GeoLine pre-exists")
			curve_3d = state["Curve3D"]
		else:
			curve_3d = Curve3D.new()
			state["Curve3D"] = curve_3d
		var pos = cursor.get_cursor_world_position()
		curve_3d.add_point(Vector3(pos.x, 0, pos.z)),
	func(event: InputEvent, cursor, state: Dictionary): 
		if "Curve3D" in state:
			var line: GeoLine = geo_feature_layer.create_feature()
			line.set_curve3d(state["Curve3D"])
#			print(state["Curve3D"].get_baked_points()[0])
#			print("\n\n")
#			print(geo_feature_layer.get_all_features()[0].get_curve3d().get_baked_points()[0])
			state.clear()
)
# FIXME: Implement this functionality in Geodot
var polygon_add_action = EditingAction.new(
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
			print(geo_feature_layer.get_all_features().size())
			var polygon: GeoPolygon = geo_feature_layer.create_feature()
			polygon.set_outer_vertices(state["GeoPolygonVertices"])
			state.clear()
)

var add_actions := {
	"GeoPoint": point_add_action,
	"GeoLine": line_add_action,
	"GeoPolygon": polygon_add_action
}


func set_buttons_active(are_active: bool):
	for child in get_children():
		if child is Button:
			child.disabled = not are_active
