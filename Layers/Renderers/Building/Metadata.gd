extends RefCounted
class_name BuildingMetadata

const fallback_height := 4.
const floor_height := 2.5

var extent: float
var geo_center: Vector2
var engine_center: Vector3
var ground_height: float
var cellar_height: float
var footprint: Array
var height: float
var roof_height: float
var holes: Array
var geo_offset: Array

func _init(feature: GeoPolygon, center: Array, render_info: LayerComposition.RenderInfo):
	# === Geo Coordinates ===
	var geo_footprint := Array(feature.get_outer_vertices())
	holes = feature.get_holes()
	geo_center = geo_footprint.reduce(
		func(accum, v): return accum + v, Vector2.ZERO) / geo_footprint.size()

	# === Engine Coordinates (relative to offset center) ===
	geo_offset = [-center[0], -center[1]]
	footprint = feature.get_offset_outer_vertices(geo_offset[0], geo_offset[1])

	# === Bounding Box for Extent ===
	var min_vertex = Vector2(INF, INF)
	var max_vertex = Vector2(-INF, -INF)

	for v in footprint:
		min_vertex.x = min(min_vertex.x, v.x)
		min_vertex.y = min(min_vertex.y, v.y)
		max_vertex.x = max(max_vertex.x, v.x)
		max_vertex.y = max(max_vertex.y, v.y)

	extent = (max_vertex - min_vertex).length()

	# === Flip to match Godot's coordinate system (Z-forward) ===
	footprint = footprint.map(func(v): return Vector2(v.x, -v.y))

	# === Center footprint at origin ===
	var engine_center_2d = footprint.reduce(
		func(accum, v): return accum + v, Vector2.ZERO) / footprint.size()
	footprint = footprint.map(func(v): return v - engine_center_2d)

	# === Ground height at geo center ===
	ground_height = sample_lowest_point_in_height_model(
		bbox_to_verts(get_bounding_box(geo_footprint)),
		render_info.ground_height_layer
	) # safety to prevent buildings from "floating in the air"
	cellar_height = floor_height + render_info.ground_height_layer.get_value_at_position(geo_center.x, geo_center.y) - ground_height
	ground_height -= floor_height
	engine_center = Vector3(engine_center_2d.x, ground_height, engine_center_2d.y)

	# === Building height ===
	height = util.str_to_var_or_default(
		feature.get_attribute(render_info.height_attribute_name),
		fallback_height
	)
	var height_stdev = util.str_to_var_or_default(
		feature.get_attribute(render_info.height_stdev_attribute_name),
		2
	)
	roof_height = fmod(height, floor_height) + height_stdev



func bbox_to_verts(bbox: Rect2):
	return [bbox.position, Vector2(bbox.position.x, bbox.end.y), bbox.end, Vector2(bbox.end.x, bbox.position.y)]


func get_bounding_box(points: Array) -> Rect2:
	var min_x = points[0].x
	var max_x = points[0].x
	var min_y = points[0].y
	var max_y = points[0].y

	for point in points:
		min_x = min(min_x, point.x)
		max_x = max(max_x, point.x)
		min_y = min(min_y, point.y)
		max_y = max(max_y, point.y)
	
	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))


func sample_lowest_point_in_height_model(points: Array, height_layer: GeoRasterLayer):
	var lowest_height = INF
	for point in points:
		lowest_height = min(lowest_height, height_layer.get_value_at_position(point.x, point.y))
	
	return lowest_height
