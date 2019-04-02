tool
extends Node

func _ready():
	pass


# This will add all of the resources in a node into the passed
# in resource list.
# And this will return a dictionary containing pointing to the index
# where the resources the node needs are in the passed in resource list.
#
# We will just edit/add-to the passed in dictionary (dep_dict) and list (resources_list)
# directly.
func add_node_resources_to_list_and_dict(node, dep_dict, resources_list, resource_check_dict):
	
	# Store CUSTOM DATA in the node, if it has the following function:
	# DSCN_add_resources.
	if (node.has_method("DSCN_add_resources") == true):
		node.DSCN_custom_add_resources(node, dep_dict, resources_list);
	
	
	# *** All of the base-type/basic nodes ***
	
	if (node is Node):
		_add_resources_node(node, dep_dict, resources_list, resource_check_dict);
	if (node is CanvasItem):
		_add_resources_canvas_item(node, dep_dict, resources_list, resource_check_dict);
	if (node is Viewport):
		_add_resources_viewport(node, dep_dict, resources_list, resource_check_dict);
	if (node is AudioStreamPlayer):
		_add_resources_audio_stream_player(node, dep_dict, resources_list, resource_check_dict);
	if (node is WorldEnvironment):
		_add_resources_world_environment(node, dep_dict, resources_list, resource_check_dict);
	
	
	# *** All of the Node2D extending nodes ***
	if (node is Node2D):
		# Until there is a better way, we'll just do this manually in order of the
		# "Inheritied By" section of the documentation, found below:
		# http://docs.godotengine.org/en/3.0/classes/class_node2d.html?
		#
		# And then we'll add anything else that is missing!
		# The only nodes here are nodes that have resources to save.
		# Other nodes to not seem to have any resources to save.
		
		if (node is TouchScreenButton):
			_add_resources_touch_screen_button(node, dep_dict, resources_list, resource_check_dict);
		elif (node is Particles2D):
			_add_resources_particles2d(node, dep_dict, resources_list, resource_check_dict);
		elif (node is AnimatedSprite):
			_add_resources_animated_sprite(node, dep_dict, resources_list, resource_check_dict);
		elif (node is Light2D):
			_add_resources_light2d(node, dep_dict, resources_list, resource_check_dict);
		elif (node is Path2D):
			_add_resources_path2d(node, dep_dict, resources_list, resource_check_dict);
		elif (node is Line2D):
			_add_resources_line2d(node, dep_dict, resources_list, resource_check_dict);
		elif (node is AudioStreamPlayer2D):
			_add_resources_audio_stream_player2d(node, dep_dict, resources_list, resource_check_dict);
		elif (node is Sprite):
			_add_resources_sprite(node, dep_dict, resources_list, resource_check_dict);
		elif (node is CollisionShape2D):
			_add_resources_collision_shape2d(node, dep_dict, resources_list, resource_check_dict);
		elif (node is NavigationPolygonInstance):
			_add_resources_navigation_polygon_instance(node, dep_dict, resources_list, resource_check_dict);
		elif (node is Polygon2D):
			_add_resources_polygon2d(node, dep_dict, resources_list, resource_check_dict);
		elif (node is LightOccluder2D):
			_add_resources_light_occluder2d(node, dep_dict, resources_list, resource_check_dict);
		elif (node is TileMap):
			_add_resources_tilemap(node, dep_dict, resources_list, resource_check_dict);
	
	# *** All of the Control extending nodes ***
	if (node is Control):
		
		_add_resources_control(node, dep_dict, resources_list, resource_check_dict);
		
		if (node is TextureRect):
			_add_resources_texture_rect(node, dep_dict, resources_list, resource_check_dict);
		elif (node is VideoPlayer):
			_add_resources_video_player(node, dep_dict, resources_list, resource_check_dict);
		elif (node is NinePatchRect):
			_add_resources_nine_patch_rect(node, dep_dict, resources_list, resource_check_dict);
		elif (node is Button):
			_add_resources_button(node, dep_dict, resources_list, resource_check_dict);
		elif (node is TextureButton):
			_add_resources_texture_button(node, dep_dict, resources_list, resource_check_dict);
	
	# *** All of the Spatial extending nodes ***
	if (node is Spatial):
		
		_add_resources_spatial(node, dep_dict, resources_list, resource_check_dict);
		
		if (node is Camera):
			_add_resources_camera(node, dep_dict, resources_list, resource_check_dict);
		elif (node is CollisionShape):
			_add_resources_collision_shape(node, dep_dict, resources_list, resource_check_dict);
		elif (node is AudioStreamPlayer3D):
			_add_resources_audio_stream_player3d(node, dep_dict, resources_list, resource_check_dict);
		elif (node is Path):
			_add_resources_path(node, dep_dict, resources_list, resource_check_dict);
		elif (node is BakedLightmap):
			_add_resources_baked_lightmap(node, dep_dict, resources_list, resource_check_dict);
		elif (node is GIProbe):
			_add_resources_gi_probe(node, dep_dict, resources_list, resource_check_dict);
		
		elif (node is GeometryInstance):
			_add_resources_geometry_instance(node, dep_dict, resources_list, resource_check_dict);
			
			if (node is MultiMesh):
				_add_resources_multi_mesh(node, dep_dict, resources_list, resource_check_dict);
			elif (node is MeshInstance):
				_add_resources_mesh_instance(node, dep_dict, resources_list, resource_check_dict);
			elif (node is Particles):
				_add_resources_particles(node, dep_dict, resources_list, resource_check_dict);
			elif (node is AnimatedSprite3D):
				_add_resources_animated_sprite3d(node, dep_dict, resources_list, resource_check_dict);
			elif (node is Sprite3D):
				_add_resources_sprite3d(node, dep_dict, resources_list, resource_check_dict);
		
		elif (node is NavigationMeshInstance):
			_add_resources_navigation_mesh_instance(node, dep_dict, resources_list, resource_check_dict);
		elif (node is GridMap):
			_add_resources_grid_map(node, dep_dict, resources_list, resource_check_dict);


# This will get the resources the node needs from the passed in resource list,
# using the node's resource dictionary (presumably made with get_node_resource_dependencies_dict)
# and will refill the node with the resources it needs.
#
# We will just edit/add-to the passed in dictionary (dep_dict) and list (resources_list)
# directly.
func load_node_resources_from_list(node, dep_dict, resources_list):
	
	var dep_dict_resources = dep_dict["DSCN_Dependencies"]
	
	# *** All of the base-type/basic nodes ***
	if (node is Node):
		_load_resources_node(node, dep_dict_resources, resources_list);
	if (node is CanvasItem):
		_load_resources_canvas_item(node, dep_dict_resources, resources_list);
	if (node is Viewport):
		_load_resources_viewport(node, dep_dict_resources, resources_list);
	if (node is AudioStreamPlayer):
		_load_resources_audio_stream_player(node, dep_dict_resources, resources_list);
	if (node is WorldEnvironment):
		_load_resources_world_environment(node, dep_dict_resources, resources_list);
	
	
	
	# *** All of the Node2D extending nodes ***
	if (node is Node2D):
		# Until there is a better way, we'll just do this manually in order of the
		# "Inheritied By" section of the documentation, found below:
		# http://docs.godotengine.org/en/3.0/classes/class_node2d.html?
		#
		# And then we'll add anything else that is missing!
		# The only nodes here are nodes that have resources to load.
		# Other nodes to not seem to have any resources to load.
		
		if (node is TouchScreenButton):
			_load_resources_touch_screen_button(node, dep_dict_resources, resources_list);
		elif (node is Particles2D):
			_load_resources_particles2d(node, dep_dict_resources, resources_list);
		elif (node is AnimatedSprite):
			_load_resources_animated_sprite(node, dep_dict_resources, resources_list);
		elif (node is Light2D):
			_load_resources_light2d(node, dep_dict_resources, resources_list);
		elif (node is Path2D):
			_load_resources_path2d(node, dep_dict_resources, resources_list);
		elif (node is Line2D):
			_load_resources_line2d(node, dep_dict_resources, resources_list);
		elif (node is AudioStreamPlayer2D):
			_load_resources_audio_stream_player2d(node, dep_dict_resources, resources_list);
		elif (node is Sprite):
			_load_resources_sprite(node, dep_dict_resources, resources_list);
		elif (node is CollisionShape2D):
			_load_resources_collision_shape2d(node, dep_dict_resources, resources_list);
		elif (node is NavigationPolygonInstance):
			_load_resources_navigation_polygon_instance(node, dep_dict_resources, resources_list);
		elif (node is Polygon2D):
			_load_resources_polygon2d(node, dep_dict_resources, resources_list);
		elif (node is LightOccluder2D):
			_load_resources_light_occluder2d(node, dep_dict_resources, resources_list);
		elif (node is TileMap):
			_load_resources_tilemap(node, dep_dict_resources, resources_list);
	
	# *** All of the Control extending nodes ***
	if (node is Control):
		
		_load_resources_control(node, dep_dict_resources, resources_list);
		
		if (node is TextureRect):
			_load_resources_texture_rect(node, dep_dict_resources, resources_list);
		elif (node is VideoPlayer):
			_load_resources_video_player(node, dep_dict_resources, resources_list);
		elif (node is NinePatchRect):
			_load_resources_nine_patch_rect(node, dep_dict_resources, resources_list);
		elif (node is Button):
			_load_resources_button(node, dep_dict_resources, resources_list);
		elif (node is TextureButton):
			_load_resources_texture_button(node, dep_dict_resources, resources_list);
	
	# *** All of the Spatial extending nodes ***
	if (node is Spatial):
		
		_load_resources_spatial(node, dep_dict_resources, resources_list);
		
		if (node is Camera):
			_load_resources_camera(node, dep_dict_resources, resources_list);
		elif (node is CollisionShape):
			_load_resources_collision_shape(node, dep_dict_resources, resources_list);
		elif (node is AudioStreamPlayer3D):
			_load_resources_audio_stream_player3d(node, dep_dict_resources, resources_list);
		elif (node is Path):
			_load_resources_path(node, dep_dict_resources, resources_list);
		elif (node is BakedLightmap):
			_load_resources_baked_lightmap(node, dep_dict_resources, resources_list);
		elif (node is GIProbe):
			_load_resources_gi_probe(node, dep_dict_resources, resources_list);
		elif (node is GeometryInstance):
			_load_resources_geometry_instance(node, dep_dict_resources, resources_list);
			
			if (node is MultiMesh):
				_load_resources_multi_mesh(node, dep_dict_resources, resources_list);
			elif (node is MeshInstance):
				_load_resources_mesh_instance(node, dep_dict_resources, resources_list);
			elif (node is Particles):
				_load_resources_particles(node, dep_dict_resources, resources_list);
			elif (node is AnimatedSprite3D):
				_load_resources_animated_sprite3d(node, dep_dict_resources, resources_list);
			elif (node is Sprite3D):
				_load_resources_sprite3d(node, dep_dict_resources, resources_list);
		
		elif (node is NavigationMeshInstance):
			_load_resources_navigation_mesh_instance(node, dep_dict_resources, resources_list);
		elif (node is GridMap):
			_load_resources_grid_map(node, dep_dict_resources, resources_list);
	
	# Load CUSTOM DATA in the node, if it has the following function:
	# DSCN_load_resources.
	if (node.has_method("DSCN_load_resources") == true):
		node.DSCN_custom_load_resources(node, dep_dict, resources_list);



# ==========================================
# ==== RESOURCE DEPENDENCY ADDING FUNCTIONS

func _check_and_add_resource_to_list(resource, resources_list, resource_to_check_for=null, resource_check_dict=null):
	
	if (resource_to_check_for != null and resource_check_dict != null):
		if (resource_check_dict.has(resource_to_check_for) == true):
			return resource_check_dict[resource_to_check_for];
	
	
	var find_result = resources_list.find(resource);
	
	if (find_result == -1):
		resources_list.append(resource);
		
		if (resource_to_check_for != null and resource_check_dict != null):
			resource_check_dict[resource_to_check_for] = resources_list.size()-1;
		
		return resources_list.size()-1;
	
	else:
		return find_result;


func __add_resources_mesh(mesh, dep_dict, resources_list, resource_check_dict):
	
	if (mesh is PrimitiveMesh):
		if (mesh.material != null):
			if (mesh.material is ShaderMaterial):
				dep_dict["primitive_mesh_shader_material"] = _check_and_add_resource_to_list(mesh.material, resources_list);
				#mesh.material = null;
			
			elif (mesh.material is SpatialMaterial):
				dep_dict = __add_resources_spatial_material(mesh.material, dep_dict, resources_list, resource_check_dict);
				dep_dict["primitive_mesh_spatial_material"] = _check_and_add_resource_to_list(mesh.material, resources_list);
				#mesh.material = null;
	
	elif (mesh is ArrayMesh):
		var material_count = mesh.get_surface_count();
		
		for i in range(0, material_count):
			var surface_material = mesh.surface_get_material(i);
			
			if (surface_material == null):
				continue;
			
			if (surface_material is SpatialMaterial):
				dep_dict = __add_resources_spatial_material(surface_material, dep_dict, resources_list, resource_check_dict, "_array_mesh_" + str(i));
			
			dep_dict["array_mesh_material_" + str(i)] = _check_and_add_resource_to_list(surface_material, resources_list);
			#mesh.surface_set_material(i, null);
		
		dep_dict["array_mesh_surface_count"] = material_count;


func __add_resources_spatial_material(material, dep_dict, resources_list, resource_check_dict, additional_string=""):
	
	if (material.albedo_texture != null):
		dep_dict["spatial_material_albedo_texture" + additional_string] = _check_and_add_resource_to_list(
													material.albedo_texture.get_data(),
													resources_list,
													material.albedo_texture,
													resource_check_dict);
		#material.albedo_texture = null;
	
	if (material.anisotropy_flowmap != null):
		dep_dict["spatial_material_anisotropy_flowmap" + additional_string] = _check_and_add_resource_to_list(
													material.anisotropy_flowmap.get_data(),
													resources_list,
													material.anisotropy_flowmap,
													resource_check_dict);
		#material.anisotropy_flowmap = null
	
	if (material.ao_texture != null):
		dep_dict["spatial_material_ao_texture" + additional_string] = _check_and_add_resource_to_list(
													material.ao_texture.get_data(),
													resources_list,
													material.ao_texture,
													resource_check_dict);
		#material.ao_texture = null
	
	if (material.clearcoat_texture != null):
		dep_dict["spatial_material_clearcoat_texture" + additional_string] = _check_and_add_resource_to_list(
													material.clearcoat_texture.get_data(),
													resources_list,
													material.clearcoat_texture,
													resource_check_dict);
		#material.clearcoat_texture = null
	
	if (material.depth_texture != null):
		dep_dict["spatial_material_depth_texture" + additional_string] = _check_and_add_resource_to_list(
													material.depth_texture.get_data(),
													resources_list,
													material.depth_texture,
													resource_check_dict);
		#material.depth_texture = null
	
	if (material.detail_albedo != null):
		dep_dict["spatial_material_detail_albedo" + additional_string] = _check_and_add_resource_to_list(
													material.detail_albedo.get_data(),
													resources_list,
													material.detail_albedo,
													resource_check_dict);
		#material.detail_albedo = null
	
	if (material.detail_mask != null):
		dep_dict["spatial_material_detail_mask" + additional_string] = _check_and_add_resource_to_list(
													material.detail_mask.get_data(),
													resources_list,
													material.detail_mask,
													resource_check_dict);
		#material.detail_mask = null
	
	if (material.detail_normal != null):
		dep_dict["spatial_material_detail_normal" + additional_string] = _check_and_add_resource_to_list(
													material.detail_normal.get_data(),
													resources_list,
													material.detail_normal,
													resource_check_dict);
		#material.detail_normal = null
	
	if (material.emission_texture != null):
		dep_dict["spatial_material_emission_texture" + additional_string] = _check_and_add_resource_to_list(
													material.emission_texture.get_data(),
													resources_list,
													material.emission_texture,
													resource_check_dict);
		#material.emission_texture = null
	
	if (material.metallic_texture != null):
		dep_dict["spatial_material_metallic_texture" + additional_string] = _check_and_add_resource_to_list(
													material.metallic_texture.get_data(),
													resources_list,
													material.metallic_texture,
													resource_check_dict);
		#material.metallic_texture = null
	
	if (material.normal_texture != null):
		dep_dict["spatial_material_normal_texture" + additional_string] = _check_and_add_resource_to_list(
													material.normal_texture.get_data(),
													resources_list,
													material.normal_texture,
													resource_check_dict);
		#material.normal_texture = null
	
	if (material.refraction_texture != null):
		dep_dict["spatial_material_refraction_texture" + additional_string] = _check_and_add_resource_to_list(
													material.refraction_texture.get_data(),
													resources_list,
													material.refraction_texture,
													resource_check_dict);
		#material.refraction_texture = null
	
	if (material.rim_texture != null):
		dep_dict["spatial_material_rim_texture" + additional_string] = _check_and_add_resource_to_list(
													material.rim_texture.get_data(),
													resources_list,
													material.rim_texture,
													resource_check_dict);
		#material.rim_texture = null
	
	if (material.roughness_texture != null):
		dep_dict["spatial_material_roughness_texture" + additional_string] = _check_and_add_resource_to_list(
													material.roughness_texture.get_data(),
													resources_list,
													material.roughness_texture,
													resource_check_dict);
		#material.roughness_texture = null
	
	if (material.subsurf_scatter_texture != null):
		dep_dict["spatial_material_subsurf_scatter_texture" + additional_string] = _check_and_add_resource_to_list(
													material.subsurf_scatter_texture.get_data(),
													resources_list,
													material.subsurf_scatter_texture,
													resource_check_dict);
		#material.subsurf_scatter_texture = null
	
	if (material.transmission_texture != null):
		dep_dict["spatial_material_transmission_texture" + additional_string] = _check_and_add_resource_to_list(
													material.transmission_texture.get_data(),
													resources_list,
													material.transmittion_texture,
													resource_check_dict);
		#material.transmission_texture = null
	
	return dep_dict;


# == Node And Other Base Nodes

func _add_resources_node(node, dep_dict, resources_list, resource_check_dict):
	# This will add the Node's resources.
	# Right now this adds the following:
		# script, groups
	
	if node.get_script() != null:
		dep_dict["script"] = _check_and_add_resource_to_list(node.get_script(), resources_list);
	
	var node_groups = node.get_groups();
	if (node_groups.size() > 0):
		dep_dict["group_size"] = node_groups.size();
		for i in range(0, node_groups.size()):
			dep_dict["group_id_" + str(i)] = node_groups[i];
	

func _add_resources_canvas_item(node, dep_dict, resources_list, resource_check_dict):
	# This will add the CanvasItem's resources.
	# Right now this adds the following:
		# material
	
	if node.material != null:
		dep_dict["material"] = _check_and_add_resource_to_list(node.material, resources_list);
		node.material = null;

func _add_resources_viewport(node, dep_dict, resources_list, resource_check_dict):
	# This will add the Viewport's resources.
	# Right now this adds the following:
		# world, world_2d
	
	if (node.world != null):
		dep_dict["world"] = _check_and_add_resource_to_list(node.world, resources_list);
		node.world = null;
	
	if (node.world_2d != null):
		dep_dict["world_2d"] = _check_and_add_resource_to_list(node.world_2d, resources_list);
		node.world_2d = null;

func _add_resources_audio_stream_player(node, dep_dict, resources_list, resource_check_dict):
	# This will add the AudioStreamPlayers's resources.
	# Right now this adds the following:
		# stream
	
	if (node.stream != null):
		dep_dict["stream"] = _check_and_add_resource_to_list(node.stream, resources_list);
		node.stream = null;

func _add_resources_world_environment(node, dep_dict, resources_list, resource_check_dict):
	# This will add the WorldEnvironment's resources.
	# Right now this adds the following:
		# environment
	
	if (node.environment != null):
		dep_dict["environment"] = _check_and_add_resource_to_list(node.environment, resources_list);
		node.environment = null;

# == Node2D (and Node2D extending) nodes

func _add_resources_touch_screen_button(node, dep_dict, resources_list, resource_check_dict):
	# This will add the TouchScreenButton's basic resources.
	# Right now this adds the following:
		# Bitmask, Normal, Pressed,
	
	if (node.bitmask != null):
		dep_dict["bitmask"] = _check_and_add_resource_to_list(node.bitmask, resources_list);
		node.bitmask = null;
	
	if (node.normal != null):
		dep_dict["normal"] = _check_and_add_resource_to_list(node.normal.get_data(), resources_list, node.normal, resource_check_dict);
		node.normal = null;
	
	if (node.pressed != null):
		dep_dict["pressed"] = _check_and_add_resource_to_list(node.pressed.get_data(), resources_list, node.pressed, resource_check_dict);
		node.pressed = null;

func _add_resources_particles2d(node, dep_dict, resources_list, resource_check_dict):
	# This will add the TouchScreenButton's basic resources.
	# Right now this adds the following:
		# Normal_map, process_material, texture,
		
	if (node.normal_map != null):
		dep_dict["normal_map"] = _check_and_add_resource_to_list(node.normal_map.get_data(), resources_list, node.normal_map, resource_check_dict);
		node.normal_map = null;
	
	if (node.process_material != null):
		dep_dict["process_material"] = _check_and_add_resource_to_list(node.process_material, resources_list);
		node.process_material = null;
	
	if (node.texture != null):
		dep_dict["texture"] = _check_and_add_resource_to_list(node.texture.get_data(), resources_list, node.texture, resource_check_dict);
		node.texture = null;

func _add_resources_animated_sprite(node, dep_dict, resources_list, resource_check_dict):
	# This will add the AnimatedSprite's basic resources.
	# Right now this adds the following:
		# Frames
	
	if (node.frames != null):
		dep_dict["frames"] = _check_and_add_resource_to_list(node.frames, resources_list);
		node.frames = null;

func _add_resources_light2d(node, dep_dict, resources_list, resource_check_dict):
	# This will add the Light2D's basic resources.
	# Right now this adds the following:
		# texture
	
	if (node.texture != null):
		dep_dict["texture"] =  _check_and_add_resource_to_list(node.texture.get_data(), resources_list, node.texture, resource_check_dict);
		node.texture = null;

func _add_resources_path2d(node, dep_dict, resources_list, resource_check_dict):
	# This will add the Path2D's basic resources.
	# Right now this adds the following:
		# curve
	
	if (node.curve != null):
		dep_dict["curve"] = _check_and_add_resource_to_list(node.curve, resources_list);
		node.curve = null;

func _add_resources_line2d(node, dep_dict, resources_list, resource_check_dict):
	# This will add the Line2D's basic resources.
	# Right now this adds the following:
		# gradient, texture
	
	if (node.gradient != null):
		dep_dict["gradient"] = _check_and_add_resource_to_list(node.gradient, resources_list);
		node.gradient = null;
	
	if (node.texture != null):
		dep_dict["texture"] = _check_and_add_resource_to_list(node.texture.get_data(), resources_list, node.texture, resource_check_dict);
		node.texture = null;

func _add_resources_audio_stream_player2d(node, dep_dict, resources_list, resource_check_dict):
	# This will add the Line2D's basic resources.
	# Right now this adds the following:
		# stream
	
	if (node.stream != null):
		dep_dict["stream"] = _check_and_add_resource_to_list(node.steam, resources_list);
		node.stream = null;

func _add_resources_sprite(node, dep_dict, resources_list, resource_check_dict):
	# This will add the Sprite's resources.
	# Right now this adds the following:
		# Texture, Normal Map,
	
	if (node.texture != null):
		dep_dict["texture"] = _check_and_add_resource_to_list(node.texture.get_data(), resources_list, node.texture, resource_check_dict);
		node.texture = null;
	
	if (node.normal_map != null):
		dep_dict["normal_map"] = _check_and_add_resource_to_list(node.normal_map.get_data(), resources_list, node.normal_map, resource_check_dict);
		node.normal_map = null;

func _add_resources_collision_shape2d(node, dep_dict, resources_list, resource_check_dict):
	# This will add the CollisionShape2D's resources.
	# Right now this adds the following:
		# shape,
	
	if (node.shape != null):
		dep_dict["shape"] = _check_and_add_resource_to_list(node.shape, resources_list);
		node.shape = null;

func _add_resources_navigation_polygon_instance(node, dep_dict, resources_list, resource_check_dict):
	# This will add the NavigationPolygonInstance's resources.
	# Right now this adds the following:
		# navpoly,
	
	if (node.navpoly != null):
		dep_dict["navpoly"] = _check_and_add_resource_to_list(node.navpoly, resources_list);
		node.navpoly = null;

func _add_resources_polygon2d(node, dep_dict, resources_list, resource_check_dict):
	# This will add the NavigationPolygonInstance's resources.
	# Right now this adds the following:
		# texure,
	
	if (node.texture != null):
		dep_dict["texture"] = _check_and_add_resource_to_list(node.texture.get_data(), resources_list, node.texture, resource_check_dict);
		node.texture = null;

func _add_resources_light_occluder2d(node, dep_dict, resources_list, resource_check_dict):
	# This will add the LightOccluder2D's resources.
	# Right now this adds the following:
		# occluder,
	
	if (node.occluder != null):
		dep_dict["occluder"] = _check_and_add_resource_to_list(node.occluder, resources_list);
		node.occluder = null;

func _add_resources_tilemap(node, dep_dict, resources_list, resource_check_dict):
	# This will add the TileMap's basic resources.
	# Right now this adds the following:
		# tile_set,
	
	# TODO: add tileset image saving/loading!
	
	if (node.tile_set != null):
		dep_dict["tile_set"] = _check_and_add_resource_to_list(node.tile_set, resources_list);
		node.tile_set = null;

# ==

# == Control (and Control extending) nodes

func _add_resources_control(node, dep_dict, resources_list, resource_check_dict):
	# This will add the Control's basic resources.
	# Right now this adds the following:
		# theme,
	
	if (node.theme != null):
		dep_dict["theme"] = _check_and_add_resource_to_list(node.theme, resources_list);
		node.theme = null;

func _add_resources_texture_rect(node, dep_dict, resources_list, resource_check_dict):
	# This will add the TextureRect's basic resources.
	# Right now this adds the following:
		# texture,
	
	if (node.texture != null):
		dep_dict["texture"] = _check_and_add_resource_to_list(node.texture.get_data(), resources_list, node.texture, resource_check_dict);
		node.texture = null;

func _add_resources_video_player(node, dep_dict, resources_list, resource_check_dict):
	# This will add the VideoPlayer's basic resources.
	# Right now this adds the following:
		# stream,
	
	if (node.stream != null):
		dep_dict["stream"] = _check_and_add_resource_to_list(node.stream, resources_list);
		node.stream = null;

func _add_resources_nine_patch_rect(node, dep_dict, resources_list, resource_check_dict):
	# This will add the NinePathRect's basic resources.
	# Right now this adds the following:
		# texture,
	
	if (node.texture != null):
		dep_dict["texture"] = _check_and_add_resource_to_list(node.texture.get_data(), resources_list, node.texture, resource_check_dict);
		node.texture = null;

func _add_resources_button(node, dep_dict, resources_list, resource_check_dict):
	# This will add the Buttons's basic resources.
	# Right now this adds the following:
		# icon,
	
	if (node.icon != null):
		dep_dict["icon"] = _check_and_add_resource_to_list(node.icon.get_data(), resources_list, node.icon, resource_check_dict);
		node.icon = null;

func _add_resources_texture_button(node, dep_dict, resources_list, resource_check_dict):
	# This will add the NinePathRect's basic resources.
	# Right now this adds the following:
		# texture_click_mask, texture_disabled,
		# texture_focused, texture_hover, texture_normal,
		# texture_pressed,
	
	if (node.texture_click_mask != null):
		dep_dict["texture_click_mask"] = _check_and_add_resource_to_list(node.texture_click_mask, resources_list);
		node.texture_click_mask = null;
	
	if (node.texture_disabled != null):
		dep_dict["texture_disabled"] = _check_and_add_resource_to_list(node.texture_disabled.get_data(), resources_list, node.texture_disabled, resource_check_dict);
		node.texture_disabled = null;
	
	if (node.texture_focused != null):
		dep_dict["texture_focused"] = _check_and_add_resource_to_list(node.texture_focused.get_data(), resources_list, node.texture_focused, resource_check_dict);
		node.texture_focused = null;
	
	if (node.texture_hover != null):
		dep_dict["texture_hover"] = _check_and_add_resource_to_list(node.texture_hover.get_data(), resources_list, node.texture_hover, resource_check_dict);
		node.texture_hover = null;
	
	if (node.texture_normal != null):
		dep_dict["texture_normal"] = _check_and_add_resource_to_list(node.texture_normal.get_data(), resources_list, node.texture_normal, resource_check_dict);
		node.texture_normal = null;
	
	if (node.texture_pressed != null):
		dep_dict["texture_pressed"] = _check_and_add_resource_to_list(node.texture_pressed.get_data(), resources_list, node.texture_pressed, resource_check_dict);
		node.texture_pressed = null;

# ==

# == Spatial (And Spatial extending) nodes

func _add_resources_spatial(node, dep_dict, resources_list, resource_check_dict):
	# This will load the Spatial's basic resources.
	# Right now this loads the following:
		# gizmo
	
	if (node.gizmo != null):
		dep_dict["gizmo"] = _check_and_add_resource_to_list(node.gizmo, resources_list);
		node.gizmo = null;

func _add_resources_camera(node, dep_dict, resources_list, resource_check_dict):
	# This will load the Canera's basic resources.
	# Right now this loads the following:
		# environment
	
	if (node.environment != null):
		dep_dict["environment"] = _check_and_add_resource_to_list(node.environment, resources_list);
		node.environment = null;

func _add_resources_collision_shape(node, dep_dict, resources_list, resource_check_dict):
	# This will load the CollisionShape's basic resources.
	# Right now this loads the following:
		# shape
	
	if (node.shape != null):
		dep_dict["shape"] = _check_and_add_resource_to_list(node.shape, resources_list);
		node.shape = null;

func _add_resources_audio_stream_player3d(node, dep_dict, resources_list, resource_check_dict):
	# This will load the AudioStreamPlayer3D's basic resources.
	# Right now this loads the following:
		# stream
	
	if (node.stream != null):
		dep_dict["stream"] = _check_and_add_resource_to_list(node.stream, resources_list);
		node.stream = null;

func _add_resources_path(node, dep_dict, resources_list, resource_check_dict):
	# This will load the Path's basic resources.
	# Right now this loads the following:
		# curve
	
	if (node.curve != null):
		dep_dict["curve"] = _check_and_add_resource_to_list(node.curve, resources_list);
		node.curve = null;

func _add_resources_baked_lightmap(node, dep_dict, resources_list, resource_check_dict):
	# This will load the BakedLightmap's basic resources.
	# Right now this loads the following:
		# light_data
	
	if (node.light_data != null):
		dep_dict["light_data"] = _check_and_add_resource_to_list(node.light_data, resources_list);
		node.light_data = null;

func _add_resources_gi_probe(node, dep_dict, resources_list, resource_check_dict):
	# This will load the GIProbes's basic resources.
	# Right now this loads the following:
		# data
	
	if (node.data != null):
		dep_dict["data"] = _check_and_add_resource_to_list(node.data, resources_list);
		node.data = null;

func _add_resources_geometry_instance(node, dep_dict, resources_list, resource_check_dict):
	# This will load the GeometryInstance's basic resources.
	# Right now this loads the following:
		# material_override (ShaderMaterial and SpatialMaterial)
	
	# TODO: support all nodes that have materials!
	
	if (node.material_override != null):
		
		if (node.material_override is SpatialMaterial):
			dep_dict = __add_resources_spatial_material(node.material_override, dep_dict, resources_list, resource_check_dict);
			dep_dict["material_override_spatial_material"] = _check_and_add_resource_to_list(node.material_override, resources_list);
		
		elif (node.material_override is ShaderMaterial):
			dep_dict["material_override_shader_material"] = _check_and_add_resource_to_list(node.material_override, resources_list);
			node.material_override = null;


func _add_resources_multi_mesh(node, dep_dict, resources_list, resource_check_dict):
	# This will load the MultiMesh's basic resources.
	# Right now this loads the following:
		# mesh
	
	if (node.mesh != null):
		__add_resources_mesh(node.mesh, dep_dict, resources_list, resource_check_dict);
		dep_dict["mesh"] = _check_and_add_resource_to_list(node.mesh, resources_list);
		node.mesh = null;

func _add_resources_mesh_instance(node, dep_dict, resources_list, resource_check_dict):
	# This will load the MeshInstance's basic resources.
	# Right now this loads the following:
		# mesh
	
	# TODO: support get_surface_material and set_surface_material materials!
	
	if (node.mesh != null):
		__add_resources_mesh(node.mesh, dep_dict, resources_list, resource_check_dict);
		dep_dict["mesh"] = _check_and_add_resource_to_list(node.mesh, resources_list);
		node.mesh = null;

func _add_resources_particles(node, dep_dict, resources_list, resource_check_dict):
	# This will load the Particles's basic resources.
	# Right now this loads the following:
		# draw_pass_1, draw_pass_2, draw_pass_3, draw_pass_4,
		# process_material
	
	if (node.draw_pass_1 != null):
		__add_resources_mesh(node.draw_pass_1, dep_dict, resources_list, resource_check_dict);
		dep_dict["draw_pass_1"] = _check_and_add_resource_to_list(node.draw_pass_1, resources_list);
		node.draw_pass_1 = null;
	
	if (node.draw_pass_2 != null):
		__add_resources_mesh(node.draw_pass_2, dep_dict, resources_list, resource_check_dict);
		dep_dict["draw_pass_2"] = _check_and_add_resource_to_list(node.draw_pass_2, resources_list);
		node.draw_pass_2 = null;
	
	if (node.draw_pass_3 != null):
		__add_resources_mesh(node.draw_pass_3, dep_dict, resources_list, resource_check_dict);
		dep_dict["draw_pass_3"] = _check_and_add_resource_to_list(node.draw_pass_3, resources_list);
		node.draw_pass_3 = null;
	
	if (node.draw_pass_4 != null):
		__add_resources_mesh(node.draw_pass_4, dep_dict, resources_list, resource_check_dict);
		dep_dict["draw_pass_4"] = _check_and_add_resource_to_list(node.draw_pass_4, resources_list);
		node.draw_pass_4 = null;
	
	if (node.process_material != null):
		dep_dict["process_material"] = _check_and_add_resource_to_list(node.process_material, resources_list);
		node.process_material = null;

func _add_resources_animated_sprite3d(node, dep_dict, resources_list, resource_check_dict):
	# This will load the AnimatedSprite3D's basic resources.
	# Right now this loads the following:
		# frames
	
	if (node.frames != null):
		dep_dict["frames"] = _check_and_add_resource_to_list(node.frames, resources_list);
		node.frames = null;

func _add_resources_sprite3d(node, dep_dict, resources_list, resource_check_dict):
	# This will load the Sprite3D's basic resources.
	# Right now this loads the following:
		# texture
	
	if (node.texture != null):
		dep_dict["texture"] = _check_and_add_resource_to_list(node.texture.get_data(), resources_list, node.texture, resource_check_dict);
		node.texture = null;

func _add_resources_navigation_mesh_instance(node, dep_dict, resources_list, resource_check_dict):
	# This will load the NavigationMeshInstance's basic resources.
	# Right now this loads the following:
		# navmesh
	
	if (node.navmesh != null):
		dep_dict["navmesh"] = _check_and_add_resource_to_list(node.navmesh, resources_list);
		node.navmesh = null;

func _add_resources_grid_map(node, dep_dict, resources_list, resource_check_dict):
	# This will load the GridMap's basic resources.
	# Right now this loads the following:
		# theme, (with mesh materials!)
	
	if (node.theme != null):
		var theme_list = node.theme.get_item_list();
		
		for i in range(0, theme_list.size()):
			
			var theme_mesh = node.theme.get_item_mesh(i);
			if (theme_mesh != null):
				__add_resources_mesh(theme_mesh, dep_dict, resources_list, resource_check_dict);
				dep_dict["grid_map_theme_mesh_" + str(i)] = _check_and_add_resource_to_list(theme_mesh, resources_list);
			
			var theme_name = node.theme.get_item_name(i);
			if (theme_name != null):
				dep_dict["grid_map_theme_name_" + str(i)] = theme_name;
			
			var theme_navmesh = node.theme.get_item_navmesh(i);
			if (theme_navmesh != null):
				dep_dict["grid_map_theme_navmesh_" + str(i)] = _check_and_add_resource_to_list(theme_navmesh, resources_list);
			
			var theme_preview = node.theme.get_item_preview(i);
			if (theme_preview != null):
				dep_dict["grid_map_theme_preview_" + str(i)] = _check_and_add_resource_to_list(theme_preview.get_data(), resources_list, theme_preview, resource_check_dict);
			
			var theme_shapes = node.theme.get_item_shapes(i);
			if (theme_shapes.size() > 0):
				dep_dict["grid_map_theme_shape_size_" + str(i)] = theme_shapes.size();
				for j in range(0, theme_shapes.size()):
					dep_dict["grid_map_theme_shape_" + str(i) + str(j)] = _check_and_add_resource_to_list(theme_shapes[j], resources_list);
		
		dep_dict["grid_map_theme_size"] = theme_list.size();
	
	"""
	if (node.theme != null):
		dep_dict["theme"] = _check_and_add_resource_to_list(node.theme, resources_list);
		node.theme = null;
	"""

# ==

# ==========================================




# ==========================================
# ==== RESOURCE DEPENDENCY LOADING FUNCTIONS

func _get_resource_from_dep_dict(resource_name, dep_dict, resources_list):
	return resources_list[dep_dict[resource_name]];

func _get_resource_into_image(image_data):
	image_data.setup_local_to_scene();
	image_data.resource_local_to_scene = true;
	
	var img = ImageTexture.new();
	img.create_from_image(image_data);
	
	img.setup_local_to_scene();
	img.resource_local_to_scene = true;
	
	return img;


func __load_resources_mesh(mesh, dep_dict, resources_list):
	
	if (mesh is PrimitiveMesh):
		if (dep_dict.has("primitive_mesh_shader_material") == true):
			mesh.material = _get_resource_from_dep_dict("primitive_mesh_shader_material", dep_dict, resources_list);
		if (dep_dict.has("primitive_mesh_spatial_material") == true):
			mesh.material = _get_resource_from_dep_dict("primitive_mesh_spatial_material", dep_dict, resources_list);
			__load_resources_spatial_material(mesh.material, dep_dict, resources_list);
	
	elif (mesh is ArrayMesh):
		if (dep_dict.has("array_mesh_surface_count") == true):
			# Get the surface count
			var surface_count = int(dep_dict["array_mesh_surface_count"]);
			
			for i in range(0, surface_count):
				if (dep_dict.has("array_mesh_material_" + str(i)) == true):
					var surface_material = _get_resource_from_dep_dict("array_mesh_material_" + str(i), dep_dict, resources_list);
					
					if (surface_material is SpatialMaterial):
						__load_resources_spatial_material(surface_material, dep_dict, resources_list, "_array_mesh_" + str(i));
					
					mesh.surface_set_material(i, surface_material);
				
				else:
					mesh.surface_set_material(i, null);


func __load_resources_spatial_material(material, dep_dict, resources_list, additional_string=""):
	
	if (dep_dict.has("spatial_material_albedo_texture" + additional_string) == true):
		var img_data = _get_resource_from_dep_dict("spatial_material_albedo_texture" + additional_string, dep_dict, resources_list);
		material.albedo_texture = _get_resource_into_image(img_data);
	
	if (dep_dict.has("spatial_material_anisotropy_flowmap" + additional_string) == true):
		var img_data = _get_resource_from_dep_dict("spatial_material_anisotropy_flowmap" + additional_string, dep_dict, resources_list);
		material.anisotropy_flowmap = _get_resource_into_image(img_data);
	
	if (dep_dict.has("spatial_material_ao_texture" + additional_string) == true):
		var img_data = _get_resource_from_dep_dict("spatial_material_ao_texture" + additional_string, dep_dict, resources_list);
		material.ao_texture = _get_resource_into_image(img_data);
	
	if (dep_dict.has("spatial_material_clearcoat_texture" + additional_string) == true):
		var img_data = _get_resource_from_dep_dict("spatial_material_clearcoat_texture" + additional_string, dep_dict, resources_list);
		material.clearcoat_texture = _get_resource_into_image(img_data);
	
	if (dep_dict.has("spatial_material_depth_texture" + additional_string) == true):
		var img_data = _get_resource_from_dep_dict("spatial_material_depth_texture" + additional_string, dep_dict, resources_list);
		material.depth_texture = _get_resource_into_image(img_data);
	
	if (dep_dict.has("spatial_material_detail_albedo" + additional_string) == true):
		var img_data = _get_resource_from_dep_dict("spatial_material_detail_albedo" + additional_string, dep_dict, resources_list);
		material.detail_albedo = _get_resource_into_image(img_data);
	
	if (dep_dict.has("spatial_material_detail_mask" + additional_string) == true):
		var img_data = _get_resource_from_dep_dict("spatial_material_detail_mask" + additional_string, dep_dict, resources_list);
		material.detail_mask = _get_resource_into_image(img_data);
	
	if (dep_dict.has("spatial_material_detail_normal" + additional_string) == true):
		var img_data = _get_resource_from_dep_dict("spatial_material_detail_normal" + additional_string, dep_dict, resources_list);
		material.detail_normal = _get_resource_into_image(img_data);
	
	if (dep_dict.has("spatial_material_emission_texture" + additional_string) == true):
		var img_data = _get_resource_from_dep_dict("spatial_material_emission_texture" + additional_string, dep_dict, resources_list);
		material.emission_texture = _get_resource_into_image(img_data);
	
	if (dep_dict.has("spatial_material_metallic_texture" + additional_string) == true):
		var img_data = _get_resource_from_dep_dict("spatial_material_metallic_texture" + additional_string, dep_dict, resources_list);
		material.metallic_texture = _get_resource_into_image(img_data);
	
	if (dep_dict.has("spatial_material_normal_texture" + additional_string) == true):
		var img_data = _get_resource_from_dep_dict("spatial_material_normal_texture" + additional_string, dep_dict, resources_list);
		material.normal_texture = _get_resource_into_image(img_data);
	
	if (dep_dict.has("spatial_material_refraction_texture" + additional_string) == true):
		var img_data = _get_resource_from_dep_dict("spatial_material_refraction_texture" + additional_string, dep_dict, resources_list);
		material.refraction_texture = _get_resource_into_image(img_data);
	
	if (dep_dict.has("spatial_material_rim_texture" + additional_string) == true):
		var img_data = _get_resource_from_dep_dict("spatial_material_rim_texture" + additional_string, dep_dict, resources_list);
		material.rim_texture = _get_resource_into_image(img_data);
	
	if (dep_dict.has("spatial_material_roughness_texture" + additional_string) == true):
		var img_data = _get_resource_from_dep_dict("spatial_material_roughness_texture" + additional_string, dep_dict, resources_list);
		material.roughness_texture = _get_resource_into_image(img_data);
	
	if (dep_dict.has("spatial_material_subsurf_scatter_texture" + additional_string) == true):
		var img_data = _get_resource_from_dep_dict("spatial_material_subsurf_scatter_texture" + additional_string, dep_dict, resources_list);
		material.subsurf_scatter_texture = _get_resource_into_image(img_data);
	
	if (dep_dict.has("spatial_material_transmission_texture" + additional_string) == true):
		var img_data = _get_resource_from_dep_dict("spatial_material_transmission_texture" + additional_string, dep_dict, resources_list);
		material.transmission_texture = _get_resource_into_image(img_data);


# == Node And Other Base Nodes

func _load_resources_node(node, dep_dict, resources_list):
	# This will load the Node's resources.
	# Right now this loads the following:
		# script, groups
	
	if (dep_dict.has("script") == true):
		node.set_script(_get_resource_from_dep_dict("script", dep_dict, resources_list));
	
	if (dep_dict.has("group_size") == true):
		var node_group_size = dep_dict["group_size"];
		for i in range(0, node_group_size):
			if (dep_dict.has("group_id_" + str(i)) == true):
				node.add_to_group(dep_dict["group_id_" + str(i)], true);

func _load_resources_canvas_item(node, dep_dict, resources_list):
	# This will load the CanvasItem's resources.
	# Right now this loads the following:
		# Material
	
	if (dep_dict.has("material") == true):
		node.material = _get_resource_from_dep_dict("material", dep_dict, resources_list);

func _load_resources_viewport(node, dep_dict, resources_list):
	# This will load the Viewport's resources.
	# Right now this loads the following:
		# world, world_2d
	
	if (dep_dict.has("world") == true):
		node.world = _get_resource_from_dep_dict("world", dep_dict, resources_list);
	if (dep_dict.has("world_2d") == true):
		node.world_2d = _get_resource_from_dep_dict("world_2d", dep_dict, resources_list);

func _load_resources_audio_stream_player(node, dep_dict, resources_list):
	# This will load the AudioStreamPlayers's resources.
	# Right now this loads the following:
		# stream
	
	if (dep_dict.has("stream") == true):
		node.stream = _get_resource_from_dep_dict("stream", dep_dict, resources_list);

func _load_resources_world_environment(node, dep_dict, resources_list):
	# This will load the WorldEnvironment's resources.
	# Right now this loads the following:
		# environment
	
	if (dep_dict.has("environment") == true):
		node.environment = _get_resource_from_dep_dict("environment", dep_dict, resources_list);

# == Node2D And Extending Nodes

func _load_resources_touch_screen_button(node, dep_dict, resources_list):
	# This will load the TouchScreenButton's basic resources.
	# Right now this loads the following:
		# bitmask, normal, pressed,
	
	if (dep_dict.has["bitmask"] == true):
		node.bitmask = _get_resource_from_dep_dict("bitmask", dep_dict, resources_list);
	if (dep_dict.has["normal"] == true):
		var img_data = _get_resource_from_dep_dict("normal", dep_dict, resources_list);
		node.normal = _get_resource_into_image(img_data);
	if (dep_dict.has["pressed"] == true):
		var img_data = _get_resource_from_dep_dict("pressed", dep_dict, resources_list);
		node.pressed = _get_resource_into_image(img_data);

func _load_resources_particles2d(node, dep_dict, resources_list):
	# This will load the TouchScreenButton's basic resources.
	# Right now this loads the following:
		# normal_map, process_material, texture,
	
	if (dep_dict.has("normal_map") == true):
		var img_data = _get_resource_from_dep_dict("normal_map", dep_dict, resources_list);
		node.normal_map = _get_resource_into_image(img_data);
	if (dep_dict.has("process_material") == true):
		node.process_material = _get_resource_from_dep_dict("process_material", dep_dict, resources_list);
	if (dep_dict.has("texture") == true):
		var img_data = _get_resource_from_dep_dict("texture", dep_dict, resources_list);
		node.texture = _get_resource_into_image(img_data);

func _load_resources_animated_sprite(node, dep_dict, resources_list):
	# This will load the AnimatedSprite's basic resources.
	# Right now this loads the following:
		# frames
	
	if (dep_dict.has["frames"] == true):
		node.frames = _get_resource_from_dep_dict("frames", dep_dict, resources_list);

func _load_resources_light2d(node, dep_dict, resources_list):
	# This will load the Light2D's basic resources.
	# Right now this loads the following:
		# texture
	
	if (dep_dict.has("texture") == true):
		var img_data = _get_resource_from_dep_dict("texture", dep_dict, resources_list);
		node.texture = _get_resource_into_image(img_data);

func _load_resources_path2d(node, dep_dict, resources_list):
	# This will load the Path2D's basic resources.
	# Right now this loads the following:
		# curve
	
	if (dep_dict.has("curve") == true):
		node.curve = _get_resource_from_dep_dict("curve", dep_dict, resources_list);

func _load_resources_line2d(node, dep_dict, resources_list):
	# This will load the Line2D's basic resources.
	# Right now this loads the following:
		# gradient, texture
	
	if (dep_dict.has["gradient"] == true):
		node.gradient = _get_resource_from_dep_dict("gradient", dep_dict, resources_list);
	if (dep_dict.has("texture") == true):
		var img_data = _get_resource_from_dep_dict("texture", dep_dict, resources_list);
		node.texture = _get_resource_into_image(img_data);

func _load_resources_audio_stream_player2d(node, dep_dict, resources_list):
	# This will load the Line2D's basic resources.
	# Right now this loads the following:
		# stream
	
	if (dep_dict.has("stream") == true):
		node.stream = _get_resource_from_dep_dict("stream", dep_dict, resources_list);

func _load_resources_sprite(node, dep_dict, resources_list):
	# This will load the Sprite's resources.
	# Right now this loads the following:
		# texture, Normal Map,
	
	if (dep_dict.has("texture") == true):
		var img_data = _get_resource_from_dep_dict("texture", dep_dict, resources_list);
		node.texture = _get_resource_into_image(img_data);
	if (dep_dict.has("normal_map") == true):
		var img_data = _get_resource_from_dep_dict("normal_map", dep_dict, resources_list);
		node.texture = _get_resource_into_image(img_data);

func _load_resources_collision_shape2d(node, dep_dict, resources_list):
	# This will load the CollisionShape2D's resources.
	# Right now this loads the following:
		# shape,
	
	if (dep_dict.has("shape") == true):
		node.shape = _get_resource_from_dep_dict("shape", dep_dict, resources_list);

func _load_resources_navigation_polygon_instance(node, dep_dict, resources_list):
	# This will load the NavigationPolygonInstance's resources.
	# Right now this loads the following:
		# navpoly,
	
	if (dep_dict.has("navpoly") == true):
		node.navpoly = _get_resource_from_dep_dict("navpoly", dep_dict, resources_list);

func _load_resources_polygon2d(node, dep_dict, resources_list):
	# This will load the NavigationPolygonInstance's resources.
	# Right now this loads the following:
		# texure,
	
	if (dep_dict.has("texture") == true):
		var img_data = _get_resource_from_dep_dict("texture", dep_dict, resources_list);
		node.texture = _get_resource_into_image(img_data);

func _load_resources_light_occluder2d(node, dep_dict, resources_list):
	# This will load the LightOccluder2D's resources.
	# Right now this loads the following:
		# occluder,
	
	if (dep_dict.has("occluder") == true):
		node.occluder = _get_resource_from_dep_dict("occluder", dep_dict, resources_list);

func _load_resources_tilemap(node, dep_dict, resources_list):
	# This will load the TileMap's basic resources.
	# Right now this loads the following:
		# tile_set,
	
	if (dep_dict.has("tile_set") == true):
		node.tile_set = _get_resource_from_dep_dict("tile_set", dep_dict, resources_list);

# ==

# == Control And Extending Nodes

func _load_resources_control(node, dep_dict, resources_list):
	# This will load the Control's basic resources.
	# Right now this loads the following:
		# theme,
	
	if (dep_dict.has("theme") == true):
		node.theme = _get_resource_from_dep_dict("theme", dep_dict, resources_list);

func _load_resources_texture_rect(node, dep_dict, resources_list):
	# This will load the TextureRect's basic resources.
	# Right now this loads the following:
		# texture,
	
	if (dep_dict.has("texture") == true):
		var img_data = _get_resource_from_dep_dict("texture", dep_dict, resources_list);
		node.texture = _get_resource_into_image(img_data);

func _load_resources_video_player(node, dep_dict, resources_list):
	# This will load the VideoPlayer's basic resources.
	# Right now this loads the following:
		# stream,
	
	if (dep_dict.has("stream") == true):
		node.stream = _get_resource_from_dep_dict("stream", dep_dict, resources_list);

func _load_resources_nine_patch_rect(node, dep_dict, resources_list):
	# This will load the NinePathRect's basic resources.
	# Right now this loads the following:
		# texture,
	
	if (dep_dict.has("texture") == true):
		var img_data = _get_resource_from_dep_dict("texture", dep_dict, resources_list);
		node.texture = _get_resource_into_image(img_data);

func _load_resources_button(node, dep_dict, resources_list):
	# This will load the Buttons's basic resources.
	# Right now this loads the following:
		# icon,
	
	if (dep_dict.has("icon") == true):
		var img_data = _get_resource_from_dep_dict("icon", dep_dict, resources_list);
		node.icon = _get_resource_into_image(img_data);

func _load_resources_texture_button(node, dep_dict, resources_list):
	# This will load the NinePathRect's basic resources.
	# Right now this loads the following:
		# texture_click_mask, texture_disabled,
		# texture_focused, texture_hover, texture_normal,
		# texture_pressed,
	
	if (dep_dict.has("texture_click_mask") == true):
		var img_data = _get_resource_from_dep_dict("texture_click_mask", dep_dict, resources_list);
		node.texture_click_mask = _get_resource_into_image(img_data);
	
	if (dep_dict.has("texture_disabled") == true):
		var img_data = _get_resource_from_dep_dict("texture_disabled", dep_dict, resources_list);
		node.texture_disabled = _get_resource_into_image(img_data);
	
	if (dep_dict.has("texture_focused") == true):
		var img_data = _get_resource_from_dep_dict("texture_focused", dep_dict, resources_list);
		node.texture_focused = _get_resource_into_image(img_data);
	
	if (dep_dict.has("texture_hover") == true):
		var img_data = _get_resource_from_dep_dict("texture_hover", dep_dict, resources_list);
		node.texture_hover = _get_resource_into_image(img_data);
	
	if (dep_dict.has("texture_normal") == true):
		var img_data = _get_resource_from_dep_dict("texture_normal", dep_dict, resources_list);
		node.texture_normal = _get_resource_into_image(img_data);
	
	if (dep_dict.has("texture_pressed") == true):
		var img_data = _get_resource_from_dep_dict("texture_pressed", dep_dict, resources_list);
		node.texture_pressed = _get_resource_into_image(img_data);

# ==

# == Spatial (And Spatial extending) nodes

func _load_resources_spatial(node, dep_dict, resources_list):
	# This will load the Spatial's basic resources.
	# Right now this loads the following:
		# gizmo
	
	if (dep_dict.has("gizmo") == true):
		node.gizmo = _get_resource_from_dep_dict("gizmo", dep_dict, resources_list);

func _load_resources_camera(node, dep_dict, resources_list):
	# This will load the Camera's basic resources.
	# Right now this loads the following:
		# environment
	
	if (dep_dict.has("environment") == true):
		node.environment = _get_resource_from_dep_dict("environment", dep_dict, resources_list);

func _load_resources_collision_shape(node, dep_dict, resources_list):
	# This will load the CollisionShape's basic resources.
	# Right now this loads the following:
		# shape
	
	if (dep_dict.has("shape") == true):
		node.shape = _get_resource_from_dep_dict("shape", dep_dict, resources_list);

func _load_resources_audio_stream_player3d(node, dep_dict, resources_list):
	# This will load the AudioStreamPlayer3D's basic resources.
	# Right now this loads the following:
		# stream
	
	if (dep_dict.has("stream") == true):
		node.stream = _get_resource_from_dep_dict("stream", dep_dict, resources_list);

func _load_resources_path(node, dep_dict, resources_list):
	# This will load the Path's basic resources.
	# Right now this loads the following:
		# curve
	
	if (dep_dict.has("curve") == true):
		node.curve = _get_resource_from_dep_dict("curve", dep_dict, resources_list);

func _load_resources_baked_lightmap(node, dep_dict, resources_list):
	# This will load the BakedLightmap's basic resources.
	# Right now this loads the following:
		# light_data
	
	if (dep_dict.has("light_data") == true):
		node.light_data = _get_resource_from_dep_dict("light_data", dep_dict, resources_list);

func _load_resources_gi_probe(node, dep_dict, resources_list):
	# This will load the GIProbe's basic resources.
	# Right now this loads the following:
		# data
	
	if (dep_dict.has("data") == true):
		node.data = _get_resource_from_dep_dict("data", dep_dict, resources_list);

func _load_resources_geometry_instance(node, dep_dict, resources_list):
	# This will load the GeometryInstance's basic resources.
	# Right now this loads the following:
		# material_override (ShaderMaterial and SpatialMaterial)
	
	if (dep_dict.has("material_override_shader_material") == true):
		node.material_override = _get_resource_from_dep_dict("material_override_shader_material", dep_dict, resources_list);
	elif (dep_dict.has("material_override_spatial_material") == true):
		node.material_override = _get_resource_from_dep_dict("material_override_spatial_material", dep_dict, resources_list);
		__load_resources_spatial_material(node.material_override, dep_dict, resources_list);
	

func _load_resources_multi_mesh(node, dep_dict, resources_list):
	# This will load the MultiMesh's basic resources.
	# Right now this loads the following:
		# mesh
	
	if (dep_dict.has("mesh") == true):
		node.mesh = _get_resource_from_dep_dict("mesh", dep_dict, resources_list);
		__load_resources_mesh(node.mesh, dep_dict, resources_list);

func _load_resources_mesh_instance(node, dep_dict, resources_list):
	# This will load the MeshInstance's basic resources.
	# Right now this loads the following:
		# mesh
	
	if (dep_dict.has("mesh") == true):
		node.mesh = _get_resource_from_dep_dict("mesh", dep_dict, resources_list);
		__load_resources_mesh(node.mesh, dep_dict, resources_list);

func _load_resources_particles(node, dep_dict, resources_list):
	# This will load the Particles's basic resources.
	# Right now this loads the following:
		# draw_pass_1, draw_pass_2, draw_pass_3, draw_pass_4,
		#process_material
	
	if (dep_dict.has("draw_pass_1") == true):
		node.draw_pass_1 = _get_resource_from_dep_dict("draw_pass_1", dep_dict, resources_list);
	
	if (dep_dict.has("draw_pass_2") == true):
		node.draw_pass_2 = _get_resource_from_dep_dict("draw_pass_2", dep_dict, resources_list);
	
	if (dep_dict.has("draw_pass_3") == true):
		node.draw_pass_3 = _get_resource_from_dep_dict("draw_pass_3", dep_dict, resources_list);
	
	if (dep_dict.has("draw_pass_4") == true):
		node.draw_pass_4 = _get_resource_from_dep_dict("draw_pass_4", dep_dict, resources_list);
	
	if (dep_dict.has("process_material") == true):
		node.process_material = _get_resource_from_dep_dict("process_material", dep_dict, resources_list);

func _load_resources_animated_sprite3d(node, dep_dict, resources_list):
	# This will load the AnimatedSprite3D's basic resources.
	# Right now this loads the following:
		# frames
	
	if (dep_dict.has("frames") == true):
		node.frames = _get_resource_from_dep_dict("frames", dep_dict, resources_list);

func _load_resources_sprite3d(node, dep_dict, resources_list):
	# This will load the Sprite3D's basic resources.
	# Right now this loads the following:
		# texture
	
	if (dep_dict.has("texture") == true):
		var img_data = _get_resource_from_dep_dict("texture", dep_dict, resources_list);
		node.texture = _get_resource_into_image(img_data);

func _load_resources_navigation_mesh_instance(node, dep_dict, resources_list):
	# This will load the NavigationMeshInstance's basic resources.
	# Right now this loads the following:
		# navmesh
	
	if (dep_dict.has("navmesh") == true):
		node.navmesh = _get_resource_from_dep_dict("navmesh", dep_dict, resources_list);

func _load_resources_grid_map(node, dep_dict, resources_list):
	# This will load the GridMap's basic resources.
	# Right now this loads the following:
		# theme
	
	if (dep_dict.has("grid_map_theme_size") != null):
		var grid_map_theme = MeshLibrary.new();
		var theme_list_size = dep_dict["grid_map_theme_size"];
		
		for i in range(0, theme_list_size):
			grid_map_theme.create_item(i);
			
			if (dep_dict.has("grid_map_theme_mesh_" + str(i)) == true):
				var theme_mesh = _get_resource_from_dep_dict("grid_map_theme_mesh_" + str(i), dep_dict, resources_list);
				__load_resources_mesh(theme_mesh, dep_dict, resources_list);
				grid_map_theme.set_item_mesh(i, theme_mesh);
			
			if (dep_dict.has("grid_map_theme_name_" + str(i)) == true):
				grid_map_theme.set_item_name(i, dep_dict["grid_map_theme_name_" + str(i)]);
			
			if (dep_dict.has("grid_map_theme_navmesh_" + str(i)) == true):
				grid_map_theme.set_item_navmesh(i, _get_resource_from_dep_dict("grid_map_theme_navmesh_" + str(i), dep_dict, resources_list));
			
			if (dep_dict.has("grid_map_theme_preview_" + str(i)) == true):
				var img_data = _get_resource_from_dep_dict("grid_map_theme_preview_" + str(i), dep_dict, resources_list);
				grid_map_theme.set_item_preview(i, _get_resource_into_image(img_data));
			
			if (dep_dict.has("grid_map_theme_shape_size_" + str(i)) == true):
				var theme_shape_size = dep_dict["grid_map_theme_shape_size_" + str(i)];
				var theme_shape_array = [];
				
				for j in range(0, theme_shape_size):
					theme_shape_array.append(_get_resource_from_dep_dict("grid_map_theme_shape_" + str(i) + str(j), dep_dict, resources_list));
				
				grid_map_theme.set_item_shapes(i, theme_shape_array);
		
		node.theme = grid_map_theme;
	
	"""
	if (dep_dict.has("theme") == true):
		node.theme = _get_resource_from_dep_dict("theme", dep_dict, resources_list);
	"""

# ==

# ==========================================

