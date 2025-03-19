extends FeatureLayerCompositionRenderer

@export var check_aabb_collision: bool = false

# Stores if the object-layer has been processed previously
var processed = false
const offset = -8.0

var object_instances = []

enum DIRECTION {
	UP,
	RIGHT,
	DOWN,
	LEFT
}


func spiral(start_position: Vector2, min_pos: Vector2, max_pos: Vector2, max_features: float, dx: float, dy: float, callback: Callable):
	var parent = Node3D.new()
	
	var x := start_position.x
	var y := start_position.y
	
	var stop_flags = 0b0000
	
	var direction = DIRECTION.UP
	var i = 0
	var step_size = 0
	DIRECTION.size()
	var instance_count = 0
	var matrix_pos := Vector2i(0, 0)
	while instance_count < max_features:
		var multiplier = i + (1 * int(direction % 2 == 0))
		for step in range(step_size):
			stop_flags |= int(x < min_pos.x) * 0b1
			stop_flags |= int(y < min_pos.y) * 0b10
			stop_flags |= int(x > max_pos.x) * 0b100
			stop_flags |= int(y > max_pos.y) * 0b1000
			
			if stop_flags == 0b1111:
				return parent
			
			var new_node = callback.call(x, y, instance_count)

			if new_node:
				instance_count += 1
				new_node.name = "%d_%d" % [matrix_pos.x, matrix_pos.y]
				parent.add_child(new_node)
			
			if instance_count > max_features:
				break
			
			match direction:
				DIRECTION.UP:
					matrix_pos += Vector2i.UP
					y += dy
				DIRECTION.DOWN:
					matrix_pos += Vector2i.DOWN
					y -= dy
				DIRECTION.RIGHT:
					matrix_pos += Vector2i.RIGHT
					x += dx
				DIRECTION.LEFT:
					matrix_pos += Vector2i.LEFT
					x -= dx
		
		i += 1
		if direction % 2 == 0:
			step_size += 1
		direction = i % DIRECTION.size()
	
	return parent


func load_feature_instance(activation_point: GeoFeature) -> Node3D:
	# Polygons (e.g. fields)
	var polygon_layer: GeoFeatureLayer = layer_composition.render_info.polygon_layer
	
	# Extract polygons
	var pos = activation_point.get_vector3()
	var engine_pos = activation_point.get_offset_vector3(-center[0], 0, -center[1])
	var poly_features = polygon_layer.get_features_near_position(pos.x, -pos.z, 0.2, 1)
	
	if poly_features.is_empty(): return Node3D.new()
	
	var poly_feature = poly_features[0]
	var engine_polygon = poly_feature.get_float_offset_outer_vertices(-center[0], -center[1])
	
	# Inset polygon
	var directions = GeometryUtil.get_polygon_vertex_directions(engine_polygon)
	engine_polygon = GeometryUtil.offset_polygon_vertices(engine_polygon, directions, offset)
	
	# Find left-most and bottom-most and right-most, top-most point in polygon
	var min_pos = Vector3(INF, 0, INF)
	var max_pos = Vector3(-INF, 0, -INF)
	for vertex in engine_polygon:
		min_pos.x = min(min_pos.x, vertex.x)
		min_pos.z = min(min_pos.z, vertex.y)
		max_pos.x = max(max_pos.x, vertex.x)
		max_pos.z = max(max_pos.z, vertex.y)
	
	var object_scene = load(layer_composition.render_info.object)
	
	# Obtain aabb over all visual instances
	var aabb
	var bounds
	var object: Node3D = object_scene.instantiate()
	
	aabb = util.get_summed_aabb(object)
	bounds = [
		Vector2(aabb.position.x, aabb.position.z), 
		Vector2(aabb.position.x, aabb.end.z),
		Vector2(aabb.end.x, aabb.end.z),
		Vector2(aabb.end.x, aabb.position.z)
	]
	
	var set_object = func(x: float, y: float, instance_count: int):
		# Add relative position to absolute object position
		var current_pos_2d := Vector2(x, -y)
		
		var fully_inside: bool
		if check_aabb_collision:
			fully_inside = bounds.reduce(func(still_inside, b): 
				return Geometry2D.is_point_in_polygon(b + current_pos_2d * Vector2(1, -1), engine_polygon) and still_inside, true)
		else:
			fully_inside = Geometry2D.is_point_in_polygon(current_pos_2d * Vector2(1, -1), engine_polygon)
		
		var object_y_pos = layer_composition.render_info.ground_height_layer.get_value_at_position(
			center[0] + current_pos_2d.x, center[1] - current_pos_2d.y)
		var object_pos = Vector3(current_pos_2d.x, object_y_pos, current_pos_2d.y)
		
		var object_y_pos_right = layer_composition.render_info.ground_height_layer.get_value_at_position(
			center[0] + current_pos_2d.x - 4, center[1] - current_pos_2d.y)
		
		var angle = atan((object_y_pos - object_y_pos_right) / 4)
		
		
		if fully_inside:
			var geom_tick = Time.get_ticks_usec()
			var new_object = object.duplicate(DUPLICATE_SCRIPTS)
			new_object.rotation.y = deg_to_rad(layer_composition.render_info.individual_rotation)
			new_object.rotation.z = angle
			new_object.position = object_pos
			
			if "feature" in new_object: new_object.feature = activation_point
			
			return new_object
		
		return fully_inside
	
	var spacing_x = layer_composition.render_info.spacing_x
	if not spacing_x > -1.0:
		spacing_x = float(activation_point.get_attribute(layer_composition.render_info.spacing_x_attribute))
	
	var spacing_y = layer_composition.render_info.spacing_y
	if not spacing_y > -1.0:
		spacing_y = float(activation_point.get_attribute(layer_composition.render_info.spacing_y_attribute))
	
	spacing_x += aabb.size.x
	spacing_y += aabb.size.z
	
	var amount = layer_composition.render_info.amount
	if not amount > 0.0:
		amount = float(activation_point.get_attribute(layer_composition.render_info.amount_attribute))
	
	var per_feature_parent = spiral(
		Vector2(engine_pos.x, -engine_pos.z), 
		Vector2(min_pos.x, min_pos.z), 
		Vector2(max_pos.x, max_pos.z), 
		amount, 
		spacing_x,
		spacing_y,
		set_object,
	)
	per_feature_parent.name = var_to_str(activation_point.get_id())
	
	return per_feature_parent


func _ready():
	super._ready()
