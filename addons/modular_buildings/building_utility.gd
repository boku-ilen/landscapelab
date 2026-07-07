extends Resource
class_name BuildingUtility

static func copy_standard_to_shader(
		standard : Material,
		shader_mat : Material
) -> void:
	if not standard is StandardMaterial3D or not shader_mat is ShaderMaterial:
		return
	# Gather the uniforms that CAN be written on this material 
	var writable_uniforms : Dictionary = {}
	for info in shader_mat.shader.get_shader_uniform_list():   # returns Array<Dictionary>
		writable_uniforms[info.name] = true
	
	# Iterate every serialised property of the StandardMaterial3D
	for prop_info in standard.get_property_list():
		# ignore editor-only or internal props
		if (prop_info.usage & PROPERTY_USAGE_STORAGE) == 0:
			continue

		var key : String = prop_info.name
		var value         = standard.get(key)
		
		if writable_uniforms.has(key):
			shader_mat.set_shader_parameter(key, value)   


static func apply_to_all_meshes_in_tree(node: Node3D, callback_mesh: Callable, callback_node: Callable):
	if node is VisualInstance3D:
		if not "mesh" in node: return
		callback_node.call(node)
		for surface_idx in range(node.mesh.get_surface_count()):
			callback_mesh.call(node.mesh, surface_idx)
	
	for child in node.get_children():
		apply_to_all_meshes_in_tree(child, callback_mesh, callback_node)

## Roughly measure the width (X‑axis length) of an asset by instantiating it once.
## Cache results for performance.
static var width_cache := {}


static func get_node_width(scene: Node3D) -> float:
	if width_cache.has(scene):
		return width_cache[scene]
	var inst := scene.instantiate() as Node3D
	var aabb = get_combined_aabb(inst)
	var width = aabb.size.x
	width_cache[scene] = width
	inst.queue_free()
	return width


static func get_combined_aabb(instance: Node3D, aabb: AABB = AABB(), variable_name := "aabb") -> AABB:
	for child in instance.get_children():
		if not child is Node3D: continue
		aabb = get_combined_aabb(child, aabb, variable_name)
	
	if instance is VisualInstance3D:
		return aabb.merge(instance.get_aabb() if variable_name == "aabb" else instance.get(variable_name))
	return aabb
