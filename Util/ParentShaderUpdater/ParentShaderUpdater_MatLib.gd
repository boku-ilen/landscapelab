class_name PSU_MatLib extends RefCounted

# Storing in which usage slot the material was found first.
# Should match a similar enum in ParentShaderUpdater.gd which tracks progress of func "get_current_mats_validate".
enum MaterialSlot {
	PARTICLEPROCESSMAT = 0, # Additional type found on GPU particles
	PARTICLEPROCESSMAT_NEXTPASS = 1, # Found on a ParticleProcessMat's NextPass slot.
	CANVASITEMMAT = 2, # Mat is assigned on CanvasItem.
	CANVASITEMMAT_NEXTPASS = 3, # Found on a CanvasItemMat's NextPass slot..
	GEOMETRYMAT_OVERRIDE = 4, # Highest priority: property "material_override"
	GEOMETRYMAT_OVERRIDE_NEXTPASS = 5, # Found on a GeometryMat's NextPass slot.
	SURFACEMAT_OVERRIDE = 6,  # Medium priority: property "surface_material_override"
	SURFACEMAT_OVERRIDE_NEXTPASS = 7,  # Found on a Surfacemat_Override's NextPass slot.
	SURFACEMAT = 8, # Low priority: property "material", only used if no SurfaceMat Override exists for that slot.
	SURFACEMAT_NEXTPASS = 9, # Found on a SurfaceMat's NextPass slot..

}

static var debug_mode := true ## Change this to a global Debug_Mode in the future Manager!
var material : Material # Only ShaderMaterial types are required for final Update functionality, but in between all types of materials need to be handled.
var material_slot : MaterialSlot # In which slot the material was found
var source_node : Node # On which Node in the level this material was first found, usually the Parent of the "ParentShaderUpdater" node.
var shader_path : String # Filled later by running fill_shader_paths() only on arrays containing valid ShaderMaterials to reduce overhead.


static func append_unique_mat_to_array(material: Material, array: Array[Material]) -> bool: # True if material was added
	if material in array or material == null:
		return false
	array.append(material)
	return true

static func append_unique_matlib_to_array(matlib : PSU_MatLib, array_matlib : Array[PSU_MatLib], debug_arrayname : String) -> bool:
	# Abort if Check via lambda (if input matlib.material already exists in input array_matlib) triggers
	if array_matlib.filter(func(matlib_from_array): return matlib_from_array.material == matlib.material).size() > 0 or \
		matlib == null or matlib.material == null:
		return false
		
	array_matlib.append(matlib)
	if debug_mode:
		if matlib.material is ShaderMaterial and matlib.material.shader != null:
			print("PSU: Parent '", matlib.source_node.name, "': MatLib '", debug_arrayname, "' added Mat '", matlib.material.resource_path.get_file(), "' (Slot '", matlib.MaterialSlot.find_key(matlib.material_slot), "', Shader '", matlib.material.shader.resource_path.get_file(), "')")
		else:
			print("PSU: Parent '", matlib.source_node.name, "': MatLib '", debug_arrayname, "' added Mat '", matlib.material.resource_path.get_file(), "' (Slot '", matlib.MaterialSlot.find_key(matlib.material_slot), "')")
	return true

static func convert_to_matlib(mat : Material, mat_slot : MaterialSlot, src_node : Node):
	var converted_to_matlib := PSU_MatLib.new()
	converted_to_matlib.material = mat
	converted_to_matlib.material_slot = mat_slot
	converted_to_matlib.source_node = src_node
	return converted_to_matlib

static func convert_append_unique_matlib_to_array(mat : Material, mat_slot : MaterialSlot, src_node : Node, array_matlib : Array[PSU_MatLib], debug_arrayname : String) -> bool:
	return append_unique_matlib_to_array(convert_to_matlib(mat, mat_slot, src_node), array_matlib, debug_arrayname)

# Returns array of all Materials in MatLib format whose "shader_path" matches input string
static func get_matlibs_matching_shader_path(find_in_shader_path : String, array_matlib : Array[PSU_MatLib]) -> Array[PSU_MatLib]:
	var matlibs_matching_saved : Array[PSU_MatLib]
	for index in array_matlib.filter(func(matlib_from_array): return matlib_from_array.shader_path == find_in_shader_path):
		append_unique_matlib_to_array(index, matlibs_matching_saved, "Current_Updatable_Mats_Match_Saved")
	return matlibs_matching_saved

static func fill_shader_paths(array_matlib : Array[PSU_MatLib], debug_arrayname : String) -> bool:
	if array_matlib.size() < 1:
		print("PSU: MatLib '", debug_arrayname, "' contains no Mats to get 'resource_path'!")
		return false
	for index in array_matlib:
		index.shader_path = index.material.shader.resource_path
	return true
