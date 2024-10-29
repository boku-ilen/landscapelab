class_name PSU_MatLib extends RefCounted

# Storing in which usage slot the material was found first.
# Should match a similar enum in ParentShaderUpdater.gd, that tracks the state of func get_current_materials!
enum MaterialSlot {
	PARTICLEPROCESSMAT = 0, # Additional type found on GPU particles
	PARTICLEPROCESSMAT_NEXTPASS = 1, # Nextpass Mat
	CANVASITEMMAT = 2, # Mat is assigned on CanvasItem # NOT YET IMPLEMENTED, MAYBE NOT NECESSARY
	CANVASITEMMAT_NEXTPASS = 3, # Nextpass Mat
	SURFACEMAT = 4, # Low priority: property "material", only used if no SurfaceMat Override exists for that slot
	SURFACEMAT_NEXTPASS = 5, # Nextpass Mat
	SURFACEMAT_OVERRIDE = 6,  # Medium priority: property "surface_material_override"
	SURFACEMAT_OVERRIDE_NEXTPASS = 7,  # Nextpass Mat
	GEOMETRYMAT_OVERRIDE = 8, # High priority: property "material_override"
	GEOMETRYMAT_OVERRIDE_NEXTPASS = 9, # Nextpass Mat	
}

static var debug_mode := true ## Change this to a global Debug_Mode in the future Manager!
var material : Material # Only ShaderMaterial types are required for final Update functionality, but in between all types of materials need to be handled.
var material_slot : MaterialSlot # In which slot the material was found
var source_node : Node # On which Node(s) in the level this material was found
var shader_path : String # Is filled later by running fill_shader_paths() only on arrays containing valid ShaderMaterials to reduce overhead.

static func convert_to_matlib(mat : Material, mat_slot : MaterialSlot, src_node : Node):
	var converted_to_matlib := PSU_MatLib.new()
	converted_to_matlib.material = mat
	converted_to_matlib.material_slot = mat_slot
	converted_to_matlib.source_node = src_node
	return converted_to_matlib

static func convert_to_matlib_append_unique_to_array(mat : Material, mat_slot : MaterialSlot, src_node : Node, array_matlib : Array[PSU_MatLib], debug_arrayname : String) -> bool:
	return append_unique_matlib_to_array(convert_to_matlib(mat, mat_slot, src_node), array_matlib, debug_arrayname)

static func append_unique_matlib_to_array(matlib : PSU_MatLib, array_matlib : Array[PSU_MatLib], debug_arrayname : String) -> bool:
	# Abort if Check via lambda (if input matlib.material already exists in input array_matlib) triggers
	if array_matlib.filter(func(matlib_from_array): return matlib_from_array.material == matlib.material).size() > 0:
		return false
		
	array_matlib.append(matlib)
	if debug_mode: print("PSU: MatLib '", debug_arrayname, "' added Mat '", matlib.material.resource_path.get_file(), "'.")
	return true

static func fill_shader_paths(array_matlib : Array[PSU_MatLib], debug_arrayname : String) -> bool:
	if array_matlib.size() < 1:
		print("PSU: MatLib '", debug_arrayname, "' contains no Mats to get 'resource_path'!")
		return false
		
	for index in array_matlib:
		index.shader_path = index.material.shader.resource_path
	return true
