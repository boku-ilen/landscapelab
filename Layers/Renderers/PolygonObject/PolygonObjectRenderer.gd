extends LayerCompositionRenderer


var radius = 10000.0
@export var check_aabb_collision: bool = false
@export var max_features = 50
@export var distance_between_objects := Vector2(10, 10)

# Stores if the object-layer has been processed previously
var processed = false

var object_instances = []

enum DIRECTION {
	UP,
	RIGHT,
	DOWN,
	LEFT
}


func spiral(start_position: Vector2, min_pos: Vector2, max_pos: Vector2, max_features: float, callback: Callable):
	var x := start_position.x
	var y := start_position.y
	var dx := distance_between_objects.x
	var dy := distance_between_objects.y
	
	var stop_flags = 0b0000
	
	var direction = DIRECTION.UP
	var i = 0
	var step_size = 0
	DIRECTION.size()
	var instance_count = 0
	while instance_count < max_features:
		var multiplier = i + (1 * int(direction % 2 == 0))
		for step in range(step_size):
			stop_flags |= int(x < min_pos.x) * 0b1
			stop_flags |= int(y < min_pos.y) * 0b10
			stop_flags |= int(x > max_pos.x) * 0b100
			stop_flags |= int(y > max_pos.y) * 0b1000
			
			if stop_flags == 0b1111:
				return

			if callback.call(x, y, instance_count):
				instance_count += 1
			
			if instance_count > max_features:
				break
			
			match direction:
				DIRECTION.UP:
					y += dy
				DIRECTION.DOWN:
					y -= dy
				DIRECTION.RIGHT:
					x += dx
				DIRECTION.LEFT:
					x -= dx
		
		i += 1
		if direction % 2 == 0:
			step_size += 1
		direction = i % DIRECTION.size()


func full_load():
	# Polygons (e.g. fields)
	var polygon_layer: GeoFeatureLayer = layer_composition.render_info.polygon_layer
	# Points which activate (i.e. fill a polygon) by looking for intersection
	var activation_layer: GeoFeatureLayer = layer_composition.render_info.activation_layer
	
	# Create the objects inside each individual polygon
	for activation_point in activation_layer.get_features_near_position(
		float(center[0]) + position_manager.center_node.position.x, 
		float(center[1]) - position_manager.center_node.position.z, 
		radius, 
		max_features):
		
		# Extract polygons
		var pos = activation_point.get_vector3()
		var engine_pos = activation_point.get_offset_vector3(-center[0], 0, -center[1])
		var poly_features = polygon_layer.get_features_near_position(pos.x, -pos.z, 0.2, 1)
		
		for poly_feature in poly_features:
			var engine_polygon = poly_feature.get_float_offset_outer_vertices(-center[0], -center[1])
			var polygon = poly_feature.get_outer_vertices()
			
			# Find left-most and bottom-most and right-most, top-most point in polygon
			var min_pos = Vector3(INF, 0, INF)
			var max_pos = Vector3(-INF, 0, -INF)
			for vertex in engine_polygon:
				min_pos.x = min(min_pos.x, vertex.x)
				min_pos.z = min(min_pos.z, vertex.y)
				max_pos.x = max(max_pos.x, vertex.x)
				max_pos.z = max(max_pos.z, vertex.y)
			
			var object_scene = load(layer_composition.render_info.object)
			var object: Node3D = object_scene.instantiate()
			
			# Obtain aabb over all visual instances
			var aabb
			var bounds
			if check_aabb_collision:
				aabb = util.get_summed_aabb(object)
				bounds = [
					Vector2(aabb.position.x, aabb.position.z), 
					Vector2(aabb.position.x, aabb.end.z),
					Vector2(aabb.end.x, aabb.end.z),
					Vector2(aabb.end.x, aabb.position.z)
				]
			
			var set_object = func(x: float, y: float, instance_count: int):
				# Add relative position to absolute object position
				var current_pos_2d := Vector2(x, y)
				
				var fully_inside: bool
				if check_aabb_collision:
					fully_inside = bounds.reduce(func(still_inside, b): 
						return Geometry2D.is_point_in_polygon(b + current_pos_2d, engine_polygon) and still_inside, true)
				else:
					fully_inside = Geometry2D.is_point_in_polygon(current_pos_2d, engine_polygon)
				
				var object_y_pos = layer_composition.render_info.ground_height_layer.get_value_at_position(
					center[0] + engine_pos.x, (center[1] - engine_pos.z))
				var object_pos = Vector3(x, object_y_pos, y)
				
				if fully_inside:
					var new_object = object_scene.instantiate()
					new_object.rotation.y = deg_to_rad(layer_composition.render_info.individual_rotation)
					new_object.position = object_pos
					object_instances.append(new_object)
				
				return fully_inside
				
			spiral(
				Vector2(engine_pos.x, engine_pos.z), 
				Vector2(min_pos.x, min_pos.z), 
				Vector2(max_pos.x, max_pos.z), 
				max_features, 
				set_object
			)


func apply_new_data():
	for child in get_children():
		child.queue_free()
	
	for object in object_instances:
		add_child(object)
	
	object_instances.clear()
	
	logger.info("Applied new PolygonObjectRenderer data for %s" % [name])


func _ready():
	super._ready()
