extends LayerCompositionRenderer


var radius = 10000
var max_features = 2000
var distance_between_objects = 10
# Stores if the object-layer has been processed previously
var processed = false
var very_large_number = 999999.0

var object_instances = []


func full_load():
	var polygon_layer: GeoFeatureLayer = layer_composition.render_info.polygon_layer
	var object_layer: GeoFeatureLayer = layer_composition.render_info.object_layer
	
	# Extract features
	var features = polygon_layer.get_features_near_position(center[0], center[1], radius, max_features)
	
	# Create the objects inside each individual polygon
	for poly_feature in features:
		var polygon = poly_feature.get_outer_vertices()
		
		# Find left-most and bottom-most and right-most, top-most point in polygon
		var min_pos = Vector3(very_large_number, 0, very_large_number)
		var max_pos = Vector3(-very_large_number, 0, -very_large_number)
		for vertex in polygon: 
			min_pos.x = vertex.x if vertex.x < min_pos.x else min_pos.x
			min_pos.z = vertex.y if vertex.y < min_pos.z else min_pos.z
			
			max_pos.x = vertex.x if vertex.x > max_pos.x else max_pos.x
			max_pos.z = vertex.y if vertex.y > max_pos.z else max_pos.z
		
		var object: Node3D = layer_composition.render_info.object.instantiate()
		
		var current_pos = min_pos
		while current_pos.x <= max_pos.x:
			current_pos.z = min_pos.z
			while current_pos.z <= max_pos.z:
				# Predefined points in the object that have to be inside the polygon
				# (i.e. in most cases some form of foothold)
				var fully_inside = true
				for foothold in object.get_node("Footholds").get_children():
					# Add relative foothold position to absolute object position
					var foothold_pos = (current_pos + foothold.position)
					var point_feature = object_layer.create_feature()
					#point_feature.set_offset_vector3(Vector3(foothold_pos.x, 0, foothold_pos.z), -center[0], 0, -center[1])
					point_feature.set_vector3(Vector3(foothold_pos.x, 0, foothold_pos.z))
					
					if not poly_feature.intersects_with(point_feature):
						fully_inside = false
				
				if fully_inside:
					var new_object = layer_composition.render_info.object.instantiate()
					new_object.rotation.y = deg_to_rad(layer_composition.render_info.individual_rotation)
					new_object.position = current_pos
					new_object.position.y = layer_composition.render_info.ground_height_layer.get_value_at_position(
						center[0] + current_pos.x, center[1] - current_pos.z)
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


func _ready():
	super._ready()
