extends LayerRenderer


var radius = 10000
var max_features = 2000
var distance_between_objects = 10

var object_instances = []

onready var polygon_layer = layer.render_info.polygon_layer
onready var object_layer: FeatureLayer = layer.render_info.object_layer


func load_new_data():
	# Extract features
	var features = polygon_layer.get_features_near_position(center[0], center[1], radius, max_features)
	
	# Create the objects inside each individual polygon
	for poly_feature in features:
		var polygon = poly_feature.get_outer_vertices()
		
		# Find mid point and add objects from there
		var current_pos = Vector2(0,0)
		for vertex in polygon: current_pos += vertex
		current_pos /= polygon.size()
		
		var object: Spatial = layer.render_info.object.instance()
		
		while true:
			# Predefined points in the object that have to be inside the polygon
			# (i.e. in most cases some form of foothold)
			for foothold in object.get_footholds():
				# Add relative foothold position to absolute object position
				var foothold_pos = (current_pos + foothold.translation) * layer.render_info.individual_rotation 
				var point_feature = object_layer.create_feature()
				# TODO: implement this function
				point_feature.set_position(foothold_pos)
				
				if point_feature.intersects_with(poly_feature):
					var new_object = layer.render_info.object.instance()
					new_object.rotation_degrees.y = layer.render_info.individual_rotation
					new_object.translation = current_pos
					object_instances.append(new_object)
				else:
					break
				
				# TODO: go in all directions 
				current_pos += Vector3.RIGHT * distance_between_objects


func apply_new_data():
	for child in get_children():
		child.queue_free()
	
	for object in object_instances:
		add_child(object)
	
	object_instances.clear()
