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

var weather_manager: WeatherManager :
	get:
		return weather_manager
	set(new_weather_manager):
		# FIXME: Seems like there's a condition where this is called once with a null
		# weather manager. Not necessarily a problem since it's called again correctly
		# later, but feels like it shouldn't be necessary.
		if not new_weather_manager:
			return
		
		weather_manager = new_weather_manager
		
		if not weather_manager.wind_speed_changed.is_connected(_apply_new_wind_speed):
			weather_manager.wind_speed_changed.connect(_apply_new_wind_speed)
		
		if not weather_manager.wind_direction_changed.is_connected(_apply_new_wind_direction):
			weather_manager.wind_direction_changed.connect(_apply_new_wind_direction)
		
		_apply_new_wind()


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
	object_to_mesh_name = {}
	mesh_name_to_mmi = {}

	mesh_name_to_transforms = {}

	fresh_multimeshes = {}
	
	# Create MultiMeshes
	for mesh_name in meshes.keys():
		var mesh_path = meshes[mesh_name]["mesh"]
		
		if not mesh_path in mesh_name_to_mmi:
			var mmi := MultiMeshInstance3D.new()
			# Set correct layer mask so streets are not rendered onto trees
			mmi.set_layer_mask_value(1, false)
			mmi.set_layer_mask_value(3, true)
			mmi.name = mesh_name
			
			mesh_name_to_mmi[mesh_path] = mmi
			
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
	
	# Reset RNG to make results consistent as long as the underlying data does not change
	rng.seed = hash(global_position)
	rng.state = 0
	
	for mesh_name in meshes.keys():
		# We use the mesh path rather than the mesh name for indexing multimeshes.
		# That's because multiple indices may be mapped to the same mesh, in which case it's more
		# efficient to share a mesh between them.
		var mesh_path = meshes[mesh_name]["mesh"]
		fresh_multimeshes[mesh_path] = MultiMesh.new()
		
		# FIXME: Do we want to use this individual billboard logic, or force a shared billboard?
		# A shared billboard would probably be significantly more efficient since we would only 
		# need 1 multimesh in the distance, though this is a bit more practical
		if is_detailed or not "billboard" in meshes[mesh_name]:
			fresh_multimeshes[mesh_path].mesh = load(meshes[mesh_name]["mesh"])
		else:
			fresh_multimeshes[mesh_path].mesh = load(meshes[mesh_name]["billboard"])
		
		fresh_multimeshes[mesh_path].transform_format = MultiMesh.TRANSFORM_3D
		fresh_multimeshes[mesh_path].instance_count = 0
		fresh_multimeshes[mesh_path].use_custom_data = true
		
		# Reset the transform buffer
		mesh_name_to_transforms[mesh_path] = []
	
	# This is our custom function for getting the radius of additional points around an existing
	# point at the location x, y.
	# A larger radius means that points are spaced further apart at this location.
	# This renderer takes a custom formula with arbitrary raster layers for calculating this radius.
	var get_radius = func(x, y):
		var formated_string = placement_formula
		while formated_string.find("$") >= 0:
			var begin_index = formated_string.find("$", 0)
			var length = formated_string.find("$", begin_index + 1) - begin_index
			var slice = formated_string.substr(begin_index + 1, length - 1)
			
			var layer: GeoRasterLayer = placement_inputs[slice]
			var value = layer.get_value_at_position(center_x + (x - size / 2.0), center_y - (y - size / 2.0))
			
			var value_string = "(%f)" % [value]  # Surround with parentheses to avoid errors with negative values
		
			formated_string = formated_string.left(begin_index) + value_string + formated_string.right(-(begin_index + length + 1))
	
		var expression = Expression.new()
		expression.parse(formated_string)
		
		var result = expression.execute()
		
		return result
	
	# Generate points within a 2D rectangle from 0,0 to size,size
	var sampler = VariablePoissonSampler2D.new()
	sampler.generate(rng, get_radius, placement_min_radius, placement_max_radius, size, size, 30)
	
	var object_locations = sampler.get_samples()
	
	for location in object_locations:
		# These MultiMeshes are assumed to have their 0,0 in the center, not in the top left.
		# Therefore, we transform the locations.
		# Note: This corresponds to the coordinates used in `get_value_at_position` in `get_radius`.
		location -= Vector2(size / 2.0, size / 2.0)
		
		# Choose a random mesh based on the probability distribution within this chunk of the
		# probability layer
		var probability_chunk = probability_layer.get_features_near_position(
			center_x + location.x,
			center_y - location.y,
			1.0, 0.0)[0]
		var attributes = probability_chunk.get_attributes()
		
		# First, calculate the sum of all probabilities
		var probability_sum := 0.0
		for attribute_value in attributes.values():
			probability_sum += float(attribute_value)
		
		# Generate a random value
		var random_value = rng.randf_range(0.0, probability_sum)

		# Check into which "section" of the probability attributes this random value falls
		var mesh_name
		var counting_probability_sum := 0.0
		for attribute_name in attributes.keys():
			counting_probability_sum += float(attributes[attribute_name])
			if random_value <= counting_probability_sum:
				mesh_name = attribute_name
				break
		
		var height_here = height_layer.get_value_at_position(
			center_x + location.x,
			center_y - location.y
		)
		var scale_here = scale_layer.get_value_at_position(
			center_x + location.x,
			center_y - location.y
		)
		scale_here *= meshes[mesh_name]["scale"] if "scale" in meshes[mesh_name] else 1.0
		
		# Avoid very small instances
		if scale_here < 1.0: continue # TODO: Expose this minimum height
		
		var mesh_path = meshes[mesh_name]["mesh"]
		
		mesh_name_to_transforms[mesh_path].append(Transform3D()
				.scaled(Vector3.ONE * scale_here)
				# FIXME: Make rotation optional
				.rotated(Vector3.UP, PI * 0.5 * rng.randf_range(-1.0, 1.0))
				.translated(Vector3(location.x, height_here, location.y))
		)
	
	# Apply our mesh_name_to_transforms buffers to the actual multimeshes
	for mesh_path in mesh_name_to_transforms.keys():
		fresh_multimeshes[mesh_path].instance_count = mesh_name_to_transforms[mesh_path].size()
		
		for i in range(mesh_name_to_transforms[mesh_path].size()):
			fresh_multimeshes[mesh_path].set_instance_transform(i, mesh_name_to_transforms[mesh_path][i])
	
	is_refine_load = false


func override_apply():
	# Set empty areas to inactive
	for child in get_children():
		if child is MultiMeshInstance3D and (child.name not in fresh_multimeshes.keys() and child.multimesh):
			child.multimesh.instance_count = 0
	
	# Apply fresh multimeshes to the actual instances in the scene tree
	for mesh_name in fresh_multimeshes.keys():
		if fresh_multimeshes[mesh_name].instance_count > 0:
			mesh_name_to_mmi[mesh_name].visible = true
			mesh_name_to_mmi[mesh_name].multimesh = fresh_multimeshes[mesh_name].duplicate()
			rebuild_aabb(mesh_name_to_mmi[mesh_name])
		else:
			mesh_name_to_mmi[mesh_name].visible = false
	
	# TODO: Do we need to do this every override_apply? i.e., is it possible that new meshes have
	# been added here?
	_apply_new_wind()


func _apply_new_wind_speed(wind_speed: float):
	_apply_new_wind()


func _apply_new_wind_direction(wind_direction: int):
	_apply_new_wind()


func _apply_new_wind():
	for mmi in mesh_name_to_mmi.values():
		# It's possible that this instances does not have a multimesh yet (i.e. _ready hasn't been
		# called yet)
		if mmi.multimesh:
			var mesh = mmi.multimesh.mesh
			# Apply the wind speed shader parameter to all surface materials
			for surface_id in mesh.get_surface_count():
				var material = mesh.surface_get_material(surface_id)
				
				if material is ShaderMaterial:
					var force = Vector2.UP.rotated(deg_to_rad(weather_manager.wind_direction)) * weather_manager.wind_speed
					material.set_shader_parameter("wind_speed", force)
