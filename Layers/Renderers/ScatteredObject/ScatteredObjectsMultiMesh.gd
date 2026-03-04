extends RenderChunk

var height_layer: GeoRasterLayer
var scatter_layer: GeoRasterLayer
var objects: Dictionary

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
	
	$LIDOverlayViewport.set_resolution(size)  # 1m resolution
	$LIDOverlayViewport.set_size(size)
	
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
	for object_name in objects.keys():
		if not object_name in mesh_name_to_mmi:
			var mmi := MultiMeshInstance3D.new()
			# Set correct layer mask so streets are not rendered onto trees
			mmi.set_layer_mask_value(1, false)
			mmi.set_layer_mask_value(3, true)
			mmi.name = object_name
			
			mesh_name_to_mmi[object_name] = mmi
			
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
	
	for object_name in objects.keys():
		fresh_multimeshes[object_name] = MultiMesh.new()
		
		if is_detailed or not "billboard" in objects[object_name]:
			fresh_multimeshes[object_name].mesh = load(objects[object_name]["mesh"])
		else:
			fresh_multimeshes[object_name].mesh = load(objects[object_name]["billboard"])
		
		fresh_multimeshes[object_name].transform_format = MultiMesh.TRANSFORM_3D
		fresh_multimeshes[object_name].instance_count = 0
		fresh_multimeshes[object_name].use_custom_data = true
			
		# Done more than once, but shouldn't matter
		mesh_name_to_transforms[object_name] = []
	
	for object_name in objects.keys():
		var object = objects[object_name]
		
		var location_getter = ScatteredLocationsGetter.new(
			center_x,
			center_y,
			size,
			object["density_x"] if "density_x" in object else object["density"],
			object["density_y"] if "density_y" in object else object["density"],
			object.get("randomness", 1.0),
			scatter_layer,
			height_layer,
			object["condition"]
			# $LIDOverlayViewport.get_texture().get_image()
		)
		
		var object_locations = location_getter.get_object_locations()
		
		for location in object_locations:
			mesh_name_to_transforms[object_name].append(Transform3D()
					# FIXME: Make rotation optional
					.scaled(Vector3.ONE * (objects[object_name]["scale"] if "scale" in objects[object_name] else 1.0))
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
