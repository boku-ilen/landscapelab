extends Node3D
class_name BuildingFactory


const hinge_material: ShaderMaterial = preload("res://addons/modular_buildings/Material/hinge_corner.tres")

# How much the building blocks may be scaled before using spacers
const MIN_SCALE := 0.9
const MAX_SCALE := 1.1
# How much deviation from 90 deg is allowed before using hinge-corner
const TOLERATE_90_DEG_DEVIATION = 0.01

## Build a building from footprint, floors and asset pack definition
##  footprint: Array[Vector2]
##  asset_pack: Dictionary[int:Array[AssetEntry]] mapping floor index (0 = ground) to possible assets
##  floors: total number of floors (height)
##  floor_height: vertical distance between floors (in metres)
static func build_building(building_root: Node3D, metadata: ModularBuildingMetadata) -> Node3D:
	# Long term it should probably be deterministic
	randomize()
	
	var edges: Array[Edge] = _footprint_to_edges(metadata.footprint)
	building_root.position = metadata.position
	if edges.is_empty():
		return building_root
	
	var module_indices := {}
	var overall_floor_height := 0.
	
	var corner_infos = _compute_corner_infos(edges)

	# create mapping of all meshes used to MultiMeshInstances that represent all instances within the building
	var mesh_multi_map = {}
	var all_meshes = []
	for floor_def in metadata.floor_definitions:
		for wall_def in floor_def.walls:
			all_meshes.append(wall_def.model)
		all_meshes.append(floor_def.spacer_block)
		all_meshes.append(floor_def.corner_90)
		all_meshes.append(floor_def.door)
	
	for mesh in all_meshes:
		if mesh in mesh_multi_map.keys():
			# skip already known meshes (e.g. for repeated layer definitions)
			continue
		mesh_multi_map[mesh] = MultiMeshInstance3D.new()
		mesh_multi_map[mesh].multimesh = MultiMesh.new()
		mesh_multi_map[mesh].multimesh.transform_format = MultiMesh.TRANSFORM_3D
		mesh_multi_map[mesh].multimesh.mesh = mesh
		# needs to be true so we can set instance parameters (angle,..) 
		mesh_multi_map[mesh].multimesh.use_custom_data = true
		# assumption: 2000 instances is enough for any single component mesh -> more instances means more memory!
		mesh_multi_map[mesh].multimesh.instance_count = 2000
		mesh_multi_map[mesh].multimesh.visible_instance_count = 0
		building_root.add_child(mesh_multi_map[mesh])

	# Iterate floors and edges
	var floor_num = 0
	while overall_floor_height < metadata.building_height:		
		# Meta
		
		var floor_assets = metadata.floor_definitions[min(floor_num, len(metadata.floor_definitions) - 1)]
		var floor_height = floor_assets.height
		
		var corner_mesh = mesh_multi_map[floor_assets.corner_90].multimesh
		for idx in corner_mesh.mesh.get_surface_count():
			var standard_mat = corner_mesh.mesh.surface_get_material(idx)
			var shader_mat: ShaderMaterial = hinge_material.duplicate(false)
			
			if standard_mat != null:
				standard_mat = standard_mat.duplicate()
				BuildingUtility.copy_standard_to_shader(standard_mat, shader_mat)
			
			corner_mesh.mesh.surface_set_material(idx, shader_mat)
		
		# map point-specified special features to the what edges are affected
		var point_edge_mapping = {}
		for feature_id in metadata.feature_positions:
			point_edge_mapping[feature_id] = []
			for point in metadata.feature_positions[feature_id]:
				var distances = []
				for i in edges.size():
					# get closest in-segment point
					var closest_p = Geometry2D.get_closest_point_to_segment(point, edges[i].p0, edges[i].p1)
					distances.append([i, (point - closest_p).length(), closest_p])
				# store which edge passes the closest
				distances.sort_custom(func (l1, l2): return l1[1] < l2[1])
				point_edge_mapping[feature_id].append([distances[0][0], distances[0][2]])
		
		# Create the corner pieces, the edges will be updated according to they
		# mesh extent (to guarantee no overlap)
		for i in edges.size():
			var edge_current = _populate_corner(
				edges[i], 
				corner_mesh, 
				corner_infos[i],
				overall_floor_height)
			
			# Populate the edges with modules
			
			# for the special feature points belonging to this edge, we pass their on-segment points 
			var points_on_edge: Dictionary[String, Array] = {}
			for k in metadata.feature_positions:
				points_on_edge.set(k, [])
				for point_i in metadata.feature_positions[k].size():
					if point_edge_mapping[k][point_i][0] == i:
						points_on_edge[k].append(point_edge_mapping[k][point_i][1])
			
			# To ensure a uniform distribution along the floors, we also store the chosen modules
			module_indices = _compute_edges(
				edge_current.p0,
				edge_current.p1, 
				overall_floor_height, 
				floor_assets.walls, 
				floor_assets.spacer_block,
				module_indices,
				mesh_multi_map,
				points_on_edge)
		
		overall_floor_height += floor_height
		floor_num += 1
		
		# repeat until we've reached or exceeded the knwon height of the building
		if overall_floor_height >= metadata.building_height:
			break
	
	return building_root

# Returns the new edge with regard to the corner
static func _populate_corner(
	edge_i: Edge,
	corner_mesh: MultiMesh, 
	corner_info_i: Dictionary,
	overall_floor_height: float) -> Edge:
	# Create a hinge corner asset from the mesh
	var next_instance_index = corner_mesh.visible_instance_count
	corner_mesh.visible_instance_count += 1
	
	
	# Cached asset extents
	var asset_extent = ModuleSpecs.get_module_spec(corner_mesh.mesh).asset_extent
	
	# Create a new edge that respects the extent of the corner asset
	var subtrahend_0 = edge_i.dir * asset_extent.x 
	var subtrahend_1 = edge_i.dir * asset_extent.y
	

	var corner_transform = Transform3D()\
		.translated(corner_info_i["position"])\
		.looking_at(corner_info_i.position + Vector3(corner_info_i.direction.x, 0, corner_info_i.direction.y) * 5)\
		.translated(Vector3.UP * overall_floor_height)#\

	corner_mesh.set_instance_transform(next_instance_index, corner_transform)
	corner_mesh.set_instance_custom_data(next_instance_index, Color(corner_info_i["angle"], 0, 0, 0))
	
	return Edge.new(edge_i.p0 + subtrahend_0, edge_i.p1 - subtrahend_1)

# Calculate the mean (middle) angle between two angles in radians.
static func _mean_angle(alpha: float, beta: float)-> float:
	var smallest = min(alpha, beta) + PI
	var largest = max(alpha, beta) + PI
	var result = smallest + (largest - smallest) / 2
	# special case: distance via the wrap point 2*PI+x === 0+x smaller than straight distance
	# theoretically ambiguous at exactly largest-smallest = PI
	if 2*PI - largest + smallest < largest - smallest and not largest - smallest - PI < 0.0001:
		result = smallest - (2*PI - largest + smallest) / 2
	return result - PI

static func _compute_corner_infos(edges: Array[Edge]) -> Array[Dictionary]:
	var corner_infos: Array[Dictionary] = []
	corner_infos.resize(edges.size())
	for i in edges.size():
		# Set dict
		corner_infos[i] = {}
		
		# Determine the angle to the next edge 
		var edge_current: Edge = edges[i]
		var edge_next: Edge = edges[(i+1) % edges.size()]

		corner_infos[i]["angle"] = (edge_current.dir).angle_to(edge_next.dir)
		
		# Correct transformation (position and rotation)
		var corner_position = edge_current.p1
		corner_infos[i]["position"] = Vector3(corner_position.x, 0, corner_position.y)
		
		corner_infos[i]["direction"] = Vector2.from_angle(_mean_angle(edge_current.dir.angle(), edge_next.dir.angle()))
		
	return corner_infos


## Populate a single edge with facade modules
static func _instance_module(multi_mesh: MultiMesh, module_width: float, scale_x: float,
		p1: Vector2, dir: Vector2, cursor: float, overall_floor_height: float, edge_vec: Vector2, index: int) -> void:
	
	var new_instance_id = multi_mesh.visible_instance_count
	multi_mesh.visible_instance_count += 1

	# Position centre‑line of segment along edge
	var off: Vector2 = dir * (cursor + module_width * scale_x * 0.5)
	
	# Aim outward (perpendicular to edge)
	var look_dir = Vector3(edge_vec.x, overall_floor_height, edge_vec.y).cross(Vector3.UP)
	var instance_transform = Transform3D()\
		.translated(Vector3(p1.x + off.x, overall_floor_height, p1.y + off.y))\
		.looking_at(look_dir + Vector3(p1.x + off.x, overall_floor_height, p1.y + off.y))
	
	multi_mesh.set_instance_transform(
		new_instance_id, 
		instance_transform
	)

# ------------------------------------------------
# _populate_edge with balanced spacers
# ------------------------------------------------
static func _compute_edges(p1: Vector2, p2: Vector2,
		overall_floor_height: float, floor_assets: Array[WallTileDefinition], spacer_block: Mesh, module_indices: Dictionary, multi_mesh_map: Dictionary, feature_offsets: Dictionary[String, Array]) -> Dictionary:
	var edge_vec: Vector2 = p2 - p1
	var edge_length: float = edge_vec.length()
	if edge_length < 0.01:
		return module_indices
	var dir: Vector2 = edge_vec.normalized()

	var spacer_width: float = spacer_block.get_aabb().size.x

	# ------------------------
	# 1) Choose main modules   
	# ------------------------
	# We need to store the modules until we know how many of them can fit
	var modules: Array = []
	
	# To ensure a uniform distribution along the floors, store the indices
	#var module_indices_set = floor_assets in module_indices
	
	var current_block_index := 0
	
	# Store how much width we processed altogether until now
	var used_width := 0.0
	
	var use_fillers := false
	var spacers := {"left": [], "right": [], "scale": 1.}
	var module_scale := 1.0
	var last_module_index = -1
	while not floor_assets.is_empty():
		var random_index: int = last_module_index
		var valid_found = false
		
		# check if we have a type of module to repeat from below
		for wall_def_i in len(floor_assets):
			var wall_def = floor_assets[wall_def_i]
			if len(modules) in module_indices.keys():
				valid_found = wall_def.facade_feature_id == module_indices[len(modules)].facade_feature_id and wall_def.facade_feature_id != ""
				if valid_found:
					# this spot had a module type last layer for which we have an equivalent
					random_index = wall_def_i
					break
		
		# randomly choose with a biased distribution
		while not valid_found:
			var biased_random = []
			for wall_tile_i in range(len(floor_assets)):
				biased_random.append({"bias": floor_assets[wall_tile_i].probability * randf(), "index": wall_tile_i})
			biased_random.sort_custom(func (a,b): return a["bias"] > b["bias"])
			random_index = biased_random[0]["index"]
			if last_module_index < 0:
				break
			valid_found = floor_assets[random_index].may_repeat or random_index != last_module_index
		last_module_index = random_index
		var mesh: Mesh = floor_assets[random_index].model
		
		var module_width := mesh.get_aabb().size.x
		
		# Module is overriden if we need a feature specified by geodata point at this spot
		var potential_positioned_features = floor_assets.filter(func (w): return w.facade_feature_id in feature_offsets.keys())
		if len(potential_positioned_features) > 0:
			# candidate for placement, check if close enough
			var candidate_mesh: Mesh = potential_positioned_features[0].model
			var candidate_width = candidate_mesh.get_aabb().size.x

			if feature_offsets[potential_positioned_features[0].facade_feature_id].any(func (off): return (off - (p1 + ((p2-p1).normalized()) * (used_width + candidate_width / 2))).length() < candidate_width / 2):
				mesh = candidate_mesh
				last_module_index = floor_assets.find(potential_positioned_features[0])
				module_width = candidate_width
		
		# save chosen module for future layers
		module_indices[len(modules)] = floor_assets[last_module_index]

		if used_width + module_width > edge_length:
			break
			
		modules.append({"mesh": mesh, "width": module_width})
		used_width += module_width
		current_block_index += 1

	if use_fillers:
		spacers = _get_spacers(edge_length, used_width, spacer_width)

	# ------------------------
	# 2) Instantiate modules   
	# ------------------------
	var cursor := 0.0

	# 2a) Leading spacers
	var spacer_stretch_factor = (edge_length - used_width) / spacer_width * 0.5
	var spacer_current_index = multi_mesh_map[spacer_block].multimesh.visible_instance_count
	multi_mesh_map[spacer_block].multimesh.visible_instance_count += 2
	var look_dir = Vector3(edge_vec.x, overall_floor_height, edge_vec.y).cross(Vector3.UP)
	var spacer_current_offset: Vector2 = dir * (cursor + (edge_length - used_width) * 0.25)
	cursor += (edge_length - used_width) * 0.5

	multi_mesh_map[spacer_block].multimesh.set_instance_transform(spacer_current_index, Transform3D()\
		.translated(Vector3(p1.x + spacer_current_offset.x, overall_floor_height, p1.y + spacer_current_offset.y))\
		.looking_at(look_dir + Vector3(p1.x + spacer_current_offset.x, overall_floor_height, p1.y + spacer_current_offset.y)))
	
	# spacer width controlled by shader via instance data
	multi_mesh_map[spacer_block].multimesh.set_instance_custom_data(spacer_current_index, Color(spacer_stretch_factor, 0.0,0.0,0.0))

	# 2b) Main building modules
	var index := 0
	for m in modules:
		_instance_module(multi_mesh_map[m["mesh"]].multimesh, m["width"], module_scale,
			p1, dir, cursor, overall_floor_height, edge_vec, index)
		cursor += m.width * module_scale
		index += 1
	
	# 2c) ending spacers
	spacer_current_offset = dir * (cursor + (edge_length - used_width) * 0.25)
	cursor += (edge_length - used_width) * 0.5
	spacer_current_index += 1
	multi_mesh_map[spacer_block].multimesh.set_instance_transform(spacer_current_index, Transform3D()\
		.translated(Vector3(p1.x + spacer_current_offset.x, overall_floor_height, p1.y + spacer_current_offset.y))\
		.looking_at(look_dir + Vector3(p1.x + spacer_current_offset.x, overall_floor_height, p1.y + spacer_current_offset.y)))
	multi_mesh_map[spacer_block].multimesh.set_instance_custom_data(spacer_current_index, Color(spacer_stretch_factor, 0.0,0.0,0.0))
	return module_indices


static func _get_spacers(edge_length: float, used_width: float, spacer_width: float):
	assert(spacer_width != 0.0, "Not a valid spacer-element")
	
	# with dynamically sized spacers, each side takes half the remaining space
	var remaining_edge = max(edge_length - used_width, 0.0)

	return {"left": remaining_edge / spacer_width * 0.5, "right": remaining_edge / spacer_width * 0.5, "scale": 1}


static func _footprint_to_edges(footprint: Array[Vector2]) -> Array[Edge]:
	if Geometry2D.is_polygon_clockwise(footprint): 
		footprint.reverse()
	
	if footprint.size() < 3:
		push_error("Footprint must have at least 3 vertices")
		return []
	
	# Create edge list
	var edges: Array[Edge] = []
	for i in range(footprint.size()):
		edges.push_back(Edge.new(footprint[i], footprint[(i+1)%footprint.size()]))
	
	return edges
