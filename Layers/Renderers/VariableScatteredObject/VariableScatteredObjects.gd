extends RenderChunk

var height_layer: GeoRasterLayer

var placement_formula: String
var placement_inputs: Dictionary[String, GeoRasterLayer]

var placement_min_radius: float
var placement_max_radius: float

var probability_layer: GeoFeatureLayer
var meshes: Dictionary[String, Dictionary]

var scale_layer: GeoRasterLayer

var rng := RandomNumberGenerator.new()
var initial_rng_state

var refine_load_distance := 200

var object_to_mesh_name = {}
var mesh_name_to_mmi = {}

var mesh_name_to_transforms = {}

var fresh_multimeshes = {}

var is_detailed = true
var is_refine_load = false


func override_can_increase_quality(distance: float):
	return distance < refine_load_distance and not is_detailed


func override_increase_quality(distance: float):
	if distance < refine_load_distance and not is_detailed:
		is_detailed = true
		is_refine_load = true
		return true
	else:
		return false


func override_decrease_quality(distance: float):
	if distance > refine_load_distance and is_detailed:
		is_detailed = false
		return true
	else:
		return false


func _ready():
	super._ready()
	
	#$LIDOverlayViewport.set_resolution(size)  # 1m resolution
	#$LIDOverlayViewport.set_size(size)
	
	## FIXME: This causes the first load to be practically redundant
	#$LIDOverlayViewport.update_done.connect(func():
		#build(get_parent().get_parent().center[0], get_parent().get_parent().center[1])
	#)
	
	create_multimeshes()


func create_multimeshes():
	rng.seed = name.hash()
	initial_rng_state = rng.state
	
	object_to_mesh_name = {}
	mesh_name_to_mmi = {}

	mesh_name_to_transforms = {}

	fresh_multimeshes = {}
	
	# Create MultiMeshes
	for mesh_name in meshes.keys():
		if not mesh_name in mesh_name_to_mmi:
			var mmi := MultiMeshInstance3D.new()
			# Set correct layer mask so streets are not rendered onto trees
			mmi.set_layer_mask_value(1, false)
			mmi.set_layer_mask_value(3, true)
			mmi.name = mesh_name
			
			mesh_name_to_mmi[mesh_name] = mmi
			
			# For debugging:
			if OS.is_debug_build():
				mmi.add_child(preload("res://addons/parentshaderupdater/PSUGatherer.tscn").instantiate())
			
			add_child(mmi)


func rebuild_aabb(node):
	var aabb = AABB(global_transform.origin - position - Vector3(size / 2.0, 0.0, size / 2.0), Vector3(size, 100000, size))
	node.set_custom_aabb(aabb)


func override_build(center_x, center_y):
	mesh_name_to_transforms = {}
	fresh_multimeshes = {}
	
	for mesh_name in meshes.keys():
		fresh_multimeshes[mesh_name] = MultiMesh.new()
		
		if is_detailed or not "billboard" in meshes[mesh_name]:
			fresh_multimeshes[mesh_name].mesh = load(meshes[mesh_name]["mesh"])
		else:
			fresh_multimeshes[mesh_name].mesh = load(meshes[mesh_name]["billboard"])
		
		fresh_multimeshes[mesh_name].transform_format = MultiMesh.TRANSFORM_3D
		fresh_multimeshes[mesh_name].instance_count = 0
		fresh_multimeshes[mesh_name].use_custom_data = true
			
		# Done more than once, but shouldn't matter
		mesh_name_to_transforms[mesh_name] = []
	
	var get_density = func(x, y):
		var formated_string = placement_formula
		while formated_string.find("$") >= 0:
			var begin_index = formated_string.find("$", 0)
			var length = formated_string.find("$", begin_index + 1) - begin_index
			var slice = formated_string.substr(begin_index + 1, length - 1)
			
			var layer: GeoRasterLayer = placement_inputs[slice]
			var value = layer.get_value_at_position(center_x + x + position.x, center_y - y - position.z)
			
			var value_string = "(%f)" % [value]  # Surround with parentheses to avoid errors with negative values
		
			formated_string = formated_string.left(begin_index) + value_string + formated_string.right(-(begin_index + length + 1))
	
		var expression = Expression.new()
		expression.parse(formated_string)
		
		var result = expression.execute()
		
		return result
	
	print("generating...")
	
	var sampler = VariablePoissonSampler2D.new()
	sampler.generate(get_density, placement_min_radius, placement_max_radius, size, size, 30)
	
	var object_locations = sampler.get_samples()
	
	print(object_locations.size())
	
	for location in object_locations:
		# Choose a random mesh based on the probability distribution within this chunk of the
		# probability layer
		# FIXME: use world position
		var probability_chunk = probability_layer.get_features_near_position(
			center_x + position.x + location.x,
			center_y + position.z + location.y,
			1.0, 0.0)[0]
		var attributes = probability_chunk.get_attributes()
		var probability_sum := 0.0
		
		for attribute_value in attributes.values():
			probability_sum += attribute_value
		
		var random_value = rng.randf_range(0.0, probability_sum)
		
		var mesh_name
		
		for attribute_name in attributes.keys():
			if attributes[attribute_name] < random_value:
				mesh_name = attribute_name
				break
		
		mesh_name_to_transforms[mesh_name].append(Transform3D()
				# FIXME: Make rotation optional
				# FIXME: apply scale from scale layer
				.scaled(Vector3.ONE * (meshes[mesh_name]["scale"] if "scale" in meshes[mesh_name] else 1.0))
				.rotated(Vector3.UP, PI * 0.5 * rng.randf_range(-1.0, 1.0)) \
				.translated(location)
		)
	
	for mesh_name in mesh_name_to_transforms.keys():
		fresh_multimeshes[mesh_name].instance_count = mesh_name_to_transforms[mesh_name].size()
		
		for i in range(mesh_name_to_transforms[mesh_name].size()):
			fresh_multimeshes[mesh_name].set_instance_transform(i, mesh_name_to_transforms[mesh_name][i])
	
	is_refine_load = false


func override_apply():
	for child in get_children():
		if child is MultiMeshInstance3D and (child.name not in fresh_multimeshes.keys() and child.multimesh):
			child.multimesh.instance_count = 0
	
	for mesh_name in fresh_multimeshes.keys():
		if fresh_multimeshes[mesh_name].instance_count > 0:
			mesh_name_to_mmi[mesh_name].visible = true
			mesh_name_to_mmi[mesh_name].multimesh = fresh_multimeshes[mesh_name].duplicate()
			rebuild_aabb(mesh_name_to_mmi[mesh_name])
		else:
			mesh_name_to_mmi[mesh_name].visible = false
