extends Node3D
class_name ModularBuilding

var metadata_instance: ModularBuildingMetadata
var graphs_by_floor: Array[BuildingGraphRunner.RunnableNode]
var feature: GeoFeature
var material_table: Dictionary[String, Material]
var rng := RandomNumberGenerator.new()
var last_lod := BuildingFactory.BuildingDetail.Billboard
var layer_composition: LayerComposition
var building_metadata: BuildingMetadata

var current_instance = null
var addon_layers: Dictionary
var addon_objects = {}

var refine_ridge_meshes = [
	preload("res://Buildings/Components/Roofs/Resources/RidgeCap_Rect_Large.obj"),
	preload("res://Buildings/Components/Roofs/Resources/RidgeCap_Pentagonal_Large.obj"),
	preload("res://Buildings/Components/Roofs/Resources/RidgeCap_Round_Large.obj"),
	preload("res://Buildings/Components/Roofs/Resources/RidgeCap_Rect_Small.obj"),
	preload("res://Buildings/Components/Roofs/Resources/RidgeCap_Round_Large_Overhang.obj"),
	preload("res://Buildings/Components/Roofs/Resources/RidgeCap_Round_Small.obj"),
	]

var refine_gutter_mesh = preload("res://Buildings/Components/Roofs/Resources/Gutters.res")


func _init(modular_metadata: ModularBuildingMetadata, geo_metadata: BuildingMetadata, node_graphs: Array[BuildingGraphRunner.RunnableNode], materials: Dictionary[String, Material], geo_feature: GeoFeature, composition: LayerComposition, addon_ls, addon_objs) -> void:
	metadata_instance = modular_metadata
	graphs_by_floor = node_graphs
	feature = geo_feature
	material_table = materials
	rng.seed = feature.get_id()
	layer_composition = composition
	addon_layers = addon_ls
	addon_objects = addon_objs
	building_metadata = geo_metadata

func construct_with_lod(lod_level: BuildingFactory.BuildingDetail):
	last_lod = lod_level


	var data_sources: Dictionary[String, NodeDataSource] = {
		"prev_module_id": FixedInputDataSource.new("prev_id"),
		"below_module_id": FixedInputDataSource.new("low_id"),
		"edge_dist": FixedInputDataSource.new(4.2),
		"edge_length": FixedInputDataSource.new(22.3),
		"edge_normal": FixedInputDataSource.new(Vector3(1,0,1)),
		"is_most_distant_edge": FixedInputDataSource.new(false),
		"floor_num": FixedInputDataSource.new(2.0),
		"floor_amount": FixedInputDataSource.new(5.0),
		"all_module_ids": FixedInputDataSource.new(["x"]),
		"rand": FixedInputDataSource.new(0.1),
		"geo_feature": FixedInputDataSource.new(feature) 
	}
	var root_node = Node3D.new()
	add_child(root_node)
	BuildingFactory.build_building(root_node, metadata_instance, graphs_by_floor, data_sources, material_table, feature, lod_level)
	# roof construction: only at full detail
	if lod_level == BuildingFactory.BuildingDetail.Full:
		# setup old roof
		var roof_and_material = RoofFactory.prepare_roof(
				layer_composition,
				feature,
				addon_layers,
				addon_objects,
				building_metadata,
				true,
				{"prefer_pointed_roof": true})
	
		# slightly randomize footprint for robustness (avoid precise 90° angles, ...)
		var randomized_footprint: Array[Vector2]
		randomized_footprint.assign(metadata_instance.footprint.map(
				func (x): return x + Vector2(rng.randf_range(0.01, 0.02), rng.randf_range(0.01, 0.02))
		))
	
		var roof_mat: StandardMaterial3D = roof_and_material["material"].material0.duplicate()
		roof_mat.albedo_color = roof_and_material["roof"].color
	
		# compute straight skeleton roof
		var roof := StraightSkeleton.get_mesh(randomized_footprint, metadata_instance.roof_height, roof_mat, 1)
	
		# determine roof y position
		var actual_height = 0.0
		var floor_num = 0
		while actual_height < metadata_instance.building_height:
			actual_height += metadata_instance.floor_definitions[min(floor_num, metadata_instance.floor_definitions.size() - 1)].height
	
			floor_num += 1
	
		# if straight skeleton result is provably valid, use it
		if not roof.broken and not RoofFactory.requires_flat_roof(feature, layer_composition, building_metadata):
			var outer_footprint = Geometry2D.offset_polygon(randomized_footprint, 0.9)[0]
			var saved_footprint: Array[Vector2] = []
			saved_footprint.append_array(outer_footprint)
	
			var roof_node := MeshInstance3D.new()
			roof_node.mesh = roof.mesh
			add_child(roof_node)
			roof_node.position.y = actual_height
			
			var roof_data = {
				"building": self,
				"roof": roof.skeleton_info,
				"roof_node": roof_node,
				"is_refined": false,
				"height": roof.mesh.get_aabb().size.y,
				"refine_meshes": [],
				"color": roof_and_material["roof"].color,
				"footprint": saved_footprint,
				"original_footprint": saved_footprint
			}
			refine_roof(roof_data)
		# TODO: Should we do something like this? It would probably be "correct", but seems to make buildings too small
		# actual_height += roof.mesh.get_aabb().size.y
		else:
			# fallback to old roofs otherwise
			var roof_surface_material_callback: Callable = RoofFactory.set_surface_overrides.bind(roof_and_material["roof"], roof_and_material["material"])
			var roof_component = roof_and_material["roof"]
			add_child(roof_component)
			roof_component.build(PackedVector2Array(building_metadata.footprint))
			roof_component.position.y = actual_height
			roof_surface_material_callback.call()

		scale.y = clamp((metadata_instance.building_height + building_metadata.roof_height_stdev) / actual_height, 0.65, 1.35)
	
	
	if current_instance != null:
		current_instance.queue_free()
		remove_child(current_instance)
	current_instance = root_node

func refine_roof(roof: Dictionary)-> Dictionary:
	roof["is_refined"] = true
	#logger.info("refining " + roof["building"].name)
	var skeleton_data: StraightSkeleton.StraightSkeletonInfo = roof["roof"]

	# ridge caps along bisector lines
	var bisectors := skeleton_data.bisectors
	var refine_ridge_mesh = refine_ridge_meshes[randi_range(0, refine_ridge_meshes.size() - 1)]
	var ridge_cap_multimesh = MultiMeshInstance3D.new()
	ridge_cap_multimesh.multimesh = MultiMesh.new()
	ridge_cap_multimesh.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	ridge_cap_multimesh.multimesh.mesh = refine_ridge_mesh
	ridge_cap_multimesh.multimesh.instance_count = bisectors.size()
	ridge_cap_multimesh.multimesh.visible_instance_count = bisectors.size()
	var base_material = StandardMaterial3D.new()
	base_material.albedo_color = roof["color"]
	ridge_cap_multimesh.material_overlay = base_material


	# ridge caps along bisectors
	for bisector_i in bisectors.size():
		var bisector := bisectors[bisector_i]
		# downscale 2D coordinates (StraightSkeleton get_mesh() upscales by 200 to reduce float rounding error)
		var origin := Vector3(bisector.origin.x / 200, (bisector.start_t / skeleton_data.max_t) * roof["height"], bisector.origin.y / 200)
		var endpoint := Vector3(bisector.endpoint.x / 200, (bisector.end_t / skeleton_data.max_t) * roof["height"], bisector.endpoint.y / 200)
		var midpoint := (origin + endpoint) * 0.5
		var aabb: AABB = refine_ridge_mesh.get_aabb()
		var mesh_length: float = aabb.size.z

		var scale_z := origin.distance_to(endpoint) / mesh_length

		# skip if midpoint and origin are in the same place (i.e. line has near 0 length)
		if not origin.distance_squared_to(midpoint) < 0.001:
			ridge_cap_multimesh.multimesh.set_instance_transform(
					bisector_i,
					Transform3D().translated(midpoint + Vector3.UP * (roof["roof_node"].position.y))\
						.looking_at(origin + Vector3.UP * (roof["roof_node"].position.y))\
						.scaled_local(Vector3(1,1,scale_z))
			)

	# gutters offset outward from roof edge
	var offset_footprint = Geometry2D.offset_polygon(roof["footprint"], refine_gutter_mesh.get_aabb().size.x / 8, Geometry2D.JOIN_SQUARE)[0]

	var gutter_multimesh := MultiMeshInstance3D.new()
	gutter_multimesh.multimesh = MultiMesh.new()
	gutter_multimesh.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	gutter_multimesh.multimesh.mesh = refine_gutter_mesh#.duplicate()
	gutter_multimesh.multimesh.instance_count = offset_footprint.size() + 1
	gutter_multimesh.multimesh.visible_instance_count = gutter_multimesh.multimesh.instance_count
	gutter_multimesh.material_overlay = base_material

	# gutters around outside edge
	for vert_i in offset_footprint.size():
		var edge_start: Vector2 = offset_footprint[vert_i]
		var edge_end: Vector2 = offset_footprint[(vert_i + 1) % offset_footprint.size()]
		var from = Vector3(edge_start.x, roof["roof_node"].position.y - 0.25, edge_start.y)
		var to = Vector3(edge_end.x, roof["roof_node"].position.y - 0.25, edge_end.y)
		var mesh_length = refine_gutter_mesh.get_aabb().size.z
		gutter_multimesh.multimesh.set_instance_transform(
				vert_i,
				Transform3D().translated((from + to) * 0.5)\
					.looking_at(to, Vector3.DOWN)\
					.scaled_local(Vector3(0.25,0.25,from.distance_to(to) / mesh_length))
		)

	# drain pipe - TODO model
	gutter_multimesh.multimesh.set_instance_transform(
			roof["footprint"].size(),
			Transform3D().translated(Vector3(roof["footprint"][0].x, roof["roof_node"].position.y * 0.5 - 0.2, roof["footprint"][0].y))\
				.scaled_local(Vector3(0.3, roof["roof_node"].position.y / refine_gutter_mesh.get_aabb().size.z, 0.3))\
				.rotated_local(Vector3.RIGHT, -PI/2)
	)


	gutter_multimesh.name = "gutter_ref"
	ridge_cap_multimesh.name = "roof_ref"
	(roof["building"] as Node3D).add_child.call_deferred(ridge_cap_multimesh)
	(roof["building"] as Node3D).add_child.call_deferred(gutter_multimesh)
	roof["refine_meshes"].append(ridge_cap_multimesh)
	roof["refine_meshes"].append(gutter_multimesh)
	return roof