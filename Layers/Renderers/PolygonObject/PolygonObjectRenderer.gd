extends LayerCompositionRenderer


@export var create_objects_as_geodata: bool = false
var radius = 10000.0
var max_features = 2000
var distance_between_objects = 10
# Stores if the object-layer has been processed previously
var processed = false

var object_instances = []


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
		var pos = activation_point.get_vector3()#get_offset_vector3(-center[0], 0, -center[1])
		var poly_features = polygon_layer.get_features_near_position(pos.x, -pos.z, 0.2, 1)
		
		for poly_feature in poly_features:
			var polygon = poly_feature.get_float_offset_outer_vertices(-center[0], -center[1])
			
			# Find left-most and bottom-most and right-most, top-most point in polygon
			var min_pos = Vector3(INF, 0, INF)
			var max_pos = Vector3(-INF, 0, -INF)
			for vertex in polygon: 
				min_pos.x = vertex.x if vertex.x < min_pos.x else min_pos.x
				min_pos.z = vertex.y if vertex.y < min_pos.z else min_pos.z
				
				max_pos.x = vertex.x if vertex.x > max_pos.x else max_pos.x
				max_pos.z = vertex.y if vertex.y > max_pos.z else max_pos.z
			
			var object: Node3D = load(layer_composition.render_info.object).instantiate()
			
			var aabb = util.get_summed_aabb(object)
			
			var current_pos = min_pos
			while current_pos.x <= max_pos.x:
				current_pos.z = min_pos.z
				while current_pos.z <= max_pos.z:
					# Predefined points in the object that have to be inside the polygon
					# (i.e. in most cases some form of foothold)
					var fully_inside = true
					var bounds = [
						Vector2(aabb.position.x, aabb.position.z), 
						Vector2(aabb.position.x, aabb.end.z),
						Vector2(aabb.end.x, aabb.end.z),
						Vector2(aabb.end.x, aabb.position.z)
					]
					
					# Add relative foothold position to absolute object position
					var current_pos_2d = Vector2(current_pos.x, current_pos.z)
					fully_inside = bounds.reduce(func(still_inside, b): 
						return Geometry2D.is_point_in_polygon(b + current_pos_2d, polygon) and still_inside, true)
					var engine_pos = current_pos
					engine_pos.z = -engine_pos.z
					#engine_pos.x -= position_manager.center_node.position.x
					#engine_pos.z -= position_manager.center_node.position.z
					
					engine_pos.y = layer_composition.render_info.ground_height_layer.get_value_at_position(
							center[0] + engine_pos.x, (center[1] - engine_pos.z))
					print(engine_pos)
					print(center[0] + engine_pos.x, " - ", center[1] - engine_pos.z)
					
					if fully_inside:
						var new_object = object.duplicate()
						new_object.rotation.y = deg_to_rad(layer_composition.render_info.individual_rotation)
						new_object.position = engine_pos
						object_instances.append(new_object)
					
					# Go up and right
					current_pos += Vector3.BACK * distance_between_objects
				current_pos += Vector3.RIGHT * distance_between_objects


func apply_new_data():
	for child in get_children():
		child.queue_free()
	
	for object in object_instances:
		add_child(object)
	
	object_instances.clear()
	
	logger.info("Applied new PolygonObjectRenderer data for %s" % [name])


func _ready():
	super._ready()
