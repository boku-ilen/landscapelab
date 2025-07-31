extends RenderChunk

var height_layer: GeoRasterLayer
var scatter_layer: GeoRasterLayer
var objects: Dictionary

var rng := RandomNumberGenerator.new()
var initial_rng_state

var refine_load_distance = 500

var object_to_mesh_name = {}
var mesh_name_to_mmi = {}

var mesh_name_to_transforms = {}

var fresh_multimeshes = {}

var is_detailed = true
var is_refine_load = false


#func override_can_increase_quality(distance: float):
	#return distance < refine_load_distance and not is_detailed
#
#
#func override_increase_quality(distance: float):
	#if distance < refine_load_distance and not is_detailed:
		#is_detailed = true
		#is_refine_load = true
		#return true
	#else:
		#return false
#
#
#func override_decrease_quality(distance: float):
	#if distance > refine_load_distance and is_detailed:
		#is_detailed = false
		#return true
	#else:
		#return false


func _ready():
	super._ready()
	create_multimeshes()


func create_multimeshes():
	rng.seed = name.hash()
	initial_rng_state = rng.state
	
	object_to_mesh_name = {}
	mesh_name_to_mmi = {}

	mesh_name_to_transforms = {}

	fresh_multimeshes = {}
	
	# Create MultiMeshes
	for object_name in objects.keys():
		if not object_name in mesh_name_to_mmi:
			var mmi := MultiMeshInstance3D.new()
			# Set correct layer mask so streets are not rendered onto trees
			mmi.set_layer_mask_value(1, false)
			mmi.set_layer_mask_value(3, true)
			mmi.name = object_name
			
			mesh_name_to_mmi[object_name] = mmi
			
			# For debugging:
			mmi.add_child(preload("res://addons/parentshaderupdater/PSUGatherer.tscn").instantiate())
			
			add_child(mmi)
	
	# FIXME: Optional Billboard LOD System?
	#var mmi := MultiMeshInstance3D.new()
	## Set correct layer mask so streets are not rendered onto trees
	#mmi.set_layer_mask_value(1, false)
	#mmi.set_layer_mask_value(3, true)
	#mmi.name = "Billboard"
	#mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	#
	## For debugging:
	#mmi.add_child(preload("res://addons/parentshaderupdater/PSUGatherer.tscn").instantiate())
	#
	#mesh_name_to_mmi["Billboard"] = mmi
	#add_child(mmi)


func rebuild_aabb(node):
	var aabb = AABB(global_transform.origin - position - Vector3(size / 2.0, 0.0, size / 2.0), Vector3(size, 100000, size))
	node.set_custom_aabb(aabb)


func override_build(center_x, center_y):
	mesh_name_to_transforms = {}
	fresh_multimeshes = {}
	
	if is_detailed:
		for object_name in objects.keys():
			fresh_multimeshes[object_name] = MultiMesh.new()
			fresh_multimeshes[object_name].mesh = load(objects[object_name]["mesh"])
			fresh_multimeshes[object_name].transform_format = MultiMesh.TRANSFORM_3D
			fresh_multimeshes[object_name].instance_count = 0
			fresh_multimeshes[object_name].use_custom_data = true
			
			# Done more than once, but shouldn't matter
			mesh_name_to_transforms[object_name] = []
	#else:
		#var mesh_name = "Billboard"
		#fresh_multimeshes[mesh_name] = MultiMesh.new()
		#fresh_multimeshes[mesh_name].mesh = billboard_mesh
		#fresh_multimeshes[mesh_name].transform_format = MultiMesh.TRANSFORM_3D
		#fresh_multimeshes[mesh_name].instance_count = 0
		#fresh_multimeshes[mesh_name].use_custom_data = true
		#
		## Done more than once, but shouldn't matter
		#mesh_name_to_transforms[mesh_name] = []
		#mesh_name_to_color[mesh_name] = []
		#mesh_name_to_custom_data[mesh_name] = []
	
	for object_name in objects.keys():
		var object = objects[object_name]
		
		var location_getter = ScatteredLocationsGetter.new(
			center_x,
			center_y,
			size,
			object["density"],
			object.get("randomness", 1.0),
			scatter_layer,
			height_layer,
			object["condition"]
		)
		
		var object_locations = location_getter.get_object_locations()
		
		# FIXME: Get scale based on other layer?
		#var instance_scale = feature.get_attribute("height1").to_float() * 1.3
		
		#if instance_scale < 1.0: continue
		#elif instance_scale < 5.0 and not is_detailed: continue

		for location in object_locations:
			mesh_name_to_transforms[object_name].append(Transform3D()
					# FIXME: Make rotation optional
					.rotated(Vector3.UP, PI * 0.5 * rng.randf_range(-1.0, 1.0)) \
					.translated(location)
			)
	
	for mesh_name in mesh_name_to_transforms.keys():
		fresh_multimeshes[mesh_name].instance_count = mesh_name_to_transforms[mesh_name].size()
		
		for i in range(mesh_name_to_transforms[mesh_name].size()):
			fresh_multimeshes[mesh_name].set_instance_transform(i, mesh_name_to_transforms[mesh_name][i])
			#fresh_multimeshes[mesh_name].set_instance_custom_data(i, mesh_name_to_custom_data[mesh_name][i])
	
	is_refine_load = false


func override_apply():
	for child in get_children():
		if child.name not in fresh_multimeshes.keys() and child.multimesh:
			child.multimesh.instance_count = 0
	
	for mesh_name in fresh_multimeshes.keys():
		if fresh_multimeshes[mesh_name].instance_count > 0:
			mesh_name_to_mmi[mesh_name].visible = true
			mesh_name_to_mmi[mesh_name].multimesh = fresh_multimeshes[mesh_name].duplicate()
			rebuild_aabb(mesh_name_to_mmi[mesh_name])
		else:
			mesh_name_to_mmi[mesh_name].visible = false
